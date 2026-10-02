import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/app.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/models/proxmox_container.dart';
import 'package:peira/core/models/proxmox_node.dart';
import 'package:peira/core/providers/grafana_providers.dart';
import 'package:peira/core/providers/proxmox_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/providers/tailscale_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/webview/webview_factory.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';
import 'package:peira/screens/setup/setup_probe.dart';
import 'package:peira/screens/setup/setup_wizard_screen.dart';

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

/// Serves canned bodies (or errors) per path for the probe's real Dio.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes, {this.throwType});

  final Map<String, (int, String)> routes;
  final DioExceptionType? throwType;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (throwType != null) {
      throw DioException(requestOptions: options, type: throwType!);
    }
    final (status, body) = routes[options.uri.path] ?? (501, '{"data":null}');
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<ProbeResult> _probe(HttpClientAdapter adapter) => probeProxmox(
      url: 'https://10.0.0.5:8006',
      tokenId: 'app@pve!homelab',
      tokenSecret: 'secret',
      trustSelfSigned: true,
      adapter: adapter,
    );

void main() {
  group('probeProxmox classifies outcomes', () {
    test('success reports version and node names', () async {
      final result = await _probe(_FakeAdapter({
        '/api2/json/version': (200, '{"data":{"version":"8.2.4"}}'),
        '/api2/json/nodes':
            (200, '{"data":[{"node":"pve","status":"online"}]}'),
      }));
      final success = result as ProbeSuccess;
      expect(success.version, '8.2.4');
      expect(success.nodes, ['pve']);
    });

    test('401 names the token', () async {
      final result = await _probe(
          _FakeAdapter({'/api2/json/version': (401, '{"data":null}')}));
      expect((result as ProbeFailure).message, contains('rejected the token'));
    });

    test('403 names the missing privilege', () async {
      final result = await _probe(
          _FakeAdapter({'/api2/json/version': (403, '{"data":null}')}));
      expect((result as ProbeFailure).message, contains('PVEAuditor'));
    });

    test('connection error names host and default port', () async {
      final result = await _probe(
          _FakeAdapter(const {}, throwType: DioExceptionType.connectionError));
      final message = (result as ProbeFailure).message;
      expect(message, contains('10.0.0.5'));
      expect(message, contains('8006'));
    });

    test('bad certificate points at the trust toggle', () async {
      final result = await _probe(
          _FakeAdapter(const {}, throwType: DioExceptionType.badCertificate));
      expect((result as ProbeFailure).message, contains('self-signed'));
    });
  });

  Widget app({required SetupProbe probe}) => ProviderScope(
        overrides: [
          settingsRepositoryProvider
              .overrideWithValue(_FakeSettingsRepository(const AppSettings())),
          setupProbeProvider.overrideWithValue(probe),
          // Enough for the dashboard the wizard lands on.
          nodesProvider.overrideWith((ref) async => const [
                ProxmoxNode(
                    node: 'pve',
                    status: 'online',
                    cpu: 0.05,
                    mem: 8 << 30,
                    maxmem: 16 << 30),
              ]),
          allContainersProvider.overrideWith((ref) async => const [
                ProxmoxContainer(
                    vmid: 100, status: 'running', name: 'web', node: 'pve'),
              ]),
          allVmsProvider.overrideWith((ref) async => const []),
          activeAlertsProvider.overrideWith((ref) async => const []),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider
              .overrideWith((ref) async => throw Exception('no tailscale')),
          serviceReachableProvider.overrideWith((ref, url) async => false),
          webViewFactoryProvider.overrideWithValue(_FakeWebViewFactory()),
        ],
        child: const HomeLabApp(),
      );

  Future<void> fill(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'https://10.0.0.5:8006');
    await tester.enterText(fields.at(1), 'app@pve!homelab');
    await tester.enterText(fields.at(2), 'secret');
    await tester.pump();
  }

  testWidgets('test connection surfaces success, save lands on the dashboard',
      (tester) async {
    tester.view.physicalSize = const Size(1250, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(
      probe: ({
        required url,
        required tokenId,
        required tokenSecret,
        required trustSelfSigned,
      }) async =>
          const ProbeSuccess(version: '8.2.4', nodes: ['pve']),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(SetupWizardScreen), findsOneWidget);
    // The self-signed trust default must survive (flipping it breaks the
    // default homelab path).
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await fill(tester);
    await tester.tap(find.text('Test connection'));
    await tester.pumpAndSettle();
    expect(find.textContaining('found 1 node: pve'), findsOneWidget);

    await tester.tap(find.text('Save & open dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupWizardScreen), findsNothing);
    expect(find.text('Dashboard'), findsWidgets); // rail is up
  });

  testWidgets('a failing test names the actual problem and does not navigate',
      (tester) async {
    tester.view.physicalSize = const Size(1250, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(
      probe: ({
        required url,
        required tokenId,
        required tokenSecret,
        required trustSelfSigned,
      }) async =>
          const ProbeFailure('Proxmox rejected the token. Check the token ID '
              '(user@realm!name) and the secret.'),
    ));
    await tester.pumpAndSettle();

    await fill(tester);
    await tester.tap(find.text('Test connection'));
    await tester.pumpAndSettle();
    expect(find.textContaining('rejected the token'), findsOneWidget);
    expect(find.byType(SetupWizardScreen), findsOneWidget);
  });

  testWidgets('configured settings skip the wizard entirely', (tester) async {
    tester.view.physicalSize = const Size(1250, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository(
            const AppSettings(
                proxmoxUrl: 'https://10.0.0.5:8006',
                proxmoxTokenId: 'user@pve!token',
                proxmoxTokenSecret: 'secret'))),
        nodesProvider.overrideWith((ref) async => const []),
        allContainersProvider.overrideWith((ref) async => const []),
        allVmsProvider.overrideWith((ref) async => const []),
        activeAlertsProvider.overrideWith((ref) async => const []),
        recentTasksProvider.overrideWith((ref) async => const []),
        tailscaleStatusProvider
            .overrideWith((ref) async => throw Exception('no tailscale')),
        serviceReachableProvider.overrideWith((ref, url) async => false),
        webViewFactoryProvider.overrideWithValue(_FakeWebViewFactory()),
      ],
      child: const HomeLabApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(SetupWizardScreen), findsNothing);
  });
}
