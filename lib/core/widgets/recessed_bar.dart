import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';
import 'kit_parts.dart';

/// A meter as a glass tube set into the panel: a dark bore with lit walls,
/// filled to [fraction] with liquid coloured along its length by [gradient]
/// and shaded across its height like liquid in a round tube, ending in a
/// rounded meniscus. The fill rises from empty when first shown. Same glass
/// and lighting as the instrument gauges and the dashboard thermometers.
class RecessedBar extends StatelessWidget {
  const RecessedBar({
    super.key,
    required this.fraction,
    required this.gradient,
    this.height = 8,
    this.borderColor,
  });

  final double fraction;
  final List<Color> gradient;

  /// Requested height; the tube needs at least 10px to read as glass.
  final double height;

  /// Tube wall tint (glass by default; the torrent tubes use an emerald tint).
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (context.kit != InstrumentKit.brass) {
      return KitMeter(fraction: fraction, colors: gradient, height: height);
    }
    final target = fraction.clamp(0.0, 1.0);
    final brass = context.brass;
    return SizedBox(
      height: math.max(height, 10),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: kMolAnimationsEnabled ? 0 : target, end: target),
        duration: kMolAnimationsEnabled
            ? const Duration(milliseconds: 900)
            : Duration.zero,
        curve: const Cubic(0.2, 0.8, 0.2, 1),
        builder: (context, value, _) => CustomPaint(
          painter: _GlassTubePainter(brass, value, gradient, borderColor),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _GlassTubePainter extends CustomPainter {
  _GlassTubePainter(this.brass, this.fraction, this.colors, this.wallTint);

  final Brass brass;
  final double fraction;
  final List<Color> colors;
  final Color? wallTint;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final rect = Offset.zero & size;
    final bore = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));

    // Bore: dark glass, the top inner wall in shadow.
    canvas.drawRRect(bore, Paint()..color = const Color(0xE6070A08));

    // Liquid: coloured along its length, shaded across its height.
    final inset = h * 0.18;
    final width = (size.width - inset * 2) * fraction;
    if (width > 0.5) {
      final col = Rect.fromLTWH(inset, inset, math.max(width, h - inset * 2),
          h - inset * 2);
      final liquid = RRect.fromRectAndRadius(col, Radius.circular(col.height / 2));
      canvas.drawRRect(
        liquid,
        Paint()
          ..shader = LinearGradient(
            colors: colors.length == 1 ? [colors[0], colors[0]] : colors,
          ).createShader(Rect.fromLTWH(inset, 0, size.width - inset * 2, h)),
      );
      canvas.drawRRect(
        liquid,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0.4),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.5),
            ],
            stops: const [0, 0.32, 0.6, 1],
          ).createShader(col),
      );
    }

    // Walls and the long glass reflection along the top.
    canvas.drawRRect(
      bore.deflate(0.35),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = wallTint ??
            (brass.isDark ? const Color(0x40F3E7C2) : const Color(0x8046381F)),
    );
    canvas.drawLine(
      Offset(h * 0.6, h * 0.27),
      Offset(size.width - h * 0.6, h * 0.27),
      Paint()
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(_GlassTubePainter old) =>
      !identical(old.brass, brass) ||
      old.fraction != fraction ||
      old.colors != colors ||
      old.wallTint != wallTint;
}
