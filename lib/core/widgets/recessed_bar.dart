import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A recessed meter track with a gradient fill (dashboard / node-card idiom):
/// dark inset channel, gilt hairline border, gradient fill with a light lip.
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
  final double height;

  /// Track border tint (gilt hairline by default; the recessed green torrent
  /// track uses an emerald tint).
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final pal = context.brass.isDark ? _Palette.dark : _Palette.light;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: pal.track,
        border: Border.all(color: borderColor ?? pal.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(colors: gradient),
            border: Border(top: BorderSide(color: pal.lip)),
          ),
        ),
      ),
    );
  }
}

/// File-local dark/light pair for the track dress (dark values verbatim; on
/// parchment the channel is an umber ink wash and the lip warm paper-white).
class _Palette {
  const _Palette({
    required this.border,
    required this.track,
    required this.lip,
  });

  final Color border;
  final Color track;
  final Color lip;

  static const dark = _Palette(
    border: Color(0x38C9AA58),
    track: Color(0x59000000),
    lip: Color(0x59C8FFB4),
  );
  static const light = _Palette(
    border: Color(0x476E5220),
    track: Color(0x2E46381F),
    lip: Color(0x59FFFBEE),
  );
}
