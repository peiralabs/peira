import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../build_config.dart';

part 'app_settings.freezed.dart';

/// Stored login for one embedded webview service — autofilled into the
/// service's own login form so the operator isn't re-typing it every session.
typedef WebLogin = ({String username, String password});

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
    // Home Assistant web UI (embedded webview tab). The full HA frontend
    // does device control/add/remove, automations, and settings, so the tab
    // needs only the URL — HA's own login persists in the webview.
    @Default('') String homeAssistantUrl,
    // Embedded service webviews (2026-08-18 service expansion): SearXNG
    // (AI hub › Search), Karakeep + Paperless (Library hub), immich (Media ›
    // Photos), changedetection.io (Metrics hub › Watches). Each needs only a
    // URL — the service's own login persists in the webview.
    @Default('') String searxngUrl,
    @Default('') String karakeepUrl,
    @Default('') String paperlessUrl,
    @Default('') String immichUrl,
    @Default('') String changedetectionUrl,
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
    // Stored logins for the embedded service webviews (Jellyseerr, Karakeep,
    // Paperless, Immich, Open WebUI, changedetection.io…), so their own login
    // forms are autofilled instead of re-typed each session. One JSON blob in
    // the keychain — `{"Karakeep":{"u":"…","p":"…"}, …}` — keyed by the
    // service label the webview screen already dispatches on. Passwords never
    // leave secure storage except as an autofill script injected into that
    // service's page; parse it through [webLogins], write it via
    // [withWebLogin]. changedetection.io stores a password with an empty
    // username (single-field login).
    @Default('') String webLoginsJson,
    // Auto-submit the login form after autofilling (once per browser session,
    // to avoid lockout loops). Off = fill only, operator clicks sign-in.
    @Default(true) bool webAutoLogin,
    // Desktop notifications (Linux `notify-send`) for newly-firing Grafana
    // alerts, so the app is useful running in the background. iOS has no
    // equivalent path and ignores this.
    @Default(true) bool notifyAlerts,
  }) = _AppSettings;

  /// The Proxmox tab and dashboard need these three to function.
  bool get isConfigured =>
      proxmoxUrl.isNotEmpty &&
      proxmoxTokenId.isNotEmpty &&
      proxmoxTokenSecret.isNotEmpty;

  /// Prometheus endpoint for the native Metrics tab. Falls back to the
  /// Grafana host on the standard :9090 port (they share the monitoring CT),
  /// so existing installs work without re-seeding the keyring.
  String get prometheusEndpoint {
    if (prometheusUrl.isNotEmpty) return prometheusUrl;
    if (grafanaUrl.isEmpty) return '';
    final g = Uri.tryParse(grafanaUrl);
    if (g == null || g.host.isEmpty) return '';
    return g.replace(port: 9090).toString();
  }

  /// Ollama daemon API endpoint for the native model-library tab. Falls back
  /// to the Open WebUI host on the standard :11434 daemon port.
  String get ollamaApiEndpoint {
    if (ollamaApiUrl.isNotEmpty) return ollamaApiUrl;
    if (ollamaUrl.isEmpty) return '';
    final u = Uri.tryParse(ollamaUrl);
    if (u == null || u.host.isEmpty) return '';
    return u.replace(port: 11434).toString();
  }

  /// Hermes OpenAI-compatible API endpoint for the native chat tab. Falls
  /// back to the Hermes host on the standard :8642 API port.
  String get hermesApiEndpoint {
    if (hermesApiUrl.isNotEmpty) return hermesApiUrl;
    if (hermesUrl.isEmpty) return '';
    final u = Uri.tryParse(hermesUrl);
    if (u == null || u.host.isEmpty) return '';
    return u.replace(port: 8642).toString();
  }

  /// Model name for the native chat tab. The personal build always talks to
  /// the Hermes agent's fixed route; the public AI Chat build sends whatever
  /// the operator configured (empty = not yet configured, the screen refuses
  /// to send).
  String get chatModel => kPublicBuild ? aiChatModel : 'hermes-agent';

  /// Ask-Your-Homelab RAG endpoint for the native Ask tab. Falls back to the
  /// Wiki host on the ask-homelab service port :9113 (they share CT 106).
  String get askEndpoint {
    if (askUrl.isNotEmpty) return askUrl;
    if (wikiUrl.isEmpty) return '';
    final u = Uri.tryParse(wikiUrl);
    if (u == null || u.host.isEmpty) return '';
    return u.replace(port: 9113).toString();
  }

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

  /// Stored webview logins keyed by service label. Malformed JSON (or an
  /// entry missing a password) is skipped, so a corrupt blob degrades to
  /// "no autofill" rather than throwing.
  Map<String, WebLogin> get webLogins {
    if (webLoginsJson.isEmpty) return const {};
    try {
      final decoded = jsonDecode(webLoginsJson);
      if (decoded is! Map) return const {};
      final out = <String, WebLogin>{};
      decoded.forEach((service, value) {
        if (service is! String || value is! Map) return;
        final p = value['p'];
        if (p is! String || p.isEmpty) return;
        final u = value['u'];
        out[service] = (username: u is String ? u : '', password: p);
      });
      return out;
    } on FormatException {
      return const {};
    }
  }

  /// The login for [service], or null when none is stored.
  WebLogin? webLoginFor(String service) => webLogins[service];

  /// Returns a copy with [service]'s login set (or removed when both fields
  /// are blank), re-encoding the JSON blob. Used by the settings screen.
  AppSettings withWebLogin(String service, WebLogin login) {
    final map = {
      for (final e in webLogins.entries)
        e.key: {'u': e.value.username, 'p': e.value.password},
    };
    if (login.username.trim().isEmpty && login.password.isEmpty) {
      map.remove(service);
    } else {
      map[service] = {'u': login.username.trim(), 'p': login.password};
    }
    return copyWith(webLoginsJson: map.isEmpty ? '' : jsonEncode(map));
  }
}
