import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/mol_motion.dart';

/// How much of the instrument to draw.
enum AstrolabeDetail {
  /// Everything: legend ring, rotating rete + alidade, heartbeat.
  full,

  /// Static brand mark: disc + ticks + enlarged core only.
  compact,
}

/// The Brass Edition signature emblem — a brass astronomical instrument built
/// entirely from geometric primitives, reinterpreting the house-server logo.
/// Exact geometry from design/brass/Astrolabe.dc.html (viewBox 0 0 200 200).
///
/// Placement is deliberately scarce (design: "the crown jewel"): dashboard
/// hero (120, full), masthead (46, compact), rail brand (46, compact),
/// loading splash (156, full), About modal (168, full). Nowhere else.
class Astrolabe extends StatefulWidget {
  const Astrolabe({
    super.key,
    required this.size,
    this.detail = AstrolabeDetail.full,
  });

  final double size;
  final AstrolabeDetail detail;

  @override
  State<Astrolabe> createState() => _AstrolabeState();
}

class _AstrolabeState extends State<Astrolabe> with TickerProviderStateMixin {
  AnimationController? _alidade;
  AnimationController? _rete;

  /// Static body recorded once and replayed each frame — survives across
  /// frames here in the State so only the rete + alidade repaint live.
  final _cache = _AstrolabeStaticCache();

  bool get _spins =>
      widget.detail == AstrolabeDetail.full && kMolAnimationsEnabled;

  @override
  void initState() {
    super.initState();
    if (_spins) {
      _alidade = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 92),
      )..repeat();
      _rete = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 140),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _alidade?.dispose();
    _rete?.dispose();
    _cache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painterFor = _spins
        ? Listenable.merge([_alidade!, _rete!])
        : null;
    // Resolved per build so a System/Light/Dark flip re-records the cache.
    final shadows = Theme.of(context).brightness == Brightness.dark
        ? _Shadows.dark
        : _Shadows.light;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      // The rotating emblem invalidates only its own layer, not the whole
      // screen (software-rendered Linux desktop — paint loop matters).
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AstrolabePainter(
            detail: widget.detail,
            cache: _cache,
            shadows: shadows,
            alidadeTurns: _alidade,
            reteTurns: _rete,
            repaint: painterFor,
          ),
        ),
      ),
    );
  }
}

/// The instrument's cast shadows — the only brightness-dependent colours in
/// the emblem (the brass object itself is shared verbatim between modes).
/// Additive black shadows grey the parchment, so light mode swaps them for
/// sepia-umber ink washes with the same geometry.
class _Shadows {
  const _Shadows({required this.drop, required this.hub});

  /// Root drop shadow under the whole instrument.
  final Color drop;

  /// Drop shadow beneath the core hub.
  final Color hub;

  static const dark = _Shadows(
    drop: Color(0x99000000),
    hub: Color(0x73000000),
  );

  static const light = _Shadows(
    drop: Color(0x40352511),
    hub: Color(0x33352511),
  );
}

/// Lazily recorded static layers, keyed by detail + shadow palette (the
/// pictures bake in the mode-dependent cast shadows). Two pictures because
/// the rotating rete/alidade sit *between* the static body (disc, ticks,
/// legend) and the static top (core, heartbeat, specular) in the design's
/// z-order.
class _AstrolabeStaticCache {
  ui.Picture? below;
  ui.Picture? above;
  AstrolabeDetail? detail;
  _Shadows? shadows;

  void dispose() {
    below?.dispose();
    above?.dispose();
    below = null;
    above = null;
    detail = null;
    shadows = null;
  }
}

class _AstrolabePainter extends CustomPainter {
  _AstrolabePainter({
    required this.detail,
    required this.cache,
    required this.shadows,
    this.alidadeTurns,
    this.reteTurns,
    super.repaint,
  });

  final AstrolabeDetail detail;
  final _AstrolabeStaticCache cache;
  final _Shadows shadows;
  final Animation<double>? alidadeTurns;
  final Animation<double>? reteTurns;

  bool get full => detail == AstrolabeDetail.full;

  // Brass gradient stop sets (design SVG defs).
  static const _rimColors = [
    Color(0xFF7D5F26),
    Color(0xFFEFD489),
    Color(0xFFFFF8D6),
    Color(0xFFD3AE58),
    Color(0xFF67501F),
  ];
  static const _rimStops = [0.0, 0.32, 0.5, 0.68, 1.0];

  Paint _rimStroke(Rect bounds, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _rimColors,
      stops: _rimStops,
    ).createShader(bounds);

  Paint _rimFill(Rect bounds) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _rimColors,
      stops: _rimStops,
    ).createShader(bounds);

  static Paint _emerFill(Rect bounds) => Paint()
    ..shader = const RadialGradient(
      center: Alignment(-0.3, -0.48),
      radius: 0.72,
      colors: [Color(0xFFF2FFEE), Color(0xFF6AC274), Color(0xFF164A24)],
      stops: [0, 0.4, 1],
    ).createShader(bounds);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // The painter always works in the fixed 200×200 design space, so one
    // recording per detail replays correctly at every size.
    canvas.scale(size.width / 200, size.height / 200);
    const c = Offset(100, 100);

    if (cache.detail != detail ||
        !identical(cache.shadows, shadows) ||
        cache.below == null) {
      _record(c);
    }
    canvas.drawPicture(cache.below!);
    if (full) {
      canvas.save();
      _rotateAbout(canvas, c, -2 * math.pi * (reteTurns?.value ?? 0));
      _rete(canvas, c);
      canvas.restore();
      canvas.save();
      _rotateAbout(canvas, c, 2 * math.pi * (alidadeTurns?.value ?? 0));
      _alidade(canvas, c);
      canvas.restore();
    }
    canvas.drawPicture(cache.above!);
    canvas.restore();
  }

  /// Records the static layers once (lazily, on first paint or on a detail
  /// change). The legend TextPainters are laid out here only — never again
  /// per frame.
  void _record(Offset c) {
    cache.below?.dispose();
    cache.above?.dispose();

    final belowRec = ui.PictureRecorder();
    final below = Canvas(belowRec);
    // Root drop shadow (design: drop-shadow(0 6px 11px rgba(0,0,0,.6))).
    below.drawCircle(
      c + const Offset(0, 6),
      96,
      Paint()
        ..color = shadows.drop
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    _throne(below);
    _disc(below, c);
    _limbTicks(below, c);
    if (full) _legend(below, c);
    _innerField(below, c);
    cache.below = belowRec.endRecording();

    final aboveRec = ui.PictureRecorder();
    final above = Canvas(aboveRec);
    _core(above, c);
    if (full) _heartbeat(above);
    _specular(above, c);
    cache.above = aboveRec.endRecording();

    cache.detail = detail;
    cache.shadows = shadows;
  }

  void _rotateAbout(Canvas canvas, Offset c, double angle) {
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.translate(-c.dx, -c.dy);
  }

  void _throne(Canvas canvas) {
    const ring = Offset(100, 4.5);
    final bounds = Rect.fromCircle(center: ring, radius: 5.6);
    canvas.drawCircle(ring, 5.6, _rimStroke(bounds, 2.6));
    canvas.drawCircle(ring, 1.6, Paint()..color = const Color(0xFF5A4318));
    final trap = Path()
      ..moveTo(93, 9)
      ..lineTo(107, 9)
      ..lineTo(104, 18)
      ..lineTo(96, 18)
      ..close();
    canvas.drawPath(trap, _rimFill(trap.getBounds()));
    canvas.drawPath(
      trap,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = const Color(0xFF5A4318),
    );
  }

  void _disc(Canvas canvas, Offset c) {
    final bounds = Rect.fromCircle(center: c, radius: 96);
    canvas.drawCircle(
      c,
      96,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.26, -0.44),
          radius: 0.8,
          colors: [
            Color(0xFFFFF6D2),
            Color(0xFFEECD82),
            Color(0xFFC19A44),
            Color(0xFF836429),
            Color(0xFF4A3717),
          ],
          stops: [0, 0.2, 0.52, 0.78, 1],
        ).createShader(bounds),
    );
    canvas.drawCircle(c, 96, _rimStroke(bounds, 4.4));
    canvas.drawCircle(
      c,
      93,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = const Color(0x99281C08),
    );
    canvas.drawCircle(
      c,
      90.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = const Color(0x47FFF8D6),
    );
  }

  void _limbTicks(Canvas canvas, Offset c) {
    final step = full ? 5 : 15;
    final majEvery = full ? 6 : 2;
    final paintMinor = Paint()
      ..color = const Color(0xFF3A2A0D).withValues(alpha: 0.42)
      ..strokeWidth = 0.8;
    final paintMajor = Paint()
      ..color = const Color(0xFF3A2A0D).withValues(alpha: 0.9)
      ..strokeWidth = full ? 1.7 : 2.2;
    for (var i = 0; i < 360 ~/ step; i++) {
      final major = i % majEvery == 0;
      final a = (i * step - 90) * math.pi / 180;
      const ro = 94.0;
      final ri = major ? 84.0 : 89.0;
      canvas.drawLine(
        c + Offset(ro * math.cos(a), ro * math.sin(a)),
        c + Offset(ri * math.cos(a), ri * math.sin(a)),
        major ? paintMajor : paintMinor,
      );
    }
  }

  void _legend(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c,
      78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..color = const Color(0x8C120C03),
    );
    for (final (r, a) in [(86.5, 0.2), (69.5, 0.16)]) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xFFFFF8D6).withValues(alpha: a),
      );
    }
    // Circular legend text: no textPath in Flutter — place each character
    // along the r78 circle, rotated to the local tangent. The source path
    // starts at the leftmost point and sweeps clockwise.
    const text = 'BUILDAHOMELAB.DEV · 4 NODES · 55W IDLE · SELF-HOSTED · ';
    const r = 78.0;
    var theta = math.pi; // leftmost point
    for (final ch in text.characters) {
      final tp = TextPainter(
        text: TextSpan(
          text: ch,
          style: const TextStyle(
            fontFamily: 'EB Garamond',
            fontWeight: FontWeight.w600,
            fontSize: 8.6,
            color: Color(0xFFF6E6B2),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final advance = tp.width + 1.7; // letter-spacing 1.7
      theta += (advance / 2) / r;
      final pos = c + Offset(r * math.cos(theta), r * math.sin(theta));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(theta + math.pi / 2);
      final baseline =
          tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      tp.paint(canvas, Offset(-tp.width / 2, -baseline + 2.6));
      canvas.restore();
      theta += (advance / 2) / r;
    }
  }

  void _innerField(Canvas canvas, Offset c) {
    final bounds = Rect.fromCircle(center: c, radius: 66);
    canvas.drawCircle(
      c,
      66,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.16, -0.36),
          radius: 0.72,
          colors: [Color(0xFF7A6333), Color(0xFF4C3F20), Color(0xFF221B0E)],
          stops: [0, 0.55, 1],
        ).createShader(bounds),
    );
    canvas.drawCircle(c, 66, _rimStroke(bounds, 1.6));
    canvas.drawCircle(
      c,
      63.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0x1FFFF8D6),
    );
  }

  void _rete(Canvas canvas, Offset c) {
    Paint line(double alpha, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = const Color(0xFFF0D682).withValues(alpha: alpha);
    // Offset ecliptic ring.
    canvas.drawCircle(const Offset(100, 88), 41, line(0.34, 0.9));
    // Main ring.
    canvas.drawCircle(c, 58, line(0.4, 1.0));
    // Dashed inner ring (1.5 on, 4 off).
    final dashPaint = line(0.28, 0.8);
    const dashR = 45.0;
    const dashOn = 1.5, dashOff = 4.0;
    const circumference = 2 * math.pi * dashR;
    final n = (circumference / (dashOn + dashOff)).floor();
    for (var i = 0; i < n; i++) {
      final a0 = i * (dashOn + dashOff) / dashR;
      canvas.drawArc(Rect.fromCircle(center: c, radius: dashR), a0,
          dashOn / dashR, false, dashPaint);
    }
    // 12 radial spokes r58 → r46.
    final spoke = line(0.32, 0.7);
    for (var k = 0; k < 12; k++) {
      final a = k * 30 * math.pi / 180;
      canvas.drawLine(
        c + Offset(58 * math.cos(a), 58 * math.sin(a)),
        c + Offset(46 * math.cos(a), 46 * math.sin(a)),
        spoke,
      );
    }
    // 4 emerald node stars at r55.
    final star = Path()
      ..moveTo(0, -6.5)
      ..lineTo(1.5, -1.5)
      ..lineTo(6.5, 0)
      ..lineTo(1.5, 1.5)
      ..lineTo(0, 6.5)
      ..lineTo(-1.5, 1.5)
      ..lineTo(-6.5, 0)
      ..lineTo(-1.5, -1.5)
      ..close();
    for (final deg in [50, 140, 225, 315]) {
      final a = (deg - 90) * math.pi / 180;
      final p = c + Offset(55 * math.cos(a), 55 * math.sin(a));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.drawPath(
          star, _emerFill(Rect.fromCircle(center: Offset.zero, radius: 6.5)));
      canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = const Color(0x80E9FFE9),
      );
      canvas.drawCircle(
          Offset.zero, 1.5, Paint()..color = const Color(0xFFEAFFF0));
      canvas.restore();
    }
  }

  void _alidade(Canvas canvas, Offset c) {
    final lens = Path()
      ..moveTo(100, 11)
      ..lineTo(102.4, 100)
      ..lineTo(100, 189)
      ..lineTo(97.6, 100)
      ..close();
    final ruleShader = const LinearGradient(
      colors: [
        Color(0xFF6A4F20),
        Color(0xFFF4DD96),
        Color(0xFFFFF8D6),
        Color(0xFFD3AE58),
        Color(0xFF6A4F20),
      ],
      stops: [0, 0.42, 0.5, 0.58, 1],
    ).createShader(lens.getBounds());
    canvas.drawPath(lens, Paint()..shader = ruleShader);
    canvas.drawPath(
      lens,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4
        ..color = const Color(0x80281C08),
    );
    canvas.drawLine(
      const Offset(100, 14),
      const Offset(100, 186),
      Paint()
        ..strokeWidth = 0.7
        ..color = const Color(0x8CFFF8D6),
    );
    final pointer = Path()
      ..moveTo(100, 5)
      ..lineTo(104.5, 13)
      ..lineTo(100, 21)
      ..lineTo(95.5, 13)
      ..close();
    canvas.drawPath(pointer, _rimFill(pointer.getBounds()));
    canvas.drawPath(
      pointer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = const Color(0xFF5A4318),
    );
    canvas.drawCircle(
        const Offset(100, 13), 1.4, Paint()..color = const Color(0xFF4A3512));
    const weight = Offset(100, 184);
    final wBounds = Rect.fromCircle(center: weight, radius: 6);
    canvas.drawCircle(weight, 6, _rimStroke(wBounds, 1.8));
    canvas.drawCircle(weight, 2.4, _rimFill(wBounds));
  }

  void _core(Canvas canvas, Offset c) {
    canvas.save();
    if (!full) {
      // Compact scales the core ×1.5 so the brand reads small.
      canvas.translate(c.dx, c.dy);
      canvas.scale(1.5);
      canvas.translate(-c.dx, -c.dy);
    }
    canvas.drawCircle(const Offset(100, 103.5), 35,
        Paint()..color = shadows.hub);
    final hubBounds = Rect.fromCircle(center: c, radius: 34);
    canvas.drawCircle(
      c,
      34,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.44),
          radius: 0.78,
          colors: [Color(0xFFFFF6D2), Color(0xFFDCB862), Color(0xFF665020)],
          stops: [0, 0.44, 1],
        ).createShader(hubBounds),
    );
    canvas.drawCircle(c, 34, _rimStroke(hubBounds, 2.6));
    canvas.drawCircle(
      c,
      31,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0x66FFF8D6),
    );
    canvas.drawCircle(c, 29.5, Paint()..color = const Color(0x6B1A1207));

    // House-server logo: roof, chimney, three server rungs.
    const dark = Color(0xFF241A09);
    final roof = Path()
      ..moveTo(100, 80)
      ..lineTo(82, 92)
      ..lineTo(118, 92)
      ..close();
    canvas.drawPath(roof, Paint()..color = dark);
    canvas.drawPath(
      roof,
      _rimStroke(roof.getBounds(), 1.7)
        ..strokeJoin = StrokeJoin.round,
    );
    const chimney = Rect.fromLTWH(110, 81.5, 4.6, 7.5);
    canvas.drawRect(chimney, Paint()..color = dark);
    canvas.drawRect(chimney, _rimStroke(chimney, 1.2));
    for (final y in [94.0, 103.0, 112.0]) {
      final rung = RRect.fromRectAndRadius(
          Rect.fromLTWH(83, y, 34, 7), const Radius.circular(2.3));
      canvas.drawRRect(rung, Paint()..color = dark);
      canvas.drawRRect(rung, _rimStroke(rung.outerRect, 1.5));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(87, y + 2.4, 12, 2.2), const Radius.circular(1.1)),
        Paint()..color = const Color(0x99F0D682),
      );
      final led = Offset(111.5, y + 3.5);
      canvas.drawCircle(
          led, 2.1, _emerFill(Rect.fromCircle(center: led, radius: 2.1)));
    }
    canvas.restore();
  }

  void _heartbeat(Canvas canvas) {
    const pts = [
      Offset(78, 150),
      Offset(88, 150),
      Offset(93, 150),
      Offset(97, 137),
      Offset(101, 163),
      Offset(105, 144),
      Offset(109, 150),
      Offset(122, 150),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF6FD0E0).withValues(alpha: 0.9),
    );
  }

  void _specular(Canvas canvas, Offset c) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(70, 56), width: 96, height: 62),
      Paint()..color = const Color(0x2BFFFCEC),
    );
    // Top rim highlight arc: M100,4 a96,96 0 0,1 90,60 — from the top point,
    // 96-radius arc sweeping clockwise to (190, 64).
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 96),
      -math.pi / 2,
      0.72,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x52FFFCEC),
    );
  }

  @override
  bool shouldRepaint(_AstrolabePainter old) =>
      old.detail != detail ||
      !identical(old.shadows, shadows) ||
      old.alidadeTurns != alidadeTurns ||
      old.reteTurns != reteTurns;
}
