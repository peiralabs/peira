import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// App-wide backdrop: the Brass Edition "desk" — a deep bottle-green field
/// lit warmly from above, with faint jewel-tone glows in the lower corners
/// and a barely-there gilt damask dot texture. Static by design (the old
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _DeskPainter(isDark: isDark, accent: accent),
      child: child,
    );
  }
}

class _DeskPainter extends CustomPainter {
  const _DeskPainter({required this.isDark, this.accent});

  final bool isDark;
  final Color? accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base field: linear-gradient(168deg, #15251b, #0e1912 58%, #0a120d).
    final base = isDark
        ? const [Color(0xFF15251B), Color(0xFF0E1912), Color(0xFF0A120D)]
        : const [Color(0xFFF3EBDA), Color(0xFFE8DECA), Color(0xFFD8CBB0)];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.2, -1),
          end: const Alignment(0.2, 1),
          stops: const [0, 0.58, 1],
          colors: base,
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
      // Warm gilt lamplight from the top, deep green wash upper-right,
      // oxblood lower-left, sapphire lower-right (design §Desk background).
      glowAt(const Alignment(0, -1.1), size.width * 0.60, size.height * 0.42,
          const Color(0x29E8CD78));
      glowAt(const Alignment(0.56, -1.16), size.width * 1.2, size.height * 0.9,
          const Color(0x803A543A));
      glowAt(const Alignment(-0.88, 1.12), size.width * 0.9, size.height * 0.7,
          const Color(0x664A1F22));
      glowAt(const Alignment(1.0, 1.16), size.width * 0.8, size.height * 0.7,
          const Color(0x611E2F4A));
    } else {
      glowAt(const Alignment(0, -1.1), size.width * 0.60, size.height * 0.42,
          const Color(0x33E8CD78));
    }

    if (accent != null) {
      glowAt(const Alignment(-0.8, -1.3), 350, 350,
          accent!.withValues(alpha: isDark ? 0.07 : 0.05));
    }

    // Damask dot texture: 1.4px round gilt dots on a 22px grid, drawn as a
    // single drawPoints call (one canvas op instead of thousands — the Linux
    // desktop renders in software).
    final dot = Paint()
      ..color = isDark ? const Color(0x0DC9AA58) : const Color(0x14806A38)
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
      old.isDark != isDark || old.accent != accent;
}
