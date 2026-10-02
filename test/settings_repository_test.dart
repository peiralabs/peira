// Round-trips AppSettings through the REAL SettingsRepository serialization.
//
// The repository maintains a hand-written key map + load + save; a field
// added to AppSettings but not to all three silently never persists (found
// live on card t_5b6be464's distro leg: sshUsername saved from the Settings
// screen came back 'root' after relaunch). Every field here is set to a
// distinct non-default value so a dropped mapping fails the equality check.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/settings/settings_repository.dart';

class _MemoryStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => Map.of(_data);

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
}

void main() {
  test('every AppSettings field survives a save/load round-trip', () async {
    const original = AppSettings(
      proxmoxUrl: 'https://192.168.1.10:8006',
      proxmoxTokenId: 'user@pve!token',
      proxmoxTokenSecret: 'secret-1',
      dockerUrl: 'https://docker.example:2376',
      dockerTlsVerify: false,
      grafanaUrl: 'http://g.example:3000',
      grafanaApiKey: 'gkey',
      prometheusUrl: 'http://p.example:9090',
      hermesUrl: 'http://h.example',
      wikiUrl: 'http://w.example:3000',
      ollamaUrl: 'http://o.example:8080',
      ollamaApiUrl: 'http://o.example:11434',
      hermesApiUrl: 'http://h.example:8642',
      hermesApiKey: 'hkey',
      aiChatModel: 'llama3.2',
      askUrl: 'http://w.example:9113',
      homeAssistantUrl: 'http://ha.example:8123',
      searxngUrl: 'http://sx.example:8888',
      karakeepUrl: 'http://kk.example:3000',
      paperlessUrl: 'http://pl.example:8020',
      immichUrl: 'http://im.example:2283',
      changedetectionUrl: 'http://cd.example:5000',
      lokiUrl: 'http://lk.example:3100',
      pdmUrl: 'https://pdm.example:8443',
      pdmTokenId: 'user@pam!pdmtoken',
      pdmTokenSecret: 'pdmsecret-1',
      pdmFingerprint: 'AA:BB:CC:DD',
      jellyseerrUrl: 'http://j.example:5055',
      jellyfinUrl: 'http://j.example:8096',
      jellyfinApiKey: 'jfkey',
      plexUrl: 'http://plex.example:32400',
      plexToken: 'ptok',
      radarrUrl: 'http://r.example:7878',
      radarrApiKey: 'rkey',
      sonarrUrl: 'http://s.example:8989',
      sonarrApiKey: 'skey',
      prowlarrUrl: 'http://pr.example:9696',
      prowlarrApiKey: 'prkey',
      qbittorrentUrl: 'http://q.example:8082',
      qbittorrentUser: 'quser',
      qbittorrentPass: 'qpass',
      trustSelfSigned: false,
      themeMode: 'light',
      railCollapsed: true,
      sshTargets: 'node1=root@192.168.1.10',
      sshUsername: 'admin',
      electricityRateUsdPerKwh: 0.42,
    );

    final repo = SettingsRepository(_MemoryStorage());
    await repo.save(original);
    final loaded = await repo.load();

    expect(loaded, original);
  });

  test('absent ssh username loads as root (pre-existing installs)', () async {
    final repo = SettingsRepository(_MemoryStorage());
    await repo.save(const AppSettings(sshUsername: ''));
    // A cleared field round-trips as written…
    expect((await repo.load()).sshUsername, '');
    // …and the effective user falls back.
    expect((await repo.load()).sshUser, 'root');
  });
}
