import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/app.dart';
import 'package:peira/core/demo/demo.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/grafana_providers.dart';
import 'package:peira/core/providers/navigation_providers.dart';
import 'package:peira/core/providers/ollama_providers.dart';
import 'package:peira/core/providers/proxmox_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/providers/tailscale_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';
import 'package:peira/screens/guide/guide_screen.dart';

class _Settings implements SettingsRepository {
  _Settings(this.settings);
  AppSettings settings;
  @override
  Future<AppSettings> load() async => settings;
  @override
  Future<void> save(AppSettings value) async => settings = value;
}

const _configured = AppSettings(
  proxmoxUrl: 'https://pve.example:8006',
  proxmoxTokenId: 'user@pve!token',
  proxmoxTokenSecret: 'secret',
);

Future<_Settings> _pump(
  WidgetTester tester,
  AppSettings settings, {
  bool demo = false,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _Settings(settings);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (demo) ...demoOverrides,
        if (!demo) ...[
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(repo),
          nodesProvider.overrideWith((ref) async => const []),
          allContainersProvider.overrideWith((ref) async => const []),
          activeAlertsProvider.overrideWith((ref) async => const []),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider.overrideWith(
            (ref) async => throw Exception('no tailscale in tests'),
          ),
          ollamaModelsProvider.overrideWith((ref) async => const []),
          ollamaRunningProvider.overrideWith((ref) async => const <String>{}),
        ],
        guideAutoOpenProvider.overrideWithValue(true),
      ],
      child: const HomeLabApp(),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('opens by itself, pages through, and "don\'t show" is saved', (
    tester,
  ) async {
    final repo = await _pump(tester, _configured);
    expect(find.byType(GuideDialog), findsOneWidget);
    expect(find.textContaining('Welcome to'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Tips'), findsOneWidget);
    expect(find.text('6 / 6'), findsOneWidget);

    await tester.tap(find.text("Don't show this again"));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideDialog), findsNothing);
    expect(repo.settings.guideDismissed, isTrue);
  });

  testWidgets('stays closed once dismissed; the Ctrl+K palette reopens it', (
    tester,
  ) async {
    await _pump(tester, _configured.copyWith(guideDismissed: true));
    expect(find.byType(GuideDialog), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'guide');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guide').last);
    await tester.pumpAndSettle();
    expect(find.byType(GuideDialog), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideDialog), findsNothing);
  });

  testWidgets('does not open over demo data', (tester) async {
    await _pump(tester, const AppSettings(), demo: true);
    expect(find.byType(GuideDialog), findsNothing);
  });
}
