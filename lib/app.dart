import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/build_config.dart';
import 'core/providers/settings_providers.dart';
import 'core/theme/app_theme.dart';
import 'screens/app_shell.dart';

class HomeLabApp extends ConsumerWidget {
  const HomeLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    final mode = switch (settings?.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      // Two authored palettes (bottle-green vs parchment): snap between them —
      // a half-lerped brass instrument looks broken, not transitional.
      themeAnimationDuration: Duration.zero,
      home: const AppShell(),
    );
  }
}
