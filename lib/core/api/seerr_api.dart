import 'package:dio/dio.dart';

import 'media_dio.dart';

/// Availability per server/constants/media.ts `MediaStatus` at v3.5.1. The
/// published spec stops at 6 = DELETED; the code inserted BLOCKLISTED at 6.
String seerrMediaStatus(int? s) => switch (s) {
  2 => 'Requested',
  3 => 'Processing',
  4 => 'Partly available',
  5 => 'Available',
  6 => 'Blocklisted',
  7 => 'Deleted',
  _ => 'Not requested',
};

/// `MediaRequestStatus`: 1 pending, 2 approved, 3 declined, 4 failed,
/// 5 completed.
String seerrRequestStatus(int? s) => switch (s) {
  1 => 'Pending approval',
  2 => 'Approved',
  3 => 'Declined',
  4 => 'Failed',
  5 => 'Completed',
  _ => 'Unknown',
};

/// `IssueType` 1–4.
const seerrIssueTypes = {1: 'Video', 2: 'Audio', 3: 'Subtitles', 4: 'Other'};

/// A movie or show from search, discover or trending.
class SeerrTitle {
  const SeerrTitle({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.year,
    this.overview = '',
    this.posterPath,
    this.vote,
    this.status,
    this.mediaId,
  });

  factory SeerrTitle.fromJson(Map<String, dynamic> j) {
    final info = (j['mediaInfo'] as Map?)?.cast<String, dynamic>();
    final date = (j['releaseDate'] ?? j['firstAirDate'] ?? '') as String;
    return SeerrTitle(
      tmdbId: (j['id'] as num?)?.toInt() ?? 0,
      mediaType:
          j['mediaType'] as String? ?? (j['name'] != null ? 'tv' : 'movie'),
      title: (j['title'] ?? j['name'] ?? '') as String,
      year: date.length >= 4 ? date.substring(0, 4) : null,
      overview: j['overview'] as String? ?? '',
      posterPath: j['posterPath'] as String?,
      vote: (j['voteAverage'] as num?)?.toDouble(),
      status: (info?['status'] as num?)?.toInt(),
      mediaId: (info?['id'] as num?)?.toInt(),
    );
  }

  final int tmdbId;

  /// `movie`, `tv` or `person` (search only; not requestable).
  final String mediaType;
  final String title;
  final String? year;
  final String overview;
  final String? posterPath;
  final double? vote;

  /// MediaStatus, null when Seerr has no record yet.
  final int? status;

  /// Seerr's own media id (for status changes and removal).
  final int? mediaId;

  String? get posterUrl =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w300$posterPath';
}

class SeerrRequest {
  const SeerrRequest({
    required this.id,
    required this.status,
    required this.mediaType,
    required this.tmdbId,
    required this.requestedBy,
    this.mediaStatus,
    this.created,
    this.is4k = false,
    this.seasons = const [],
  });

  factory SeerrRequest.fromJson(Map<String, dynamic> j) {
    final media = (j['media'] as Map?)?.cast<String, dynamic>() ?? const {};
    final user = (j['requestedBy'] as Map?) ?? const {};
    return SeerrRequest(
      id: (j['id'] as num?)?.toInt() ?? 0,
      status: (j['status'] as num?)?.toInt() ?? 0,
      mediaType: (j['type'] ?? media['mediaType'] ?? 'movie') as String,
      tmdbId: (media['tmdbId'] as num?)?.toInt() ?? 0,
      mediaStatus: (media['status'] as num?)?.toInt(),
      requestedBy:
          '${user['displayName'] ?? user['username'] ?? user['email'] ?? ''}',
      created: DateTime.tryParse('${j['createdAt']}'),
      is4k: j['is4k'] == true,
      seasons: [
        for (final s in (j['seasons'] as List?) ?? const [])
          if (s is Map && s['seasonNumber'] is num)
            (s['seasonNumber'] as num).toInt(),
      ],
    );
  }

  final int id;
  final int status;
  final String mediaType;
  final int tmdbId;
  final int? mediaStatus;
  final String requestedBy;
  final DateTime? created;
  final bool is4k;
  final List<int> seasons;
}

class SeerrIssue {
  const SeerrIssue({
    required this.id,
    required this.type,
    required this.open,
    required this.mediaType,
    required this.tmdbId,
    required this.comments,
    required this.createdBy,
  });
  final int id;
  final int type;
  final bool open;
  final String mediaType;
  final int tmdbId;
  final List<({String user, String message})> comments;
  final String createdBy;
}

/// Full details for one title (`/movie/{id}`, `/tv/{id}`).
class SeerrDetails {
  const SeerrDetails(this.title, this.raw);
  final SeerrTitle title;
  final Map<String, dynamic> raw;

  /// TV only: (season number, episode count, name), specials (0) excluded.
  List<({int number, int episodes, String name})> get seasons => [
    for (final s in (raw['seasons'] as List?) ?? const [])
      if (s is Map && (s['seasonNumber'] as num? ?? 0) > 0)
        (
          number: (s['seasonNumber'] as num).toInt(),
          episodes: (s['episodeCount'] as num?)?.toInt() ?? 0,
          name: '${s['name'] ?? 'Season ${s['seasonNumber']}'}',
        ),
  ];

  String get tagline => '${raw['tagline'] ?? ''}';
  List<String> get genres => [
    for (final g in (raw['genres'] as List?) ?? const [])
      if (g is Map) '${g['name']}',
  ];
  int? get runtime => (raw['runtime'] as num?)?.toInt();
}

/// Seerr (merged Overseerr / Jellyseerr) API, spec seerr-api.yml at v3.5.1,
/// with the instance API key (`X-Api-Key`). Requests made with the key are
/// made as the key's owner (the admin) unless a userId is given.
class SeerrApi {
  SeerrApi(this._dio, this.baseUrl);

  factory SeerrApi.fromSettings({
    required String url,
    required String apiKey,
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) => SeerrApi(
    mediaDio(
      '$url/api/v1',
      headers: {'X-Api-Key': apiKey},
      trustSelfSigned: trustSelfSigned,
      adapter: adapter,
    ),
    url,
  );

  final Dio _dio;
  final String baseUrl;

  String webUrl(String mediaType, int tmdbId) => '$baseUrl/$mediaType/$tmdbId';

  Future<Map<String, dynamic>> _get(
    String p, [
    Map<String, dynamic>? q,
  ]) async =>
      (await _dio.get<Map<String, dynamic>>(p, queryParameters: q)).data ??
      const {};

  ({List<SeerrTitle> results, int pages}) _titles(Map<String, dynamic> d) => (
    results: [
      for (final r in (d['results'] as List?) ?? const [])
        if (r is Map && r['mediaType'] != 'person')
          SeerrTitle.fromJson(r.cast<String, dynamic>()),
    ],
    pages: (d['totalPages'] as num?)?.toInt() ?? 1,
  );

  Future<({List<SeerrTitle> results, int pages})> search(
    String query, {
    int page = 1,
  }) async => _titles(await _get('/search', {'query': query, 'page': page}));

  /// [kind]: `trending`, `movies`, `tv`, `upcoming` (movies) or
  /// `watchlist`.
  Future<({List<SeerrTitle> results, int pages})> discover(
    String kind, {
    int page = 1,
  }) async => _titles(
    await _get(
      switch (kind) {
        'movies' => '/discover/movies',
        'tv' => '/discover/tv',
        'upcoming' => '/discover/movies/upcoming',
        'watchlist' => '/discover/watchlist',
        _ => '/discover/trending',
      },
      {'page': page},
    ),
  );

  Future<SeerrDetails> details(String mediaType, int tmdbId) async {
    final d = await _get('/${mediaType == 'tv' ? 'tv' : 'movie'}/$tmdbId');
    return SeerrDetails(SeerrTitle.fromJson({...d, 'mediaType': mediaType}), d);
  }

  /// Requests a movie, or the given TV [seasons] (all when empty).
  Future<void> request(
    String mediaType,
    int tmdbId, {
    List<int> seasons = const [],
    bool is4k = false,
  }) => _dio.post<void>(
    '/request',
    data: {
      'mediaType': mediaType,
      'mediaId': tmdbId,
      if (mediaType == 'tv') 'seasons': seasons.isEmpty ? 'all' : seasons,
      'is4k': is4k,
    },
  );

  /// [filter] from the spec's enum: all, approved, available, pending,
  /// processing, unavailable, failed, deleted, completed.
  Future<({List<SeerrRequest> requests, int total})> requests({
    String filter = 'all',
    int skip = 0,
  }) async {
    final d = await _get('/request', {
      'take': 50,
      'skip': skip,
      'filter': filter,
      'sort': 'added',
      'sortDirection': 'desc',
    });
    return (
      requests: [
        for (final r in (d['results'] as List?) ?? const [])
          if (r is Map) SeerrRequest.fromJson(r.cast<String, dynamic>()),
      ],
      total: ((d['pageInfo'] as Map?)?['results'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Map<String, dynamic>> requestCounts() => _get('/request/count');

  /// [action]: `approve` or `decline`.
  Future<void> setRequest(int id, String action) =>
      _dio.post<void>('/request/$id/$action');

  Future<void> retryRequest(int id) => _dio.post<void>('/request/$id/retry');

  Future<void> deleteRequest(int id) => _dio.delete<void>('/request/$id');

  /// Marks media `available` or another MediaStatus name.
  Future<void> setMediaStatus(int mediaId, String status) =>
      _dio.post<void>('/media/$mediaId/$status', data: {'is4k': false});

  /// Removes Seerr's record (and its requests) for the media; the files in
  /// Radarr/Sonarr stay.
  Future<void> deleteMedia(int mediaId) => _dio.delete<void>('/media/$mediaId');

  Future<List<SeerrIssue>> issues({String filter = 'open'}) async {
    final d = await _get('/issue', {
      'take': 50,
      'skip': 0,
      'filter': filter,
      'sort': 'added',
    });
    return [
      for (final r in (d['results'] as List?) ?? const [])
        if (r is Map)
          SeerrIssue(
            id: (r['id'] as num?)?.toInt() ?? 0,
            type: (r['issueType'] as num?)?.toInt() ?? 4,
            open: (r['status'] as num?)?.toInt() != 2,
            mediaType: '${(r['media'] as Map?)?['mediaType'] ?? 'movie'}',
            tmdbId: ((r['media'] as Map?)?['tmdbId'] as num?)?.toInt() ?? 0,
            createdBy:
                '${(r['createdBy'] as Map?)?['displayName'] ?? (r['createdBy'] as Map?)?['email'] ?? ''}',
            comments: [
              for (final c in (r['comments'] as List?) ?? const [])
                if (c is Map)
                  (
                    user: '${(c['user'] as Map?)?['displayName'] ?? ''}',
                    message: '${c['message'] ?? ''}',
                  ),
            ],
          ),
    ];
  }

  Future<void> reportIssue(int mediaId, int type, String message) =>
      _dio.post<void>(
        '/issue',
        data: {'issueType': type, 'message': message, 'mediaId': mediaId},
      );

  Future<void> commentIssue(int id, String message) =>
      _dio.post<void>('/issue/$id/comment', data: {'message': message});

  /// [status]: `open` or `resolved`.
  Future<void> setIssue(int id, String status) =>
      _dio.post<void>('/issue/$id/$status');

  Future<void> deleteIssue(int id) => _dio.delete<void>('/issue/$id');

  Future<Map<String, dynamic>> status() => _get('/status');
  Future<Map<String, dynamic>> about() => _get('/settings/about');

  Future<List<({String id, String name, bool running, DateTime? next})>>
  jobs() async => [
    for (final j
        in (await _dio.get<List<dynamic>>('/settings/jobs')).data ?? const [])
      if (j is Map)
        (
          id: '${j['id']}',
          name: '${j['name']}',
          running: j['running'] == true,
          next: DateTime.tryParse('${j['nextExecutionTime']}'),
        ),
  ];

  Future<void> runJob(String id) => _dio.post<void>('/settings/jobs/$id/run');
}
