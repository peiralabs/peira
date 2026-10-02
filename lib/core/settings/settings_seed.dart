import 'dart:convert';
import 'dart:io';

import '../models/app_settings.dart';

/// One-shot provisioning for desktop: reads a seed file, deletes it, and
/// returns the parsed settings so the controller can persist them into the
/// platform keychain.
///
/// External tooling cannot write flutter_secure_storage's keyring item
/// directly — the Linux plugin registers its libsecret schema name from a
/// dangling pointer (setLabel() replaces the string the schema points into),
/// so the runtime schema name is not reproducible outside the process. A
/// seed file the app imports itself sidesteps that entirely.
class SettingsSeed {
  /// Keys mirror SettingsRepository's storage keys.
  static AppSettings? consume({String? configDir}) {
    if (!Platform.isLinux) return null;
    final dir =
        configDir ??
        Platform.environment['XDG_CONFIG_HOME'] ??
        '${Platform.environment['HOME']}/.config';
    final file = File('$dir/homelab/seed.json');
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      String read(String key) => (json[key] as String?)?.trim() ?? '';
      return AppSettings(
        proxmoxUrl: read('proxmox_url'),
        proxmoxTokenId: read('proxmox_token_id'),
        proxmoxTokenSecret: read('proxmox_token_secret'),
        grafanaUrl: read('grafana_url'),
        grafanaApiKey: read('grafana_api_key'),
        prometheusUrl: read('prometheus_url'),
        hermesUrl: read('hermes_url'),
        wikiUrl: read('wiki_url'),
        ollamaUrl: read('ollama_url'),
        ollamaApiUrl: read('ollama_api_url'),
        hermesApiUrl: read('hermes_api_url'),
        hermesApiKey: read('hermes_api_key'),
        aiChatModel: read('ai_chat_model'),
        askUrl: read('ask_url'),
        jellyseerrUrl: read('jellyseerr_url'),
        jellyfinUrl: read('jellyfin_url'),
        jellyfinApiKey: read('jellyfin_api_key'),
        plexUrl: read('plex_url'),
        plexToken: read('plex_token'),
        radarrUrl: read('radarr_url'),
        radarrApiKey: read('radarr_api_key'),
        sonarrUrl: read('sonarr_url'),
        sonarrApiKey: read('sonarr_api_key'),
        prowlarrUrl: read('prowlarr_url'),
        prowlarrApiKey: read('prowlarr_api_key'),
        qbittorrentUrl: read('qbittorrent_url'),
        qbittorrentUser: read('qbittorrent_user'),
        qbittorrentPass: read('qbittorrent_pass'),
        sshTargets: read('ssh_targets'),
        electricityRateUsdPerKwh:
            double.tryParse(read('electricity_rate_usd_per_kwh')) ?? 0.30,
        trustSelfSigned:
            json['trust_self_signed'] != false &&
            json['trust_self_signed'] != 'false',
      );
    } on Object {
      // Malformed seed: treat as absent. The finally below still removes it
      // so credentials never linger in a plain file.
      return null;
    } finally {
      try {
        file.deleteSync();
      } on Object {
        // Best effort — the file may already be gone.
      }
    }
  }
}
