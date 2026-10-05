import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_config.dart';
import '../../core/models/app_settings.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/update/update_check.dart';
import '../../core/util/open_url.dart';
import '../../core/webview/web_logins.dart';
import '../../core/widgets/brass_icon_badge.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/screen_header.dart';

/// Credentials and service endpoints. Everything entered here lands in
/// flutter_secure_storage — nothing is written to plain files.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _proxmoxUrl = TextEditingController();
  final _proxmoxTokenId = TextEditingController();
  final _proxmoxTokenSecret = TextEditingController();
  final _dockerUrl = TextEditingController();
  final _grafanaUrl = TextEditingController();
  final _grafanaApiKey = TextEditingController();
  final _prometheusUrl = TextEditingController();
  final _hermesUrl = TextEditingController();
  final _wikiUrl = TextEditingController();
  final _ollamaUrl = TextEditingController();
  final _ollamaApiUrl = TextEditingController();
  final _hermesApiUrl = TextEditingController();
  final _hermesApiKey = TextEditingController();
  final _aiChatModel = TextEditingController();
  final _askUrl = TextEditingController();
  final _homeAssistantUrl = TextEditingController();
  final _searxngUrl = TextEditingController();
  final _karakeepUrl = TextEditingController();
  final _paperlessUrl = TextEditingController();
  final _immichUrl = TextEditingController();
  final _changedetectionUrl = TextEditingController();
  final _lokiUrl = TextEditingController();
  final _pdmUrl = TextEditingController();
  final _pdmTokenId = TextEditingController();
  final _pdmTokenSecret = TextEditingController();
  final _pdmFingerprint = TextEditingController();
  final _jellyseerrUrl = TextEditingController();
  final _jellyfinUrl = TextEditingController();
  final _jellyfinApiKey = TextEditingController();
  final _plexUrl = TextEditingController();
  final _plexToken = TextEditingController();
  final _radarrUrl = TextEditingController();
  final _radarrApiKey = TextEditingController();
  final _sonarrUrl = TextEditingController();
  final _sonarrApiKey = TextEditingController();
  final _prowlarrUrl = TextEditingController();
  final _prowlarrApiKey = TextEditingController();
  final _qbittorrentUrl = TextEditingController();
  final _qbittorrentUser = TextEditingController();
  final _qbittorrentPass = TextEditingController();
  final _sshTargets = TextEditingController();
  final _sshUsername = TextEditingController();
  final _electricityRate = TextEditingController();
  bool _trustSelfSigned = true;
  bool _dockerTlsVerify = true;
  bool _seeded = false;

  // Per-service stored logins for the embedded webviews (autofilled into each
  // service's own login form). Keyed by the service label.
  final _webLoginUser = {
    for (final s in WebLogins.services) s: TextEditingController(),
  };
  final _webLoginPass = {
    for (final s in WebLogins.services) s: TextEditingController(),
  };
  bool _webAutoLogin = true;
  bool _notifyAlerts = true;

  @override
  void dispose() {
    for (final c in [
      _proxmoxUrl,
      _proxmoxTokenId,
      _proxmoxTokenSecret,
      _dockerUrl,
      _grafanaUrl,
      _grafanaApiKey,
      _prometheusUrl,
      _hermesUrl,
      _wikiUrl,
      _ollamaUrl,
      _ollamaApiUrl,
      _hermesApiUrl,
      _hermesApiKey,
      _aiChatModel,
      _askUrl,
      _homeAssistantUrl,
      _searxngUrl,
      _karakeepUrl,
      _paperlessUrl,
      _immichUrl,
      _changedetectionUrl,
      _lokiUrl,
      _pdmUrl,
      _pdmTokenId,
      _pdmTokenSecret,
      _pdmFingerprint,
      _jellyseerrUrl,
      _jellyfinUrl,
      _jellyfinApiKey,
      _plexUrl,
      _plexToken,
      _radarrUrl,
      _radarrApiKey,
      _sonarrUrl,
      _sonarrApiKey,
      _prowlarrUrl,
      _prowlarrApiKey,
      _qbittorrentUrl,
      _qbittorrentUser,
      _qbittorrentPass,
      _sshTargets,
      _sshUsername,
      _electricityRate,
      ..._webLoginUser.values,
      ..._webLoginPass.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _themeMode = 'system';
  String _themeId = 'brass';

  void _seedFrom(AppSettings settings) {
    if (_seeded) return;
    _seeded = true;
    _themeMode = settings.themeMode;
    _themeId = settings.themeId;
    _proxmoxUrl.text = settings.proxmoxUrl;
    _proxmoxTokenId.text = settings.proxmoxTokenId;
    _proxmoxTokenSecret.text = settings.proxmoxTokenSecret;
    _dockerUrl.text = settings.dockerUrl;
    _grafanaUrl.text = settings.grafanaUrl;
    _grafanaApiKey.text = settings.grafanaApiKey;
    _prometheusUrl.text = settings.prometheusUrl;
    _hermesUrl.text = settings.hermesUrl;
    _wikiUrl.text = settings.wikiUrl;
    _ollamaUrl.text = settings.ollamaUrl;
    _ollamaApiUrl.text = settings.ollamaApiUrl;
    _hermesApiUrl.text = settings.hermesApiUrl;
    _hermesApiKey.text = settings.hermesApiKey;
    _aiChatModel.text = settings.aiChatModel;
    _askUrl.text = settings.askUrl;
    _homeAssistantUrl.text = settings.homeAssistantUrl;
    _searxngUrl.text = settings.searxngUrl;
    _karakeepUrl.text = settings.karakeepUrl;
    _paperlessUrl.text = settings.paperlessUrl;
    _immichUrl.text = settings.immichUrl;
    _changedetectionUrl.text = settings.changedetectionUrl;
    _lokiUrl.text = settings.lokiUrl;
    _pdmUrl.text = settings.pdmUrl;
    _pdmTokenId.text = settings.pdmTokenId;
    _pdmTokenSecret.text = settings.pdmTokenSecret;
    _pdmFingerprint.text = settings.pdmFingerprint;
    _jellyseerrUrl.text = settings.jellyseerrUrl;
    _jellyfinUrl.text = settings.jellyfinUrl;
    _jellyfinApiKey.text = settings.jellyfinApiKey;
    _plexUrl.text = settings.plexUrl;
    _plexToken.text = settings.plexToken;
    _radarrUrl.text = settings.radarrUrl;
    _radarrApiKey.text = settings.radarrApiKey;
    _sonarrUrl.text = settings.sonarrUrl;
    _sonarrApiKey.text = settings.sonarrApiKey;
    _prowlarrUrl.text = settings.prowlarrUrl;
    _prowlarrApiKey.text = settings.prowlarrApiKey;
    _qbittorrentUrl.text = settings.qbittorrentUrl;
    _qbittorrentUser.text = settings.qbittorrentUser;
    _qbittorrentPass.text = settings.qbittorrentPass;
    _sshTargets.text = settings.sshTargets;
    _sshUsername.text = settings.sshUsername;
    _electricityRate.text = settings.electricityRateUsdPerKwh.toString();
    _trustSelfSigned = settings.trustSelfSigned;
    _dockerTlsVerify = settings.dockerTlsVerify;
    _webAutoLogin = settings.webAutoLogin;
    _notifyAlerts = settings.notifyAlerts;
    for (final service in WebLogins.services) {
      final login = settings.webLoginFor(service);
      _webLoginUser[service]!.text = login?.username ?? '';
      _webLoginPass[service]!.text = login?.password ?? '';
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Preserve fields the form doesn't edit (theme + rail state live in the
    // shell chrome) so Save can't silently reset them.
    final current = ref.read(settingsControllerProvider).value;
    final settings = AppSettings(
      themeMode: _themeMode,
      themeId: _themeId,
      railCollapsed: current?.railCollapsed ?? false,
      proxmoxUrl: _cleanUrl(_proxmoxUrl.text),
      proxmoxTokenId: _proxmoxTokenId.text.trim(),
      proxmoxTokenSecret: _proxmoxTokenSecret.text.trim(),
      dockerUrl: _cleanUrl(_dockerUrl.text),
      dockerTlsVerify: _dockerTlsVerify,
      grafanaUrl: _cleanUrl(_grafanaUrl.text),
      grafanaApiKey: _grafanaApiKey.text.trim(),
      prometheusUrl: _cleanUrl(_prometheusUrl.text),
      hermesUrl: _cleanUrl(_hermesUrl.text),
      wikiUrl: _cleanUrl(_wikiUrl.text),
      ollamaUrl: _cleanUrl(_ollamaUrl.text),
      ollamaApiUrl: _cleanUrl(_ollamaApiUrl.text),
      hermesApiUrl: _cleanUrl(_hermesApiUrl.text),
      hermesApiKey: _hermesApiKey.text.trim(),
      aiChatModel: _aiChatModel.text.trim(),
      askUrl: _cleanUrl(_askUrl.text),
      homeAssistantUrl: _cleanUrl(_homeAssistantUrl.text),
      searxngUrl: _cleanUrl(_searxngUrl.text),
      karakeepUrl: _cleanUrl(_karakeepUrl.text),
      paperlessUrl: _cleanUrl(_paperlessUrl.text),
      immichUrl: _cleanUrl(_immichUrl.text),
      changedetectionUrl: _cleanUrl(_changedetectionUrl.text),
      lokiUrl: _cleanUrl(_lokiUrl.text),
      pdmUrl: _cleanUrl(_pdmUrl.text),
      pdmTokenId: _pdmTokenId.text.trim(),
      pdmTokenSecret: _pdmTokenSecret.text.trim(),
      pdmFingerprint: _pdmFingerprint.text.trim(),
      jellyseerrUrl: _cleanUrl(_jellyseerrUrl.text),
      jellyfinUrl: _cleanUrl(_jellyfinUrl.text),
      jellyfinApiKey: _jellyfinApiKey.text.trim(),
      plexUrl: _cleanUrl(_plexUrl.text),
      plexToken: _plexToken.text.trim(),
      radarrUrl: _cleanUrl(_radarrUrl.text),
      radarrApiKey: _radarrApiKey.text.trim(),
      sonarrUrl: _cleanUrl(_sonarrUrl.text),
      sonarrApiKey: _sonarrApiKey.text.trim(),
      prowlarrUrl: _cleanUrl(_prowlarrUrl.text),
      prowlarrApiKey: _prowlarrApiKey.text.trim(),
      qbittorrentUrl: _cleanUrl(_qbittorrentUrl.text),
      qbittorrentUser: _qbittorrentUser.text.trim(),
      qbittorrentPass: _qbittorrentPass.text,
      sshTargets: _sshTargets.text.trim(),
      sshUsername: _sshUsername.text.trim(),
      electricityRateUsdPerKwh:
          double.tryParse(_electricityRate.text.trim()) ?? 0.30,
      trustSelfSigned: _trustSelfSigned,
      webAutoLogin: _webAutoLogin,
      notifyAlerts: _notifyAlerts,
    );
    // Fold the per-service webview logins into the JSON blob.
    var withLogins = settings;
    for (final service in WebLogins.services) {
      withLogins = withLogins.withWebLogin(service, (
        username: _webLoginUser[service]!.text.trim(),
        password: _webLoginPass[service]!.text,
      ));
    }
    await ref.read(settingsControllerProvider.notifier).save(withLogins);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  static String _cleanUrl(String value) {
    var v = value.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }

  static String? _validateUrl(String? value, {bool required = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Required' : null;
    final uri = Uri.tryParse(v);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a full URL, e.g. https://host:8006';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);

    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load settings: $e')),
      data: (current) {
        _seedFrom(current);
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
            children: [
              ScreenHeader(
                icon: Ph.gearSix,
                badgeField: BrassIconBadge.navyField,
                // The badge well is navy in both modes, so the icy icon ink
                // is shared; only the subtitle sits on the page itself.
                iconColor: const Color(0xFFDCE8F8),
                title: 'Settings',
                subtitle: 'SYSTEM KEYCHAIN · NEVER PLAIN FILES',
                subtitleColor: context.brass.isDark
                    ? const Color(0xFF9DB8DD)
                    : const Color(0xFF425C86),
              ),
              const SizedBox(height: 16),
              const SectionDivider(),
              const SizedBox(height: 8),
              _section(context, 'Appearance'),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'system', label: Text('System')),
                        ButtonSegment(value: 'light', label: Text('Light')),
                        ButtonSegment(value: 'dark', label: Text('Dark')),
                      ],
                      selected: {_themeMode},
                      onSelectionChanged: (selection) {
                        final v = selection.first;
                        setState(() => _themeMode = v);
                        // Apply immediately once configured; before first
                        // save the choice rides along with the Save button.
                        final cur = ref.read(settingsControllerProvider).value;
                        if (cur != null) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .save(cur.copyWith(themeMode: v));
                        }
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pack in ThemePack.all)
                      ChoiceChip(
                        label: Text(pack.label),
                        selected: _themeId == pack.id,
                        onSelected: (_) {
                          if (_themeId == pack.id) return;
                          setState(() => _themeId = pack.id);
                          // Apply immediately once configured; before first
                          // save the choice rides along with the Save button.
                          final cur =
                              ref.read(settingsControllerProvider).value;
                          if (cur != null) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .save(cur.copyWith(themeId: pack.id));
                          }
                        },
                      ),
                  ],
                ),
              ),
              _section(context, 'Proxmox'),
              _urlField(
                _proxmoxUrl,
                'Proxmox URL',
                hint: 'https://192.168.1.10:8006',
                required: true,
              ),
              _textField(
                _proxmoxTokenId,
                'API token ID',
                hint: 'user@realm!tokenid',
                required: true,
              ),
              _textField(
                _proxmoxTokenSecret,
                'API token secret',
                obscure: true,
                required: true,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Trust self-signed certificate'),
                subtitle: const Text(
                  'For the Proxmox host only — leave on for LAN use',
                ),
                value: _trustSelfSigned,
                onChanged: (v) => setState(() => _trustSelfSigned = v),
              ),
              _section(context, 'Datacenter Manager'),
              _urlField(_pdmUrl, 'PDM URL', hint: 'https://10.0.0.6:8443'),
              _textField(
                _pdmTokenId,
                'PDM API token ID (optional — enables native status)',
                hint: 'user@pam!tokenname',
              ),
              _textField(
                _pdmTokenSecret,
                'PDM API token secret',
                obscure: true,
              ),
              _textField(
                _pdmFingerprint,
                'PDM certificate fingerprint (SHA-256)',
                hint: 'AA:BB:… — pins the self-signed cert; empty = system CAs',
              ),
              _section(context, 'Grafana'),
              _urlField(_grafanaUrl, 'Grafana URL'),
              _textField(_grafanaApiKey, 'Grafana API key', obscure: true),
              _urlField(
                _prometheusUrl,
                'Prometheus URL (optional — defaults to Grafana host :9090)',
              ),
              _section(context, 'Power'),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _electricityRate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Electricity rate (\$/kWh)',
                    hintText: '0.30',
                    helperText:
                        'Drives the Metrics tab UPS power-cost estimate.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    return double.tryParse(t) == null
                        ? 'Enter a number, e.g. 0.30'
                        : null;
                  },
                ),
              ),
              _section(context, 'Other services'),
              _urlField(
                _dockerUrl,
                'Docker Engine URL',
                hint: 'http://host:2375',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _dockerTlsVerify,
                onChanged: (v) => setState(() => _dockerTlsVerify = v),
                title: const Text('Verify Docker TLS certificates'),
                subtitle: const Text(
                  'Disable only for a self-signed certificate on a trusted '
                  'LAN host.',
                ),
              ),
              // The Hermes dashboard root is a personal-lab service; the
              // public AI Chat tab is configured by its endpoint + model.
              if (!kPublicBuild) _urlField(_hermesUrl, 'Hermes URL'),
              // "Wiki.js", not "Wiki": the tab's native reskin targets
              // Wiki.js v2 specifically and no-ops on any other wiki's DOM
              // (web_masks.dart) — the label sets that expectation.
              _urlField(_wikiUrl, 'Wiki.js URL'),
              _urlField(_ollamaUrl, 'Ollama / Open WebUI URL'),
              _urlField(
                _ollamaApiUrl,
                'Ollama daemon URL (defaults to the Open WebUI host :11434)',
              ),
              _urlField(
                _hermesApiUrl,
                kPublicBuild
                    ? 'AI Chat endpoint URL (OpenAI-compatible — Ollama, '
                          'LiteLLM, OpenRouter, vLLM)'
                    : 'Hermes API URL (optional, defaults to :8642)',
              ),
              _textField(
                _hermesApiKey,
                kPublicBuild ? 'AI Chat API key (optional)' : 'Hermes API key',
                obscure: true,
              ),
              if (kPublicBuild)
                _textField(
                  _aiChatModel,
                  'AI Chat model (e.g. llama3.2, gpt-4o-mini)',
                ),
              if (!kPublicBuild)
                _urlField(
                  _askUrl,
                  'Ask URL (optional — defaults to the Wiki host :9113)',
                ),
              _urlField(
                _homeAssistantUrl,
                'Home Assistant URL',
                hint: 'http://10.0.0.20:8123',
              ),
              _urlField(
                _searxngUrl,
                'SearXNG URL',
                hint: 'http://10.0.0.21:8888',
              ),
              _urlField(
                _karakeepUrl,
                'Karakeep URL',
                hint: 'http://10.0.0.22:3000',
              ),
              _urlField(
                _paperlessUrl,
                'Paperless-ngx URL',
                hint: 'http://10.0.0.23:8020',
              ),
              _urlField(
                _changedetectionUrl,
                'changedetection.io URL',
                hint: 'http://10.0.0.24:5000',
              ),
              _urlField(
                _lokiUrl,
                'Loki URL (native Logs sub-tab)',
                hint: 'http://10.0.0.25:3100',
              ),
              _urlField(_jellyseerrUrl, 'Jellyseerr URL'),
              _section(context, 'Web logins'),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Stored credentials are autofilled into each embedded '
                  "service's own login form, so you don't re-type them every "
                  'session. Kept in the system keychain, injected only into '
                  "that service's page.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _webAutoLogin,
                onChanged: (v) => setState(() => _webAutoLogin = v),
                title: const Text('Auto-submit after filling'),
                subtitle: const Text(
                  'Sign in automatically (once per session). Off = fill only.',
                ),
              ),
              for (final service in WebLogins.services) ..._loginFields(service),
              _section(context, 'Notifications'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifyAlerts,
                onChanged: (v) => setState(() => _notifyAlerts = v),
                title: const Text('Desktop alert notifications'),
                subtitle: const Text(
                  'Pop a desktop notification when a new Grafana alert fires '
                  '(Linux · notify-send).',
                ),
              ),
              // Media services live wherever the operator runs them (NAS,
              // CT, VM…) — the hints are documentation addresses, nothing
              // assumes a NAS.
              _section(context, 'Media'),
              _urlField(
                _jellyfinUrl,
                'Jellyfin URL',
                hint: 'http://10.0.0.10:8096',
              ),
              _textField(_jellyfinApiKey, 'Jellyfin API key', obscure: true),
              _urlField(_plexUrl, 'Plex URL', hint: 'http://10.0.0.10:32400'),
              _textField(_plexToken, 'Plex token', obscure: true),
              _urlField(
                _immichUrl,
                'Immich URL',
                hint: 'http://10.0.0.10:2283',
              ),
              _urlField(
                _radarrUrl,
                'Radarr URL',
                hint: 'http://10.0.0.10:7878',
              ),
              _textField(_radarrApiKey, 'Radarr API key', obscure: true),
              _urlField(
                _sonarrUrl,
                'Sonarr URL',
                hint: 'http://10.0.0.10:8989',
              ),
              _textField(_sonarrApiKey, 'Sonarr API key', obscure: true),
              _urlField(
                _prowlarrUrl,
                'Prowlarr URL',
                hint: 'http://10.0.0.10:9696',
              ),
              _textField(_prowlarrApiKey, 'Prowlarr API key', obscure: true),
              _urlField(
                _qbittorrentUrl,
                'qBittorrent URL',
                hint: 'http://10.0.0.10:8082',
              ),
              _textField(_qbittorrentUser, 'qBittorrent username'),
              _textField(
                _qbittorrentPass,
                'qBittorrent password',
                obscure: true,
              ),
              _section(context, 'Terminal'),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _sshUsername,
                  decoration: const InputDecoration(
                    labelText: 'SSH username for Proxmox nodes',
                    hintText: 'root',
                    helperText:
                        'Used for the node and container targets built from '
                        'Proxmox inventory. Containers are entered with '
                        "'pct enter' on the node, which needs root — a "
                        'non-root user runs it through sudo.',
                    helperMaxLines: 4,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _sshTargets,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'SSH quick-connect shortcuts',
                    hintText:
                        'node1=root@192.168.1.10\nnas=admin@nas.tail1234.ts.net',
                    helperText:
                        'One per line: label=user@host. Shown as chips in the Terminal tab.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              // Check-only updates (public builds): an AppImage cannot
              // replace itself in place, so this points at the releases
              // page rather than auto-updating. No telemetry — the single
              // API call happens when the operator asks for it.
              if (kPublicBuild) ...[
                _section(context, 'Updates'),
                const _UpdateChecker(),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Username + password inputs for one embedded service's stored login.
  /// changedetection.io has a single shared password (no username).
  List<Widget> _loginFields(String service) {
    final passwordOnly = service == 'changedetection.io';
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Text(
          service,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      if (!passwordOnly)
        _textField(_webLoginUser[service]!, '$service username / email'),
      _textField(
        _webLoginPass[service]!,
        '$service password',
        obscure: true,
      ),
    ];
  }

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 10),
    child: BrassSectionHeader(title: title),
  );

  Widget _urlField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => _validateUrl(v, required: required),
    ),
  );

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool obscure = false,
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null
          : null,
    ),
  );
}

/// One-shot release check against the GitHub Releases API (public builds).
class _UpdateChecker extends StatefulWidget {
  const _UpdateChecker();

  @override
  State<_UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<_UpdateChecker> {
  String? _status;
  bool _busy = false;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await checkForUpdate();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = switch (result) {
        UpdateAvailable(:final latestTag) =>
          '$latestTag is available — you have v$kAppVersion. Download it '
              'from the releases page and replace this AppImage.',
        UpToDate() => 'Up to date (v$kAppVersion).',
        UpdateCheckFailed(:final message) => message,
      };
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _busy ? null : _check,
              child: const Text('Check for updates'),
            ),
            TextButton(
              onPressed: () =>
                  openUrl('https://github.com/$kReleaseRepo/releases'),
              child: const Text('Releases page'),
            ),
            const Text('v$kAppVersion'),
          ],
        ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_status!),
          ),
      ],
    ),
  );
}
