import 'package:freezed_annotation/freezed_annotation.dart';

import '../build_config.dart';

part 'app_settings.freezed.dart';

/// All service endpoints and credentials, persisted via
/// flutter_secure_storage — never in plain files or source.
@freezed
abstract class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    @Default('') String proxmoxUrl,
    @Default('') String proxmoxTokenId,
    @Default('') String proxmoxTokenSecret,
    // Docker Engine API exposed over TCP. No authentication headers are
    // added; deployments should keep the endpoint on a trusted network.
    @Default('') String dockerUrl,
    @Default(true) bool dockerTlsVerify,
    @Default('') String grafanaUrl,
    @Default('') String grafanaApiKey,
    @Default('') String prometheusUrl,
    @Default('') String hermesUrl,
    @Default('') String wikiUrl,
    @Default('') String ollamaUrl,
    // Native AI tabs. The Ollama daemon API and the Hermes OpenAI-style API
    // default to the standard ports on the same hosts as the web UIs.
    @Default('') String ollamaApiUrl,
    @Default('') String hermesApiUrl,
    @Default('') String hermesApiKey,
    // Public-build AI Chat: the model name sent to the OpenAI-compatible
    // endpoint (e.g. llama3.2 on Ollama). The personal build pins the Hermes
    // agent route and never reads this.
    @Default('') String aiChatModel,
    // Ask-Your-Homelab RAG endpoint (native Ask tab). Defaults to the Wiki
    // host on the ask-homelab service port.
    @Default('') String askUrl,
    // Home Assistant (native tab; the token below unlocks it).
    @Default('') String homeAssistantUrl,
    // Service URLs (2026-08-18 service expansion): SearXNG (AI hub ›
    // Search), Karakeep + Paperless (Library hub), immich (Media › Photos),
    // changedetection.io (Metrics hub › Watches). Each tab is native over the
    // service's API; the credentials follow.
    @Default('') String searxngUrl,
    @Default('') String karakeepUrl,
    @Default('') String paperlessUrl,
    @Default('') String immichUrl,
    @Default('') String changedetectionUrl,
    // API credentials that turn those services' tabs native (2026-10-27).
    // Each tab keeps an "open in browser" action for whatever the API
    // cannot do; without its credential a tab shows a setup prompt.
    // Home Assistant: long-lived access token (Bearer).
    @Default('') String homeAssistantToken,
    // Paperless-ngx: per-user API token (`Authorization: Token …`).
    @Default('') String paperlessToken,
    // Immich: API key (`x-api-key`).
    @Default('') String immichApiKey,
    // Karakeep: API key (Bearer).
    @Default('') String karakeepApiKey,
    // Seerr / Jellyseerr: API key (`X-Api-Key`).
    @Default('') String jellyseerrApiKey,
    // Open WebUI: API key (Bearer), from Settings › Account.
    @Default('') String openWebuiApiKey,
    // changedetection.io: API key (`x-api-key`), Settings › API.
    @Default('') String changedetectionApiKey,
    // Wiki.js: API key (Bearer) for its GraphQL API, Administration › API.
    @Default('') String wikiApiKey,
    // Loki log store for the native Logs sub-tab (read-only query API).
    @Default('') String lokiUrl,
    // Proxmox Datacenter Manager. The URL alone lights the Proxmox-tab panel
    // (reachability + browser deep-link); an API token adds native remote
    // status. PDM's self-signed cert is pinned by SHA-256 fingerprint instead
    // of riding the blanket trust toggle, whose documented scope is the
    // Proxmox host only.
    @Default('') String pdmUrl,
    @Default('') String pdmTokenId,
    @Default('') String pdmTokenSecret,
    @Default('') String pdmFingerprint,
    // Two fixed Proxmox Backup Server slots. Tokens provide read/verify
    // access; [pbs1User]/[pbs2User] identify the password login used for an
    // in-memory elevated ticket. Passwords are never stored.
    @Default('') String pbs1Name,
    @Default('') String pbs1Url,
    @Default('') String pbs1TokenId,
    @Default('') String pbs1TokenSecret,
    @Default('') String pbs1Fingerprint,
    @Default('') String pbs1User,
    @Default('') String pbs1PveStorage,
    @Default('') String pbs2Name,
    @Default('') String pbs2Url,
    @Default('') String pbs2TokenId,
    @Default('') String pbs2TokenSecret,
    @Default('') String pbs2Fingerprint,
    @Default('') String pbs2User,
    @Default('') String pbs2PveStorage,
    @Default('') String jellyseerrUrl,
    // Media servers (native status panels). Jellyfin uses an API key,
    // Plex an X-Plex-Token.
    @Default('') String jellyfinUrl,
    @Default('') String jellyfinApiKey,
    @Default('') String plexUrl,
    @Default('') String plexToken,
    // Media stack (native tabs). arr apps use an X-Api-Key; qBittorrent uses
    // WebUI username/password (cookie auth).
    @Default('') String radarrUrl,
    @Default('') String radarrApiKey,
    @Default('') String sonarrUrl,
    @Default('') String sonarrApiKey,
    @Default('') String prowlarrUrl,
    @Default('') String prowlarrApiKey,
    @Default('') String qbittorrentUrl,
    @Default('') String qbittorrentUser,
    @Default('') String qbittorrentPass,
    @Default(true) bool trustSelfSigned,
    // 'system' | 'dark' | 'light' — the in-app palette switch.
    @Default('system') String themeMode,
    // Theme family id (see ThemePack.all) — e.g. 'brass', 'graphite'. An
    // unknown or missing value falls back to Brass Edition.
    @Default('brass') String themeId,
    // Nav rail collapsed to the 78px icon dock (brass knob toggle).
    @Default(false) bool railCollapsed,
    // Terminal SSH quick-connect shortcuts, one per line as `label=user@host`
    // (or bare `user@host`, which labels itself). No IPs are baked in — the
    // operator supplies their own targets (Tailscale IPs, DNS names, …).
    @Default('') String sshTargets,
    // SSH username for the terminal targets built from Proxmox inventory
    // (node shells and `pct enter` container hops). Proxmox's own hardening
    // guidance is to disable root SSH; see [sshUser] for how non-root users
    // reach containers.
    @Default('root') String sshUsername,
    // Electricity tariff ($/kWh) for the Metrics tab's UPS power-cost estimate.
    // Mirrors the Grafana 'Homelab Power & Cost' dashboard's $rate variable —
    // avg UPS watts × this rate → $/day·month·year. Not a credential, but kept
    // in settings so the estimate is operator-tunable (tariffs vary) rather
    // than hardcoded.
    @Default(0.30) double electricityRateUsdPerKwh,
    // Desktop notifications (Linux `notify-send`) for newly-firing Grafana
    // alerts, so the app is useful running in the background. iOS has no
    // equivalent path and ignores this.
    @Default(true) bool notifyAlerts,
    // Rail tabs whose services have no settings are hidden; this shows them
    // anyway (each then renders its "not set up" prompt).
    @Default(false) bool showUnconfiguredTabs,
    // The in-app guide opens by itself until the operator ticks "Don't
    // show this again" in it.
    @Default(false) bool guideDismissed,
  }) = _AppSettings;

  /// The Proxmox tab and dashboard need these three to function.
  bool get isConfigured =>
      proxmoxUrl.isNotEmpty &&
      proxmoxTokenId.isNotEmpty &&
      proxmoxTokenSecret.isNotEmpty;

  /// Returns [override] when set; otherwise [base] with its port replaced by
  /// [port] (empty when [base] is missing or unparseable). The shared shape
  /// behind the service-endpoint fallbacks below.
  static String _derive(String override, String base, int port) {
    if (override.isNotEmpty) return override;
    if (base.isEmpty) return '';
    final u = Uri.tryParse(base);
    if (u == null || u.host.isEmpty) return '';
    return u.replace(port: port).toString();
  }

  /// Prometheus endpoint for the native Metrics tab. Falls back to the
  /// Grafana host on the standard :9090 port (they share the monitoring CT),
  /// so existing installs work without re-seeding the keyring.
  String get prometheusEndpoint => _derive(prometheusUrl, grafanaUrl, 9090);

  /// Ollama daemon API endpoint for the native model-library tab. Falls back
  /// to the Open WebUI host on the standard :11434 daemon port.
  String get ollamaApiEndpoint => _derive(ollamaApiUrl, ollamaUrl, 11434);

  /// Hermes OpenAI-compatible API endpoint for the native chat tab. Falls
  /// back to the Hermes host on the standard :8642 API port.
  String get hermesApiEndpoint => _derive(hermesApiUrl, hermesUrl, 8642);

  /// Model name for the native chat tab. The personal build always talks to
  /// the Hermes agent's fixed route; the public AI Chat build sends whatever
  /// the operator configured (empty = not yet configured, the screen refuses
  /// to send).
  String get chatModel => kPublicBuild ? aiChatModel : 'hermes-agent';

  /// Ask-Your-Homelab RAG endpoint for the native Ask tab. Falls back to the
  /// Wiki host on the ask-homelab service port :9113 (they share CT 106).
  String get askEndpoint => _derive(askUrl, wikiUrl, 9113);

  /// Effective SSH username for Proxmox-inventory terminal targets — a
  /// cleared field falls back to root rather than producing `@host`.
  String get sshUser {
    final u = sshUsername.trim();
    return u.isEmpty ? 'root' : u;
  }

  /// Parsed SSH quick-connect shortcuts for the terminal. Each non-empty line
  /// is `label=user@host`; a line with no `=` labels itself.
  List<({String label, String target})> get sshShortcuts {
    final out = <({String label, String target})>[];
    for (final raw in sshTargets.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final eq = line.indexOf('=');
      if (eq > 0) {
        out.add((
          label: line.substring(0, eq).trim(),
          target: line.substring(eq + 1).trim(),
        ));
      } else {
        out.add((label: line, target: line));
      }
    }
    return out;
  }

  /// A media server is usable once it has both a URL and its auth secret.
  bool get jellyfinConfigured =>
      jellyfinUrl.isNotEmpty && jellyfinApiKey.isNotEmpty;
  bool get plexConfigured => plexUrl.isNotEmpty && plexToken.isNotEmpty;

  /// A *arr service is usable once it has both a URL and an API key.
  bool get radarrConfigured => radarrUrl.isNotEmpty && radarrApiKey.isNotEmpty;
  bool get sonarrConfigured => sonarrUrl.isNotEmpty && sonarrApiKey.isNotEmpty;
  bool get prowlarrConfigured =>
      prowlarrUrl.isNotEmpty && prowlarrApiKey.isNotEmpty;

  /// qBittorrent just needs a URL; the WebUI may allow unauthenticated LAN
  /// access, so credentials are optional.
  bool get qbittorrentConfigured => qbittorrentUrl.isNotEmpty;

  /// The PDM panel appears once a URL is set; native remote status
  /// additionally needs the API token pair.
  bool get pdmConfigured => pdmUrl.isNotEmpty;
  bool get pdmTokenConfigured =>
      pdmUrl.isNotEmpty && pdmTokenId.isNotEmpty && pdmTokenSecret.isNotEmpty;

  bool get pbs1Configured =>
      pbs1Url.isNotEmpty &&
      pbs1TokenId.isNotEmpty &&
      pbs1TokenSecret.isNotEmpty;
  bool get pbs2Configured =>
      pbs2Url.isNotEmpty &&
      pbs2TokenId.isNotEmpty &&
      pbs2TokenSecret.isNotEmpty;

  /// A native service tab is usable once it has a URL and its API credential.
  bool get homeAssistantConfigured =>
      homeAssistantUrl.isNotEmpty && homeAssistantToken.isNotEmpty;
  bool get paperlessConfigured =>
      paperlessUrl.isNotEmpty && paperlessToken.isNotEmpty;
  bool get immichConfigured => immichUrl.isNotEmpty && immichApiKey.isNotEmpty;
  bool get karakeepConfigured =>
      karakeepUrl.isNotEmpty && karakeepApiKey.isNotEmpty;
  bool get jellyseerrConfigured =>
      jellyseerrUrl.isNotEmpty && jellyseerrApiKey.isNotEmpty;
  bool get openWebuiConfigured =>
      ollamaUrl.isNotEmpty && openWebuiApiKey.isNotEmpty;
  bool get changedetectionConfigured =>
      changedetectionUrl.isNotEmpty && changedetectionApiKey.isNotEmpty;
  bool get wikiConfigured => wikiUrl.isNotEmpty && wikiApiKey.isNotEmpty;

  /// SearXNG's JSON API needs no credential, only `json` enabled in the
  /// instance's `search.formats`.
  bool get searxngConfigured => searxngUrl.isNotEmpty;
}
