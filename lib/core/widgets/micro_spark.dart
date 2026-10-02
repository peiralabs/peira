import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A tiny trend line: a stroke over a faint gradient fill (dashboard / node
/// card CPU sparkline idiom).
class MicroSpark extends CustomPainter {
  MicroSpark(this.data, this.color);

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxV = math.max(1.0, data.reduce(math.max));
    final dx = size.width / (data.length - 1);
    Offset pt(int i) => Offset(
      i * dx,
      size.height - (data[i] / maxV).clamp(0.0, 1.0) * size.height,
    );

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < data.length; i++) {
      line.lineTo(pt(i).dx, pt(i).dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant MicroSpark old) =>
      old.data != data || old.color != color;
}
