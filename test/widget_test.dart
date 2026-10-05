import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/app.dart';
import 'package:peira/core/api/ollama_api.dart';
import 'package:peira/core/build_config.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/models/grafana_alert.dart';
import 'package:peira/core/models/proxmox_container.dart';
import 'package:peira/core/models/proxmox_node.dart';
import 'package:peira/core/models/radarr_movie.dart';
import 'package:peira/core/models/tailscale_status.dart';
import 'package:peira/core/navigation/app_tab.dart';
import 'package:peira/core/providers/grafana_providers.dart';
import 'package:peira/core/providers/media_providers.dart';
import 'package:peira/core/providers/ollama_providers.dart';
import 'package:peira/core/providers/proxmox_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/providers/tailscale_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/webview/display_server.dart';
import 'package:peira/core/webview/webview_factory.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';
import 'package:peira/core/widgets/command_palette.dart';
import 'package:peira/core/widgets/glass_nav_rail.dart';
import 'package:peira/core/widgets/instrument_gauge.dart';

/// In-memory stand-in — flutter_secure_storage has no platform backend in
/// widget tests, so its futures would never resolve.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

/// Real factories touch platform channels (CEF / WKWebView) that don't exist
/// in widget tests.
class _FakeWebViewFactory implements WebViewFactory {
  @override
  Widget build(String url,
          {String? maskScript, bool controls = false, String? controlsLabel}) =>
      Center(child: Text('webview: $url'));
}

/// Records the mask script of every build so tests can assert the screen
/// re-delivers a re-resolved mask on a brightness flip (the platform views'
/// didUpdateWidget → executeJavaScript path can't run without CEF/WKWebView).
class _RecordingWebViewFactory implements WebViewFactory {
  final masks = <String?>[];

  @override
  Widget build(String url,
      {String? maskScript, bool controls = false, String? controlsLabel}) {
    masks.add(maskScript);
    return Center(child: Text('webview: $url'));
  }
}

const _fakeNodes = [
  ProxmoxNode(
      node: 'node1',
      status: 'online',
      cpu: 0.07,
      mem: 8 << 30,
      maxmem: 16 << 30),
];

const _fakeContainers = [
  ProxmoxContainer(
      vmid: 100,
      status: 'running',
      name: 'ollama-node1',
      node: 'node1',
      mem: 4 << 30,
      maxmem: 14 << 30),
  ProxmoxContainer(
      vmid: 108,
      status: 'stopped',
      name: 'explore-minecraft',
      node: 'node4'),
];

final _fakeAlerts = [
  GrafanaAlert(
    labels: const {'alertname': 'Disk Usage High', 'severity': 'warning'},
    annotations: const {'summary': 'node3 / at 82%'},
    startsAt: DateTime.utc(2026, 7, 4, 8),
  ),
];

const _fakeOllamaModels = [
  OllamaModel(
      name: 'qwen2.5:14b', sizeBytes: 9663676416,
      parameterSize: '14B', quantization: 'Q4_K_M'),
  OllamaModel(
      name: 'llama3.1:8b', sizeBytes: 5046586573,
      parameterSize: '8B', quantization: 'Q4_K_M'),
  OllamaModel(
      name: 'nomic-embed-text', sizeBytes: 287309824,
      parameterSize: '137M', quantization: 'F16'),
];
const _fakeOllamaRunning = {'qwen2.5:14b'};

const _fakeTailscale = TailscaleStatus(
  backendState: 'Running',
  self: TailscaleDevice(
      hostName: 'laptop',
      tailscaleIPs: ['100.64.0.10'],
      os: 'linux',
      online: true),
  peer: {
    'k1': TailscaleDevice(
        hostName: 'node4',
        tailscaleIPs: ['100.64.0.20'],
        os: 'linux',
        online: true,
        exitNodeOption: true),
    'k2': TailscaleDevice(
        hostName: 'old-phone',
        tailscaleIPs: ['100.64.0.30'],
        os: 'android'),
  },
);

// The IndexedStack keeps every tab alive, so the Proxmox/Tailscale providers
// are always watched — override them or every test hits the network/CLI.
Widget _app({
  AppSettings settings = const AppSettings(),
  List<GrafanaAlert> alerts = const [],
  WebViewFactory? webViewFactory,
}) =>
    ProviderScope(
      overrides: [
        // No network in widget tests — pin reachability pills to healthy.
        serviceReachableProvider.overrideWith((ref, url) async => true),
        settingsRepositoryProvider
            .overrideWithValue(_FakeSettingsRepository(settings)),
        nodesProvider.overrideWith((ref) async => _fakeNodes),
        allContainersProvider.overrideWith((ref) async => _fakeContainers),
        activeAlertsProvider.overrideWith((ref) async => alerts),
        recentTasksProvider.overrideWith((ref) async => const []),
        webViewFactoryProvider
            .overrideWithValue(webViewFactory ?? _FakeWebViewFactory()),
        webviewSupportProvider.overrideWithValue(null),
        tailscaleStatusProvider.overrideWith((ref) async => _fakeTailscale),
        ollamaModelsProvider.overrideWith((ref) async => _fakeOllamaModels),
        ollamaRunningProvider.overrideWith((ref) async => _fakeOllamaRunning),
      ],
      child: const HomeLabApp(),
    );

// Every service field populated, mirroring a fully-seeded install, so tests
// that exercise the webview / Grafana tabs start from a realistic state
// rather than proxmox-only settings.
const _configured = AppSettings(
  proxmoxUrl: 'https://pve.example:8006',
  proxmoxTokenId: 'user@pve!token',
  proxmoxTokenSecret: 'secret',
  grafanaUrl: 'http://grafana.example:3000',
  grafanaApiKey: 'test-grafana-key',
  ollamaUrl: 'http://ollama.example:8080',
  ollamaApiUrl: 'http://ollama.example:11434',
  hermesUrl: 'http://hermes.example',
  hermesApiUrl: 'http://hermes.example:8642',
  hermesApiKey: 'test-hermes-key',
  wikiUrl: 'http://wiki.example:3000',
  homeAssistantUrl: 'http://ha.example:8123',
);

/// A desktop viewport tall + wide enough that the whole glass nav dock (10
/// destinations) and the dashboard's lower cards are on-screen and
/// hit-testable. The dock is wider than the old rail, which narrows the content
/// column and pushes lazily-built ListView cards further down.
void _desktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1300, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('app shell shows all desktop destinations', (tester) async {
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    // Test host is desktop, so the glass nav dock renders.
    expect(find.byType(GlassNavRail), findsOneWidget);
    for (final label in [
      'Dashboard',
      'Proxmox',
      'Metrics',
      'AI',
      'Media',
      'Home Assistant',
      // The Vault hub collapses to a single "Wiki" destination in the public
      // build (Ask is personal-only), so the rail label is "Wiki" there.
      kPublicBuild ? 'Wiki' : 'Vault',
      'Tailscale',
      'Terminal',
      'Settings',
    ]) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('command palette opens from the dock, filters, and navigates',
      (tester) async {
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    // Open via the dock search affordance.
    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await tester.pumpAndSettle();
    expect(find.byType(CommandPalette), findsOneWidget);

    // Fuzzy-filter to Proxmox and run that result.
    await tester.enterText(
      find.descendant(
        of: find.byType(CommandPalette),
        matching: find.byType(TextField),
      ),
      'proxmox',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CommandPalette),
        matching: find.text('Proxmox'),
      ),
    );
    await tester.pumpAndSettle();

    // Palette closes and the Proxmox tab (index 1) is now selected.
    expect(find.byType(CommandPalette), findsNothing);
    final rail = tester.widget<GlassNavRail>(find.byType(GlassNavRail));
    expect(rail.selectedIndex, 1);
  });

  testWidgets('Tailscale tab lists self and peers with status',
      (tester) async {
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tailscale'));
    await tester.pumpAndSettle();

    expect(find.text('laptop (this device)'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('PEERS (2)'), findsOneWidget);
    expect(find.text('node4'), findsOneWidget);
    expect(
        find.text('100.64.0.20 · linux · exit node'), findsOneWidget);
    expect(find.text('old-phone'), findsOneWidget);
  });

  testWidgets('Proxmox tab shows node cards and grouped containers',
      (tester) async {
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proxmox'));
    await tester.pumpAndSettle();

    expect(find.text('Nodes'), findsOneWidget);
    expect(find.text('CPU LOAD'), findsOneWidget);
    expect(find.text('8 / 16 GB'), findsOneWidget);
    expect(find.text('100 — ollama-node1'), findsOneWidget);
    expect(find.text('CT'), findsOneWidget);
  });

  testWidgets('dashboard shows node tiles, CT summary, and alert feed',
      (tester) async {
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured, alerts: _fakeAlerts));
    await tester.pumpAndSettle();

    // Cluster panel renders the brass instrument gauges; the attention strip
    // flags the stopped guest; the alert feed shows its data.
    expect(find.byType(InstrumentGauge), findsWidgets);
    expect(find.text('$kAppName Cluster'), findsOneWidget);
    expect(find.text('1 guest stopped'), findsOneWidget);
    expect(find.text('Disk Usage High'), findsOneWidget);
    expect(find.text('node3 / at 82%'), findsOneWidget);
  });

  testWidgets('dashboard shows all-clear when no alerts are active',
      (tester) async {
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    expect(find.text('No active alerts — all quiet in the archive.'),
        findsOneWidget);
  });

  testWidgets('nav dock shows a warning light for stopped containers',
      (tester) async {
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    // The stopped CT surfaces as a badge on the Proxmox destination (index 1),
    // rendered as a breathing status light rather than a number chip.
    final rail = tester.widget<GlassNavRail>(find.byType(GlassNavRail));
    expect(rail.badges[1], 1);
  });

  testWidgets('tapping the attention chip jumps to the Proxmox tab',
      (tester) async {
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 guest stopped'));
    await tester.pumpAndSettle();

    final rail = tester.widget<GlassNavRail>(find.byType(GlassNavRail));
    expect(rail.selectedIndex, 1);
  });

  testWidgets('tapping an alert jumps to the Metrics tab', (tester) async {
    // Taller viewport so the alert feed (now below the node cards, dials and
    // container summary) is on-screen and hit-testable.
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured, alerts: _fakeAlerts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Disk Usage High'));
    await tester.pumpAndSettle();

    final rail = tester.widget<GlassNavRail>(find.byType(GlassNavRail));
    expect(rail.selectedIndex, AppTab.metrics.railIndex);
  });

  testWidgets('Media tab shows the Radarr library and sub-tabs',
      (tester) async {
    _desktopViewport(tester);
    const media = AppSettings(
      proxmoxUrl: 'https://pve.example:8006',
      proxmoxTokenId: 'user@pve!token',
      proxmoxTokenSecret: 'secret',
      radarrUrl: 'http://nas.example:7878',
      radarrApiKey: 'radarr-key',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider
              .overrideWithValue(_FakeSettingsRepository(media)),
          nodesProvider.overrideWith((ref) async => _fakeNodes),
          allContainersProvider.overrideWith((ref) async => _fakeContainers),
          activeAlertsProvider.overrideWith((ref) async => const []),
          recentTasksProvider.overrideWith((ref) async => const []),
          webViewFactoryProvider.overrideWithValue(_FakeWebViewFactory()),
          tailscaleStatusProvider.overrideWith((ref) async => _fakeTailscale),
          ollamaModelsProvider.overrideWith((ref) async => _fakeOllamaModels),
          ollamaRunningProvider
              .overrideWith((ref) async => _fakeOllamaRunning),
          radarrMoviesProvider.overrideWith((ref) async => const [
                RadarrMovie(
                    id: 1, title: 'Dune: Part Two', year: 2024,
                    monitored: true, hasFile: true, sizeOnDisk: 18 << 30),
              ]),
          radarrQueueProvider.overrideWith((ref) async => const []),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Media'));
    await tester.pumpAndSettle();

    // Sub-tab bar renders with the media servers first; the initial Jellyfin
    // sub-tab (unconfigured here) shows its honest empty state.
    expect(find.text('Jellyfin'), findsWidgets);
    expect(find.text('Plex'), findsWidgets);
    expect(find.text('Sonarr'), findsWidgets);
    expect(find.text('Prowlarr'), findsWidgets);
    expect(
        find.textContaining('Jellyfin is not configured'), findsOneWidget);

    // Plex's empty state names its actual credential (token, not API key).
    await tester.tap(find.text('Plex').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Add its URL and token'), findsOneWidget);

    // The Radarr library renders on its sub-tab.
    await tester.tap(find.text('Radarr').first);
    await tester.pumpAndSettle();
    expect(find.text('Dune: Part Two'), findsOneWidget);
  });

  testWidgets('webview tab without a URL points at Settings', (tester) async {
    _desktopViewport(tester);
    // Proxmox configured but Wiki URL unset — the tab should prompt for it.
    const noWiki = AppSettings(
      proxmoxUrl: 'https://pve.example:8006',
      proxmoxTokenId: 'user@pve!token',
      proxmoxTokenSecret: 'secret',
    );
    await tester.pumpWidget(_app(settings: noWiki));
    await tester.pumpAndSettle();

    // The wiki webview is the Vault hub's default sub-view.
    await tester.tap(find.text(kPublicBuild ? 'Wiki' : 'Vault'));
    await tester.pumpAndSettle();

    expect(find.text('Wiki has no URL yet.\nEnter it in Settings.'),
        findsOneWidget);
  });

  testWidgets('webview tab with a URL builds the platform web view lazily',
      (tester) async {
    _desktopViewport(tester);
    const settings = AppSettings(
      proxmoxUrl: 'https://pve.example:8006',
      proxmoxTokenId: 'user@pve!token',
      proxmoxTokenSecret: 'secret',
      wikiUrl: 'http://wiki.example:3000',
    );
    await tester.pumpWidget(_app(settings: settings));
    await tester.pumpAndSettle();

    // Not built until the hub is selected.
    expect(find.text('webview: http://wiki.example:3000'), findsNothing);

    await tester.tap(find.text(kPublicBuild ? 'Wiki' : 'Vault'));
    await tester.pumpAndSettle();

    expect(find.text('webview: http://wiki.example:3000'), findsOneWidget);
  });

  testWidgets('brightness flip re-delivers the mask script to an open webview',
      (tester) async {
    _desktopViewport(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final factory = _RecordingWebViewFactory();
    // _configured keeps the default themeMode 'system', so the effective
    // brightness follows platformBrightness.
    await tester.pumpWidget(
        _app(settings: _configured, webViewFactory: factory));
    await tester.pumpAndSettle();

    await tester.tap(find.text(kPublicBuild ? 'Wiki' : 'Vault'));
    await tester.pumpAndSettle();
    expect(factory.masks.last, contains('color-scheme: light'));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    // The Theme-driven rebuild handed the still-open webview a dark mask;
    // CefWebView/IosWebView re-inject it from didUpdateWidget.
    expect(factory.masks.last, contains('color-scheme: dark'));
  });

  testWidgets('first launch without credentials shows the setup wizard',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // The guided wizard replaced the blank Settings gate (t_abe366ce): the
    // three fields that matter, a real connection test, and no nav rail
    // until Proxmox is configured.
    expect(find.text('Connect your Proxmox'), findsOneWidget);
    expect(find.text('Test connection'), findsOneWidget);
    expect(find.byType(GlassNavRail), findsNothing);
  });

  testWidgets('Ollama tab lists model cards with status pills',
      (tester) async {
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    // The model library is the AI hub's Models sub-view.
    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Models'));
    await tester.pumpAndSettle();

    expect(find.text('qwen2.5:14b'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('llama3.1:8b'), findsOneWidget);
    expect(find.text('nomic-embed-text'), findsOneWidget);
    expect(find.text('Idle'), findsNWidgets(2));
    expect(find.text('9.0 GB'), findsOneWidget);
    expect(find.text('274 MB'), findsOneWidget);
    expect(find.text('LOCAL MODEL LIBRARY · 3 MODELS'), findsOneWidget);
  });

  testWidgets('Hermes tab renders the empty transcript and input bar',
      (tester) async {
    if (kPublicBuild) return; // Hermes branding + private AI-chain string are de-baked in the public build.
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    // Chat (Hermes) is the AI hub's default sub-view.
    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();

    expect(find.text('AI ASSISTANT · CLAUDE-HAIKU-4-5'), findsOneWidget);
    expect(find.text('Ask Hermes anything about your homelab…'),
        findsOneWidget);
  });

  testWidgets('Ask tab renders the empty transcript and input bar',
      (tester) async {
    if (kPublicBuild) return; // Ask tab is personal-only (not in the public build).
    _desktopViewport(tester);
    await tester.pumpWidget(_app(settings: _configured));
    await tester.pumpAndSettle();

    // Ask lives in the Vault hub beside the wiki.
    await tester.tap(find.text(kPublicBuild ? 'Wiki' : 'Vault'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR HOMELAB · CITED FROM THE VAULT'), findsOneWidget);
    expect(
        find.text('Ask your homelab — "what\'s the NAS double-hop again?"'),
        findsOneWidget);
  });

  testWidgets('locked keyring shows unlock gate, not a blank Settings screen',
      (tester) async {
    _desktopViewport(tester);
    final repo = _LockedThenOkRepository(_configured);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(repo),
          nodesProvider.overrideWith((ref) async => _fakeNodes),
          allContainersProvider.overrideWith((ref) async => _fakeContainers),
          activeAlertsProvider.overrideWith((ref) async => const []),
          recentTasksProvider.overrideWith((ref) async => const []),
          webViewFactoryProvider.overrideWithValue(_FakeWebViewFactory()),
          tailscaleStatusProvider.overrideWith((ref) async => _fakeTailscale),
          ollamaModelsProvider.overrideWith((ref) async => _fakeOllamaModels),
          ollamaRunningProvider
              .overrideWith((ref) async => _fakeOllamaRunning),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Gate is shown; the shell and the blank first-launch Settings form are not.
    expect(find.text('Keyring locked'), findsOneWidget);
    expect(find.text('Unlock & retry'), findsOneWidget);
    expect(find.byType(GlassNavRail), findsNothing);
    expect(find.text('API token ID'), findsNothing);

    // Unlock the keyring, then retry → the real shell loads.
    repo.locked = false;
    await tester.tap(find.text('Unlock & retry'));
    await tester.pumpAndSettle();

    expect(find.text('Keyring locked'), findsNothing);
    expect(find.byType(GlassNavRail), findsOneWidget);
  });
}

/// Throws [KeyringLockedException] until [locked] is cleared — models a keyring
/// that's locked at launch and readable after the user unlocks it and retries.
class _LockedThenOkRepository implements SettingsRepository {
  _LockedThenOkRepository(this._settings);

  final AppSettings _settings;
  bool locked = true;

  @override
  Future<AppSettings> load() async {
    if (locked) throw const KeyringLockedException('locked');
    return _settings;
  }

  @override
  Future<void> save(AppSettings settings) async {}
}
