import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';

/// The non-Brass instrument kits' meters, dials and toggles. The shared
/// widgets (RecessedBar, LiquidTube, InstrumentGauge, BrassToggle) keep their
/// Brass rendering and hand every other family to these.

Color _at(List<Color> colors, double t) {
  if (colors.isEmpty) return Colors.grey;
  if (colors.length == 1) return colors.first;
  final x = t.clamp(0.0, 1.0) * (colors.length - 1);
  final i = x.floor().clamp(0, colors.length - 2);
  return Color.lerp(colors[i], colors[i + 1], x - i)!;
}

// ---------------------------------------------------------------- meters --

/// A horizontal meter in the active kit's idiom, filling to [fraction].
/// [colors] run along its length (a load ramp or a single colour).
class KitMeter extends StatelessWidget {
  const KitMeter({
    super.key,
    required this.fraction,
    required this.colors,
    this.height = 12,
    this.epoch = 0,
  });

  final double fraction;
  final List<Color> colors;
  final double height;
  final int epoch;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final b = context.brass;
    final target = fraction.clamp(0.0, 1.0);
    return SizedBox(
      height: math.max(height, kit == InstrumentKit.nord ? 8 : 10),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(epoch),
        tween: Tween(begin: kMolAnimationsEnabled ? 0 : target, end: target),
        duration: kMolAnimationsEnabled
            ? const Duration(milliseconds: 1000)
            : Duration.zero,
        curve: const Cubic(0.2, 0.8, 0.2, 1),
        builder: (context, v, _) => kit == InstrumentKit.aqua
            ? _GelBar(fraction: v, colors: colors, dark: b.isDark)
            : CustomPaint(
                painter: _MeterPainter(kit, b, v, colors),
                child: const SizedBox.expand(),
              ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter(this.kit, this.b, this.fraction, this.colors);

  final InstrumentKit kit;
  final Brass b;
  final double fraction;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kit) {
      case InstrumentKit.graphite:
        _cells(canvas, size, 10, gap: 2, radius: 1,
            off: b.isDark ? const Color(0xFF2A2F35) : const Color(0xFFCDD2D8));
      case InstrumentKit.terminal:
        _cells(canvas, size, 24, gap: 1.5, radius: 0,
            off: const Color(0x1A39FF6A), glow: true,
            tint: const Color(0xFF39FF6A));
      case InstrumentKit.obsidian:
        // Steel cells: the metric's own (low-chroma) colour, a faint glow.
        _cells(canvas, size, 14, gap: 2, radius: 0.5,
            off: b.isDark ? const Color(0xFF17181A) : const Color(0xFFD9DBDF),
            glow: b.isDark, dim: 0.9);
      case InstrumentKit.catppuccin:
        _cells(canvas, size, 8, gap: 3, radius: size.height / 2,
            off: b.isDark ? const Color(0xFF45475A) : const Color(0xFFCCD0DA));
      case InstrumentKit.nord:
        _strip(canvas, size);
      case InstrumentKit.ember:
        _magicEye(canvas, size);
      case InstrumentKit.brass:
      case InstrumentKit.aqua:
        break;
    }
  }

  /// A segmented bar graph: [n] cells, lit up to [fraction].
  void _cells(
    Canvas canvas,
    Size size,
    int n, {
    required double gap,
    required double radius,
    required Color off,
    bool glow = false,
    Color? tint,
    double dim = 1,
  }) {
    final w = (size.width - gap * (n - 1)) / n;
    final lit = (fraction * n).round();
    for (var i = 0; i < n; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (w + gap), 0, w, size.height),
        Radius.circular(math.min(radius, w / 2)),
      );
      if (i < lit) {
        final c = (tint ?? _at(colors, (i + 0.5) / n)).withValues(alpha: dim);
        if (glow) {
          canvas.drawRRect(
            r,
            Paint()
              ..color = c.withValues(alpha: 0.6 * dim)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
        canvas.drawRRect(r, Paint()..color = c);
        // A faint highlight along the top of each lit cell.
        canvas.drawLine(
          Offset(r.left + 1, r.top + 1),
          Offset(r.right - 1, r.top + 1),
          Paint()
            ..strokeWidth = 1
            ..color = Colors.white.withValues(alpha: 0.25),
        );
      } else {
        canvas.drawRRect(r, Paint()..color = off);
      }
    }
  }

  /// Cockpit LED strip: a hairline track and a thin glowing bar with a
  /// bright leading edge.
  void _strip(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final c = _at(colors, 1);
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF88C0D0).withValues(alpha: 0.18),
    );
    final end = size.width * fraction;
    if (end <= 0) return;
    final bar = Paint()
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: colors.length > 1 ? colors : [c, c])
          .createShader(Offset.zero & size);
    canvas.drawLine(
      Offset(0, cy),
      Offset(end, cy),
      Paint()
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = c.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawLine(Offset(0, cy), Offset(end, cy), bar);
    canvas.drawCircle(Offset(end, cy), 2.6, Paint()..color = Colors.white);
  }

  /// A "magic eye" tuning indicator: green phosphor spreading from the
  /// centre of a smoked-glass window as the value rises.
  void _magicEye(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF0B120C));
    canvas.save();
    canvas.clipRRect(rr);
    const phosphor = Color(0xFF6CFF9C);
    // Unlit phosphor still glows faintly.
    canvas.drawRect(rect, Paint()..color = phosphor.withValues(alpha: 0.08));
    final half = size.width / 2 * fraction;
    final lit = Rect.fromLTRB(
        size.width / 2 - half, 0, size.width / 2 + half, size.height);
    canvas.drawRect(
      lit,
      Paint()
        ..color = phosphor.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawRect(
      lit.deflate(1.5),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E9E57), phosphor, Color(0xFF2E9E57)],
        ).createShader(lit),
    );
    canvas.restore();
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x99B9A58C),
    );
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.kit != kit ||
      !identical(old.b, b) ||
      old.fraction != fraction ||
      old.colors != colors;
}

/// An Aqua gel bar: a glossy capsule of coloured gel with moving diagonal
/// stripes (the stripes stand still under `flutter test`).
class _GelBar extends StatefulWidget {
  const _GelBar({
    required this.fraction,
    required this.colors,
    required this.dark,
  });

  final double fraction;
  final List<Color> colors;
  final bool dark;

  @override
  State<_GelBar> createState() => _GelBarState();
}

class _GelBarState extends State<_GelBar> with SingleTickerProviderStateMixin {
  late final AnimationController _stripes;

  @override
  void initState() {
    super.initState();
    _stripes = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (kMolAnimationsEnabled) _stripes.repeat();
  }

  @override
  void dispose() {
    _stripes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _stripes,
    builder: (context, _) => CustomPaint(
      painter: _GelPainter(
        widget.fraction,
        widget.colors,
        widget.dark,
        _stripes.value,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _GelPainter extends CustomPainter {
  _GelPainter(this.fraction, this.colors, this.dark, this.phase);

  final double fraction;
  final List<Color> colors;
  final bool dark;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final rect = Offset.zero & size;
    final track = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
    canvas.drawRRect(
      track,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF1A1A1C), Color(0xFF3A3A3C)]
              : const [Color(0xFFC9CDD3), Color(0xFFEDEFF2)],
        ).createShader(rect),
    );
    final w = math.max(size.width * fraction, h);
    if (fraction > 0) {
      final gel = Rect.fromLTWH(0, 0, w, h);
      final rr = RRect.fromRectAndRadius(gel, Radius.circular(h / 2));
      final c = _at(colors, 1);
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawRect(
        gel,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(c, Colors.white, 0.35)!,
              c,
              Color.lerp(c, Colors.black, 0.25)!,
              Color.lerp(c, Colors.white, 0.2)!,
            ],
            stops: const [0, 0.45, 0.55, 1],
          ).createShader(gel),
      );
      // Barber-pole stripes drifting right.
      final stripe = Paint()..color = Colors.white.withValues(alpha: 0.16);
      final pitch = h * 1.6;
      for (var x = -h * 2 + phase * pitch; x < w + h; x += pitch) {
        canvas.drawPath(
          Path()
            ..moveTo(x, h)
            ..lineTo(x + h * 0.8, 0)
            ..lineTo(x + h * 0.8 + pitch / 2, 0)
            ..lineTo(x + pitch / 2, h)
            ..close(),
          stripe,
        );
      }
      // The gloss: a hard white highlight across the upper half.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(h * 0.3, 1, w - h * 0.6, h * 0.42),
          Radius.circular(h / 4),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
      canvas.restore();
    }
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = dark ? const Color(0xFF5A5A5E) : const Color(0xFF9DA4AE),
    );
  }

  @override
  bool shouldRepaint(_GelPainter old) =>
      old.fraction != fraction ||
      old.colors != colors ||
      old.dark != dark ||
      old.phase != phase;
}

// ----------------------------------------------------------------- dials --

/// The face and value indicator of a round dial in the active kit's idiom
/// (the readout is placed by [kitReadoutAlignment]). Geometry in a 130-unit
/// space, scaled to the widget.
class KitDialPainter extends CustomPainter {
  KitDialPainter(this.kit, this.b, this.fraction, this.color);

  final InstrumentKit kit;
  final Brass b;
  final double fraction;
  final Color color;

  static const _c = Offset(65, 65);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 130, size.height / 130);
    switch (kit) {
      case InstrumentKit.graphite:
        _braun(canvas);
      case InstrumentKit.terminal:
        _vectorScope(canvas);
      case InstrumentKit.nord:
        _cockpit(canvas);
      case InstrumentKit.ember:
        _vu(canvas);
      case InstrumentKit.obsidian:
        _nightVision(canvas);
      case InstrumentKit.aqua:
        _glass(canvas);
      case InstrumentKit.catppuccin:
        _soft(canvas);
      case InstrumentKit.brass:
        break;
    }
    canvas.restore();
  }

  void _ring(Canvas canvas, double r, Color c, double w) => canvas.drawCircle(
    _c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c,
  );

  void _ticks(Canvas canvas, double rOut, double rIn, double rMajor, Color c,
      {double start = -225, double sweep = 270, int n = 27, int every = 5}) {
    for (var i = 0; i <= n; i++) {
      final a = (start + sweep * i / n) * math.pi / 180;
      final major = i % every == 0;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        _c + d * rOut,
        _c + d * (major ? rMajor : rIn),
        Paint()
          ..strokeWidth = major ? 1.6 : 0.8
          ..color = major ? c : c.withValues(alpha: 0.5),
      );
    }
  }

  void _needle(Canvas canvas, Offset pivot, double angle, double len,
      Color body, Color tip, {double width = 1.6}) {
    final d = Offset(math.cos(angle), math.sin(angle));
    canvas.drawLine(
      pivot + const Offset(1, 2),
      pivot + d * len + const Offset(1, 2),
      Paint()
        ..strokeWidth = width + 1
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawLine(
      pivot,
      pivot + d * len * 0.72,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = body,
    );
    canvas.drawLine(
      pivot + d * len * 0.72,
      pivot + d * len,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = tip,
    );
  }

  /// Braun lab gauge: pale face, black scale over 270°, a thin black needle
  /// with an orange pointer, black hub.
  void _braun(Canvas canvas) {
    canvas.drawCircle(_c, 62, Paint()..color = const Color(0xFF2B2F33));
    canvas.drawCircle(
      _c,
      58,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [Color(0xFFF2F3F0), Color(0xFFD9DCD6)],
        ).createShader(Rect.fromCircle(center: _c, radius: 58)),
    );
    _ticks(canvas, 54, 50, 46, const Color(0xFF1B1E21));
    // The value's own colour marks the scale up to the reading.
    const a0 = -225 * math.pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: _c, radius: 56),
      a0,
      270 * math.pi / 180 * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
    _needle(canvas, _c, a0 + 270 * math.pi / 180 * fraction, 50,
        const Color(0xFF1B1E21), const Color(0xFFFF6A00));
    canvas.drawCircle(_c, 5, Paint()..color = const Color(0xFF1B1E21));
  }

  /// Vector scope: concentric phosphor rings and the reading as a glowing
  /// trace around the outer ring.
  void _vectorScope(Canvas canvas) {
    const g = Color(0xFF39FF6A);
    canvas.drawCircle(_c, 62, Paint()..color = const Color(0xFF020703));
    for (final r in [20.0, 34.0, 48.0]) {
      _ring(canvas, r, g.withValues(alpha: 0.12), 0.8);
    }
    canvas.drawLine(const Offset(65, 6), const Offset(65, 124),
        Paint()..color = g.withValues(alpha: 0.1));
    canvas.drawLine(const Offset(6, 65), const Offset(124, 65),
        Paint()..color = g.withValues(alpha: 0.1));
    _ticks(canvas, 60, 57, 54, g.withValues(alpha: 0.6),
        start: -90, sweep: 360, n: 40);
    final sweep = 2 * math.pi * fraction;
    final rect = Rect.fromCircle(center: _c, radius: 50);
    canvas.drawArc(rect, -math.pi / 2, sweep, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawArc(rect, -math.pi / 2, sweep, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = Color.lerp(color, Colors.white, 0.3)!);
    _ring(canvas, 62, g.withValues(alpha: 0.45), 1.2);
  }

  /// Glass cockpit: navy face, labelled 270° scale, a thick value arc.
  void _cockpit(Canvas canvas) {
    canvas.drawCircle(_c, 62, Paint()..color = const Color(0xFF0D1B2A));
    _ring(canvas, 62, const Color(0x9988C0D0), 1.2);
    const start = -225 * math.pi / 180, total = 270 * math.pi / 180;
    final rect = Rect.fromCircle(center: _c, radius: 47);
    canvas.drawArc(rect, start, total, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF1E3045));
    canvas.drawArc(rect, start, total * fraction, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = color);
    _ticks(canvas, 58, 55, 53, const Color(0xFF88C0D0));
    for (final (k, label) in const [(0.0, '0'), (0.5, '50'), (1.0, '100')]) {
      final a = start + total * k;
      final p = _c + Offset(math.cos(a), math.sin(a)) * 38;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 7,
              color: Color(0xFF88C0D0)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  /// A VU meter: warm-lit cream face, black scale with a red zone, the
  /// needle swinging from a pivot low on the face.
  void _vu(Canvas canvas) {
    canvas.drawCircle(_c, 62, Paint()..color = const Color(0xFF3A2620));
    canvas.drawCircle(
      _c,
      57,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.3),
          colors: [Color(0xFFFFF1CF), Color(0xFFE9D4A4)],
        ).createShader(Rect.fromCircle(center: _c, radius: 57)),
    );
    const pivot = Offset(65, 84);
    const start = -140 * math.pi / 180, total = 100 * math.pi / 180;
    final scale = Rect.fromCircle(center: pivot, radius: 52);
    canvas.drawArc(scale, start, total * 0.75, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFF2A1F18));
    canvas.drawArc(scale, start + total * 0.75, total * 0.25, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..color = const Color(0xFFC0392B));
    for (var i = 0; i <= 10; i++) {
      final a = start + total * i / 10;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(pivot + d * 52, pivot + d * (i.isEven ? 45 : 48),
          Paint()
            ..strokeWidth = 1
            ..color = i >= 8 ? const Color(0xFFC0392B) : const Color(0xFF2A1F18));
    }
    final tp = TextPainter(
      text: const TextSpan(
        text: 'VU',
        style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A1F18)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(65 - tp.width / 2, 52));
    _needle(canvas, pivot, start + total * fraction, 54,
        const Color(0xFF1A1310), const Color(0xFF1A1310), width: 1.2);
    canvas.drawCircle(pivot, 4, Paint()..color = const Color(0xFF1A1310));
    // A warm lamp glows behind the face.
    canvas.drawCircle(
      _c,
      57,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0xFF7A4A10).withValues(alpha: 0.25)],
          stops: const [0.7, 1],
        ).createShader(Rect.fromCircle(center: _c, radius: 57)),
    );
  }

  /// Steel graticule on matte black: a fine steel crosshair and rings, the
  /// reading as a ring of tick segments in the metric's colour.
  void _nightVision(Canvas canvas) {
    const g = Color(0xFFAEB4BE);
    canvas.drawCircle(_c, 62, Paint()..color = const Color(0xFF020A04));
    _ring(canvas, 62, const Color(0xFF2C2C30), 2);
    for (final r in [18.0, 36.0]) {
      _ring(canvas, r, g.withValues(alpha: 0.12), 0.7);
    }
    for (final d in const [Offset(1, 0), Offset(0, 1)]) {
      canvas.drawLine(_c - d * 56, _c + d * 56,
          Paint()..color = g.withValues(alpha: 0.12));
    }
    const n = 36;
    final lit = (fraction * n).round();
    for (var i = 0; i < n; i++) {
      final a = (-90 + 360 * i / n) * math.pi / 180;
      final d = Offset(math.cos(a), math.sin(a));
      final on = i < lit;
      canvas.drawLine(_c + d * 46, _c + d * 56,
          Paint()
            ..strokeWidth = 3
            ..color = on ? color.withValues(alpha: 0.85) : const Color(0xFF161616));
    }
  }

  /// Aqua glass dial: a glossy face under a highlight dome, a thin silver
  /// bezel, a recessed groove, and the reading as a tube of coloured gel
  /// with a specular streak along its top and a soft shadow beneath.
  void _glass(Canvas canvas) {
    final dark = b.isDark;
    final faceRect = Rect.fromCircle(center: _c, radius: 60);
    // Face: lit from above, like glass over a pale (or graphite) dial.
    canvas.drawCircle(
      _c,
      60,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.45),
          radius: 1.05,
          colors: dark
              ? const [Color(0xFF55565C), Color(0xFF2A2A2E), Color(0xFF161618)]
              : const [Color(0xFFFFFFFF), Color(0xFFE9EEF4), Color(0xFFC9D3DF)],
          stops: const [0, 0.55, 1],
        ).createShader(faceRect),
    );
    // Silver bezel.
    canvas.drawCircle(
      _c,
      61,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..shader = const SweepGradient(
          colors: [Color(0xFFF7F8FA), Color(0xFF9AA3AE), Color(0xFFE6EAEF),
              Color(0xFF8A939E), Color(0xFFF7F8FA)],
        ).createShader(faceRect),
    );
    // Groove: the empty track, sunk into the face.
    final rect = Rect.fromCircle(center: _c, radius: 45);
    canvas.drawCircle(
      _c,
      45,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..color = dark ? const Color(0xFF111113) : const Color(0xFFBAC4D0),
    );
    canvas.drawCircle(
      _c.translate(0, 1.2),
      45,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..color = Colors.black.withValues(alpha: dark ? 0.35 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    final sweep = 2 * math.pi * fraction;
    if (sweep > 0) {
      // Shadow under the gel.
      canvas.drawArc(rect.shift(const Offset(0, 1.5)), -math.pi / 2, sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 11
            ..strokeCap = StrokeCap.round
            ..color = Colors.black.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      // The gel: shaded across its width like a filled tube.
      final deep = Color.lerp(color, Colors.black, 0.35)!;
      final shine = Color.lerp(color, Colors.white, 0.55)!;
      const r0 = 45 - 5.5, r1 = 45 + 5.5;
      canvas.drawArc(rect, -math.pi / 2, sweep, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 11
            ..strokeCap = StrokeCap.round
            ..shader = RadialGradient(
              colors: [deep, color, shine, color, deep],
              stops: const [r0 / r1, (r0 + 2.5) / r1, (r0 + 6.5) / r1,
                  (r0 + 8.5) / r1, 1],
            ).createShader(Rect.fromCircle(center: _c, radius: r1)));
      // Specular streak along the gel.
      canvas.drawArc(Rect.fromCircle(center: _c, radius: 47.5), -math.pi / 2,
          sweep, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: 0.7));
    }
    // The glass dome: a bright highlight across the upper face.
    final dome =
        Rect.fromCenter(center: const Offset(65, 36), width: 92, height: 46);
    canvas.drawOval(
      dome,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.32 : 0.75),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(dome),
    );
  }

  /// Soft synth ring: a thick rounded pastel arc on a soft track.
  void _soft(Canvas canvas) {
    final dark = b.isDark;
    canvas.drawCircle(_c, 62,
        Paint()..color = dark ? const Color(0xFF313244) : const Color(0xFFFFFFFF));
    _ring(canvas, 62, b.giltBright.withValues(alpha: 0.35), 1.5);
    final rect = Rect.fromCircle(center: _c, radius: 47);
    canvas.drawArc(rect, 0, 2 * math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..color = dark ? const Color(0xFF45475A) : const Color(0xFFDCE0E8));
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(KitDialPainter old) =>
      old.kit != kit ||
      !identical(old.b, b) ||
      old.fraction != fraction ||
      old.color != color;
}

/// Where a kit's dial puts its readout: centred, or below the needle's pivot
/// on needle dials so the needle never crosses it.
Alignment kitReadoutAlignment(InstrumentKit kit) => switch (kit) {
  InstrumentKit.graphite => const Alignment(0, 0.52),
  InstrumentKit.ember => const Alignment(0, 0.7),
  _ => Alignment.center,
};

/// Readout size on a kit's dial, relative to the Brass size.
double kitReadoutScale(InstrumentKit kit) => switch (kit) {
  InstrumentKit.graphite || InstrumentKit.ember => 0.72,
  _ => 1,
};

// --------------------------------------------------------------- toggles --

/// A toggle in the active kit's idiom; every one shows a green (on) or red
/// (off) indicator.
class KitToggle extends StatelessWidget {
  const KitToggle({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static Size sizeFor(InstrumentKit kit) => switch (kit) {
    InstrumentKit.terminal || InstrumentKit.aqua => const Size(46, 24),
    InstrumentKit.nord => const Size(32, 32),
    InstrumentKit.obsidian => const Size(30, 56),
    _ => const Size(28, 46),
  };

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final b = context.brass;
    final enabled = onChanged != null;
    final size = sizeFor(kit);
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: enabled ? () => onChanged!(!value) : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: SizedBox.fromSize(
              size: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: value ? 1 : 0),
                duration: kMolAnimationsEnabled
                    ? const Duration(milliseconds: 180)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                builder: (context, t, _) =>
                    CustomPaint(painter: _TogglePainter(kit, b, t, value)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _onGreen = Color(0xFF3FE06A);
const _offRed = Color(0xFFFF4A3D);

class _TogglePainter extends CustomPainter {
  _TogglePainter(this.kit, this.b, this.t, this.on);

  final InstrumentKit kit;
  final Brass b;
  final double t;
  final bool on;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kit) {
      case InstrumentKit.graphite:
        _rocker(canvas, size, radius: 3,
            body: b.isDark ? const Color(0xFF2B3036) : const Color(0xFFD5DADF),
            paddle: b.isDark ? const Color(0xFF41474E) : const Color(0xFFF2F4F6));
      case InstrumentKit.catppuccin:
        _rocker(canvas, size, radius: 12,
            body: b.isDark ? const Color(0xFF45475A) : const Color(0xFFCCD0DA),
            paddle: b.isDark ? const Color(0xFF585B70) : const Color(0xFFFFFFFF));
      case InstrumentKit.ember:
        _rocker(canvas, size, radius: 4,
            body: const Color(0xFF2A1A16), paddle: const Color(0xFF4A2E26));
      case InstrumentKit.terminal:
        _slide(canvas, size);
      case InstrumentKit.aqua:
        _capsule(canvas, size);
      case InstrumentKit.nord:
        _push(canvas, size);
      case InstrumentKit.obsidian:
        _guarded(canvas, size);
      case InstrumentKit.brass:
        break;
    }
  }

  void _lamp(Canvas canvas, Offset c, double r) {
    final j = on ? _onGreen : _offRed;
    canvas.drawCircle(c, r * 1.6,
        Paint()
          ..color = j.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r));
    canvas.drawCircle(c, r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.35),
            colors: [Color.lerp(j, Colors.white, 0.5)!, j,
                Color.lerp(j, Colors.black, 0.4)!],
          ).createShader(Rect.fromCircle(center: c, radius: r)));
  }

  /// A flat rocker: the paddle tips toward the pressed end, an indicator
  /// window below it.
  void _rocker(Canvas canvas, Size size,
      {required double radius, required Color body, required Color paddle}) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rr.shift(const Offset(0.5, 1.2)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    canvas.drawRRect(rr, Paint()..color = body);
    final p = Rect.fromLTWH(4, 4, size.width - 8, size.height - 18);
    final pr = RRect.fromRectAndRadius(p, Radius.circular(radius * 0.7));
    // The pressed half sits lower (darker); the raised half catches light.
    canvas.drawRRect(pr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(paddle, Colors.black, 0.25 * t)!,
              Color.lerp(paddle, Colors.black, 0.25 * (1 - t))!,
            ],
          ).createShader(p));
    canvas.drawLine(Offset(p.left + 3, p.center.dy), Offset(p.right - 3, p.center.dy),
        Paint()
          ..strokeWidth = 1
          ..color = Colors.black.withValues(alpha: 0.25));
    final ink = Paint()
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..color = b.textMuted;
    canvas.drawLine(Offset(p.center.dx, p.top + 5), Offset(p.center.dx, p.top + 10), ink);
    canvas.drawCircle(Offset(p.center.dx, p.bottom - 7.5), 2.6, ink);
    _lamp(canvas, Offset(size.width / 2, size.height - 7), 3.2);
  }

  /// A slide switch: the knob slides along a slot past a lit LED legend.
  void _slide(Canvas canvas, Size size) {
    const g = Color(0xFF39FF6A);
    final rect = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = const Color(0xFF020703));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = g.withValues(alpha: 0.5));
    final kw = size.width * 0.45;
    final kx = 2 + (size.width - kw - 4) * t;
    final knob = Rect.fromLTWH(kx, 2, kw, size.height - 4);
    canvas.drawRect(knob, Paint()..color = on ? g : const Color(0xFF1A3A22));
    if (on) {
      canvas.drawRect(knob,
          Paint()
            ..color = g.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
    final tp = TextPainter(
      text: TextSpan(
        text: on ? 'ON' : 'OFF',
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: on ? const Color(0xFF020703) : g.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, knob.center - Offset(tp.width / 2, tp.height / 2));
    _lamp(canvas, Offset(on ? 7 : size.width - 7, size.height / 2), 2.4);
  }

  /// An Aqua capsule switch: blue gel when on, grey when off, a glossy knob.
  void _capsule(Canvas canvas, Size size) {
    final h = size.height;
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
    final gel = Color.lerp(
        b.isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB),
        _onGreen, t)!;
    canvas.drawRRect(rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(gel, Colors.white, 0.3)!, gel],
          ).createShader(rect));
    canvas.drawRRect(rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.black.withValues(alpha: 0.25));
    final kc = Offset(h / 2 + (size.width - h) * t, h / 2);
    canvas.drawCircle(kc.translate(0, 1), h / 2 - 2,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    canvas.drawCircle(kc, h / 2 - 2,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.2, -0.5),
            colors: [Colors.white, Color(0xFFE6E8EB)],
          ).createShader(Rect.fromCircle(center: kc, radius: h / 2 - 2)));
    if (!on) _lamp(canvas, Offset(size.width - h / 2, h / 2), 2.4);
  }

  /// A lit push-button: the key's ring glows cyan when latched on.
  void _push(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF0D1B2A));
    if (on) {
      canvas.drawRRect(rr,
          Paint()
            ..color = const Color(0xFF88C0D0).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
    final key = RRect.fromRectAndRadius(
        rect.deflate(3 + (on ? 0.8 : 0)), const Radius.circular(4));
    canvas.drawRRect(key,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: on
                ? const [Color(0xFF2B4E66), Color(0xFF1B3346)]
                : const [Color(0xFF3B4252), Color(0xFF2B313D)],
          ).createShader(key.outerRect));
    canvas.drawRRect(rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = on ? const Color(0xFF8FD3E6) : const Color(0xFF4C566A));
    _lamp(canvas, rect.center, 3.2);
  }

  /// A guarded toggle: a bat lever under a hinged safety cover that is
  /// lifted when the switch is on.
  void _guarded(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF151517));
    canvas.drawRRect(rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF2C2C30));
    final c = Offset(size.width / 2, 24);
    canvas.drawCircle(c, 6, Paint()..color = const Color(0xFF3A3A3E));
    final tip = c.translate(0, 11 - 22 * t);
    canvas.drawLine(c, tip,
        Paint()
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFB8BCC2));
    canvas.drawCircle(tip, 3, Paint()..color = const Color(0xFFD8DCE2));
    // The cover: hinged at the top; closed over the lever when off, swung
    // up (seen nearly edge-on) when on.
    final coverH = 30 * (1 - 0.82 * t);
    final cover = Rect.fromLTWH(3, 6, size.width - 6, coverH);
    // Smoked graphite, steel-edged: low-chroma like the rest of Obsidian.
    canvas.drawRRect(RRect.fromRectAndRadius(cover, const Radius.circular(3)),
        Paint()..color = const Color(0xFF3A3D42).withValues(alpha: 0.7 + 0.2 * t));
    canvas.drawRRect(RRect.fromRectAndRadius(cover, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF9398A0));
    canvas.drawLine(const Offset(5, 6), Offset(size.width - 5, 6),
        Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFF6E7076));
    _lamp(canvas, Offset(size.width / 2, size.height - 8), 3.2);
  }

  @override
  bool shouldRepaint(_TogglePainter old) =>
      old.kit != kit || !identical(old.b, b) || old.t != t || old.on != on;
}
