import 'package:dio/dio.dart';

import 'media_dio.dart';

/// One photo or video (`AssetResponseDto`).
class ImmichAsset {
  const ImmichAsset({
    required this.id,
    required this.type,
    required this.fileName,
    required this.isFavorite,
    required this.visibility,
    this.taken,
    this.exif = const {},
    this.people = const [],
  });

  factory ImmichAsset.fromJson(Map<String, dynamic> j) => ImmichAsset(
    id: j['id'] as String? ?? '',
    type: j['type'] as String? ?? 'IMAGE',
    fileName: j['originalFileName'] as String? ?? '',
    isFavorite: j['isFavorite'] == true,
    visibility: j['visibility'] as String? ?? 'timeline',
    taken: DateTime.tryParse(
      j['localDateTime'] as String? ?? j['fileCreatedAt'] as String? ?? '',
    ),
    exif: (j['exifInfo'] as Map?)?.cast<String, dynamic>() ?? const {},
    people: [
      for (final p in (j['people'] as List?) ?? const [])
        if (p is Map && (p['name'] as String? ?? '').isNotEmpty)
          p['name'] as String,
    ],
  );

  final String id;

  /// `IMAGE`, `VIDEO`, `AUDIO` or `OTHER`.
  final String type;
  final String fileName;
  final bool isFavorite;

  /// `timeline`, `archive`, `hidden` or `locked`.
  final String visibility;
  final DateTime? taken;
  final Map<String, dynamic> exif;
  final List<String> people;

  bool get isVideo => type == 'VIDEO';
}

class ImmichAssetPage {
  const ImmichAssetPage(this.assets, this.nextPage);
  final List<ImmichAsset> assets;

  /// Null on the last page.
  final int? nextPage;
}

class ImmichAlbum {
  const ImmichAlbum({
    required this.id,
    required this.name,
    required this.description,
    required this.assetCount,
    this.thumbnailAssetId,
  });

  /// Immich 3 albums carry no asset list; read it with
  /// [ImmichApi.albumAssets].
  factory ImmichAlbum.fromJson(Map<String, dynamic> j) => ImmichAlbum(
    id: j['id'] as String? ?? '',
    name: j['albumName'] as String? ?? '',
    description: j['description'] as String? ?? '',
    assetCount: (j['assetCount'] as num?)?.toInt() ?? 0,
    thumbnailAssetId: j['albumThumbnailAssetId'] as String?,
  );

  final String id;
  final String name;
  final String description;
  final int assetCount;
  final String? thumbnailAssetId;
}

class ImmichPerson {
  const ImmichPerson({
    required this.id,
    required this.name,
    required this.isHidden,
    required this.isFavorite,
  });

  factory ImmichPerson.fromJson(Map<String, dynamic> j) => ImmichPerson(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    isHidden: j['isHidden'] == true,
    isFavorite: j['isFavorite'] == true,
  );

  final String id;
  final String name;
  final bool isHidden;
  final bool isFavorite;
}

class ImmichMemory {
  const ImmichMemory(this.id, this.year, this.assets);
  final String id;
  final int? year;
  final List<ImmichAsset> assets;
}

class ImmichDuplicateGroup {
  const ImmichDuplicateGroup(this.id, this.assets, this.keepIds);
  final String id;
  final List<ImmichAsset> assets;
  final Set<String> keepIds;
}

/// One background job queue (`/queues`).
class ImmichQueue {
  const ImmichQueue(this.name, this.isPaused, this.counts);
  final String name;
  final bool isPaused;

  /// active, completed, failed, delayed, waiting, paused.
  final Map<String, int> counts;
}

class ImmichServer {
  const ImmichServer({
    required this.version,
    required this.photos,
    required this.videos,
    required this.usageBytes,
    required this.diskSize,
    required this.diskUse,
    required this.diskPercent,
    required this.features,
  });
  final String version;
  final int photos;
  final int videos;
  final int usageBytes;
  final String diskSize;
  final String diskUse;
  final double diskPercent;
  final Map<String, bool> features;
}

/// Immich REST API (spec: open-api/immich-openapi-specs.json, checked
/// against v3.3.5) with an API key (`x-api-key`). Destructive calls move
/// assets to the trash unless `force` is set.
class ImmichApi {
  ImmichApi(this._dio, this.baseUrl, this.apiKey);

  factory ImmichApi.fromSettings({
    required String url,
    required String apiKey,
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) => ImmichApi(
    mediaDio(
      url,
      headers: {'x-api-key': apiKey, 'Accept': 'application/json'},
      trustSelfSigned: trustSelfSigned,
      adapter: adapter,
    ),
    url,
    apiKey,
  );

  final Dio _dio;
  final String baseUrl;
  final String apiKey;

  /// Headers for loading [thumbnailUrl] / [personThumbnailUrl] images.
  Map<String, String> get imageHeaders => {'x-api-key': apiKey};

  /// `size` is `thumbnail` (small webp) or `preview` (large jpeg).
  String thumbnailUrl(String assetId, {String size = 'thumbnail'}) =>
      '$baseUrl/api/assets/$assetId/thumbnail?size=$size';
  String personThumbnailUrl(String personId) =>
      '$baseUrl/api/people/$personId/thumbnail';

  /// The asset's page in Immich's own web UI.
  String webUrl(String assetId) => '$baseUrl/photos/$assetId';

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? q,
  ]) async =>
      (await _dio.get<Map<String, dynamic>>(path, queryParameters: q)).data ??
      const {};

  Future<List<dynamic>> _list(String path, [Map<String, dynamic>? q]) async =>
      (await _dio.get<List<dynamic>>(path, queryParameters: q)).data ??
      const [];

  ImmichAssetPage _page(Map<String, dynamic>? body) {
    final a = (body?['assets'] as Map?) ?? const {};
    return ImmichAssetPage([
      for (final i in (a['items'] as List?) ?? const [])
        if (i is Map) ImmichAsset.fromJson(i.cast<String, dynamic>()),
    ], int.tryParse('${a['nextPage']}'));
  }

  /// Newest first. [visibility] `timeline` (default) or `archive`;
  /// [type] `IMAGE` / `VIDEO`; [personIds] narrows to people.
  Future<ImmichAssetPage> assets({
    int page = 1,
    int size = 60,
    String visibility = 'timeline',
    bool? favorites,
    String? type,
    List<String> personIds = const [],
    String? fileName,
    bool trashed = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/search/metadata',
      data: {
        'page': page,
        'size': size,
        'order': 'desc',
        if (!trashed) 'visibility': visibility,
        'isFavorite': ?favorites,
        'type': ?type,
        if (personIds.isNotEmpty) 'personIds': personIds,
        'originalFileName': ?fileName,
        if (trashed) ...{
          'withDeleted': true,
          'trashedAfter': '1970-01-01T00:00:00Z',
        },
      },
    );
    return _page(res.data);
  }

  /// CLIP smart search ("dog on a beach").
  Future<ImmichAssetPage> smartSearch(String query, {int page = 1}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/search/smart',
      data: {'query': query, 'page': page, 'size': 60},
    );
    return _page(res.data);
  }

  Future<ImmichAsset> asset(String id) async =>
      ImmichAsset.fromJson(await _get('/api/assets/$id'));

  Future<void> updateAssets(
    List<String> ids, {
    bool? isFavorite,
    String? visibility,
    String? description,
  }) => _dio.put<void>(
    '/api/assets',
    data: {
      'ids': ids,
      'isFavorite': ?isFavorite,
      'visibility': ?visibility,
      'description': ?description,
    },
  );

  /// Moves to the trash; [force] deletes permanently.
  Future<void> deleteAssets(List<String> ids, {bool force = false}) =>
      _dio.delete<void>('/api/assets', data: {'ids': ids, 'force': force});

  Future<int> emptyTrash() async =>
      ((await _dio.post<Map<String, dynamic>>(
                '/api/trash/empty',
              )).data?['count']
              as num?)
          ?.toInt() ??
      0;

  Future<int> restoreTrash() async =>
      ((await _dio.post<Map<String, dynamic>>(
                '/api/trash/restore',
              )).data?['count']
              as num?)
          ?.toInt() ??
      0;

  Future<List<ImmichAlbum>> albums() async => [
    for (final a in await _list('/api/albums'))
      if (a is Map) ImmichAlbum.fromJson(a.cast<String, dynamic>()),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<ImmichAlbum> album(String id) async =>
      ImmichAlbum.fromJson(await _get('/api/albums/$id'));

  /// An album's assets, newest month first, from the timeline API (the
  /// only non-deprecated album listing in v3). Buckets come back columnar:
  /// one array per field.
  Future<List<ImmichAsset>> albumAssets(String albumId) async {
    final buckets = await _list('/api/timeline/buckets', {'albumId': albumId});
    final out = <ImmichAsset>[];
    for (final b in buckets) {
      if (b is! Map) continue;
      final cols = await _get('/api/timeline/bucket', {
        'albumId': albumId,
        'timeBucket': b['timeBucket'],
      });
      final ids = (cols['id'] as List?) ?? const [];
      List<dynamic> col(String k) => (cols[k] as List?) ?? const [];
      for (var i = 0; i < ids.length; i++) {
        T? at<T>(String k) {
          final c = col(k);
          return i < c.length && c[i] is T ? c[i] as T : null;
        }

        out.add(
          ImmichAsset(
            id: '${ids[i]}',
            type: at<bool>('isImage') == false ? 'VIDEO' : 'IMAGE',
            fileName: '',
            isFavorite: at<bool>('isFavorite') ?? false,
            visibility: at<String>('visibility') ?? 'timeline',
            taken: DateTime.tryParse(at<String>('fileCreatedAt') ?? ''),
          ),
        );
      }
    }
    return out;
  }

  Future<ImmichAlbum> createAlbum(
    String name, {
    String description = '',
    List<String> assetIds = const [],
  }) async => ImmichAlbum.fromJson(
    (await _dio.post<Map<String, dynamic>>(
          '/api/albums',
          data: {
            'albumName': name,
            if (description.isNotEmpty) 'description': description,
            if (assetIds.isNotEmpty) 'assetIds': assetIds,
          },
        )).data ??
        const {},
  );

  Future<void> updateAlbum(String id, {String? name, String? description}) =>
      _dio.patch<void>(
        '/api/albums/$id',
        data: {'albumName': ?name, 'description': ?description},
      );

  Future<void> deleteAlbum(String id) => _dio.delete<void>('/api/albums/$id');

  Future<void> addToAlbum(String albumId, List<String> assetIds) =>
      _dio.put<void>('/api/albums/$albumId/assets', data: {'ids': assetIds});

  Future<void> removeFromAlbum(String albumId, List<String> assetIds) =>
      _dio.delete<void>('/api/albums/$albumId/assets', data: {'ids': assetIds});

  Future<List<ImmichPerson>> people({bool withHidden = true}) async {
    final body = await _get('/api/people', {
      'withHidden': withHidden,
      'size': 500,
    });
    return [
      for (final p in (body['people'] as List?) ?? const [])
        if (p is Map) ImmichPerson.fromJson(p.cast<String, dynamic>()),
    ];
  }

  Future<void> updatePerson(
    String id, {
    String? name,
    bool? isHidden,
    bool? isFavorite,
  }) => _dio.put<void>(
    '/api/people/$id',
    data: {'name': ?name, 'isHidden': ?isHidden, 'isFavorite': ?isFavorite},
  );

  Future<List<ImmichMemory>> memories() async => [
    for (final m in await _list('/api/memories'))
      if (m is Map)
        ImmichMemory(
          '${m['id']}',
          ((m['data'] as Map?)?['year'] as num?)?.toInt(),
          [
            for (final a in (m['assets'] as List?) ?? const [])
              if (a is Map) ImmichAsset.fromJson(a.cast<String, dynamic>()),
          ],
        ),
  ];

  Future<List<ImmichDuplicateGroup>> duplicates() async => [
    for (final d in await _list('/api/duplicates'))
      if (d is Map)
        ImmichDuplicateGroup(
          '${d['duplicateId']}',
          [
            for (final a in (d['assets'] as List?) ?? const [])
              if (a is Map) ImmichAsset.fromJson(a.cast<String, dynamic>()),
          ],
          {
            for (final k in (d['suggestedKeepAssetIds'] as List?) ?? const [])
              '$k',
          },
        ),
  ];

  /// Marks a group as not duplicates (keeps every asset).
  Future<void> dismissDuplicate(String id) =>
      _dio.delete<void>('/api/duplicates/$id');

  Future<ImmichServer> server() async {
    final results = await Future.wait([
      _get('/api/server/about'),
      _get('/api/server/statistics'),
      _get('/api/server/storage'),
      _get('/api/server/features'),
    ]);
    final (about, stats, storage, features) = (
      results[0],
      results[1],
      results[2],
      results[3],
    );
    return ImmichServer(
      version: '${about['version'] ?? ''}',
      photos: (stats['photos'] as num?)?.toInt() ?? 0,
      videos: (stats['videos'] as num?)?.toInt() ?? 0,
      usageBytes: (stats['usage'] as num?)?.toInt() ?? 0,
      diskSize: '${storage['diskSize'] ?? ''}',
      diskUse: '${storage['diskUse'] ?? ''}',
      diskPercent: (storage['diskUsagePercentage'] as num?)?.toDouble() ?? 0,
      features: {
        for (final e in features.entries)
          if (e.value is bool) e.key: e.value as bool,
      },
    );
  }

  Future<List<ImmichQueue>> queues() async => [
    for (final q in await _list('/api/queues'))
      if (q is Map)
        ImmichQueue('${q['name']}', q['isPaused'] == true, {
          for (final e in ((q['statistics'] as Map?) ?? const {}).entries)
            '${e.key}': (e.value as num?)?.toInt() ?? 0,
        }),
  ]..sort((a, b) => a.name.compareTo(b.name));

  /// [command]: `start`, `pause`, `resume`, `empty` or `clear-failed`;
  /// `start` with [force] reprocesses every asset, not just missing ones.
  Future<void> queueCommand(
    String queue,
    String command, {
    bool force = false,
  }) => _dio.put<void>(
    '/api/jobs/$queue',
    data: {'command': command, 'force': force},
  );
}
