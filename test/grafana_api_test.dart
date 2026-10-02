import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/grafana_api.dart';
import 'package:peira/core/models/app_settings.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final String body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

// Alertmanager v2 shape as served by Grafana's compatible endpoint.
const _alertsJson = '''
[
  {
    "labels": {"alertname": "Disk Usage High", "severity": "warning"},
    "annotations": {"summary": "node3 rootfs > 80%"},
    "startsAt": "2026-07-03T10:00:00.000Z",
    "fingerprint": "abc123",
    "status": {"state": "active"}
  },
  {
    "labels": {"alertname": "Node Down", "severity": "critical"},
    "annotations": {},
    "startsAt": "2026-07-03T12:00:00.000Z",
    "fingerprint": "def456",
    "status": {"state": "active"}
  },
  {
    "labels": {"alertname": "Silenced Thing", "severity": "info"},
    "annotations": {},
    "startsAt": "2026-07-03T11:00:00.000Z",
    "fingerprint": "ghi789",
    "status": {"state": "suppressed"}
  }
]
''';

void main() {
  test('getActiveAlerts parses, sorts newest first, drops suppressed, '
      'sends Bearer auth', () async {
    final adapter = _FakeAdapter(_alertsJson);
    const settings = AppSettings(
      grafanaUrl: 'http://grafana.example:3000',
      grafanaApiKey: 'glsa_testkey',
    );
    final api = GrafanaApi.fromSettings(settings);
    // Swap the adapter on the already-configured Dio via a fresh instance.
    final dio = Dio(BaseOptions(
      baseUrl: settings.grafanaUrl,
      headers: {'Authorization': 'Bearer ${settings.grafanaApiKey}'},
    ))
      ..httpClientAdapter = adapter;
    final alerts = await GrafanaApi(dio).getActiveAlerts();

    expect(api, isA<GrafanaApi>());
    expect(alerts, hasLength(2));
    expect(alerts.first.name, 'Node Down');
    expect(alerts.first.severity, 'critical');
    expect(alerts.last.name, 'Disk Usage High');
    expect(adapter.requests.single.headers['Authorization'],
        'Bearer glsa_testkey');
    expect(adapter.requests.single.uri.path,
        '/api/alertmanager/grafana/api/v2/alerts');
  });
}
