import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';
import 'kit_parts.dart';

/// Mechanical instrument parts: screw heads, trace windows (oscilloscope / strip-chart recorder), a liquid thermometer
/// tube, a knurled knob and engraved lettering. Light comes from the upper
/// left everywhere, matching the astrolabe, ledges and raised dials.

/// Shadow ink: black in the dark, warm umber on parchment.
Color _ink(Brass b) => b.isDark ? const Color(0xFF000000) : const Color(0xFF46381F);

/// Lettering cut into a plate: a shadow along the top edge of each stroke
/// (the cut's upper wall) and a lit lip along the bottom.
List<Shadow> engraved(Brass b) => [
  Shadow(
    offset: const Offset(0, -0.8),
    blurRadius: 0.4,
    color: _ink(b).withValues(alpha: b.isDark ? 0.85 : 0.45),
  ),
  Shadow(
    offset: const Offset(0, 1),
    blurRadius: 0.3,
    color: (b.isDark ? const Color(0xFFFFF3D0) : const Color(0xFFFFFFFF))
        .withValues(alpha: b.isDark ? 0.18 : 0.75),
  ),
];

/// A slotted, countersunk screw head. [angle] is the slot's turn — vary it
/// per screw, as no two screws are ever driven to the same angle.
class ScrewHead extends StatelessWidget {
  const ScrewHead({super.key, this.size = 8, this.angle = 0.4});

  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    // Moulded cases have nothing to fasten.
    if (kit == InstrumentKit.terminal || kit == InstrumentKit.aqua) {
      return SizedBox(width: size, height: size);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ScrewPainter(context.brass, angle, kit)),
    );
  }
}

class _ScrewPainter extends CustomPainter {
  _ScrewPainter(this.brass, this.angle, this.kit);

  final Brass brass;
  final double angle;
  final InstrumentKit kit;

  @override
  void paint(Canvas canvas, Size size) {
    final m = brass.brassStops;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final ink = _ink(brass);
    // Countersink: a dark ring the head sits down into.
    canvas.drawCircle(
      c.translate(0, 0.4),
      r,
      Paint()..color = ink.withValues(alpha: brass.isDark ? 0.75 : 0.35),
    );
    // Domed head.
    canvas.drawCircle(
      c,
      r * 0.86,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [m[2], m[3], m[4]],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final recess = Color.lerp(m[4], ink, 0.6)!;
    switch (kit) {
      case InstrumentKit.graphite:
        // Hex socket.
        final hex = Path();
        for (var k = 0; k < 6; k++) {
          final a = angle + k * math.pi / 3;
          final v = c + Offset(math.cos(a), math.sin(a)) * (r * 0.42);
          k == 0 ? hex.moveTo(v.dx, v.dy) : hex.lineTo(v.dx, v.dy);
        }
        canvas.drawPath(hex..close(), Paint()..color = recess);
        return;
      case InstrumentKit.nord:
        // Cross-head.
        for (final a in [angle, angle + math.pi / 2]) {
          final d = Offset(math.cos(a), math.sin(a)) * (r * 0.62);
          canvas.drawLine(c - d, c + d,
              Paint()
                ..strokeWidth = r * 0.26
                ..strokeCap = StrokeCap.round
                ..color = recess);
        }
        return;
      case InstrumentKit.obsidian:
      case InstrumentKit.catppuccin:
        // Rivets: a plain dome, no drive.
        return;
      case InstrumentKit.brass:
      case InstrumentKit.ember:
      case InstrumentKit.terminal:
      case InstrumentKit.aqua:
        break;
    }
    // Slot, with its lower wall catching the light.
    final d = Offset(math.cos(angle), math.sin(angle)) * (r * 0.7);
    canvas.drawLine(
      c - d,
      c + d,
      Paint()
        ..strokeWidth = r * 0.32
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(m[4], ink, 0.6)!,
    );
    canvas.drawLine(
      c - d + const Offset(0, 0.6),
      c + d + const Offset(0, 0.6),
      Paint()
        ..strokeWidth = 0.5
        ..color = m[2].withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_ScrewPainter old) =>
      !identical(old.brass, brass) || old.angle != angle || old.kit != kit;
}

/// How a trace window draws: a phosphor oscilloscope screen, or a strip of
/// ruled chart paper with an inked trace (and, with [TraceStyle.recorder],
/// the pen arm writing the latest value).
enum TraceStyle { scope, paper, recorder }

/// A recessed window behind glass showing [data] (0..[maxValue]) as a trace.
class TraceWindow extends StatelessWidget {
  const TraceWindow({
    super.key,
    required this.data,
    required this.color,
    required this.style,
    this.maxValue,
    this.radius = 6,
  });

  final List<double> data;
  final Color color;
  final TraceStyle style;

  /// Full-scale value; defaults to a little above the data's peak.
  final double? maxValue;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _TracePainter(
      context.kit,
      context.brass,
      // One sample is a steady signal: draw it as a flat trace rather than
      // an empty screen (the history fills in over the next refreshes).
      data.length == 1 ? [data.first, data.first] : data,
      color,
      style,
      maxValue,
      radius,
    ),
    child: const SizedBox.expand(),
  );
}

class _TracePainter extends CustomPainter {
  _TracePainter(
    this.kit,
    this.brass,
    this.data,
    this.color,
    this.style,
    this.maxValue,
    this.radius, {
    this.back = true,
    this.front = true,
  });

  /// Paint the screen (ground, ruling, trace) and/or the glass over it
  /// (vignette, reflection, lip shadow, bezel). [ScopeFrame] paints the two
  /// layers either side of its child.
  final bool back;
  final bool front;

  final InstrumentKit kit;
  final Brass brass;
  final List<double> data;
  final Color color;
  final TraceStyle style;
  final double? maxValue;
  final double radius;

  /// Set by [ScopeFrame]: the chart look instead of the trace look.
  TraceLook? chartLook;

  late final TraceLook look =
      chartLook ?? TraceLook.of(kit, brass, style, color);

  @override
  void paint(Canvas canvas, Size size) {
    final b = brass;
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final ink = _ink(b);
    // The recorder keeps room on the right for its pen carriage.
    final penRoom = style == TraceStyle.recorder ? 26.0 : 0.0;
    final plot = Rect.fromLTRB(4, 5, size.width - 4 - penRoom, size.height - 5);

    canvas.save();
    canvas.clipRRect(rr);
    if (back) _paintScreen(canvas, size, rect, plot, penRoom);
    if (!front) {
      canvas.restore();
      return;
    }
    _paintGlass(canvas, rect, rr, ink);
  }

  void _paintScreen(
    Canvas canvas,
    Size size,
    Rect rect,
    Rect plot,
    double penRoom,
  ) {
    final b = brass;
    final l = look;
    // Ground: a CRT face, chart paper, an LCD panel... per the family. A
    // screen's radial ground is stretched to the window's width, and its
    // backlight glows softly behind the trace: a lamp behind the glass.
    final g = l.ground;
    if (g is RadialGradient) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: g.colors,
            stops: g.stops,
            radius: 0.75,
            transform: const _StretchToWidth(),
          ).createShader(rect),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              l.trace.withValues(alpha: 0.16),
              l.trace.withValues(alpha: 0.06),
              l.trace.withValues(alpha: 0),
            ],
            stops: const [0, 0.5, 1],
            radius: 0.62,
            transform: const _StretchToWidth(),
          ).createShader(rect),
      );
    } else {
      canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
    }

    // Graticule / chart ruling: 10 columns, 4 rows, minor lines between
    // (dotted on the families whose screens use dot grids).
    final major = Paint()
      ..strokeWidth = 0.6
      ..color = l.gridMajor;
    final minor = Paint()
      ..strokeWidth = 0.5
      ..color = l.gridMinor;
    void line(Offset a, Offset c, Paint p) {
      if (!l.dotted) {
        canvas.drawLine(a, c, p);
        return;
      }
      final len = (c - a).distance;
      final d = (c - a) / len;
      for (var k = 0.0; k < len; k += 4) {
        canvas.drawCircle(a + d * k, p.strokeWidth * 0.9, p);
      }
    }
    for (var i = 0; i <= 20; i++) {
      final x = plot.left + plot.width * i / 20;
      line(Offset(x, rect.top), Offset(x, rect.bottom),
          i.isEven ? major : minor);
    }
    for (var j = 0; j <= 8; j++) {
      final y = plot.top + plot.height * j / 8;
      line(Offset(rect.left, y), Offset(rect.right, y),
          j.isEven ? major : minor);
    }

    if (data.length >= 2) {
      final top = maxValue ?? math.max(1.0, data.reduce(math.max) * 1.2);
      Offset pt(int i) => Offset(
        plot.left + plot.width * i / (data.length - 1),
        plot.bottom - (data[i] / top).clamp(0.0, 1.0) * plot.height,
      );
      final path = Path()..moveTo(pt(0).dx, pt(0).dy);
      for (var i = 1; i < data.length; i++) {
        final p0 = pt(i - 1), p1 = pt(i);
        final mx = (p0.dx + p1.dx) / 2;
        path.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
      }
      if (l.fill != null) {
        final area = Path.from(path)
          ..lineTo(pt(data.length - 1).dx, plot.bottom)
          ..lineTo(plot.left, plot.bottom)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [l.fill!, l.fill!.withValues(alpha: 0)],
            ).createShader(plot),
        );
      }
      // Glow (phosphor bloom) or bleed (ink soaking into paper), then the
      // trace itself.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = l.glow ? 4 : l.width + 0.4
          ..color = l.trace.withValues(alpha: l.glow ? 0.35 : 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, l.glow ? 3 : 0.8),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = l.width
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = l.trace,
      );

      if (style == TraceStyle.recorder) {
        // Pen carriage on its rail at the right edge, the arm reaching to
        // the latest value, the nib inking it.
        final last = pt(data.length - 1);
        final m = b.brassStops;
        final railX = size.width - penRoom / 2;
        canvas.drawLine(
          Offset(railX, rect.top),
          Offset(railX, rect.bottom),
          Paint()
            ..strokeWidth = 3
            ..shader = LinearGradient(colors: [m[4], m[2], m[4]])
                .createShader(Rect.fromLTWH(railX - 1.5, 0, 3, size.height)),
        );
        final carriage = Rect.fromCenter(
          center: Offset(railX, last.dy),
          width: 16,
          height: 11,
        );
        canvas.drawLine(
          last,
          Offset(railX - 7, last.dy),
          Paint()
            ..strokeWidth = 2
            ..color = m[3],
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(carriage.shift(const Offset(0.6, 1)),
              const Radius.circular(1.5)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(carriage, const Radius.circular(1.5)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [m[2], m[3], m[4]],
            ).createShader(carriage),
        );
        canvas.drawCircle(last, 2.8, Paint()..color = l.nib);
        canvas.drawCircle(
          last.translate(-0.6, -0.6),
          0.7,
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
      }
    }

  }

  void _paintGlass(Canvas canvas, Rect rect, RRect rr, Color ink) {
    final b = brass;
    final l = look;
    // Glass: a vignette toward the edges and a soft diagonal reflection.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.0,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: l.vignette),
          ],
          stops: const [0.6, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: l.gloss),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.18, 0.3, 0.45],
        ).createShader(rect),
    );
    // The window's lip shadows the top of the screen.
    final lip = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(20))
      ..addRRect(rr.shift(const Offset(0, 3)));
    canvas.drawPath(
      lip,
      Paint()
        ..color = ink.withValues(alpha: (b.isDark ? 0.7 : 0.35) * l.lip)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();

    // Bezel: a fine chamfer, dark along the top, lit along the bottom.
    canvas.drawRRect(
      rr.inflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ink.withValues(alpha: b.isDark ? 0.6 : 0.3),
            b.giltBright.withValues(alpha: b.isDark ? 0.35 : 0.5),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.kit != kit ||
      !identical(old.brass, brass) ||
      old.data != data ||
      old.color != color ||
      old.style != style ||
      old.maxValue != maxValue ||
      old.back != back ||
      old.front != front;
}

/// How a family draws a trace window: the screen's ground and ruling, the
/// trace's ink, and the glass over it.
class TraceLook {
  const TraceLook({
    required this.ground,
    required this.gridMajor,
    required this.gridMinor,
    required this.trace,
    this.width = 1.4,
    this.glow = false,
    this.dotted = false,
    this.fill,
    this.vignette = 0.12,
    this.gloss = 0.1,
    this.nib = const Color(0xFF8C2F28),
    this.lip = 1,
  });

  final Gradient ground;
  final Color gridMajor;
  final Color gridMinor;
  final Color trace;
  final double width;

  /// Phosphor bloom around the trace (screens) instead of an ink bleed.
  final bool glow;
  final bool dotted;

  /// Tint under the trace, fading downward.
  final Color? fill;
  final double vignette;
  final double gloss;

  /// The recorder pen's ink drop.
  final Color nib;

  /// Strength of the window lip's shadow (1 = full).
  final double lip;

  /// The look behind a chart that draws its own lines and labels (Metrics,
  /// PBS, Home Assistant): the family's screen in dark mode, a light paper or
  /// panel of the same family in light mode (the chart's text and series
  /// colours are tuned to the mode), and only a breath of glass so dense
  /// multi-line charts stay legible.
  static TraceLook forChart(InstrumentKit kit, Brass b) {
    LinearGradient panel(Color top, Color bottom) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bottom],
    );
    TraceLook light(Color top, Color bottom, Color grid) => TraceLook(
      ground: panel(top, bottom),
      gridMajor: grid.withValues(alpha: 0.38),
      gridMinor: grid.withValues(alpha: 0.16),
      trace: b.textBody,
      dotted: kit == InstrumentKit.nord || kit == InstrumentKit.catppuccin,
      vignette: 0.04,
      gloss: 0.03,
      lip: 0.35,
    );
    if (!b.isDark) {
      return switch (kit) {
        InstrumentKit.brass => light(const Color(0xFFF2EBD8),
            const Color(0xFFEDE4CE), const Color(0xFFB0563E)),
        InstrumentKit.graphite => light(const Color(0xFFF4F5F2),
            const Color(0xFFEAECE8), const Color(0xFF8A949C)),
        InstrumentKit.terminal => light(const Color(0xFFF0F7F1),
            const Color(0xFFE6F0E8), const Color(0xFF2E9E57)),
        InstrumentKit.nord => light(const Color(0xFFF4F7FA),
            const Color(0xFFE9EEF4), const Color(0xFF5E81AC)),
        InstrumentKit.ember => light(const Color(0xFFFAF3EC),
            const Color(0xFFF2E7DC), const Color(0xFFB0563E)),
        InstrumentKit.obsidian => light(const Color(0xFFF7F7F8),
            const Color(0xFFEDEDEF), const Color(0xFF6E7076)),
        InstrumentKit.aqua => light(const Color(0xFFFFFFFF),
            const Color(0xFFF2F5F9), const Color(0xFF9DB3CC)),
        InstrumentKit.catppuccin => light(const Color(0xFFEFF1F5),
            const Color(0xFFE6E9EF), const Color(0xFF8C8FA1)),
      };
    }
    final dark = kit == InstrumentKit.graphite
        // Graphite's trace look is plotter paper in both modes; in dark mode
        // a chart drawn for dark backgrounds needs dark lab glass instead.
        ? const TraceLook(
            ground: RadialGradient(
              radius: 0.9,
              colors: [Color(0xFF22272C), Color(0xFF131619)],
            ),
            gridMajor: Color(0x4D8A949C),
            gridMinor: Color(0x1F8A949C),
            trace: Color(0xFFD5DADF),
          )
        : kit == InstrumentKit.ember
        // Ember's own screen is amber on brown; behind red-family series it
        // drowned them, so charts get a near-neutral warm black.
        ? const TraceLook(
            ground: RadialGradient(
              radius: 0.9,
              colors: [Color(0xFF15100D), Color(0xFF0A0807)],
            ),
            gridMajor: Color(0x24E8D8C8),
            gridMinor: Color(0x10E8D8C8),
            trace: Color(0xFFFFC27A),
          )
        : TraceLook.of(kit, b, TraceStyle.scope, b.sparkGreen);
    return TraceLook(
      ground: dark.ground,
      gridMajor: dark.gridMajor,
      gridMinor: dark.gridMinor,
      trace: dark.trace,
      dotted: dark.dotted,
      vignette: 0.16,
      gloss: 0.03,
      lip: 0.5,
    );
  }

  static const _paper = Color(0xFFF2EBD8);
  static const _paperShade = Color(0xFFE2D8BF);

  static TraceLook of(
    InstrumentKit kit,
    Brass b,
    TraceStyle style,
    Color color,
  ) {
    RadialGradient crt(Color centre, Color edge) =>
        RadialGradient(radius: 0.9, colors: [centre, edge]);
    LinearGradient panel(Color top, Color bottom) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bottom],
    );
    switch (kit) {
      case InstrumentKit.brass:
        if (style == TraceStyle.scope) {
          return TraceLook(
            ground: crt(Color.lerp(const Color(0xFF07130B), color, 0.08)!,
                const Color(0xFF030805)),
            gridMajor: color.withValues(alpha: 0.16),
            gridMinor: color.withValues(alpha: 0.07),
            trace: Color.lerp(color, Colors.white, 0.35)!,
            glow: true,
            vignette: 0.45,
            gloss: 0.07,
          );
        }
        return const TraceLook(
          ground: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_paperShade, _paper, _paper],
            stops: [0, 0.25, 1],
          ),
          gridMajor: Color(0x55B0563E),
          gridMinor: Color(0x26B0563E),
          trace: Color(0xFF283A6E),
          width: 1.2,
          gloss: 0.16,
        );
      case InstrumentKit.graphite:
        // Plotter paper: pale grey grid, a fine black pen; orange nib.
        return TraceLook(
          ground: panel(const Color(0xFFF1F2EF), const Color(0xFFE2E5E0)),
          gridMajor: const Color(0x598A949C),
          gridMinor: const Color(0x268A949C),
          trace: const Color(0xFF1B1F24),
          width: 1.3,
          vignette: 0.08,
          nib: const Color(0xFFFF6A00),
        );
      case InstrumentKit.terminal:
        return TraceLook(
          ground: crt(const Color(0xFF04120A), const Color(0xFF010502)),
          gridMajor: const Color(0x2939FF6A),
          gridMinor: const Color(0x1239FF6A),
          trace: const Color(0xFF7DFFA0),
          glow: true,
          vignette: 0.5,
          gloss: 0.05,
          nib: const Color(0xFF39FF6A),
        );
      case InstrumentKit.nord:
        return TraceLook(
          ground: panel(const Color(0xFF13243A), const Color(0xFF0D1B2A)),
          gridMajor: const Color(0x2488C0D0),
          gridMinor: const Color(0x1088C0D0),
          trace: const Color(0xFF8FD3E6),
          width: 1.6,
          glow: true,
          dotted: true,
          vignette: 0.3,
          gloss: 0.06,
          nib: const Color(0xFF8FD3E6),
        );
      case InstrumentKit.ember:
        return TraceLook(
          ground: crt(const Color(0xFF1E0E06), const Color(0xFF0A0503)),
          gridMajor: const Color(0x24FFB15C),
          gridMinor: const Color(0x10FFB15C),
          trace: const Color(0xFFFFC27A),
          glow: true,
          vignette: 0.5,
          gloss: 0.05,
          nib: const Color(0xFFFF8A3D),
        );
      case InstrumentKit.obsidian:
        // Matte black glass, steel ruling, a silver trace.
        return TraceLook(
          ground: crt(const Color(0xFF0E0F11), const Color(0xFF000000)),
          gridMajor: const Color(0x2EAEB4BE),
          gridMinor: const Color(0x12AEB4BE),
          trace: const Color(0xFFD8DCE2),
          glow: true,
          vignette: 0.5,
          gloss: 0.05,
          nib: const Color(0xFFD8DCE2),
        );
      case InstrumentKit.aqua:
        return TraceLook(
          ground: b.isDark
              ? panel(const Color(0xFF2C2C2E), const Color(0xFF1C1C1E))
              : panel(const Color(0xFFFFFFFF), const Color(0xFFEEF3F9)),
          gridMajor:
              b.isDark ? const Color(0x9948484A) : const Color(0xE6C8D6E6),
          gridMinor:
              b.isDark ? const Color(0x4D48484A) : const Color(0x80C8D6E6),
          trace: b.giltBright,
          width: 2,
          fill: b.giltBright.withValues(alpha: 0.14),
          vignette: 0.05,
          gloss: 0.25,
          nib: b.giltBright,
        );
      case InstrumentKit.catppuccin:
        return TraceLook(
          ground: b.isDark
              ? panel(const Color(0xFF181825), const Color(0xFF11111B))
              : panel(const Color(0xFFE6E9EF), const Color(0xFFDCE0E8)),
          gridMajor:
              b.isDark ? const Color(0xFF45475A) : const Color(0xFFBCC0CC),
          gridMinor:
              b.isDark ? const Color(0x8045475A) : const Color(0x80BCC0CC),
          trace: b.giltBright,
          width: 2,
          dotted: true,
          fill: b.giltBright.withValues(alpha: 0.16),
          vignette: 0.1,
          gloss: 0.08,
          nib: b.giltBright,
        );
    }
  }
}

/// Puts any chart behind instrument glass: the screen (a phosphor scope in
/// dark themes, ruled chart paper in light ones) is painted under [child],
/// and the glass, the window lip's shadow and the bezel over it. The child
/// keeps its own interaction (tooltips, hover).
class ScopeFrame extends StatelessWidget {
  const ScopeFrame({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.fromLTRB(6, 8, 8, 6),
    this.radius = 6,
  });

  final Widget child;

  /// Graticule tint on the scope (defaults to the family's spark green).
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final b = context.brass;
    final style = b.isDark ? TraceStyle.scope : TraceStyle.paper;
    final tint = color ?? b.sparkGreen;
    final look = TraceLook.forChart(context.kit, b);
    return CustomPaint(
      painter: _TracePainter(context.kit, b, const [], tint, style, null,
          radius, front: false)..chartLook = look,
      foregroundPainter: _TracePainter(context.kit, b, const [], tint, style,
          null, radius, back: false)..chartLook = look,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A horizontal glass thermometer: reservoir bulb on the left, a bore, and a
/// liquid column filling to [fraction] with a rounded meniscus. Matches the
/// instrument gauges' tubes. The column rises from the bulb on mount and
/// whenever [epoch] changes.
class LiquidTube extends StatelessWidget {
  const LiquidTube({
    super.key,
    required this.fraction,
    required this.color,
    this.epoch = 0,
    this.height = 12,
  });

  final double fraction;
  final Color color;
  final int epoch;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (context.kit != InstrumentKit.brass) {
      return KitMeter(
        fraction: fraction,
        colors: [color],
        height: height,
        epoch: epoch,
      );
    }
    final target = fraction.clamp(0.0, 1.0);
    final brass = context.brass;
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(epoch),
        tween: Tween(begin: kMolAnimationsEnabled ? 0 : target, end: target),
        duration: kMolAnimationsEnabled
            ? const Duration(milliseconds: 1300)
            : Duration.zero,
        curve: const Cubic(0.2, 0.8, 0.2, 1),
        builder: (context, value, _) => CustomPaint(
          painter: _TubePainter(brass, value, color),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _TubePainter extends CustomPainter {
  _TubePainter(this.brass, this.fraction, this.color);

  final Brass brass;
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final bulbR = h / 2;
    final bulbC = Offset(bulbR, h / 2);
    final bore = h * 0.52;
    final liquid = h * 0.34;
    final x0 = bulbR * 1.4, x1 = size.width - bore / 2;
    final cy = h / 2;
    final deep = Color.lerp(color, Colors.black, 0.55)!;
    final shine = Color.lerp(color, Colors.white, 0.55)!;
    final wall = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = brass.isDark ? const Color(0x40F3E7C2) : const Color(0x8046381F);

    // Glass bore and bulb socket.
    final boreR = RRect.fromLTRBR(
      x0 - bore / 2,
      cy - bore / 2,
      x1 + bore / 2,
      cy + bore / 2,
      Radius.circular(bore / 2),
    );
    canvas.drawRRect(boreR, Paint()..color = const Color(0xE6070A08));
    canvas.drawRRect(boreR, wall);
    canvas.drawCircle(bulbC, bulbR, Paint()..color = const Color(0xFF070A08));
    canvas.drawCircle(bulbC, bulbR, wall);

    // Bulb of liquid, always full.
    canvas.drawCircle(
      bulbC,
      bulbR * 0.78,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [shine, color, deep],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: bulbC, radius: bulbR * 0.78)),
    );

    // Column: shaded across its height like liquid in a round tube.
    final end = x0 + (x1 - x0) * fraction;
    final col = Rect.fromLTRB(bulbC.dx, cy - liquid / 2, end, cy + liquid / 2);
    if (end > bulbC.dx) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(col, Radius.circular(liquid / 2)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [deep, shine, color, deep],
            stops: const [0, 0.3, 0.6, 1],
          ).createShader(col),
      );
    }

    // Glass reflection along the top of the bore, and on the bulb.
    canvas.drawLine(
      Offset(x0 + 2, cy - bore * 0.32),
      Offset(x1 - 2, cy - bore * 0.32),
      Paint()
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      bulbC.translate(-bulbR * 0.3, -bulbR * 0.32),
      bulbR * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_TubePainter old) =>
      !identical(old.brass, brass) ||
      old.fraction != fraction ||
      old.color != color;
}

/// A knurled brass knob with an engraved [icon] on its cap. It turns a full
/// revolution when pressed, as a real knob would under the fingers.
class KnurledKnob extends StatefulWidget {
  const KnurledKnob({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final String? tooltip;

  @override
  State<KnurledKnob> createState() => _KnurledKnobState();
}

class _KnurledKnobState extends State<KnurledKnob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  void _press() {
    widget.onPressed();
    if (kMolAnimationsEnabled) _turn.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final b = context.brass;
    final knob = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _press,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _turn,
            builder: (context, child) => CustomPaint(
              painter: _KnobPainter(
                b,
                Curves.easeOutCubic.transform(_turn.value) * 2 * math.pi,
              ),
              child: child,
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.size * 0.42,
                color: Color.lerp(b.brassStops[4], _ink(b), 0.35),
                shadows: [
                  Shadow(
                    offset: const Offset(0, 0.7),
                    color: b.brassStops[2].withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return widget.tooltip == null
        ? knob
        : Tooltip(message: widget.tooltip!, child: knob);
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter(this.brass, this.turn);

  final Brass brass;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final m = brass.brassStops;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final ink = _ink(brass);
    // Contact shadow on the panel.
    canvas.drawCircle(
      c.translate(0.6, 1.4),
      r * 0.95,
      Paint()
        ..color = ink.withValues(alpha: brass.isDark ? 0.6 : 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
    );
    // Knurled skirt: the ridges turn with the knob, the light does not.
    canvas.drawCircle(c, r, Paint()..color = m[4]);
    const ridges = 28;
    for (var i = 0; i < ridges; i++) {
      final a = turn + i * 2 * math.pi / ridges;
      final dir = Offset(math.cos(a), math.sin(a));
      // Ridges facing the upper-left light are bright, the rest dark.
      final lit = (math.cos(a - math.pi * 1.25) + 1) / 2;
      canvas.drawLine(
        c + dir * (r * 0.74),
        c + dir * (r * 0.98),
        Paint()
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(m[4], m[2], lit)!,
      );
    }
    // Polished cap.
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [m[2], m[1], m[3]],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.7)),
    );
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = ink.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_KnobPainter old) =>
      !identical(old.brass, brass) || old.turn != turn;
}

/// A bat-handle toggle switch on a small brass plate: the lever thrown up
/// is on, down is off (IEC "I" / "O" engraved beside it), and a jewel lamp
/// set below the lever shows the state — green on, red off. The lever swings
/// when flipped. Disabled when [onChanged] is null.
class BrassToggle extends StatelessWidget {
  const BrassToggle({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (context.kit != InstrumentKit.brass) {
      return KitToggle(value: value, onChanged: onChanged);
    }
    final b = context.brass;
    final enabled = onChanged != null;
    final toggle = SizedBox(
      width: 28,
      height: 54,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value ? 1 : 0),
        duration: kMolAnimationsEnabled
            ? const Duration(milliseconds: 160)
            : Duration.zero,
        curve: Curves.easeOutBack,
        builder: (context, t, _) =>
            CustomPaint(painter: _TogglePainter(b, t, value)),
      ),
    );
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: enabled ? () => onChanged!(!value) : null,
          child: Opacity(opacity: enabled ? 1 : 0.5, child: toggle),
        ),
      ),
    );
  }
}

class _TogglePainter extends CustomPainter {
  _TogglePainter(this.brass, this.t, this.on);

  final Brass brass;

  /// Lever travel: 0 = thrown down (off), 1 = thrown up (on).
  final double t;
  final bool on;

  @override
  void paint(Canvas canvas, Size size) {
    final b = brass;
    final m = b.brassStops;
    final ink = _ink(b);
    // The lever's nut sits in the upper part; the lamp below it.
    final c = Offset(size.width / 2, 20);
    final plate = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(5),
    );

    // Plate, proud of the panel.
    canvas.drawRRect(
      plate.shift(const Offset(0.5, 1.2)),
      Paint()
        ..color = ink.withValues(alpha: b.isDark ? 0.55 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [m[2], m[1], m[3], m[4]],
          stops: const [0, 0.3, 0.7, 1],
        ).createShader(Offset.zero & size),
    );

    // Engraved I (top) and O (bottom); the live one is darker-cut.
    void mark(String s, double y, bool live) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: b.displayFont,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: Color.lerp(m[4], ink, live ? 0.6 : 0.15)!
                .withValues(alpha: live ? 1 : 0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(5 - tp.width / 2, y - tp.height / 2));
    }

    mark('I', c.dy - 11, on);
    mark('O', c.dy + 11, !on);

    // Status lamp: a jewel in a dark bezel cup, lit green (on) or red (off),
    // with its glow, a domed-glass shading and a pinpoint highlight.
    final lampC = Offset(size.width / 2, size.height - 9);
    // Signal-lamp colours, brighter than the status ramp: these must read
    // at a glance across a row of switches.
    final jewel = on ? const Color(0xFF3FE06A) : const Color(0xFFFF4A3D);
    canvas.drawCircle(lampC, 5.2, Paint()..color = Color.lerp(m[4], ink, 0.5)!);
    canvas.drawCircle(
      lampC,
      5.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [m[4], m[2]],
        ).createShader(Rect.fromCircle(center: lampC, radius: 5.2)),
    );
    canvas.drawCircle(
      lampC,
      5.5,
      Paint()
        ..color = jewel.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      lampC,
      3.5,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [
            Color.lerp(jewel, Colors.white, 0.5)!,
            jewel,
            Color.lerp(jewel, Colors.black, 0.45)!,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: lampC, radius: 3.5)),
    );
    canvas.drawCircle(
      lampC.translate(-1.1, -1.2),
      0.9,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    // Mounting nut: a dark bore with a turned ring.
    canvas.drawCircle(c, 7.5, Paint()..color = Color.lerp(m[4], ink, 0.4)!);
    canvas.drawCircle(
      c,
      7.5,
      Paint()
        ..shader = SweepGradient(
          colors: [m[2], m[4], m[3], m[4], m[2]],
        ).createShader(Rect.fromCircle(center: c, radius: 7.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(c, 4, Paint()..color = const Color(0xFF151510));

    // Lever: foreshortened as it tilts toward the viewer, ending in a ball.
    const reach = 12.0;
    final dir = 1 - 2 * t; // +1 down, -1 up
    final tip = c.translate(0, dir * reach);
    final lever = Paint()
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: [m[4], m[2], m[3], m[4]])
          .createShader(Rect.fromCenter(center: c, width: 5, height: 30));
    // Its shadow falls down and to the right.
    canvas.drawLine(
      c.translate(1.2, 2),
      tip.translate(1.8, 3),
      Paint()
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    canvas.drawLine(c, tip, lever);
    canvas.drawCircle(
      tip,
      3.6,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          colors: [m[2], m[3], m[4]],
        ).createShader(Rect.fromCircle(center: tip, radius: 3.6)),
    );
  }

  @override
  bool shouldRepaint(_TogglePainter old) =>
      !identical(old.brass, brass) || old.t != t || old.on != on;
}

/// A [ListTile] row with a [BrassToggle], tappable anywhere on the row —
/// the mechanical counterpart of [SwitchListTile] (same core parameters).
class BrassSwitchTile extends StatelessWidget {
  const BrassSwitchTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.contentPadding,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) => ListTile(
    title: title,
    subtitle: subtitle,
    contentPadding: contentPadding,
    enabled: onChanged != null,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    trailing: BrassToggle(value: value, onChanged: onChanged),
  );
}

/// The glass of a CRT laid over a terminal: faint scanlines, darker curved
/// corners and a soft reflection. Pointer-transparent, so typing, selection
/// and scrolling reach the terminal underneath.
class CrtGlass extends StatelessWidget {
  const CrtGlass({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      const IgnorePointer(
        child: RepaintBoundary(child: CustomPaint(painter: _CrtPainter())),
      ),
    ],
  );
}

class _CrtPainter extends CustomPainter {
  const _CrtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Scanlines: a dark hairline every third pixel.
    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.13)
      ..strokeWidth = 1;
    for (var y = 0.5; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    // The tube's curvature darkens the corners.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
          stops: const [0.7, 1],
        ).createShader(rect),
    );
    // A broad, faint reflection across the upper left of the glass.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.4],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_CrtPainter old) => false;
}

/// Stretches a radial gradient into an ellipse spanning the shader's full
/// width (a RadialGradient is otherwise a circle sized to the shorter side).
class _StretchToWidth extends GradientTransform {
  const _StretchToWidth();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final k = bounds.height == 0 ? 1.0 : bounds.width / bounds.height;
    final c = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(k, 1, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}
