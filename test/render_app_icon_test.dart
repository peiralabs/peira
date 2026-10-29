// Machine-independent visual regression tests for the live Astrolabe emblem.
@Tags(['golden'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/widgets/astrolabe.dart';

void main() {
  // The emblem all but fills its own box, so inset it a touch to breathe inside
  // the icon tile. Animations are gated off under FLUTTER_TEST, so the rete and
  // alidade render static (deterministic) at their zero rotation.
  void renderIcon(
    String description,
    String fileName,
    double size,
    double inset,
  ) {
    goldenTest(
      description,
      fileName: fileName,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      builder: () => Theme(
        // The icon is the dark-authored brand mark: pin the dark theme so the
        // launcher asset cannot shift with ambient brightness.
        data: AppTheme.dark(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: Astrolabe(size: size - inset * 2)),
          ),
        ),
      ),
    );
  }

  renderIcon(
    'render 512px app icon from the astrolabe',
    'app_icon_512',
    512,
    24,
  );
  renderIcon(
    'render 256px app icon from the astrolabe',
    'app_icon_256',
    256,
    12,
  );

  // The launcher icon files themselves (assets/icon/homelab-*.png, shipped in
  // the AppImage) on a transparent background. Opt-in, so a normal test run
  // never rewrites a shipped asset:
  //   UPDATE_ICON_ASSETS=1 flutter test test/render_app_icon_test.dart
  final writeAssets = Platform.environment['UPDATE_ICON_ASSETS'] == '1';
  for (final (size, inset) in const [(512.0, 24.0), (256.0, 12.0)]) {
    testWidgets(
      'write assets/icon/homelab-${size.toInt()}.png',
      (tester) async {
        final key = GlobalKey();
        tester.view.physicalSize = Size(size, size);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          Theme(
            data: AppTheme.dark(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Center(child: Astrolabe(size: size - inset * 2)),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'assets/icon/homelab-${size.toInt()}.png',
          ).writeAsBytes(png!.buffer.asUint8List());
        });
      },
      skip: !writeAssets,
    );
  }
}
