// Not a `_test.dart` file — not run by default. Renders the full AppShell
// (chrome included) in demo mode under one theme, to eyeball real-screen
// theming. Software rasterizer, no GPU/display.
//   THEME_PACK=terminal flutter test test/theme_screen_preview.dart
// Writes $THEME_PREVIEW_DIR/screen-<id>.png (default /tmp).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/demo/demo.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/app_shell.dart';

import 'support/render_fonts.dart';

void main() {
  final outDir = Platform.environment['THEME_PREVIEW_DIR'] ?? '/tmp';
  final id = Platform.environment['THEME_PACK'] ?? 'brass';
  final pack = ThemePack.byId(id);

  setUpAll(loadRealFonts);

  testWidgets('render screen $id', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
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
            themeMode: ThemeMode.dark,
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
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$outDir/screen-$id.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}
