import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/plex_api.dart';

/// Serves canned JSON per path (404 for unrouted paths) and records every
/// request so headers can be asserted.
class _RouteAdapter implements HttpClientAdapter {
  _RouteAdapter(this.routes);

  final Map<String, String> routes;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final body = routes[options.path];
    return ResponseBody.fromString(body ?? '{}', body == null ? 404 : 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
  }

  @override
  void close({bool force = false}) {}
}

const _root =
    '{"MediaContainer":{"friendlyName":"den-plex","version":"1.41.0"}}';

const _sessions = '''
{"MediaContainer":{"size":1,"Metadata":[
  {"title":"Heat","year":1995,"duration":10000,"viewOffset":2500,
   "User":{"title":"den"},"Player":{"state":"paused"}}
]}}''';

const _sections = '''
{"MediaContainer":{"Directory":[
  {"key":"1","title":"Movies","type":"movie"},
  {"key":"2","title":"TV Shows","type":"show"}
]}}''';

const _recent = '''
{"MediaContainer":{"Metadata":[
  {"title":"Slow Horses","parentTitle":"Season 4"},
  {"title":"Heat 2","year":2026}
]}}''';

const _endpoint = 'http://10.0.0.10:32400';

void main() {
  test('unwraps MediaContainer for identity, sessions, counts, and recent',
      () async {
    final adapter = _RouteAdapter({
      '/': _root,
      '/status/sessions': _sessions,
      '/library/sections': _sections,
      '/library/sections/1/all': '{"MediaContainer":{"totalSize":412}}',
      '/library/sections/2/all': '{"MediaContainer":{"totalSize":58}}',
      '/library/recentlyAdded': _recent,
    });
    final status =
        await PlexApi(_endpoint, 'plex-token', adapter: adapter).getStatus();

    expect(status.serverName, 'den-plex');
    expect(status.version, '1.41.0');

    final s = status.sessions.single;
    expect(s.user, 'den');
    expect(s.title, 'Heat');
    expect(s.subtitle, '1995');
    expect(s.paused, isTrue);
    expect(s.progress, closeTo(0.25, 1e-9));

    expect(
      [for (final l in status.libraries) (l.name, l.count)],
      [('Movies', 412), ('TV Shows', 58)],
    );

    expect(
      [for (final r in status.recent) (r.title, r.subtitle)],
      [('Slow Horses', 'Season 4'), ('Heat 2', '2026')],
    );

    for (final r in adapter.requests) {
      expect(r.headers['X-Plex-Token'], 'plex-token', reason: r.path);
      expect(r.headers['Accept'], 'application/json', reason: r.path);
    }
  });

  test('a section whose count probe fails still lists with count 0', () async {
    final adapter = _RouteAdapter({
      '/': _root,
      '/status/sessions': '{"MediaContainer":{}}',
      '/library/sections': _sections,
      '/library/sections/1/all': '{"MediaContainer":{"totalSize":412}}',
      // Section 2's /all probe 404s.
      '/library/recentlyAdded': '{"MediaContainer":{}}',
    });
    final status =
        await PlexApi(_endpoint, 'plex-token', adapter: adapter).getStatus();
    expect(
      [for (final l in status.libraries) (l.name, l.count)],
      [('Movies', 412), ('TV Shows', 0)],
    );
    expect(status.sessions, isEmpty);
    expect(status.recent, isEmpty);
  });
}
