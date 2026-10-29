import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sweep_providers.dart';
import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';
import 'flip_readout.dart';
import 'kit_parts.dart';

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
    final kit = context.kit;
    if (kit != InstrumentKit.brass) {
      // The family's own dial: the value sweeps (or the needle swings) in
      // from zero on the same epoch as the Brass gauges.
      return SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(epoch),
          tween: Tween(begin: kMolAnimationsEnabled ? 0 : clamped, end: clamped),
          duration: kMolAnimationsEnabled
              ? const Duration(milliseconds: 1300)
              : Duration.zero,
          curve: const Cubic(0.2, 0.8, 0.2, 1),
          builder: (context, value, child) => CustomPaint(
            painter: KitDialPainter(kit, brass, value, color),
            child: child,
          ),
          child: Align(
            alignment: kitReadoutAlignment(kit),
            // Long values (17/17, 100%) shrink to fit inside the dial's
            // track rather than spilling over it.
            child: SizedBox(
              width: size * 0.56,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: FlipReadout(
                  text: display,
                  fontSize: 21 * size / 130 * kitReadoutScale(kit),
                  epoch: epoch,
                ),
              ),
            ),
          ),
        ),
      );
    }
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
                child: SizedBox(
                  width: size * 0.58,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: FlipReadout(
                      text: display,
                      fontSize: 21 * size / 130,
                      epoch: epoch,
                    ),
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
// Tube geometry in the 130-unit space, shared by both painters.
const _tubeR = 45.0;
const _boreW = 11.0;
const _liquidW = 7.4;
const _bulbR = 5.6;
const _bulbC = Offset(65, 65 - _tubeR);

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

    // Glass tube: a dark bore with thin lit walls, and the reservoir bulb's
    // glass at 12 o'clock where the scale starts.
    canvas.drawCircle(
      c,
      _tubeR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _boreW
        ..color = const Color(0xE6070A08),
    );
    final wall = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0x40F3E7C2);
    canvas.drawCircle(c, _tubeR - _boreW / 2, wall);
    canvas.drawCircle(c, _tubeR + _boreW / 2, wall);
    canvas.drawCircle(_bulbC, _bulbR + 1.2, Paint()..color = const Color(0xFF070A08));
    canvas.drawCircle(
      _bulbC,
      _bulbR + 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0x66F3E7C2),
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
    canvas.save();
    canvas.scale(size.width / 130, size.height / 130);
    const c = Offset(65, 65);

    // On parchment, keep any blur inside the instrument: clip to the dark
    // face disc (r61, matching the static painter). Dark mode is untouched.
    if (!isDark) {
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: 61)));
    }

    final deep = Color.lerp(color, Colors.black, 0.55)!;
    final shine = Color.lerp(color, Colors.white, 0.55)!;

    // Reservoir bulb, always full: a glossy sphere of the liquid.
    canvas.drawCircle(
      _bulbC,
      _bulbR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [shine, color, deep],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: _bulbC, radius: _bulbR)),
    );

    final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
    if (sweep > 0) {
      final arcRect = Rect.fromCircle(center: c, radius: _tubeR);
      // A faint glow where the liquid lights the bore.
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _boreW
          ..color = color.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      // The column: shaded across its width like liquid in a round tube —
      // dark at both walls, a bright core nearer the inner (lit) side.
      const r0 = _tubeR - _liquidW / 2, r1 = _tubeR + _liquidW / 2;
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _liquidW
          ..shader = RadialGradient(
            colors: [deep, shine, color, deep],
            stops: [r0 / r1, (r0 + 1.6) / r1, (r0 + 3.4) / r1, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r1)),
      );
      // Meniscus: the rounded front of the column, with its own highlight.
      final a = -math.pi / 2 + sweep;
      final tip = c + Offset(_tubeR * math.cos(a), _tubeR * math.sin(a));
      canvas.drawCircle(
        tip,
        _liquidW / 2,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.35),
            colors: [shine, color, deep],
            stops: const [0, 0.5, 1],
          ).createShader(Rect.fromCircle(center: tip, radius: _liquidW / 2)),
      );
    }

    // Glass over everything: a long soft reflection along the upper-left of
    // the tube and a pinpoint on the bulb (light from the upper left).
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: _tubeR + 2.2),
      math.pi * 1.02,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x40FFFFFF),
    );
    canvas.drawCircle(
      _bulbC + const Offset(-1.8, -1.9),
      1.3,
      Paint()..color = const Color(0xB3FFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GaugeArcPainter old) =>
      old.fraction != fraction || old.color != color || old.isDark != isDark;
}
