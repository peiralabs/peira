import 'package:dio/dio.dart';

import '../models/app_settings.dart';
import '../models/media_server_status.dart';
import 'media_dio.dart';

/// Jellyfin REST client (`X-Emby-Token` API-key auth): server identity,
/// active sessions, global item counts, and recently added titles — the
/// status-panel depth the Media tab needs, not a full library browser.
class JellyfinApi {
  JellyfinApi(
    String url,
    String apiKey, {
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) : _dio = mediaDio(
          url,
          headers: {'X-Emby-Token': apiKey},
          trustSelfSigned: trustSelfSigned,
          adapter: adapter,
        );

  factory JellyfinApi.fromSettings(AppSettings s) => JellyfinApi(
        s.jellyfinUrl,
        s.jellyfinApiKey,
        trustSelfSigned: s.trustSelfSigned,
      );

  final Dio _dio;

  Future<MediaServerStatus> getStatus() async {
    final info =
        (await _dio.get<Map<String, dynamic>>('/System/Info')).data ??
            const {};
    final sessions =
        (await _dio.get<List<dynamic>>('/Sessions')).data ?? const [];
    final counts =
        (await _dio.get<Map<String, dynamic>>('/Items/Counts')).data ??
            const {};

    // Recently added is best-effort: /Items with API-key (admin) auth works
    // on current servers, but older ones insist on a userId — the panel is
    // optional, the rest of the status is not.
    var recent = const <Map<String, dynamic>>[];
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/Items',
        queryParameters: {
          'SortBy': 'DateCreated',
          'SortOrder': 'Descending',
          'Recursive': true,
          'IncludeItemTypes': 'Movie,Series',
          'Limit': 8,
        },
      );
      recent =
          ((res.data?['Items'] as List?) ?? const []).cast<Map<String, dynamic>>();
    } on DioException {
      // Leave the panel empty.
    }

    return MediaServerStatus(
      serverName: '${info['ServerName'] ?? 'Jellyfin'}',
      version: '${info['Version'] ?? ''}',
      sessions: [
        for (final s in sessions.cast<Map<String, dynamic>>())
          if (s['NowPlayingItem'] != null) _session(s),
      ],
      libraries: [
        for (final (name, key) in const [
          ('Movies', 'MovieCount'),
          ('Shows', 'SeriesCount'),
          ('Episodes', 'EpisodeCount'),
          ('Songs', 'SongCount'),
        ])
          if (counts[key] is num && (name != 'Songs' || (counts[key] as num) > 0))
            MediaLibrary(name: name, count: (counts[key] as num).toInt()),
      ],
      recent: [
        for (final r in recent)
          MediaRecentItem(
            title: '${r['Name'] ?? ''}',
            subtitle: '${r['SeriesName'] ?? r['ProductionYear'] ?? ''}',
          ),
      ],
    );
  }

  static MediaSession _session(Map<String, dynamic> s) {
    final item =
        (s['NowPlayingItem'] as Map?)?.cast<String, dynamic>() ?? const {};
    final play = (s['PlayState'] as Map?)?.cast<String, dynamic>() ?? const {};
    final runtime = (item['RunTimeTicks'] as num?) ?? 0;
    final position = (play['PositionTicks'] as num?) ?? 0;
    final series = '${item['SeriesName'] ?? ''}';
    return MediaSession(
      user: '${s['UserName'] ?? ''}',
      title: '${item['Name'] ?? ''}',
      subtitle: series.isNotEmpty ? series : '${item['ProductionYear'] ?? ''}',
      paused: play['IsPaused'] == true,
      progress:
          runtime > 0 ? (position / runtime).clamp(0.0, 1.0).toDouble() : 0,
    );
  }
}
