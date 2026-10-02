// Renders the app icon straight from the live Astrolabe emblem so the launcher
// icon can never drift from the in-app brand mark. Regenerate with:
//   flutter test test/render_app_icon_test.dart --update-goldens
// Output (matched as goldens on every run): assets/icon/homelab-{512,256}.png
//
// Tagged `golden` so CI can exclude it: exact-pixel PNGs rendered on the
// maintainer machine's fontconfig never match a CI runner's text rendering.
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/widgets/astrolabe.dart';

import 'support/render_fonts.dart';

void main() {
  setUpAll(loadRealFonts);

  // The emblem all but fills its own box, so inset it a touch to breathe inside
  // the icon tile. Animations are gated off under FLUTTER_TEST, so the rete and
  // alidade render static (deterministic) at their zero rotation.
  Future<void> renderIcon(
    WidgetTester tester,
    double size,
    double inset,
    String path,
  ) async {
    await tester.binding.setSurfaceSize(Size(size, size));
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      // The icon is the dark-authored brand mark: pin the dark theme so the
      // launcher asset can't shift with the ambient brightness now that the
      // astrolabe's shadows are theme-resolved (tests default to light).
      Theme(
        data: AppTheme.dark(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: const Key('icon'),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Astrolabe(
                  size: size - inset * 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('icon')), matchesGoldenFile(path));
  }

  testWidgets('render 512px app icon from the astrolabe', (tester) async {
    await renderIcon(tester, 512, 24, '../assets/icon/homelab-512.png');
  });

  testWidgets('render 256px app icon from the astrolabe', (tester) async {
    await renderIcon(tester, 256, 12, '../assets/icon/homelab-256.png');
  });
}
