import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The 50px brass icon badge shared by screen headers: polished brass rim
/// around a recessed jewel-toned field (bottle-green by default; the AI
/// screens use a garnet field, the System screens a navy one).
class BrassIconBadge extends StatelessWidget {
  const BrassIconBadge({
    super.key,
    required this.icon,
    this.size = 50,
    this.field,
    this.iconColor,
  });

  final IconData icon;
  final double size;

  /// Inner-field gradient override (default: bottle-green).
  final RadialGradient? field;

  /// Icon tint override (default: warm parchment).
  final Color? iconColor;

  /// Garnet inner field (Services accent — Ollama / Hermes).
  static const garnetField = RadialGradient(
    center: Alignment(-0.2, -0.36),
    colors: [Color(0xFF8A4038), Color(0xFF2C1213)],
  );

  /// Navy inner field (System accent — Tailscale / Terminal / Settings).
  static const navyField = RadialGradient(
    center: Alignment(-0.2, -0.36),
    colors: [Color(0xFF3A5A8A), Color(0xFF101D33)],
  );

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: brass.brassV,
        boxShadow: [
          BoxShadow(
              // Black drop in the dark; sepia-umber ink on parchment.
              color: brass.isDark
                  ? const Color(0x80000000)
                  : const Color(0x40352511),
              offset: const Offset(0, 3),
              blurRadius: 6),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: field ??
              const RadialGradient(
                center: Alignment(-0.2, -0.36),
                colors: [Color(0xFF26402A), Color(0xFF0E1A10)],
              ),
        ),
        child: Icon(icon,
            size: size * 0.46, color: iconColor ?? const Color(0xFFF2E6BF)),
      ),
    );
  }
}
