import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/settings/settings_seed.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('seed_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  File seedFile() => File('${tmp.path}/homelab/seed.json');

  void writeSeed(Object json) {
    seedFile()
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(json));
  }

  test('consume parses the seed and deletes the file', () {
    writeSeed({
      'proxmox_url': 'https://pve.example:8006',
      'proxmox_token_id': 'user@pve!token',
      'proxmox_token_secret': 'secret',
      'grafana_url': 'http://grafana.example:3000',
      'grafana_api_key': 'glsa_key',
      'hermes_url': 'http://hermes.example',
      'wiki_url': 'http://wiki.example:3000',
      'ollama_url': 'http://ollama.example:8080',
      'trust_self_signed': 'true',
    });

    final result = SettingsSeed.consume(
      const AppSettings(),
      configDir: tmp.path,
    );

    expect(result, isNotNull);
    final settings = result!.settings;
    expect(result.unknownKeys, isEmpty);
    expect(settings.proxmoxUrl, 'https://pve.example:8006');
    expect(settings.proxmoxTokenId, 'user@pve!token');
    expect(settings.grafanaApiKey, 'glsa_key');
    expect(settings.trustSelfSigned, isTrue);
    expect(settings.isConfigured, isTrue);
    expect(seedFile().existsSync(), isFalse, reason: 'seed must be deleted');
  });

  test('consume returns null when no seed file exists', () {
    expect(
      SettingsSeed.consume(const AppSettings(), configDir: tmp.path),
      isNull,
    );
  });

  test('malformed seed is deleted and treated as absent', () {
    seedFile()
      ..createSync(recursive: true)
      ..writeAsStringSync('not json');

    expect(
      SettingsSeed.consume(const AppSettings(), configDir: tmp.path),
      isNull,
    );
    expect(seedFile().existsSync(), isFalse);
  });

  test('apply overwrites set keys, keeps the rest, ignores blanks', () {
    const current = AppSettings(
      proxmoxUrl: 'https://old:8006',
      paperlessUrl: 'http://paperless:8000',
      paperlessToken: 'keep-me',
    );
    final r = SettingsSeed.apply(
      current,
      jsonEncode({
        '_comment': 'ignored',
        'proxmox_url': 'https://new:8006',
        'paperless_token': '',
        'immich_api_key': 'k',
        'show_unconfigured_tabs': true,
        'electricity_rate_usd_per_kwh': 0.12,
        'not_a_setting': 'x',
      }),
    );
    expect(r.settings.proxmoxUrl, 'https://new:8006');
    expect(r.settings.paperlessUrl, 'http://paperless:8000');
    expect(r.settings.paperlessToken, 'keep-me');
    expect(r.settings.immichApiKey, 'k');
    expect(r.settings.showUnconfiguredTabs, isTrue);
    expect(r.settings.electricityRateUsdPerKwh, 0.12);
    expect(r.unknownKeys, ['not_a_setting']);
  });

  test('apply rejects anything but a JSON object', () {
    expect(
      () => SettingsSeed.apply(const AppSettings(), '[1]'),
      throwsFormatException,
    );
  });

  test('the shipped template lists exactly the stored keys', () {
    final template =
        jsonDecode(File('setup/setup.example.json').readAsStringSync())
            as Map<String, dynamic>;
    final keys = template.keys.where((k) => !k.startsWith('_')).toSet();
    expect(
      keys,
      SettingsRepository.toMap(const AppSettings()).keys.toSet(),
    );
  });
}
