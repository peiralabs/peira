import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/build_config.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/navigation_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/webview/webview_factory.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';
import 'package:peira/screens/webview/webview_screen.dart';

/// The Open WebUI model-chain strip renders this lab's private AI routing
/// (AiChain) — personal build only. Dual-mode like nav_railindex_test: the
/// assertion flips on [kPublicBuild], so each `--dart-define` run verifies
/// its own side.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

class _FakeWebViewFactory implements WebViewFactory {
  @override
  Widget build(String url,
          {String? maskScript, bool controls = false, String? controlsLabel}) =>
      Center(child: Text('webview: $url'));
}

void main() {
  testWidgets('Open WebUI model-chain strip is personal-build only',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository(
            const AppSettings(ollamaUrl: 'http://ollama.example:8080'),
          )),
          webViewFactoryProvider.overrideWithValue(_FakeWebViewFactory()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: WebViewScreen(service: 'Open WebUI', tabIndex: 0),
          ),
        ),
      ),
    );
    // The lazy webview only activates once its tab is selected (selectedTab
    // starts null so the shell can pick the initial tab).
    final context = tester.element(find.byType(WebViewScreen));
    ProviderScope.containerOf(context, listen: false)
        .read(selectedTabProvider.notifier)
        .select(0);
    await tester.pumpAndSettle();

    expect(find.text('webview: http://ollama.example:8080'), findsOneWidget);
    expect(
      find.byType(AiStatusStrip),
      kPublicBuild ? findsNothing : findsOneWidget,
    );
  });
}
