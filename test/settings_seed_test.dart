import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

    final settings = SettingsSeed.consume(configDir: tmp.path);

    expect(settings, isNotNull);
    expect(settings!.proxmoxUrl, 'https://pve.example:8006');
    expect(settings.proxmoxTokenId, 'user@pve!token');
    expect(settings.grafanaApiKey, 'glsa_key');
    expect(settings.trustSelfSigned, isTrue);
    expect(settings.isConfigured, isTrue);
    expect(seedFile().existsSync(), isFalse, reason: 'seed must be deleted');
  });

  test('consume returns null when no seed file exists', () {
    expect(SettingsSeed.consume(configDir: tmp.path), isNull);
  });

  test('malformed seed is deleted and treated as absent', () {
    seedFile()
      ..createSync(recursive: true)
      ..writeAsStringSync('not json');

    expect(SettingsSeed.consume(configDir: tmp.path), isNull);
    expect(seedFile().existsSync(), isFalse);
  });
}
