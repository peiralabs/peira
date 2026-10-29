// Not a `_test.dart` file — not run by default. Renders the full AppShell
// (chrome included) in demo mode under one theme, to eyeball real-screen
// theming. Software rasterizer, no GPU/display.
//   THEME_PACK=terminal THEME_MODE=light flutter test test/theme_screen_preview.dart
// THEME_MODE is 'dark' (default) or 'light'. Writes
// $THEME_PREVIEW_DIR/screen-<id>.png (dark) or screen-<id>-light.png (default /tmp).
// For README shots of one tab: PREVIEW_TAB=<AppTab name, e.g. homeAssistant>,
// optional PREVIEW_SUB=<hub strip index>, and PREVIEW_OUT=<file name>.
// PREVIEW_H=<logical height> renders a taller window (default 900);
// PREVIEW_ABOUT=1 opens the About overlay before the capture.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/demo/demo.dart';
import 'package:peira/core/navigation/app_tab.dart';
import 'package:peira/core/providers/navigation_providers.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/widgets/about_overlay.dart';
import 'package:peira/screens/app_shell.dart';

import 'support/render_fonts.dart';

void main() {
  final outDir = Platform.environment['THEME_PREVIEW_DIR'] ?? '/tmp';
  final id = Platform.environment['THEME_PACK'] ?? 'brass';
  final mode = Platform.environment['THEME_MODE'] ?? 'dark';
  final tabName = Platform.environment['PREVIEW_TAB'];
  final sub = int.tryParse(Platform.environment['PREVIEW_SUB'] ?? '');
  final outName = Platform.environment['PREVIEW_OUT'];
  final height = double.tryParse(Platform.environment['PREVIEW_H'] ?? '') ?? 900;
  final about = Platform.environment['PREVIEW_ABOUT'] == '1';
  final pack = ThemePack.byId(id);

  setUpAll(loadRealFonts);

  testWidgets('render screen $id', (tester) async {
    tester.view.physicalSize = Size(1440, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: demoOverrides,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(pack),
            darkTheme: AppTheme.dark(pack),
            themeMode: mode == 'light' ? ThemeMode.light : ThemeMode.dark,
            home: const AppShell(),
          ),
        ),
      ),
    );
    // AppShell runs a background alert watcher; pump fixed frames instead of
    // pumpAndSettle so we don't wait on it forever.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    if (tabName != null) {
      final tab = AppTab.values.byName(tabName);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );
      container.read(selectedTabProvider.notifier).select(tab.railIndex);
      if (sub != null) container.read(hubSubTabProvider(tab).notifier).select(sub);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }
    if (about) {
      showAboutHomeLab(tester.element(find.byType(AppShell)));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final suffix = mode == 'light' ? '-light' : '';
      await File(
        '$outDir/${outName ?? 'screen-$id$suffix.png'}',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}
