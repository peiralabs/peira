import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A round instrument standing up out of the panel (or out of a
/// [BrassLedge]): the face is [child]; beneath it the dial's side wall shows
/// as a crescent of the family's metal, lit like a short cylinder, and the
/// body casts a soft shadow onto the floor below.
///
/// The wall and shadow are painted outside the face's circle only, so a face
/// that is partly translucent (the instrument gauges in dark mode) never
/// shows metal or shadow through itself.
class RaisedDial extends StatelessWidget {
  const RaisedDial({
    super.key,
    required this.child,
    required this.diameter,
    this.height = 4,
  });

  /// The face; sized [diameter] × [diameter].
  final Widget child;
  final double diameter;

  /// How far the dial stands proud of the floor (visible side-wall band).
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DialBodyPainter(context.brass, diameter, height),
      foregroundPainter: _DialBodyPainter(context.brass, diameter, height,
          bevel: true),
      child: SizedBox(
        width: diameter,
        height: diameter + height,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: diameter, height: diameter, child: child),
        ),
      ),
    );
  }
}

class _DialBodyPainter extends CustomPainter {
  _DialBodyPainter(this.brass, this.diameter, this.height,
      {this.bevel = false});

  final Brass brass;
  final double diameter;
  final double height;

  /// Paint only the face-edge bevel (the foreground pass, over the face).
  final bool bevel;

  @override
  void paint(Canvas canvas, Size size) {
    final b = brass;
    final m = b.brassStops;
    final r = diameter / 2;
    final face = Rect.fromCircle(center: Offset(r, r), radius: r);
    final base = face.shift(Offset(0, height));
    final ink = b.isDark ? const Color(0xFF000000) : const Color(0xFF46381F);
    if (bevel) {
      // Bevel where the face meets the wall: a hairline along the lower
      // edge catching the light.
      canvas.drawArc(
        face.deflate(0.5),
        0.35,
        2.45,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = m[2].withValues(alpha: b.isDark ? 0.28 : 0.4),
      );
      return;
    }
    final outsideFace = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTRB(-diameter, -diameter, diameter * 2,
          diameter * 2 + height * 6))
      ..addOval(face);

    canvas.save();
    canvas.clipPath(outsideFace);
    // Broad ambient shadow on the floor, thrown down and slightly right
    // (light from the upper left, as on the astrolabe)...
    canvas.drawOval(
      base.shift(Offset(height * 0.4, height * 1.2)).deflate(1),
      Paint()
        ..color = ink.withValues(alpha: b.isDark ? 0.5 : 0.24)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, height * 2.2),
    );
    // ...and the tight contact shadow where the body meets the floor.
    canvas.drawOval(
      base.shift(const Offset(0, 1.2)),
      Paint()
        ..color = ink.withValues(alpha: b.isDark ? 0.75 : 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );
    // Side wall: turned metal, dimmer than the face (it faces away from the
    // light) with a soft specular band left of centre.
    Color dim(Color c, double t) => Color.lerp(c, ink, t)!;
    canvas.drawOval(
      base,
      Paint()
        ..shader = LinearGradient(
          colors: [
            dim(m[4], 0.45),
            dim(m[0], 0.25),
            dim(m[3], 0.1),
            dim(m[0], 0.3),
            dim(m[4], 0.55),
          ],
          stops: const [0, 0.25, 0.42, 0.75, 1],
        ).createShader(base),
    );
    // Occlusion: the wall darkens toward the floor.
    canvas.drawOval(
      base,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, ink.withValues(alpha: 0.45)],
          stops: const [0.85, 1],
        ).createShader(base),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialBodyPainter old) =>
      !identical(old.brass, brass) ||
      old.diameter != diameter ||
      old.height != height ||
      old.bevel != bevel;
}
