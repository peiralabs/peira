import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';

/// Health severity, mapped to a colour and a breathing cadence. Worse health
/// breathes faster — you read a room full of these peripherally, like server
/// LEDs, instead of parsing colored text chips.
enum Health {
  ok(Color(0xFF7BB26A), 3400),
  warn(Color(0xFFE0A83F), 1700),
  crit(Color(0xFFC8564A), 850),
  offline(Color(0xFF6B6B7A), 0);

  const Health(this.color, this.periodMs);

  /// The static dark-ramp colour. Brightness-aware call sites resolve the
  /// ramp through [Brass] instead (offline grey is shared between modes).
  final Color color;
  final int periodMs;

  /// Health from a load fraction (0..1) using the shared ramp thresholds.
  static Health fromLoad(double fraction) {
    if (fraction >= 0.85) return Health.crit;
    if (fraction >= 0.6) return Health.warn;
    return Health.ok;
  }
}

/// A jewelled pilot lamp for its [health], set behind domed glass in a
/// turned-brass bezel: the jewel *emits* light with a soft halo that breathes
/// (pulses brighter/dimmer) at a cadence set by severity. Offline is dark
/// glass. [size] is the jewel; the bezel makes the whole lamp 1.6× wider. The breathing controller is disabled under `flutter test` so
/// goldens settle.
class StatusLight extends StatefulWidget {
  const StatusLight({
    super.key,
    required this.health,
    this.size = 10,
    this.color,
  });

  final Health health;
  final double size;

  /// Jewel colour override (e.g. a device's OS jewel); [health] still sets
  /// whether it is lit and how it breathes.
  final Color? color;

  @override
  State<StatusLight> createState() => _StatusLightState();
}

class _StatusLightState extends State<StatusLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: widget.health.periodMs == 0 ? 1 : widget.health.periodMs,
    ),
  );

  @override
  void initState() {
    super.initState();
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(StatusLight old) {
    super.didUpdateWidget(old);
    if (old.health != widget.health) {
      _c.duration = Duration(
        milliseconds: widget.health.periodMs == 0 ? 1 : widget.health.periodMs,
      );
      _maybeAnimate();
    }
  }

  void _maybeAnimate() {
    if (kMolAnimationsEnabled && widget.health.periodMs > 0) {
      _c.repeat();
    } else {
      _c.stop();
      _c.value = 0.4;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    if (kit != InstrumentKit.brass) return _kitLamp(context, kit);
    final brass = context.brass;
    final m = brass.brassStops;
    // The jewel is a lit lamp behind dark glass, so it keeps the bright ramp
    // in both modes (on parchment the deep-tone ramp read as an unlit lamp).
    final color = widget.color ?? widget.health.color;
    final offline = widget.health == Health.offline;
    final s = widget.size;
    final outer = s * 1.6;
    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Turned-brass bezel, sitting proud of the panel.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [m[2], m[3], m[4]],
              ),
              boxShadow: [
                BoxShadow(
                  color: brass.isDark
                      ? const Color(0x99000000)
                      : const Color(0x4D46381F),
                  offset: const Offset(0.4, 0.9),
                  blurRadius: 1.4,
                ),
              ],
            ),
          ),
          // The lamp well.
          Container(
            width: s * 1.18,
            height: s * 1.18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0A0D0A),
            ),
          ),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              // Breathe between dim and bright; offline stays flat and dark.
              final t = offline
                  ? 0.0
                  : 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
              final glow = offline ? 0.0 : 0.35 + 0.55 * t;
              return Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.25, -0.3),
                    colors: [
                      Color.lerp(color, Colors.white, offline ? 0.1 : 0.45)!
                          .withValues(alpha: offline ? 0.5 : 0.8 + 0.2 * t),
                      color.withValues(alpha: offline ? 0.4 : 0.75 + 0.25 * t),
                      Color.lerp(color, Colors.black, 0.5)!,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                  boxShadow: glow > 0
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6 * glow),
                            blurRadius: s * (1.0 + 1.4 * t),
                            spreadRadius: s * 0.1 * t,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          // Domed glass: darker toward its rim, a pinpoint upper left.
          Container(
            width: s * 1.18,
            height: s * 1.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: offline ? 0.45 : 0.28),
                ],
                stops: const [0.6, 1],
              ),
            ),
          ),
          Positioned(
            left: outer * 0.31,
            top: outer * 0.28,
            child: Container(
              width: outer * 0.12,
              height: outer * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: offline ? 0.4 : 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The other families' lamps, breathing at the same severity cadence.
  Widget _kitLamp(BuildContext context, InstrumentKit kit) {
    final b = context.brass;
    final color = widget.color ?? widget.health.color;
    final offline = widget.health == Health.offline;
    final s = widget.size;
    final outer = s * 1.6;
    return SizedBox(
      width: outer,
      height: outer,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = offline ? 0.0 : 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
          final glow = offline ? 0.0 : 0.35 + 0.55 * t;
          final lit = offline
              ? color.withValues(alpha: 0.4)
              : Color.lerp(color, Colors.white, 0.15 * t)!;
          List<BoxShadow> halo(double k) => glow > 0
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6 * glow * k),
                    blurRadius: s * (1.0 + 1.4 * t) * k,
                  ),
                ]
              : const [];
          switch (kit) {
            case InstrumentKit.graphite:
              // A square LED in a flat dark bezel.
              return Center(
                child: Container(
                  width: s * 1.35,
                  height: s * 1.35,
                  padding: EdgeInsets.all(s * 0.18),
                  decoration: BoxDecoration(
                    color: b.isDark
                        ? const Color(0xFF1B1F23)
                        : const Color(0xFF3A4047),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: lit,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: halo(0.8),
                    ),
                  ),
                ),
              );
            case InstrumentKit.terminal:
              // A bare LED: all glow, no bezel.
              return Center(
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lit,
                    boxShadow: halo(1.3),
                  ),
                ),
              );
            case InstrumentKit.obsidian:
              // Dim: a low glow under a matte black ring.
              return Center(
                child: Container(
                  width: s * 1.3,
                  height: s * 1.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0A0A0A),
                    border: Border.all(color: const Color(0xFF2C2C30)),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: s * 0.8,
                    height: s * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lit.withValues(alpha: offline ? 0.4 : 0.75),
                      boxShadow: halo(0.5),
                    ),
                  ),
                ),
              );
            case InstrumentKit.aqua:
              // A candy-gloss bead: a strong highlight dome over the colour.
              return Center(
                child: Container(
                  width: s * 1.25,
                  height: s * 1.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.4),
                      colors: [Color.lerp(lit, Colors.white, 0.35)!, lit,
                          Color.lerp(lit, Colors.black, 0.35)!],
                      stops: const [0, 0.6, 1],
                    ),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
                    boxShadow: halo(0.6),
                  ),
                  alignment: const Alignment(0, -0.55),
                  child: Container(
                    width: s * 0.75,
                    height: s * 0.42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(s),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: 0.9),
                            Colors.white.withValues(alpha: 0.1)],
                      ),
                    ),
                  ),
                ),
              );
            case InstrumentKit.catppuccin:
              // A soft LED: pastel, with a wide gentle halo.
              return Center(
                child: Container(
                  width: s * 1.1,
                  height: s * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lit,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: b.isDark ? 0.15 : 0.6),
                      width: 1.5,
                    ),
                    boxShadow: halo(1.6),
                  ),
                ),
              );
            case InstrumentKit.nord:
            case InstrumentKit.ember:
            case InstrumentKit.brass:
              // Nord: a lit indicator inside a thin bright ring. Ember: a
              // jewel in a chrome bezel.
              final ember = kit == InstrumentKit.ember;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: outer,
                    height: outer,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: ember
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF7F7F7), Color(0xFFB9BBBE),
                                  Color(0xFF6E7072)],
                            )
                          : null,
                      color: ember ? null : const Color(0xFF0D1B2A),
                      border: ember
                          ? null
                          : Border.all(color: const Color(0xCC88C0D0), width: 1.2),
                    ),
                  ),
                  Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.25, -0.3),
                        colors: [Color.lerp(lit, Colors.white, 0.4)!, lit,
                            Color.lerp(lit, Colors.black, 0.45)!],
                        stops: const [0, 0.55, 1],
                      ),
                      boxShadow: halo(1),
                    ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}
