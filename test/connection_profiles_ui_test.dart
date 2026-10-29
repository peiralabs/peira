import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/app.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/grafana_providers.dart';
import 'package:peira/core/providers/proxmox_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/providers/tailscale_providers.dart';
import 'package:peira/core/settings/profile_store.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';
import 'package:peira/screens/setup/setup_wizard_screen.dart';

const _office = AppSettings(
  showUnconfiguredTabs: true,
  proxmoxUrl: 'https://192.0.2.10:8006',
  proxmoxTokenId: 'user@pve!token',
  proxmoxTokenSecret: 'office-secret',
);
const _homeUrl = 'https://198.51.100.71:8006';

/// libsecret reads cross a platform channel, so a reload after a switch is
/// still in flight for a few frames; the in-memory mock answers instantly
/// and hides that window.
class _SlowRepository extends SettingsRepository {
  _SlowRepository() : super(const FlutterSecureStorage());

  @override
  Future<AppSettings> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return super.load();
  }
}

/// The real repository and profile store over the plugin's in-memory
/// keyring, so the UI exercises the same storage the app does.
Future<void> _pumpApp(WidgetTester tester, {bool slowLoad = false}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        nodesProvider.overrideWith((ref) async => const []),
        allContainersProvider.overrideWith((ref) async => const []),
        allVmsProvider.overrideWith((ref) async => const []),
        activeAlertsProvider.overrideWith((ref) async => const []),
        recentTasksProvider.overrideWith((ref) async => const []),
        tailscaleStatusProvider.overrideWith(
          (ref) async => throw Exception('no tailscale'),
        ),
        serviceReachableProvider.overrideWith((ref, url) async => false),
        if (slowLoad)
          settingsRepositoryProvider.overrideWithValue(_SlowRepository()),
      ],
      child: const HomeLabApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings').first);
  await tester.pumpAndSettle();
}

Future<void> _nameDialog(
  WidgetTester tester,
  String name,
  String action,
) async {
  await tester.enterText(
    find.byKey(const ValueKey('profile-name-field')),
    name,
  );
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

void main() {
  const storage = FlutterSecureStorage();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SettingsRepository(storage).save(_office);
  });

  testWidgets('one profile keeps the hostname footer; duplicating switches to '
      'the copy and the footer names it', (tester) async {
    await _pumpApp(tester);
    expect(
      find.textContaining('Default · connected'),
      findsNothing,
      reason: 'a single profile looks exactly like before',
    );

    await _openSettings(tester);
    expect(find.text('Connection profiles'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile-duplicate')));
    await tester.pumpAndSettle();
    await _nameDialog(tester, 'Home', 'Create');

    expect(find.text('Home · connected'), findsOneWidget);
    final state = await ProfileStore(storage).load();
    expect(state.active.name, 'Home');
    expect(state.profiles.length, 2);

    // Switch back from the rail footer's menu.
    await tester.tap(find.byKey(const ValueKey('rail-reconnect')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-menu-default')));
    await tester.pumpAndSettle();
    expect(find.text('Default · connected'), findsOneWidget);
  });

  testWidgets('switching re-seeds the Settings form with the new profile', (
    tester,
  ) async {
    await ProfileStore(
      storage,
    ).create('Home', copyOf: _office.copyWith(proxmoxUrl: _homeUrl));
    await _pumpApp(tester);
    await _openSettings(tester);
    expect(find.text(_office.proxmoxUrl), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-switch-p2')));
    await tester.pumpAndSettle();
    expect(find.text(_homeUrl), findsOneWidget);
    expect(
      find.text(_office.proxmoxUrl),
      findsNothing,
      reason: 'stale fields would be saved into the wrong profile',
    );
    expect((await SettingsRepository(storage).load()).proxmoxUrl, _homeUrl);
  });

  testWidgets('a slow reload after a switch neither seeds the form with the '
      'old profile nor lets Save overwrite the new one', (tester) async {
    await ProfileStore(
      storage,
    ).create('Home', copyOf: _office.copyWith(proxmoxUrl: _homeUrl));
    await _pumpApp(tester, slowLoad: true);
    await _openSettings(tester);
    expect(find.text(_office.proxmoxUrl), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-switch-p2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text(_homeUrl), findsOneWidget);
    expect(find.text(_office.proxmoxUrl), findsNothing);

    // Save, then switch back: Office must still be Office.
    // A tall view builds the whole Settings list, Save included.
    tester.view.physicalSize = const Size(1400, 9000);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-switch-default')));
    await tester.pumpAndSettle();
    expect(
      (await SettingsRepository(storage).load()).proxmoxUrl,
      _office.proxmoxUrl,
    );
    expect(find.text(_office.proxmoxUrl), findsOneWidget);
  });

  testWidgets('New from setup opens the wizard; Cancel returns and drops the '
      'blank profile', (tester) async {
    await _pumpApp(tester);
    await _openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('profile-new-setup')));
    await tester.pumpAndSettle();
    await _nameDialog(tester, 'Lab 3', 'Continue to setup');

    expect(find.byType(SetupWizardScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setup-cancel-profile')));
    await tester.pumpAndSettle();

    expect(find.byType(SetupWizardScreen), findsNothing);
    final state = await ProfileStore(storage).load();
    expect(state.profiles.map((p) => p.name), ['Default']);
    expect(
      (await storage.readAll()).keys.where((k) => k.startsWith('profile.p2.')),
      isEmpty,
    );
    expect(
      (await SettingsRepository(storage).load()).proxmoxUrl,
      _office.proxmoxUrl,
    );
  });
}
