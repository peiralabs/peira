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

/// A small dot that *emits* light for its [health]: a soft halo that breathes
/// (pulses brighter/dimmer) at a cadence set by severity. Offline is a dim,
/// static dot. The breathing controller is disabled under `flutter test` so
/// goldens settle.
class StatusLight extends StatefulWidget {
  const StatusLight({super.key, required this.health, this.size = 10});

  final Health health;
  final double size;

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
    final brass = context.brass;
    // Resolve the ramp per brightness; the offline grey is shared.
    final color = switch (widget.health) {
      Health.ok => brass.ok,
      Health.warn => brass.warn,
      Health.crit => brass.crit,
      Health.offline => Health.offline.color,
    };
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // Breathe between dim and bright; offline stays flat.
        final t = widget.health == Health.offline
            ? 0.0
            : 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
        final glow = widget.health == Health.offline ? 0.0 : 0.35 + 0.55 * t;
        return Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(
              alpha: widget.health == Health.offline ? 0.45 : 0.7 + 0.3 * t,
            ),
            boxShadow: glow > 0
                ? [
                    BoxShadow(
                      // Additive halo in the dark; on parchment the breathing
                      // halo becomes a deep-tone ink wash at lower strength.
                      color: color.withValues(
                        alpha: (brass.isDark ? 0.55 : 0.28) * glow,
                      ),
                      blurRadius: s * (1.2 + 1.6 * t),
                      spreadRadius: s * 0.15 * t,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
