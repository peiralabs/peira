import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/jellyfin_api.dart';

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

const _info = '{"ServerName":"media-server","Version":"10.10.3"}';

const _sessions = '''
[
  {"UserName":"living-room",
   "NowPlayingItem":{"Name":"Cold Harbor","SeriesName":"Severance",
                     "RunTimeTicks":72000000000},
   "PlayState":{"IsPaused":true,"PositionTicks":18000000000}},
  {"UserName":"idle-tablet"}
]''';

const _counts =
    '{"MovieCount":412,"SeriesCount":58,"EpisodeCount":3210,"SongCount":0}';

const _items = '''
{"Items":[
  {"Name":"Dune: Part Two","ProductionYear":2024},
  {"Name":"Cold Harbor","SeriesName":"Severance"}
]}''';

const _endpoint = 'http://10.0.0.10:8096';

void main() {
  test('parses identity, sessions, counts, and recent with API-key auth',
      () async {
    final adapter = _RouteAdapter({
      '/System/Info': _info,
      '/Sessions': _sessions,
      '/Items/Counts': _counts,
      '/Items': _items,
    });
    final status =
        await JellyfinApi(_endpoint, 'jf-key', adapter: adapter).getStatus();

    expect(status.serverName, 'media-server');
    expect(status.version, '10.10.3');

    // The idle session (no NowPlayingItem) is filtered out.
    expect(status.sessions, hasLength(1));
    final s = status.sessions.single;
    expect(s.user, 'living-room');
    expect(s.title, 'Cold Harbor');
    expect(s.subtitle, 'Severance');
    expect(s.paused, isTrue);
    expect(s.progress, closeTo(0.25, 1e-9));

    // SongCount 0 drops the Songs entry.
    expect(
      [for (final l in status.libraries) (l.name, l.count)],
      [('Movies', 412), ('Shows', 58), ('Episodes', 3210)],
    );

    expect(
      [for (final r in status.recent) (r.title, r.subtitle)],
      [('Dune: Part Two', '2024'), ('Cold Harbor', 'Severance')],
    );

    for (final r in adapter.requests) {
      expect(r.headers['X-Emby-Token'], 'jf-key', reason: r.path);
    }
  });

  test('a server that refuses /Items still reports the rest', () async {
    final adapter = _RouteAdapter({
      '/System/Info': _info,
      '/Sessions': '[]',
      '/Items/Counts': _counts,
      // No /Items route: the recently-added probe 404s.
    });
    final status =
        await JellyfinApi(_endpoint, 'jf-key', adapter: adapter).getStatus();
    expect(status.serverName, 'media-server');
    expect(status.recent, isEmpty);
    expect(status.libraries, isNotEmpty);
  });
}
