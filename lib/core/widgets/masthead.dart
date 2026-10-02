import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/phosphor.dart';

import '../window/window_channel.dart';
import 'about_overlay.dart';
import 'astrolabe.dart';
import 'brass_ornament.dart';

/// The 62px masthead — on Linux this IS the window titlebar (the GTK titlebar
/// is a zero-height CSD widget): drag to move, double-click to maximize, brass
/// stud to close. Center opens the About overlay.
class Masthead extends StatelessWidget {
  const Masthead({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.brass.isDark ? _Palette.dark : _Palette.light;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => WindowChannel.beginMove(),
      onDoubleTap: WindowChannel.toggleMaximize,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.panelTop, palette.panelBottom],
          ),
          border: Border(bottom: BorderSide(color: palette.hairline)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gilt underline bar.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: palette.barStops,
                    stops: const [0, 0.08, 0.3, 0.5, 0.7, 0.92, 1],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 18,
              child: Row(
                children: [
                  RivetStud(),
                  SizedBox(width: 9),
                  RivetStud(),
                  SizedBox(width: 9),
                  RivetStud(),
                ],
              ),
            ),
            // Center: rule – gem – astrolabe – wordmark – gem – rule.
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => showAboutHomeLab(context),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GiltRule(width: 60, reverse: true),
                    const SizedBox(width: 16),
                    const GemDiamond(),
                    const SizedBox(width: 16),
                    const Astrolabe(size: 46, detail: AstrolabeDetail.compact),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GiltWordmark(),
                        const SizedBox(height: 1),
                        Text(
                          'EST · MMXXVI',
                          style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: 9.5 * 0.3,
                            color: palette.subtitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    const GemDiamond(),
                    const SizedBox(width: 16),
                    const GiltRule(width: 60),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 18,
              child: BrassStud(
                icon: PhBold.x,
                tooltip: 'Close',
                onTap: WindowChannel.close,
              ),
            ),
            const Positioned(
              right: 56,
              child: BrassStud(
                icon: PhBold.minus,
                size: 22,
                tooltip: 'Minimize',
                onTap: WindowChannel.minimize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Masthead-local inks, resolved per brightness: dark values verbatim from
/// the dark-only era; light is warm paper with the gilt bar dimmed to inlaid
/// bronze (still metal, not ink — the near-white center vanishes on parchment).
class _Palette {
  const _Palette({
    required this.panelTop,
    required this.panelBottom,
    required this.hairline,
    required this.barStops,
    required this.subtitle,
  });

  final Color panelTop;
  final Color panelBottom;
  final Color hairline;
  final List<Color> barStops;
  final Color subtitle;

  static const dark = _Palette(
    panelTop: Color(0xF2293A29),
    panelBottom: Color(0xD117251A),
    hairline: Color(0x66C9AA58),
    barStops: [
      Color(0x007D5F26),
      Color(0xFF7D5F26),
      Color(0xFFF2DD94),
      Color(0xFFFFF6CF),
      Color(0xFFF2DD94),
      Color(0xFF7D5F26),
      Color(0x007D5F26),
    ],
    subtitle: Color(0xFF97A986),
  );

  static const light = _Palette(
    panelTop: Color(0xF2F1E9D6),
    panelBottom: Color(0xD1E3D8C0),
    hairline: Color(0x736E5220),
    barStops: [
      Color(0x006B5220),
      Color(0xFF6B5220),
      Color(0xFFC9A855),
      Color(0xFFE8CC80),
      Color(0xFFC9A855),
      Color(0xFF6B5220),
      Color(0x006B5220),
    ],
    // Darkened from 0xFF55684A: the 9.5px small caps sat below comfortable
    // legibility on the parchment plate.
    subtitle: Color(0xFF47573E),
  );
}
