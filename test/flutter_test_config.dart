import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/render_fonts.dart';

/// Maximum fraction of pixels allowed to differ before a golden fails.
/// 0.01% (~96 px on a 1200x800 shot) absorbs sub-perceptual anti-aliasing /
/// rounding noise — e.g. a single 1/255 background pixel from a layout
/// sub-pixel shift — while any PERCEPTIBLE change (text, a line, an element,
/// hundreds of pixels) still fails. Tune here if the gate proves too loose or
/// too strict; it is the one knob for the visual regression gate.
const double _kGoldenTolerance = 0.0001;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadRealFonts();

  // Alchemist's CI goldens compare through the global goldenFileComparator;
  // swap in a tolerant one so sub-perceptual noise doesn't flake the gate.
  final existing = goldenFileComparator;
  if (existing is LocalFileComparator) {
    // LocalFileComparator derives its basedir from dirname(testFile), so pass
    // a FILE inside the existing basedir (test/) — passing the dir itself would
    // resolve goldens one level too high.
    goldenFileComparator = _TolerantGoldenComparator(
      existing.basedir.resolve('flutter_test_config.dart'),
      _kGoldenTolerance,
    );
  }

  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: CiGoldensConfig(
        // Keep the CI-only contract explicit even though these match defaults.
        // ignore: avoid_redundant_argument_values
        enabled: true,
        obscureText: false,
        // ignore: avoid_redundant_argument_values
        renderShadows: false,
      ),
    ),
    run: testMain,
  );
}

/// A [LocalFileComparator] that passes when the pixel difference is within
/// [tolerance] (a fraction in 0..1), so imperceptible anti-aliasing / rounding
/// noise does not fail the gate. Any larger diff still throws and writes the
/// usual alchemist failure images for review.
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, this.tolerance);

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      if (!result.passed) {
        debugPrint(
          'golden "$golden": tolerated '
          '${(result.diffPercent * 100).toStringAsFixed(4)}% pixel diff '
          '(<= ${(tolerance * 100).toStringAsFixed(4)}%).',
        );
      }
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
