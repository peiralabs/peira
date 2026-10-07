import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/render_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadRealFonts();

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
