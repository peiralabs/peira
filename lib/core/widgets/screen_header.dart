import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brass_icon_badge.dart';

/// The shared brass screen header (design idiom on every native screen):
/// 50px [BrassIconBadge], engraved Playfair title with the standard drop
/// shadow, a small-caps subtitle in the section's accent, and any trailing
/// widgets (stat chips, pills, buttons) right-aligned.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.icon,
    this.badgeField,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.trailing = const [],
  });

  final IconData icon;

  /// Inner-field gradient for the badge (default bottle-green; garnet for
  /// Services screens, navy for System screens).
  final RadialGradient? badgeField;

  /// Badge icon tint override.
  final Color? iconColor;

  final String title;
  final String subtitle;

  /// Small-caps subtitle colour (sage default; garnet/navy per section).
  final Color? subtitleColor;

  /// Right-aligned extras: stat chips, reachability pills, action buttons.
  /// Callers include their own inter-widget spacing.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return Row(
      children: [
        BrassIconBadge(icon: icon, field: badgeField, iconColor: iconColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontWeight: FontWeight.w800,
                  fontSize: 27,
                  height: 1.05,
                  color: brass.textHeading,
                  shadows: [
                    Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 1,
                        // Engraved in the dark; letterpress on parchment.
                        color: brass.isDark
                            ? const Color(0x80000000)
                            : const Color(0x66FFFBEE)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 12 * 0.18,
                  color: subtitleColor ?? brass.sage,
                ),
              ),
            ],
          ),
        ),
        ...trailing,
      ],
    );
  }
}
