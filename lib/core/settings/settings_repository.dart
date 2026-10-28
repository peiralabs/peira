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

  /// Settings that describe the operator, not a cluster: they stay put when
  /// the active connection profile changes (see `ProfileStore`). Every other
  /// key is per-profile.
  static final Set<String> globalKeys = {
    _keys.themeMode,
    _keys.themeId,
    _keys.railCollapsed,
    _keys.notifyAlerts,
    _keys.showUnconfiguredTabs,
    _keys.pdmUrl,
    _keys.pdmTokenId,
    _keys.pdmTokenSecret,
    _keys.pdmFingerprint,
    _keys.pbs1Name,
    _keys.pbs1Url,
    _keys.pbs1TokenId,
    _keys.pbs1TokenSecret,
    _keys.pbs1Fingerprint,
    _keys.pbs1User,
    _keys.pbs1PveStorage,
    _keys.pbs2Name,
    _keys.pbs2Url,
    _keys.pbs2TokenId,
    _keys.pbs2TokenSecret,
    _keys.pbs2Fingerprint,
    _keys.pbs2User,
    _keys.pbs2PveStorage,
  };

  /// Translates a platform error the same way [load]/[save] do, for other
  /// readers of the same secret store.
  static Never translate(PlatformException e) => _translate(e);

  static Never _translate(PlatformException e) {
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
    homeAssistantToken: 'home_assistant_token',
    paperlessToken: 'paperless_token',
    immichApiKey: 'immich_api_key',
    karakeepApiKey: 'karakeep_api_key',
    jellyseerrApiKey: 'jellyseerr_api_key',
    openWebuiApiKey: 'open_webui_api_key',
    changedetectionApiKey: 'changedetection_api_key',
    wikiApiKey: 'wiki_api_key',
    lokiUrl: 'loki_url',
    pdmUrl: 'pdm_url',
    pdmTokenId: 'pdm_token_id',
    pdmTokenSecret: 'pdm_token_secret',
    pdmFingerprint: 'pdm_fingerprint',
    pbs1Name: 'pbs1_name',
    pbs1Url: 'pbs1_url',
    pbs1TokenId: 'pbs1_token_id',
    pbs1TokenSecret: 'pbs1_token_secret',
    pbs1Fingerprint: 'pbs1_fingerprint',
    pbs1User: 'pbs1_user',
    pbs1PveStorage: 'pbs1_pve_storage',
    pbs2Name: 'pbs2_name',
    pbs2Url: 'pbs2_url',
    pbs2TokenId: 'pbs2_token_id',
    pbs2TokenSecret: 'pbs2_token_secret',
    pbs2Fingerprint: 'pbs2_fingerprint',
    pbs2User: 'pbs2_user',
    pbs2PveStorage: 'pbs2_pve_storage',
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
    notifyAlerts: 'notify_alerts',
    showUnconfiguredTabs: 'show_unconfigured_tabs',
  );

  /// Keys of features that were removed. Web-view logins (2026-10-28, when
  /// every tab went native) held service passwords, so they are deleted from
  /// the keychain — live keys and every profile's stash — rather than left
  /// unreferenced.
  static const retiredKeys = {'web_logins_json', 'web_auto_login'};

  static bool _isRetired(String key) => retiredKeys.any(
    (r) => key == r || (key.startsWith('profile.') && key.endsWith('.$r')),
  );

  Future<AppSettings> load() async {
    final Map<String, String> values;
    try {
      values = await _storage.readAll();
      final retired = [for (final k in values.keys) if (_isRetired(k)) k];
      if (retired.isNotEmpty) {
        await Future.wait([for (final k in retired) _storage.delete(key: k)]);
      }
    } on PlatformException catch (e) {
      _translate(e);
    }
    return fromMap(values);
  }

  /// Inverse of [toMap]: missing keys fall back to the [AppSettings] defaults.
  static AppSettings fromMap(Map<String, String> values) {
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
      homeAssistantToken: values[_keys.homeAssistantToken] ?? '',
      paperlessToken: values[_keys.paperlessToken] ?? '',
      immichApiKey: values[_keys.immichApiKey] ?? '',
      karakeepApiKey: values[_keys.karakeepApiKey] ?? '',
      jellyseerrApiKey: values[_keys.jellyseerrApiKey] ?? '',
      openWebuiApiKey: values[_keys.openWebuiApiKey] ?? '',
      changedetectionApiKey: values[_keys.changedetectionApiKey] ?? '',
      wikiApiKey: values[_keys.wikiApiKey] ?? '',
      lokiUrl: values[_keys.lokiUrl] ?? '',
      pdmUrl: values[_keys.pdmUrl] ?? '',
      pdmTokenId: values[_keys.pdmTokenId] ?? '',
      pdmTokenSecret: values[_keys.pdmTokenSecret] ?? '',
      pdmFingerprint: values[_keys.pdmFingerprint] ?? '',
      pbs1Name: values[_keys.pbs1Name] ?? '',
      pbs1Url: values[_keys.pbs1Url] ?? '',
      pbs1TokenId: values[_keys.pbs1TokenId] ?? '',
      pbs1TokenSecret: values[_keys.pbs1TokenSecret] ?? '',
      pbs1Fingerprint: values[_keys.pbs1Fingerprint] ?? '',
      pbs1User: values[_keys.pbs1User] ?? '',
      pbs1PveStorage: values[_keys.pbs1PveStorage] ?? '',
      pbs2Name: values[_keys.pbs2Name] ?? '',
      pbs2Url: values[_keys.pbs2Url] ?? '',
      pbs2TokenId: values[_keys.pbs2TokenId] ?? '',
      pbs2TokenSecret: values[_keys.pbs2TokenSecret] ?? '',
      pbs2Fingerprint: values[_keys.pbs2Fingerprint] ?? '',
      pbs2User: values[_keys.pbs2User] ?? '',
      pbs2PveStorage: values[_keys.pbs2PveStorage] ?? '',
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
      notifyAlerts: values[_keys.notifyAlerts] != 'false',
      showUnconfiguredTabs: values[_keys.showUnconfiguredTabs] == 'true',
    );
  }

  Future<void> save(AppSettings settings) async {
    try {
      await _write(settings);
    } on PlatformException catch (e) {
      _translate(e);
    }
  }

  /// Every stored key → its serialised value. The single source of truth for
  /// the on-disk shape; [load] reads the same keys back.
  static Map<String, String> toMap(AppSettings settings) => {
    _keys.proxmoxUrl: settings.proxmoxUrl,
    _keys.proxmoxTokenId: settings.proxmoxTokenId,
    _keys.proxmoxTokenSecret: settings.proxmoxTokenSecret,
    _keys.dockerUrl: settings.dockerUrl,
    _keys.dockerTlsVerify: settings.dockerTlsVerify.toString(),
    _keys.grafanaUrl: settings.grafanaUrl,
    _keys.grafanaApiKey: settings.grafanaApiKey,
    _keys.prometheusUrl: settings.prometheusUrl,
    _keys.hermesUrl: settings.hermesUrl,
    _keys.wikiUrl: settings.wikiUrl,
    _keys.ollamaUrl: settings.ollamaUrl,
    _keys.ollamaApiUrl: settings.ollamaApiUrl,
    _keys.hermesApiUrl: settings.hermesApiUrl,
    _keys.hermesApiKey: settings.hermesApiKey,
    _keys.aiChatModel: settings.aiChatModel,
    _keys.askUrl: settings.askUrl,
    _keys.homeAssistantUrl: settings.homeAssistantUrl,
    _keys.searxngUrl: settings.searxngUrl,
    _keys.karakeepUrl: settings.karakeepUrl,
    _keys.paperlessUrl: settings.paperlessUrl,
    _keys.immichUrl: settings.immichUrl,
    _keys.changedetectionUrl: settings.changedetectionUrl,
    _keys.homeAssistantToken: settings.homeAssistantToken,
    _keys.paperlessToken: settings.paperlessToken,
    _keys.immichApiKey: settings.immichApiKey,
    _keys.karakeepApiKey: settings.karakeepApiKey,
    _keys.jellyseerrApiKey: settings.jellyseerrApiKey,
    _keys.openWebuiApiKey: settings.openWebuiApiKey,
    _keys.changedetectionApiKey: settings.changedetectionApiKey,
    _keys.wikiApiKey: settings.wikiApiKey,
    _keys.lokiUrl: settings.lokiUrl,
    _keys.pdmUrl: settings.pdmUrl,
    _keys.pdmTokenId: settings.pdmTokenId,
    _keys.pdmTokenSecret: settings.pdmTokenSecret,
    _keys.pdmFingerprint: settings.pdmFingerprint,
    _keys.pbs1Name: settings.pbs1Name,
    _keys.pbs1Url: settings.pbs1Url,
    _keys.pbs1TokenId: settings.pbs1TokenId,
    _keys.pbs1TokenSecret: settings.pbs1TokenSecret,
    _keys.pbs1Fingerprint: settings.pbs1Fingerprint,
    _keys.pbs1User: settings.pbs1User,
    _keys.pbs1PveStorage: settings.pbs1PveStorage,
    _keys.pbs2Name: settings.pbs2Name,
    _keys.pbs2Url: settings.pbs2Url,
    _keys.pbs2TokenId: settings.pbs2TokenId,
    _keys.pbs2TokenSecret: settings.pbs2TokenSecret,
    _keys.pbs2Fingerprint: settings.pbs2Fingerprint,
    _keys.pbs2User: settings.pbs2User,
    _keys.pbs2PveStorage: settings.pbs2PveStorage,
    _keys.jellyseerrUrl: settings.jellyseerrUrl,
    _keys.jellyfinUrl: settings.jellyfinUrl,
    _keys.jellyfinApiKey: settings.jellyfinApiKey,
    _keys.plexUrl: settings.plexUrl,
    _keys.plexToken: settings.plexToken,
    _keys.radarrUrl: settings.radarrUrl,
    _keys.radarrApiKey: settings.radarrApiKey,
    _keys.sonarrUrl: settings.sonarrUrl,
    _keys.sonarrApiKey: settings.sonarrApiKey,
    _keys.prowlarrUrl: settings.prowlarrUrl,
    _keys.prowlarrApiKey: settings.prowlarrApiKey,
    _keys.qbittorrentUrl: settings.qbittorrentUrl,
    _keys.qbittorrentUser: settings.qbittorrentUser,
    _keys.qbittorrentPass: settings.qbittorrentPass,
    _keys.themeMode: settings.themeMode,
    _keys.themeId: settings.themeId,
    _keys.railCollapsed: settings.railCollapsed ? 'true' : 'false',
    _keys.sshTargets: settings.sshTargets,
    _keys.sshUsername: settings.sshUsername,
    _keys.electricityRateUsdPerKwh: settings.electricityRateUsdPerKwh
        .toString(),
    _keys.trustSelfSigned: settings.trustSelfSigned.toString(),
    _keys.notifyAlerts: settings.notifyAlerts.toString(),
    _keys.showUnconfiguredTabs: settings.showUnconfiguredTabs.toString(),
  };

  Future<void> _write(AppSettings settings) => _writeAll(toMap(settings));

  Future<void> _writeAll(Map<String, String> values) => Future.wait([
    for (final e in values.entries) _storage.write(key: e.key, value: e.value),
  ]);
}
