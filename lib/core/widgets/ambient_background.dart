import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// App-wide backdrop: the instrument "desk" — the active theme's field lit
/// warmly from above, with faint corner glows drawn from the theme's own
/// accents and a barely-there damask dot texture. Static by design (the old
/// drifting glass sheets are retired), so it costs nothing per frame and
/// settles instantly under tests.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child, this.accent});

  final Widget child;

  /// The active section's accent colour. When set, a faint accent wash leans
  /// the backdrop toward it so the app shifts hue with the current tab.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DeskPainter(brass: context.brass, accent: accent),
      child: child,
    );
  }
}

class _DeskPainter extends CustomPainter {
  const _DeskPainter({required this.brass, this.accent});

  final Brass brass;
  final Color? accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final isDark = brass.isDark;

    // Base field, lit from the top: a touch above the base colour down to the
    // recessed floor — the theme's own surfaces, not a fixed green.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.2, -1),
          end: const Alignment(0.2, 1),
          stops: const [0, 0.58, 1],
          colors: [
            Color.lerp(brass.bg, brass.panelTop, isDark ? 0.35 : 0.6)!,
            brass.bg,
            brass.recess,
          ],
        ).createShader(rect),
    );

    void glowAt(Alignment center, double rx, double ry, Color color) {
      final c = center.alongSize(size);
      final r = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(r),
      );
    }

    if (isDark) {
      // Warm lamplight from the top, deep-field wash upper-right, warm-accent
      // lower-left, cool-accent lower-right — all from the theme's palette.
      glowAt(const Alignment(0, -1.1), size.width * 0.60, size.height * 0.42,
          brass.giltBright.withValues(alpha: 0.16));
      glowAt(const Alignment(0.56, -1.16), size.width * 1.2, size.height * 0.9,
          brass.pine.withValues(alpha: 0.50));
      glowAt(const Alignment(-0.88, 1.12), size.width * 0.9, size.height * 0.7,
          brass.madder.withValues(alpha: 0.16));
      glowAt(const Alignment(1.0, 1.16), size.width * 0.8, size.height * 0.7,
          brass.navy.withValues(alpha: 0.30));
    } else {
      glowAt(const Alignment(0, -1.1), size.width * 0.60, size.height * 0.42,
          brass.giltBright.withValues(alpha: 0.20));
    }

    if (accent != null) {
      glowAt(const Alignment(-0.8, -1.3), 350, 350,
          accent!.withValues(alpha: isDark ? 0.07 : 0.05));
    }

    // Damask dot texture: 1.4px round dots on a 22px grid in the theme's
    // metal ink, drawn as a single drawPoints call (one canvas op instead of
    // thousands — the Linux desktop renders in software).
    final dot = Paint()
      ..color = brass.giltDeep.withValues(alpha: isDark ? 0.05 : 0.08)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(ui.PointMode.points, _dotGrid(size), dot);
  }

  // Offsets rebuilt only when the size changes (cached across paints and
  // painter instances — the grid is a pure function of size).
  static Size? _dotsSize;
  static List<Offset> _dots = const [];

  static List<Offset> _dotGrid(Size size) {
    if (size == _dotsSize) return _dots;
    const step = 22.0;
    final dots = <Offset>[];
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        dots.add(Offset(x, y));
      }
    }
    _dotsSize = size;
    _dots = dots;
    return dots;
  }

  @override
  bool shouldRepaint(_DeskPainter old) =>
      !identical(old.brass, brass) || old.accent != accent;
}
