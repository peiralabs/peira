import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/home_assistant_api.dart';

/// Serves canned JSON per "METHOD path" (404 for unrouted) and records every
/// request with its decoded body.
class _RouteAdapter implements HttpClientAdapter {
  _RouteAdapter(this.routes);

  final Map<String, String> routes;
  final requests = <RequestOptions>[];
  final bodies = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      final bytes = await requestStream.expand((c) => c).toList();
      bodies.add(bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes)));
    } else {
      bodies.add(null);
    }
    final body = routes['${options.method} ${options.path}'];
    return ResponseBody.fromString(
      body ?? '{}',
      body == null ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

HomeAssistantApi _api(_RouteAdapter a) => HomeAssistantApi.fromSettings(
  url: 'http://ha.example:8123',
  token: 'tok',
  adapter: a,
);

void main() {
  test('states parse, sort by entity id, and send the bearer token', () async {
    final a = _RouteAdapter({
      'GET /api/states': jsonEncode([
        {
          'entity_id': 'switch.lamp',
          'state': 'on',
          'attributes': {'friendly_name': 'Lamp'},
          'last_changed': '2026-10-28T10:00:00+00:00',
        },
        {
          'entity_id': 'media_player.tv',
          'state': 'off',
          'attributes': {'supported_features': 152461},
        },
      ]),
    });
    final states = await _api(a).states();
    expect(states.map((e) => e.entityId), ['media_player.tv', 'switch.lamp']);
    expect(states.last.name, 'Lamp');
    expect(states.first.name, 'media_player.tv', reason: 'falls back to id');
    expect(states.first.supports(256), isTrue);
    expect(states.first.supports(32), isFalse);
    expect(a.requests.single.headers['Authorization'], 'Bearer tok');
  });

  test(
    'callService posts the data and asks for a response on demand',
    () async {
      final a = _RouteAdapter({
        'POST /api/services/light/turn_on': '[]',
        'POST /api/services/todo/get_items?return_response': jsonEncode({
          'changed_states': [],
          'service_response': {
            'todo.shopping': {
              'items': [
                {'uid': 'u1', 'summary': 'Milk', 'status': 'needs_action'},
                {'uid': 'u2', 'summary': 'Eggs', 'status': 'completed'},
              ],
            },
          },
        }),
      });
      final api = _api(a);
      final res = await api.callService(
        'light',
        'turn_on',
        data: {'entity_id': 'light.desk', 'brightness_pct': 40},
      );
      expect(res, {'changed_states': []});
      expect(a.bodies.first, {'entity_id': 'light.desk', 'brightness_pct': 40});

      final items = await api.todoItems('todo.shopping');
      expect(items.map((i) => (i.summary, i.done)), [
        ('Milk', false),
        ('Eggs', true),
      ]);
      expect(a.bodies.last, {'entity_id': 'todo.shopping'});
    },
  );

  test('services flatten per domain with fields and examples', () async {
    final a = _RouteAdapter({
      'GET /api/services': jsonEncode([
        {
          'domain': 'light',
          'services': {
            'turn_on': {
              'name': 'Turn on',
              'description': 'Turns on a light.',
              'fields': {
                'brightness_pct': {'example': 47},
              },
            },
          },
        },
        {
          'domain': 'automation',
          'services': {'trigger': {}},
        },
      ]),
    });
    final services = await _api(a).services();
    expect(services.map((s) => s.id), ['automation.trigger', 'light.turn_on']);
    expect(services.last.fields['brightness_pct']?['example'], 47);
    expect(services.first.name, 'trigger');
  });

  test('logbook is newest first; history takes the first series', () async {
    final a = _RouteAdapter({});
    a.routes.addAll({
      for (final m in ['GET'])
        '$m /api/logbook/2026-10-28T00:00:00.000Z': jsonEncode([
          {'name': 'Lamp', 'when': '2026-10-28T01:00:00+00:00', 'state': 'on'},
          {'name': 'Lamp', 'when': '2026-10-28T03:00:00+00:00', 'state': 'off'},
        ]),
      'GET /api/history/period/2026-10-28T00:00:00.000Z': jsonEncode([
        [
          {'state': '20.5', 'last_changed': '2026-10-28T01:00:00+00:00'},
          {'state': '21', 'last_changed': '2026-10-28T02:00:00+00:00'},
        ],
      ]),
    });
    final since = DateTime.utc(2026, 10, 28);
    final api = _api(a);
    final log = await api.logbook(since: since);
    expect(log.map((e) => e.state), ['off', 'on']);
    final hist = await api.history('sensor.t', since: since);
    expect(hist.map((p) => p.state), ['20.5', '21']);
    expect(a.requests.last.queryParameters['filter_entity_id'], 'sensor.t');
  });
}
