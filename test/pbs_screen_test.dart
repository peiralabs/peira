import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/pbs_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/navigation/app_tab.dart';
import 'package:peira/core/providers/navigation_providers.dart';
import 'package:peira/core/providers/pbs_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/pbs/pbs_screen.dart';

class _SettingsRepository implements SettingsRepository {
  _SettingsRepository(this.settings);
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
  pbs1Name: 'Office PBS',
  pbs1Url: 'https://pbs1.example:8007',
  pbs1TokenId: 'reader@pbs!app',
  pbs1TokenSecret: 'secret-1',
  pbs1User: 'operator@pbs',
  pbs2Name: 'NAS PBS',
  pbs2Url: 'https://pbs2.example:8007',
  pbs2TokenId: 'reader@pbs!app',
  pbs2TokenSecret: 'secret-2',
  pbs2User: 'operator@pbs',
);

const _overview = PbsOverviewData(
  version: {'version': '4.2.8'},
  datastores: [
    PbsDatastoreUsage(
      store: 'backup',
      total: 1099511627776,
      used: 549755813888,
      avail: 549755813888,
      history: [],
      gcStatus: {'status': 'OK', 'backup-count': 12},
      estimatedFullDate: null,
    ),
  ],
  jobs: [],
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  AppSettings settings, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1500, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(
        _SettingsRepository(settings),
      ),
      pbsOverviewProvider.overrideWith((ref, slot) async => _overview),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: PbsScreen(railIndex: AppTab.pbs.railIndex)),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(seconds: 1));
  }
  return container;
}

void main() {
  testWidgets('not-configured state links to Settings', (tester) async {
    final container = await _pump(tester, const AppSettings());
    expect(
      find.text(
        'PBS is not configured — add a server and API token in Settings',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Open Settings'));
    expect(container.read(selectedTabProvider), AppTab.settings.railIndex);
    await tester.pump(const Duration(minutes: 1)); // drain retry backoff
  });

  testWidgets('not-configured state shows while the provider is retrying', (
    tester,
  ) async {
    await _pump(tester, const AppSettings(), settle: false);
    expect(
      find.text(
        'PBS is not configured — add a server and API token in Settings',
      ),
      findsOneWidget,
    );
    // Run out Riverpod's retry backoff so no timer outlives the test (the
    // static view schedules no frames, so pumpAndSettle would not wait).
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('configured screen renders four tabs and a datastore card', (
    tester,
  ) async {
    await _pump(tester, _configured);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Backups'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.byKey(const ValueKey('pbs-datastore-backup')), findsOneWidget);
    expect(find.text('Office PBS'), findsOneWidget);
  });

  testWidgets('server switch selects the second configured slot', (
    tester,
  ) async {
    final container = await _pump(tester, _configured);
    await tester.tap(find.text('NAS PBS'));
    await tester.pumpAndSettle();
    expect(await container.read(selectedPbsSlotProvider.future), PbsSlot.two);
  });
}
