import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';

part 'readout_faces.dart';

/// A mechanical split-flap readout: each character printed on its own flap
/// card, split by the hinge line, behind a small recessed window. The cards
/// are dark instrument parts in every theme and mode (like the gauge faces),
/// so their inks are fixed; only the window rim takes the family's metal.
///
/// Like a real flap display, a digit only moves forward: going from 3 to 7
/// it clicks through 4, 5 and 6. Whenever [epoch] changes (the gauges' sweep
/// epoch) every digit resets to 0 and clicks up to its value, in step with
/// the liquid rising in the gauge tube.
class FlipReadout extends StatelessWidget {
  const FlipReadout({
    super.key,
    required this.text,
    this.fontSize = 20,
    this.epoch = 0,
  });

  final String text;

  /// Glyph size; the cards scale from it.
  final double fontSize;

  /// Bump to replay the count-up from zero.
  final int epoch;

  /// Forces the motion on under `flutter test` (motion is otherwise off
  /// there), for the mechanism test and its filmstrip.
  @visibleForTesting
  static bool debugForceMotion = false;

  static bool get _animate => kMolAnimationsEnabled || debugForceMotion;

  @override
  Widget build(BuildContext context) {
    final look = ReadoutLook.of(context, fontSize);
    return Container(
      padding: EdgeInsets.all(fontSize * 0.14),
      decoration: look.window,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < text.length; i++) ...[
            if (i > 0) SizedBox(width: fontSize * look.gap),
            _FlapCard(
              key: ValueKey(i),
              char: text[i],
              epoch: epoch,
              face: look.face,
              flap: look.flap,
              delay: Duration(milliseconds: 90 * i),
            ),
          ],
        ],
      ),
    );
  }
}

bool _isDigit(String c) => '0123456789'.contains(c);

/// The flaps a position passes on its way from [from] to [to]: digits move
/// forward only (wrapping 9 → 0); anything else drops straight in.
List<String> _path(String from, String to) {
  if (from == to) return const [];
  if (!_isDigit(from) || !_isDigit(to)) return [to];
  final a = int.parse(from), b = int.parse(to);
  final steps = (b - a) % 10;
  return [for (var k = 1; k <= steps; k++) '${(a + k) % 10}'];
}

/// One flap position: flips through [_path] one card at a time. Each flip:
/// the shown upper leaf falls on the hinge, uncovering the next card's upper
/// half, then the next card's lower leaf drops over the old lower half.
class _FlapCard extends StatefulWidget {
  const _FlapCard({
    super.key,
    required this.char,
    required this.epoch,
    required this.face,
    required this.flap,
    required this.delay,
  });

  final String char;
  final int epoch;

  /// Draws one character in the kit's idiom (a flap card, an LCD digit, a
  /// Nixie tube...).
  final Widget Function(String char) face;

  /// Flip leaves on a hinge (split-flap); otherwise characters crossfade as
  /// they step, like segments or cathodes switching.
  final bool flap;

  /// Stagger, so a multi-digit change ripples left to right.
  final Duration delay;

  @override
  State<_FlapCard> createState() => _FlapCardState();
}

class _FlapCardState extends State<_FlapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;

  /// The card resting in the window, and the one falling onto it.
  late String _shown;
  String? _next;
  final List<String> _queue = [];
  bool _running = false;

  @override
  void initState() {
    super.initState();
    // Created here, not lazily: a lazy controller first touched in
    // dispose() would be built on an unmounted element.
    _flip = AnimationController(vsync: this);
    final target = widget.char;
    if (FlipReadout._animate && _isDigit(target)) {
      // A fresh card starts at 0 and clicks up to its value.
      _shown = '0';
      _queue.addAll(_path('0', target));
      _run(initialDelay: widget.delay);
    } else {
      _shown = target;
    }
  }

  /// Where this flap will rest once the flip in flight lands.
  String get _landing => _next ?? _shown;

  @override
  void didUpdateWidget(_FlapCard old) {
    super.didUpdateWidget(old);
    if (!FlipReadout._animate) {
      _shown = widget.char;
      return;
    }
    final target = widget.char;
    if (old.epoch != widget.epoch && _isDigit(target)) {
      // Replay: a flap cannot jump, so it rolls on round to 0 and then
      // counts up to the value, in step with the gauge's liquid.
      _queue
        ..clear()
        ..addAll(_path(_landing, '0'))
        ..addAll(_path('0', target));
      _run(initialDelay: widget.delay);
    } else if (old.char != target) {
      _queue
        ..clear()
        ..addAll(_path(_landing, target));
      _run();
    }
  }

  /// Works through [_queue] one flip at a time. Each flip owns its card, so
  /// a queue rewritten mid-flip (a replay or a new value) never disturbs the
  /// flip in flight; the loop simply continues with the new queue.
  Future<void> _run({Duration initialDelay = Duration.zero}) async {
    if (_running) return;
    _running = true;
    if (initialDelay > Duration.zero) await Future.delayed(initialDelay);
    while (mounted && _queue.isNotEmpty) {
      // A long run clicks fast; a single change gets a slower, heavier flip.
      _flip.duration = widget.flap
          ? Duration(milliseconds: _queue.length > 1 ? 120 : 380)
          : Duration(milliseconds: _queue.length > 1 ? 70 : 220);
      final step = _queue.removeAt(0);
      setState(() => _next = step);
      await _flip.forward(from: 0);
      if (!mounted) break;
      setState(() {
        _shown = step;
        _next = null;
      });
    }
    if (mounted) _flip.value = 0;
    _running = false;
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Widget _face(String c) => widget.face(c);

  /// The upper or lower half of a card, clipped at the hinge.
  Widget _half(String c, {required bool top}) => ClipRect(
    child: Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      heightFactor: 0.5,
      child: _face(c),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final next = _next;
    if (next == null) return _face(_shown);
    if (!widget.flap) {
      return AnimatedBuilder(
        animation: _flip,
        builder: (context, _) => Stack(
          children: [
            Opacity(opacity: 1 - _flip.value, child: _face(_shown)),
            Opacity(opacity: _flip.value, child: _face(next)),
          ],
        ),
      );
    }
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final t = _flip.value;
        final falling = t < 0.5;
        // Perspective tilt about the hinge; at 90° a leaf is edge-on.
        final angle = (falling ? t : 1 - t) * math.pi;
        final tilt = Matrix4.identity()
          ..setEntry(3, 2, 0.006)
          ..rotateX(falling ? angle : -angle);
        final hinge = falling ? Alignment.bottomCenter : Alignment.topCenter;
        // A leaf darkens as it turns away from the light.
        final shade = Color.fromRGBO(0, 0, 0, 0.55 * math.sin(angle));
        return Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [_half(next, top: true), _half(_shown, top: false)],
            ),
            Positioned(
              left: 0,
              right: 0,
              top: falling ? 0 : null,
              bottom: falling ? null : 0,
              child: Transform(
                alignment: hinge,
                transform: tilt,
                child: Stack(
                  children: [
                    _half(falling ? _shown : next, top: falling),
                    Positioned.fill(child: ColoredBox(color: shade)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.char,
    required this.height,
    required this.fontSize,
    required this.font,
  });

  final String char;
  final double height;
  final double fontSize;
  final String? font;

  @override
  Widget build(BuildContext context) {
    final narrow = char == '/' || char == '.' || char == ':';
    final width = fontSize * (narrow ? 0.48 : 0.74);
    final radius = Radius.circular(fontSize * 0.1);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Upper leaf (lit from above) and lower leaf (in its shadow).
          Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: radius),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF34352F), Color(0xFF22231F)],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(bottom: radius),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A1B18), Color(0xFF111210)],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              char,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: font,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                height: 1,
                color: const Color(0xFFEDE6D2),
                fontFeatures: const [
                  FontFeature.liningFigures(),
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          // The hinge: a dark split with a faint lit edge under it, drawn
          // across the glyph as on a real flap.
          Positioned(
            left: 0,
            right: 0,
            top: height / 2 - 0.6,
            child: Container(height: 1.2, color: const Color(0xE6000000)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: height / 2 + 0.6,
            child: Container(height: 0.6, color: const Color(0x1FFFFFFF)),
          ),
          // Lower leaf sits in shadow: darken the glyph's lower half a little.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height / 2,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: radius),
                  color: const Color(0x26000000),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
