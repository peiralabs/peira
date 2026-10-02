import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/demo/demo.dart';

void main(List<String> args) {
  // `--demo` / MOL_DEMO=1: a fully populated fake lab — no configuration,
  // no keyring dependency, no network. See lib/core/demo/demo.dart.
  runApp(ProviderScope(
    overrides: isDemoRequested(args) ? demoOverrides : const [],
    child: const HomeLabApp(),
  ));
}
