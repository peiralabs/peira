import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_settings.dart';

/// Thrown when the platform secret store can't be read/written because the
/// keyring is locked (or its default collection can't be unlocked).
///
/// On Linux this surfaces as a [PlatformException] with code `KeyringLocked`
/// from the (patched) flutter_secure_storage_linux plugin, which first tries
/// `secret_service_unlock_sync` — so in a real desktop session the user gets
/// the GNOME unlock prompt before this is thrown. We translate it to a typed
/// exception so the UI can show an unlock-and-retry gate instead of silently
/// falling through to a blank first-launch Settings screen (data is safe on
/// disk; the keyring is just inaccessible right now).
class KeyringLockedException implements Exception {
  const KeyringLockedException([this.detail]);

  final String? detail;

  @override
  String toString() =>
      'KeyringLockedException: ${detail ?? 'the secret store is locked'}';
}

/// Persists [AppSettings] in the platform keychain / secret service.
class SettingsRepository {
  SettingsRepository(this._storage);

  final FlutterSecureStorage _storage;

  /// Native code (linux) reports a locked keyring with this PlatformException
  /// code; see [KeyringLockedException].
  static const _keyringLockedCode = 'KeyringLocked';

  Never _translate(PlatformException e) {
    if (e.code == _keyringLockedCode) {
      throw KeyringLockedException(e.message);
    }
    throw e;
  }

  static const _keys = (
    proxmoxUrl: 'proxmox_url',
    proxmoxTokenId: 'proxmox_token_id',
    proxmoxTokenSecret: 'proxmox_token_secret',
    dockerUrl: 'docker_url',
    dockerTlsVerify: 'docker_tls_verify',
    grafanaUrl: 'grafana_url',
    grafanaApiKey: 'grafana_api_key',
    prometheusUrl: 'prometheus_url',
    hermesUrl: 'hermes_url',
    wikiUrl: 'wiki_url',
    ollamaUrl: 'ollama_url',
    ollamaApiUrl: 'ollama_api_url',
    hermesApiUrl: 'hermes_api_url',
    hermesApiKey: 'hermes_api_key',
    aiChatModel: 'ai_chat_model',
    askUrl: 'ask_url',
    homeAssistantUrl: 'home_assistant_url',
    searxngUrl: 'searxng_url',
    karakeepUrl: 'karakeep_url',
    paperlessUrl: 'paperless_url',
    immichUrl: 'immich_url',
    changedetectionUrl: 'changedetection_url',
    lokiUrl: 'loki_url',
    pdmUrl: 'pdm_url',
    pdmTokenId: 'pdm_token_id',
    pdmTokenSecret: 'pdm_token_secret',
    pdmFingerprint: 'pdm_fingerprint',
    jellyseerrUrl: 'jellyseerr_url',
    jellyfinUrl: 'jellyfin_url',
    jellyfinApiKey: 'jellyfin_api_key',
    plexUrl: 'plex_url',
    plexToken: 'plex_token',
    radarrUrl: 'radarr_url',
    radarrApiKey: 'radarr_api_key',
    sonarrUrl: 'sonarr_url',
    sonarrApiKey: 'sonarr_api_key',
    prowlarrUrl: 'prowlarr_url',
    prowlarrApiKey: 'prowlarr_api_key',
    qbittorrentUrl: 'qbittorrent_url',
    qbittorrentUser: 'qbittorrent_user',
    qbittorrentPass: 'qbittorrent_pass',
    trustSelfSigned: 'trust_self_signed',
    themeMode: 'theme_mode',
    themeId: 'theme_id',
    railCollapsed: 'rail_collapsed',
    sshTargets: 'ssh_targets',
    sshUsername: 'ssh_username',
    electricityRateUsdPerKwh: 'electricity_rate_usd_per_kwh',
    webLoginsJson: 'web_logins_json',
    webAutoLogin: 'web_auto_login',
    notifyAlerts: 'notify_alerts',
  );

  Future<AppSettings> load() async {
    final Map<String, String> values;
    try {
      values = await _storage.readAll();
    } on PlatformException catch (e) {
      _translate(e);
    }
    return AppSettings(
      proxmoxUrl: values[_keys.proxmoxUrl] ?? '',
      proxmoxTokenId: values[_keys.proxmoxTokenId] ?? '',
      proxmoxTokenSecret: values[_keys.proxmoxTokenSecret] ?? '',
      dockerUrl: values[_keys.dockerUrl] ?? '',
      dockerTlsVerify: values[_keys.dockerTlsVerify] != 'false',
      grafanaUrl: values[_keys.grafanaUrl] ?? '',
      grafanaApiKey: values[_keys.grafanaApiKey] ?? '',
      prometheusUrl: values[_keys.prometheusUrl] ?? '',
      hermesUrl: values[_keys.hermesUrl] ?? '',
      wikiUrl: values[_keys.wikiUrl] ?? '',
      ollamaUrl: values[_keys.ollamaUrl] ?? '',
      ollamaApiUrl: values[_keys.ollamaApiUrl] ?? '',
      hermesApiUrl: values[_keys.hermesApiUrl] ?? '',
      hermesApiKey: values[_keys.hermesApiKey] ?? '',
      aiChatModel: values[_keys.aiChatModel] ?? '',
      askUrl: values[_keys.askUrl] ?? '',
      homeAssistantUrl: values[_keys.homeAssistantUrl] ?? '',
      searxngUrl: values[_keys.searxngUrl] ?? '',
      karakeepUrl: values[_keys.karakeepUrl] ?? '',
      paperlessUrl: values[_keys.paperlessUrl] ?? '',
      immichUrl: values[_keys.immichUrl] ?? '',
      changedetectionUrl: values[_keys.changedetectionUrl] ?? '',
      lokiUrl: values[_keys.lokiUrl] ?? '',
      pdmUrl: values[_keys.pdmUrl] ?? '',
      pdmTokenId: values[_keys.pdmTokenId] ?? '',
      pdmTokenSecret: values[_keys.pdmTokenSecret] ?? '',
      pdmFingerprint: values[_keys.pdmFingerprint] ?? '',
      jellyseerrUrl: values[_keys.jellyseerrUrl] ?? '',
      jellyfinUrl: values[_keys.jellyfinUrl] ?? '',
      jellyfinApiKey: values[_keys.jellyfinApiKey] ?? '',
      plexUrl: values[_keys.plexUrl] ?? '',
      plexToken: values[_keys.plexToken] ?? '',
      radarrUrl: values[_keys.radarrUrl] ?? '',
      radarrApiKey: values[_keys.radarrApiKey] ?? '',
      sonarrUrl: values[_keys.sonarrUrl] ?? '',
      sonarrApiKey: values[_keys.sonarrApiKey] ?? '',
      prowlarrUrl: values[_keys.prowlarrUrl] ?? '',
      prowlarrApiKey: values[_keys.prowlarrApiKey] ?? '',
      qbittorrentUrl: values[_keys.qbittorrentUrl] ?? '',
      qbittorrentUser: values[_keys.qbittorrentUser] ?? '',
      qbittorrentPass: values[_keys.qbittorrentPass] ?? '',
      trustSelfSigned: values[_keys.trustSelfSigned] != 'false',
      themeMode: values[_keys.themeMode] ?? 'system',
      themeId: values[_keys.themeId] ?? 'brass',
      railCollapsed: values[_keys.railCollapsed] == 'true',
      sshTargets: values[_keys.sshTargets] ?? '',
      sshUsername: values[_keys.sshUsername] ?? 'root',
      electricityRateUsdPerKwh:
          double.tryParse(values[_keys.electricityRateUsdPerKwh] ?? '') ?? 0.30,
      webLoginsJson: values[_keys.webLoginsJson] ?? '',
      webAutoLogin: values[_keys.webAutoLogin] != 'false',
      notifyAlerts: values[_keys.notifyAlerts] != 'false',
    );
  }

  Future<void> save(AppSettings settings) async {
    try {
      await _write(settings);
    } on PlatformException catch (e) {
      _translate(e);
    }
  }

  Future<void> _write(AppSettings settings) async {
    await Future.wait([
      _storage.write(key: _keys.proxmoxUrl, value: settings.proxmoxUrl),
      _storage.write(key: _keys.proxmoxTokenId, value: settings.proxmoxTokenId),
      _storage.write(
        key: _keys.proxmoxTokenSecret,
        value: settings.proxmoxTokenSecret,
      ),
      _storage.write(key: _keys.dockerUrl, value: settings.dockerUrl),
      _storage.write(
        key: _keys.dockerTlsVerify,
        value: settings.dockerTlsVerify.toString(),
      ),
      _storage.write(key: _keys.grafanaUrl, value: settings.grafanaUrl),
      _storage.write(key: _keys.grafanaApiKey, value: settings.grafanaApiKey),
      _storage.write(key: _keys.prometheusUrl, value: settings.prometheusUrl),
      _storage.write(key: _keys.hermesUrl, value: settings.hermesUrl),
      _storage.write(key: _keys.wikiUrl, value: settings.wikiUrl),
      _storage.write(key: _keys.ollamaUrl, value: settings.ollamaUrl),
      _storage.write(key: _keys.ollamaApiUrl, value: settings.ollamaApiUrl),
      _storage.write(key: _keys.hermesApiUrl, value: settings.hermesApiUrl),
      _storage.write(key: _keys.hermesApiKey, value: settings.hermesApiKey),
      _storage.write(key: _keys.aiChatModel, value: settings.aiChatModel),
      _storage.write(key: _keys.askUrl, value: settings.askUrl),
      _storage.write(
        key: _keys.homeAssistantUrl,
        value: settings.homeAssistantUrl,
      ),
      _storage.write(key: _keys.searxngUrl, value: settings.searxngUrl),
      _storage.write(key: _keys.karakeepUrl, value: settings.karakeepUrl),
      _storage.write(key: _keys.paperlessUrl, value: settings.paperlessUrl),
      _storage.write(key: _keys.immichUrl, value: settings.immichUrl),
      _storage.write(
        key: _keys.changedetectionUrl,
        value: settings.changedetectionUrl,
      ),
      _storage.write(key: _keys.lokiUrl, value: settings.lokiUrl),
      _storage.write(key: _keys.pdmUrl, value: settings.pdmUrl),
      _storage.write(key: _keys.pdmTokenId, value: settings.pdmTokenId),
      _storage.write(
        key: _keys.pdmTokenSecret,
        value: settings.pdmTokenSecret,
      ),
      _storage.write(
        key: _keys.pdmFingerprint,
        value: settings.pdmFingerprint,
      ),
      _storage.write(key: _keys.jellyseerrUrl, value: settings.jellyseerrUrl),
      _storage.write(key: _keys.jellyfinUrl, value: settings.jellyfinUrl),
      _storage.write(
        key: _keys.jellyfinApiKey,
        value: settings.jellyfinApiKey,
      ),
      _storage.write(key: _keys.plexUrl, value: settings.plexUrl),
      _storage.write(key: _keys.plexToken, value: settings.plexToken),
      _storage.write(key: _keys.radarrUrl, value: settings.radarrUrl),
      _storage.write(key: _keys.radarrApiKey, value: settings.radarrApiKey),
      _storage.write(key: _keys.sonarrUrl, value: settings.sonarrUrl),
      _storage.write(key: _keys.sonarrApiKey, value: settings.sonarrApiKey),
      _storage.write(key: _keys.prowlarrUrl, value: settings.prowlarrUrl),
      _storage.write(
        key: _keys.prowlarrApiKey,
        value: settings.prowlarrApiKey,
      ),
      _storage.write(
        key: _keys.qbittorrentUrl,
        value: settings.qbittorrentUrl,
      ),
      _storage.write(
        key: _keys.qbittorrentUser,
        value: settings.qbittorrentUser,
      ),
      _storage.write(
        key: _keys.qbittorrentPass,
        value: settings.qbittorrentPass,
      ),
      _storage.write(key: _keys.themeMode, value: settings.themeMode),
      _storage.write(key: _keys.themeId, value: settings.themeId),
      _storage.write(
        key: _keys.railCollapsed,
        value: settings.railCollapsed ? 'true' : 'false',
      ),
      _storage.write(key: _keys.sshTargets, value: settings.sshTargets),
      _storage.write(key: _keys.sshUsername, value: settings.sshUsername),
      _storage.write(
        key: _keys.electricityRateUsdPerKwh,
        value: settings.electricityRateUsdPerKwh.toString(),
      ),
      _storage.write(
        key: _keys.trustSelfSigned,
        value: settings.trustSelfSigned.toString(),
      ),
      _storage.write(key: _keys.webLoginsJson, value: settings.webLoginsJson),
      _storage.write(
        key: _keys.webAutoLogin,
        value: settings.webAutoLogin.toString(),
      ),
      _storage.write(
        key: _keys.notifyAlerts,
        value: settings.notifyAlerts.toString(),
      ),
    ]);
  }
}
