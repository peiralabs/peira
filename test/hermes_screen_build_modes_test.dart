import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/build_config.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/theme/phosphor.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';
import 'package:peira/screens/hermes/hermes_screen.dart';

/// The chat screen's identity is const on [kPublicBuild] — these assertions
/// pass in BOTH modes, so the suite verifies each side under its own
/// `--dart-define=PEIRA_PUBLIC` run (the nav_railindex_test pattern).
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

const _configured = AppSettings(
  hermesUrl: 'http://hermes.example',
  hermesApiUrl: 'http://ai.example:11434',
  hermesApiKey: 'test-key',
  aiChatModel: 'llama3.2',
);

Widget _screen(AppSettings settings) => ProviderScope(
      overrides: [
        // No network in widget tests — pin the reachability pill to healthy.
        serviceReachableProvider.overrideWith((ref, url) async => true),
        settingsRepositoryProvider
            .overrideWithValue(_FakeSettingsRepository(settings)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: HermesScreen()),
      ),
    );

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('chat screen carries the build-resolved identity',
      (tester) async {
    _viewport(tester);
    await tester.pumpWidget(_screen(_configured));
    await tester.pumpAndSettle();

    expect(find.text(kPublicBuild ? 'AI Chat' : 'Hermes'), findsOneWidget);
    expect(
      find.text(kPublicBuild
          ? 'AI ASSISTANT · LLAMA3.2'
          : 'AI ASSISTANT · CLAUDE-HAIKU-4-5'),
      findsOneWidget,
    );
    expect(
      find.text(kPublicBuild
          ? 'Send a message…'
          : 'Ask Hermes anything about your homelab…'),
      findsOneWidget,
    );
    expect(
      find.text(kPublicBuild ? 'Endpoint up' : 'Hermes up'),
      findsOneWidget,
    );
    expect(
      find.text(kPublicBuild
          ? 'Chat with your own AI endpoint — Ollama, LiteLLM, '
              'OpenRouter, vLLM.'
          : 'Ask Hermes about the lab — it can see the cluster.'),
      findsOneWidget,
    );
  });

  testWidgets('refuses to send until fully configured for this build',
      (tester) async {
    _viewport(tester);
    // Endpoint set, but no key (personal guard) and no model (public
    // guard) — the system bubble names the piece this build is missing.
    await tester.pumpWidget(_screen(const AppSettings(
      hermesUrl: 'http://hermes.example',
      hermesApiUrl: 'http://ai.example:11434',
    )));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byIcon(PhBold.paperPlaneTilt));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
          kPublicBuild ? 'No model is set' : 'API key is not set'),
      findsOneWidget,
    );
  });
}
