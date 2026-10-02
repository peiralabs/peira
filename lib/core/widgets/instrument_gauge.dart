import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sweep_providers.dart';
import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';

/// A brass instrument gauge (design §Instrument gauge): polished bezel ring,
/// recessed face, 40-tick engraved scale, and a glowing value arc that sweeps
/// in from empty on mount and whenever [sweepEpochProvider] bumps.
///
/// Geometry is authored in a 130×130 space and scales with [size]. The static
/// body (bezel, face, ticks, track) paints on its own layer and repaints only
/// on brightness flips; only the glow + value arcs repaint while the sweep
/// animates. The face stays a dark instrument in both modes (light mode
/// paints an opaque bottle-green disc), so arcs/ticks/readout are shared.
class InstrumentGauge extends ConsumerWidget {
  const InstrumentGauge({
    super.key,
    required this.fraction,
    required this.color,
    required this.display,
    this.size = 130,
  });

  /// Arc fill 0..1.
  final double fraction;

  /// Fixed per-metric arc colour (brass.gaugeCpu / gaugeMemory /
  /// gaugeStorage / gaugeContainers — shared: they draw on the kept-dark
  /// face in both modes).
  final Color color;

  /// Center readout, e.g. `2%` or `10/10`.
  final String display;

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brass = context.brass;
    final epoch = ref.watch(sweepEpochProvider);
    final clamped = fraction.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Static body: repaints only on brightness flips, isolated on its
          // own layer so sweep frames re-composite it instead of repainting.
          RepaintBoundary(
            child: CustomPaint(painter: _GaugeStaticPainter(brass: brass)),
          ),
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              // Re-keying on the epoch restarts the sweep from empty.
              key: ValueKey(epoch),
              tween: Tween(
                  begin: kMolAnimationsEnabled ? 0 : clamped, end: clamped),
              duration: kMolAnimationsEnabled
                  ? const Duration(milliseconds: 1300)
                  : Duration.zero,
              curve: const Cubic(0.2, 0.8, 0.2, 1),
              builder: (context, value, child) => CustomPaint(
                painter: _GaugeArcPainter(
                    fraction: value, color: color, isDark: brass.isDark),
                child: child,
              ),
              child: Center(
                child: Text(
                  display,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.w800,
                    fontSize: 27 * size / 130,
                    // Fixed parchment ink on the kept-dark face in both
                    // modes — decoupled from textHeading by design.
                    color: const Color(0xFFF4EEDA),
                    shadows: const [
                      Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Color(0x99000000)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything that only changes with brightness: bezel, dark inner ring,
/// recessed face, engraved tick scale, and the empty track circle.
class _GaugeStaticPainter extends CustomPainter {
  const _GaugeStaticPainter({required this.brass});

  final Brass brass;

  /// Opaque bottle-green disc painted under the face in light mode so the
  /// shared arcs / ticks / readout keep their dark-mode home on parchment.
  static const _lightFaceFill = Color(0xFF16281C);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 130, size.height / 130);
    const c = Offset(65, 65);

    // On parchment an opaque disc goes under the bezel FIRST, out to the
    // bezel ring itself (r61 — the radius the dark face visually occupies),
    // so ticks / track / arcs / glow all land on the dark face exactly like
    // dark mode instead of on paper showing through the annulus.
    if (!brass.isDark) {
      canvas.drawCircle(c, 61, Paint()..color = _lightFaceFill);
    }

    // Brass bezel + dark inner ring.
    final bezelBounds = Rect.fromCircle(center: c, radius: 61);
    canvas.drawCircle(
      c,
      61,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: brass.brassStops,
          stops: const [0, 0.34, 0.5, 0.64, 1],
        ).createShader(bezelBounds),
    );
    canvas.drawCircle(
      c,
      58,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0x66000000),
    );

    // Recessed face vignette (the opaque light-mode disc is already down).
    canvas.drawCircle(
      c,
      46,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.65,
          colors: [Color(0x00142016), Color(0x73000000)],
        ).createShader(Rect.fromCircle(center: c, radius: 46)),
    );

    // Engraved 40-tick scale (every 9°, major every 5th).
    final minor = Paint()
      ..strokeWidth = 0.9
      ..color = const Color(0xFFD9BD72).withValues(alpha: 0.32);
    final major = Paint()
      ..strokeWidth = 1.8
      ..color = const Color(0xFFD9BD72).withValues(alpha: 0.75);
    for (var i = 0; i < 40; i++) {
      final isMajor = i % 5 == 0;
      final a = (i * 9 - 90) * math.pi / 180;
      const ro = 60.0;
      final ri = isMajor ? 52.0 : 55.0;
      canvas.drawLine(
        c + Offset(ro * math.cos(a), ro * math.sin(a)),
        c + Offset(ri * math.cos(a), ri * math.sin(a)),
        isMajor ? major : minor,
      );
    }

    // Empty track.
    canvas.drawCircle(
      c,
      45,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = const Color(0x1AC9AA58),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GaugeStaticPainter old) => !identical(old.brass, brass);
}

/// The per-frame layer: glow pass + value arc only.
class _GaugeArcPainter extends CustomPainter {
  const _GaugeArcPainter(
      {required this.fraction, required this.color, required this.isDark});

  final double fraction;
  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;
    canvas.save();
    canvas.scale(size.width / 130, size.height / 130);
    const c = Offset(65, 65);

    // On parchment, keep the glow blur inside the instrument: clip to the
    // dark face disc (r61, matching the static painter) so no haze bleeds
    // past the bezel rim onto paper. Dark mode is untouched.
    if (!isDark) {
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: 61)));
    }

    // Value arc from 12 o'clock.
    final arcRect = Rect.fromCircle(center: c, radius: 45);
    final sweep = 2 * math.pi * fraction;
    // Glow pass first (design: drop-shadow(0 0 6px glow)).
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GaugeArcPainter old) =>
      old.fraction != fraction || old.color != color || old.isDark != isDark;
}
