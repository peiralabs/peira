import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/app.dart';
import 'package:peira/core/api/proxmox_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/models/proxmox_container.dart';
import 'package:peira/core/models/proxmox_node.dart';
import 'package:peira/core/providers/grafana_providers.dart';
import 'package:peira/core/providers/ollama_providers.dart';
import 'package:peira/core/providers/proxmox_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/providers/tailscale_providers.dart';
import 'package:peira/core/providers/terminal_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/webview/webview_factory.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';
import 'package:peira/screens/hermes/hermes_screen.dart';

// Most homelabs run ONE Proxmox node (card t_ec2d8eeb): standalone, no
// Prometheus, no Ollama, no arr stack, no Wiki.js, no Tailscale. The app must
// render a coherent picture there — honest empty states, no stack traces —
// and the terminal must not lose its Nodes section just because a standalone
// `/cluster/status` carries no `ip` field.

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

class _FakeWebViewFactory implements WebViewFactory {
  @override
  Widget build(String url,
          {String? maskScript, bool controls = false, String? controlsLabel}) =>
      Center(child: Text('webview: $url'));
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, String> routes;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final body = routes[options.uri.path];
    if (body == null) {
      return ResponseBody.fromString('{"data":null}', 501);
    }
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _settings = AppSettings(
  proxmoxUrl: 'https://10.0.0.5:8006',
  proxmoxTokenId: 'user@pve!token',
  proxmoxTokenSecret: 'secret',
);

const _soleNode = [
  ProxmoxNode(
      node: 'pve', status: 'online', cpu: 0.05, mem: 8 << 30, maxmem: 16 << 30),
];

const _soleCt = [
  ProxmoxContainer(
      vmid: 100,
      status: 'running',
      name: 'jellyfin',
      node: 'pve',
      mem: 2 << 30,
      maxmem: 4 << 30),
];

ProxmoxApi _api(Map<String, String> routes) => ProxmoxApi(Dio(BaseOptions(
      baseUrl: '${_settings.proxmoxUrl}/api2/json',
    ))
      ..httpClientAdapter = _FakeAdapter(routes));

ProviderContainer _container(ProxmoxApi api,
    {List<ProxmoxNode> nodes = _soleNode, AppSettings settings = _settings}) {
  final container = ProviderContainer(overrides: [
    settingsRepositoryProvider
        .overrideWithValue(_FakeSettingsRepository(settings)),
    proxmoxApiProvider.overrideWith((ref) => api),
    nodesProvider.overrideWith((ref) async => nodes),
    allContainersProvider.overrideWith((ref) async => _soleCt),
  ]);
  addTearDown(container.dispose);
  // Hold a listener like the terminal screen does — an unlistened autoDispose
  // provider can be reclaimed between the body's awaits, which surfaces as a
  // mid-body throw into the provider's own catch.
  container.listen(sshTargetsProvider, (_, _) {});
  return container;
}

void main() {
  group('terminal targets on a standalone node', () {
    test('no ip in /cluster/status → falls back to the configured host',
        () async {
      final api = _api({
        '/api2/json/cluster/status':
            '{"data":[{"type":"node","name":"pve","id":"node/pve",'
                '"online":1,"local":1,"level":"","nodeid":0}]}',
      });
      final targets =
          await _container(api).read(sshTargetsProvider.future);
      final node = targets.singleWhere((t) => t.group == 'Nodes');
      expect(node.args, ['--', 'root@10.0.0.5']);
      final ct = targets.singleWhere((t) => t.group == 'Containers');
      expect(ct.args, ['-t', '--', 'root@10.0.0.5', 'pct', 'enter', '100']);
    });

    test('/cluster/status erroring entirely still yields the sole node',
        () async {
      final targets = await _container(_api({}))
          .read(sshTargetsProvider.future); // 501 on every route
      expect(targets.where((t) => t.group == 'Nodes'), hasLength(1));
      expect(targets.singleWhere((t) => t.group == 'Nodes').args,
          ['--', 'root@10.0.0.5']);
    });

    test('ip present → used as before, no fallback needed', () async {
      final api = _api({
        '/api2/json/cluster/status':
            '{"data":[{"type":"node","name":"pve","id":"node/pve",'
                '"online":1,"local":1,"ip":"10.0.0.99","nodeid":0}]}',
      });
      final targets =
          await _container(api).read(sshTargetsProvider.future);
      expect(targets.singleWhere((t) => t.group == 'Nodes').args,
          ['--', 'root@10.0.0.99']);
    });

    test('custom SSH username applies to nodes and sudo-wraps pct enter',
        () async {
      final api = _api({
        '/api2/json/cluster/status':
            '{"data":[{"type":"node","name":"pve","id":"node/pve",'
                '"online":1,"local":1,"ip":"10.0.0.99","nodeid":0}]}',
      });
      final targets = await _container(api,
              settings: _settings.copyWith(sshUsername: 'admin'))
          .read(sshTargetsProvider.future);
      expect(targets.singleWhere((t) => t.group == 'Nodes').args,
          ['--', 'admin@10.0.0.99']);
      // pct needs root on the node — a non-root user goes through sudo.
      expect(targets.singleWhere((t) => t.group == 'Containers').args,
          ['-t', '--', 'admin@10.0.0.99', 'sudo', 'pct', 'enter', '100']);
    });

    test('multi-node cluster with missing ips does NOT guess addresses',
        () async {
      const twoNodes = [
        ProxmoxNode(node: 'pve1', status: 'online', cpu: 0, mem: 0, maxmem: 1),
        ProxmoxNode(node: 'pve2', status: 'online', cpu: 0, mem: 0, maxmem: 1),
      ];
      final targets = await _container(_api({}), nodes: twoNodes)
          .read(sshTargetsProvider.future);
      // The configured host is only known to be node 1's address when there
      // IS only one node — two nodes with unknown ips get no entries at all.
      expect(targets.where((t) => t.group == 'Nodes'), isEmpty);
      expect(targets.where((t) => t.group == 'Containers'), isEmpty);
    });
  });

  testWidgets(
      'single node with nothing else installed renders honest states on every tab',
      (tester) async {
    // Desktop-shaped viewport (the window's real minimum is 1100×700; the
    // 800×600 test default is a size the desktop app can never reach, and
    // the Proxmox header's trailing buttons overflow there under the
    // harness's wide fallback font — recorded on the card, owned by the
    // iOS/narrow-width polish track).
    tester.view.physicalSize = const Size(1250, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        settingsRepositoryProvider
            .overrideWithValue(_FakeSettingsRepository(_settings)),
        // Only Proxmox exists in this lab.
        nodesProvider.overrideWith((ref) async => _soleNode),
        allContainersProvider.overrideWith((ref) async => _soleCt),
        allVmsProvider.overrideWith((ref) async => const []),
        recentTasksProvider.overrideWith((ref) async => const []),
        // Everything optional is absent — providers error like they would
        // against a machine that has never heard of these services.
        serviceReachableProvider.overrideWith((ref, url) async => false),
        activeAlertsProvider
            .overrideWith((ref) async => throw Exception('no grafana')),
        tailscaleStatusProvider
            .overrideWith((ref) async => throw Exception('no tailscale CLI')),
        ollamaModelsProvider
            .overrideWith((ref) async => throw Exception('no ollama')),
        ollamaRunningProvider
            .overrideWith((ref) async => throw Exception('no ollama')),
        webViewFactoryProvider.overrideWithValue(_FakeWebViewFactory()),
      ],
      child: const HomeLabApp(),
    ));
    await tester.pumpAndSettle();

    // Dashboard: the sole node renders, nothing crashes.
    expect(find.text('pve'), findsWidgets);
    expect(tester.takeException(), isNull);

    Future<void> visit(String tab) async {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'exception on $tab');
    }

    await visit('Proxmox');
    expect(find.text('pve'), findsWidgets);

    await visit('Metrics');
    expect(find.textContaining('Prometheus is not configured'), findsWidgets);

    // The Metrics hub's other sub-views degrade honestly too: no Loki URL,
    // no changedetection URL — hints, not stack traces.
    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'exception on Logs');
    expect(find.textContaining('Loki has no URL yet'), findsOneWidget);
    await tester.tap(find.text('Watches'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'exception on Watches');
    expect(
      find.textContaining('changedetection.io has no URL yet'),
      findsOneWidget,
    );

    await visit('AI');
    // The idle chat is an invite; sending without an endpoint must answer
    // with the configure prompt as a chat turn, not a stack trace.
    final chatField = find.descendant(
        of: find.byType(HermesScreen), matching: find.byType(TextField));
    await tester.tap(chatField);
    await tester.enterText(chatField, 'hello');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'exception on AI send');
    expect(find.textContaining('not configured yet'), findsWidgets);

    await visit('Media');
    expect(find.textContaining('not configured'), findsWidgets);

    await visit('Library');
    expect(find.textContaining('Karakeep has no URL yet'), findsOneWidget);

    await visit('Tailscale');

    await visit('Dashboard');
  });
}
