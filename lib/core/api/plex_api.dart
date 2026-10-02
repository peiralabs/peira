import 'package:dio/dio.dart';

import '../models/app_settings.dart';
import '../models/media_server_status.dart';
import 'media_dio.dart';

/// Plex REST client (`X-Plex-Token` auth, JSON via the Accept header —
/// every response arrives wrapped in a `MediaContainer`): server identity,
/// active sessions, per-section library counts, and recently added titles.
class PlexApi {
  PlexApi(
    String url,
    String token, {
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) : _dio = mediaDio(
          url,
          headers: {'X-Plex-Token': token, 'Accept': 'application/json'},
          trustSelfSigned: trustSelfSigned,
          adapter: adapter,
        );

  factory PlexApi.fromSettings(AppSettings s) => PlexApi(
        s.plexUrl,
        s.plexToken,
        trustSelfSigned: s.trustSelfSigned,
      );

  final Dio _dio;

  Future<Map<String, dynamic>> _container(String path,
      [Map<String, dynamic>? query]) async {
    final res =
        await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
    return (res.data?['MediaContainer'] as Map?)?.cast<String, dynamic>() ??
        const {};
  }

  Future<MediaServerStatus> getStatus() async {
    final root = await _container('/');
    final sessions = ((await _container('/status/sessions'))['Metadata']
                as List? ??
            const [])
        .cast<Map<String, dynamic>>();
    final sections = ((await _container('/library/sections'))['Directory']
                as List? ??
            const [])
        .cast<Map<String, dynamic>>();

    // One zero-size page per section buys its totalSize — cheap, and a
    // section that errors still lists (count 0) rather than vanishing.
    final libraries = <MediaLibrary>[];
    for (final d in sections) {
      var count = 0;
      try {
        final page = await _container(
          '/library/sections/${d['key']}/all',
          {'X-Plex-Container-Start': 0, 'X-Plex-Container-Size': 0},
        );
        count = ((page['totalSize'] as num?) ?? 0).toInt();
      } on DioException {
        // Keep the section with an unknown (0) count.
      }
      libraries.add(MediaLibrary(name: '${d['title'] ?? ''}', count: count));
    }

    // Best-effort, like the Jellyfin recently-added panel.
    var recent = const <Map<String, dynamic>>[];
    try {
      recent = ((await _container('/library/recentlyAdded'))['Metadata']
                  as List? ??
              const [])
          .cast<Map<String, dynamic>>();
    } on DioException {
      // Leave the panel empty.
    }

    return MediaServerStatus(
      serverName: '${root['friendlyName'] ?? 'Plex'}',
      version: '${root['version'] ?? ''}',
      sessions: [for (final s in sessions) _session(s)],
      libraries: libraries,
      recent: [
        for (final r in recent.take(8))
          MediaRecentItem(
            title: '${r['title'] ?? ''}',
            subtitle: '${r['grandparentTitle'] ?? r['parentTitle'] ?? r['year'] ?? ''}',
          ),
      ],
    );
  }

  static MediaSession _session(Map<String, dynamic> s) {
    final user = (s['User'] as Map?)?.cast<String, dynamic>() ?? const {};
    final player = (s['Player'] as Map?)?.cast<String, dynamic>() ?? const {};
    final duration = (s['duration'] as num?) ?? 0;
    final offset = (s['viewOffset'] as num?) ?? 0;
    final series = '${s['grandparentTitle'] ?? ''}';
    return MediaSession(
      user: '${user['title'] ?? ''}',
      title: '${s['title'] ?? ''}',
      subtitle: series.isNotEmpty ? series : '${s['year'] ?? ''}',
      paused: player['state'] == 'paused',
      progress:
          duration > 0 ? (offset / duration).clamp(0.0, 1.0).toDouble() : 0,
    );
  }
}
