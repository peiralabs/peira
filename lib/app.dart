import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/build_config.dart';
import 'core/providers/settings_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/window_background.dart';
import 'screens/app_shell.dart';

class HomeLabApp extends ConsumerWidget {
  const HomeLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    final pack = ThemePack.byId(settings?.themeId);
    final mode = switch (settings?.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(pack),
      darkTheme: AppTheme.dark(pack),
      themeMode: mode,
      // Two authored palettes per family (e.g. bottle-green vs parchment):
      // snap between them — a half-lerped instrument looks broken, not
      // transitional.
      themeAnimationDuration: Duration.zero,
      // Persist the resolved theme's base background so the native runner can
      // paint the launch window that colour next time (no wrong-theme flash).
      builder: (context, child) {
        persistWindowBackground(context.brass.bg);
        return child ?? const SizedBox.shrink();
      },
      home: const AppShell(),
    );
  }
}
