import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/build_config.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';
import 'package:peira/screens/ai/ai_screen.dart';

/// The Open WebUI model-chain strip renders this lab's private AI routing
/// (AiChain) — personal build only. The assertion flips on [kPublicBuild],
/// so each `--dart-define` run verifies its own side.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

void main() {
  testWidgets('Open WebUI model-chain strip is personal-build only', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceReachableProvider.overrideWith((ref, url) async => true),
          // No API key: the tab shows its setup prompt and opens no socket.
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(
              const AppSettings(ollamaUrl: 'http://ollama.example:8080'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: AiOpenWebUiTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open WebUI needs its API key.'), findsOneWidget);
    expect(
      find.byType(AiStatusStrip),
      kPublicBuild ? findsNothing : findsOneWidget,
    );
  });
}
