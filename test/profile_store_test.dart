import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/settings/profile_store.dart';
import 'package:peira/core/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  late ProfileStore store;
  late SettingsRepository repo;

  const office = AppSettings(
    proxmoxUrl: 'https://192.0.2.10:8006',
    proxmoxTokenId: 'user@pve!token',
    proxmoxTokenSecret: 'office-secret',
    plexUrl: 'http://192.0.2.50:32400',
    plexToken: 'plex-token',
    electricityRateUsdPerKwh: 0.17,
    themeId: 'nord',
    themeMode: 'dark',
    railCollapsed: true,
    pdmUrl: 'https://pdm.example:8443',
    pdmTokenId: 'user@pam!pdmtoken',
    pdmTokenSecret: 'pdm-secret',
    pdmFingerprint: 'AA:BB:CC:DD',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    repo = SettingsRepository(storage);
    store = ProfileStore(storage);
    await repo.save(office);
  });

  test('an install without an index reads as one Default profile and '
      'nothing is written until the first mutation', () async {
    final before = await storage.readAll();
    final state = await store.load();
    expect(state.profiles.map((p) => p.name), ['Default']);
    expect(state.active.id, ProfileStore.defaultId);
    expect(await storage.readAll(), before);
  });

  test('duplicate copies per-profile keys; switching swaps connections and '
      'leaves globals alone', () async {
    var state = await store.create('Home', copyOf: await repo.load());
    final home = state.profiles.last;
    expect(
      state.active.id,
      ProfileStore.defaultId,
      reason: 'create never switches',
    );

    state = await store.switchTo(home.id);
    expect(state.active.name, 'Home');
    var live = await repo.load();
    expect(live.proxmoxUrl, office.proxmoxUrl, reason: 'duplicate of office');

    // Edit the home profile's Proxmox (and a global) while it is active.
    await repo.save(
      live.copyWith(
        proxmoxUrl: 'https://198.51.100.71:8006',
        proxmoxTokenId: 'root@pam!token',
        themeId: 'ember',
      ),
    );

    state = await store.switchTo(ProfileStore.defaultId);
    live = await repo.load();
    expect(live.proxmoxUrl, office.proxmoxUrl);
    expect(live.proxmoxTokenId, 'user@pve!token');
    expect(live.plexToken, 'plex-token');
    expect(
      live.themeId,
      'ember',
      reason: 'theme is global, it follows the operator',
    );
    expect(live.railCollapsed, isTrue);
    expect(live.pdmUrl, office.pdmUrl);
    expect(live.pdmTokenId, office.pdmTokenId);
    expect(live.pdmTokenSecret, office.pdmTokenSecret);
    expect(live.pdmFingerprint, office.pdmFingerprint);
    final keys = (await storage.readAll()).keys;
    expect(keys.where((key) => key.contains('.pdm_')), isEmpty);

    state = await store.switchTo(home.id);
    live = await repo.load();
    expect(live.proxmoxUrl, 'https://198.51.100.71:8006');
    expect(live.proxmoxTokenId, 'root@pam!token');
    expect(live.plexUrl, office.plexUrl, reason: 'shared NAS services survive');
    expect(live.pdmUrl, office.pdmUrl);
    expect(live.pdmTokenId, office.pdmTokenId);
    expect(live.pdmTokenSecret, office.pdmTokenSecret);
    expect(live.pdmFingerprint, office.pdmFingerprint);
  });

  test(
    'a blank profile is unconfigured, so switching to it opens setup',
    () async {
      final state = await store.create('Lab 3');
      await store.switchTo(state.profiles.last.id);
      final live = await repo.load();
      expect(live.isConfigured, isFalse);
      expect(live.plexUrl, isEmpty);
      expect(
        live.themeId,
        'nord',
        reason: 'globals carried into the new profile',
      );
      expect(
        live.electricityRateUsdPerKwh,
        const AppSettings().electricityRateUsdPerKwh,
      );

      await store.switchTo(ProfileStore.defaultId);
      expect((await repo.load()).isConfigured, isTrue);
    },
  );

  test('rename and delete; the active profile cannot be deleted', () async {
    var state = await store.create('Home');
    final home = state.profiles.last;
    state = await store.rename(ProfileStore.defaultId, 'Office');
    expect(state.profiles.map((p) => p.name), ['Office', 'Home']);

    expect(() => store.delete(ProfileStore.defaultId), throwsStateError);

    state = await store.delete(home.id);
    expect(state.profiles.map((p) => p.name), ['Office']);
    final keys = (await storage.readAll()).keys;
    expect(keys.where((k) => k.startsWith('profile.${home.id}.')), isEmpty);
    expect((await repo.load()).proxmoxUrl, office.proxmoxUrl);
  });

  test(
    'a malformed index falls back to Default instead of hiding settings',
    () async {
      await storage.write(key: 'profiles', value: '{not json');
      final state = await store.load();
      expect(state.profiles.single.id, ProfileStore.defaultId);
      expect((await repo.load()).proxmoxUrl, office.proxmoxUrl);
    },
  );
}
