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
    final brass = context.brass;
    // Centred gilt rule built from the theme's own metal ramp (transparent
    // ends → dark edge → mid → peak → mid → dark edge → transparent).
    final m = brass.brassStops;
    final barStops = [
      m[0].withValues(alpha: 0),
      m[0],
      m[1],
      m[2],
      m[1],
      m[0],
      m[0].withValues(alpha: 0),
    ];
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
            colors: [brass.bannerTop, brass.panelBottom],
          ),
          border: Border(bottom: BorderSide(color: brass.hairline)),
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
                    colors: barStops,
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
                            color: brass.textMuted,
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

