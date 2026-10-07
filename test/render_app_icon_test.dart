// Machine-independent visual regression tests for the live Astrolabe emblem.
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
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
}
