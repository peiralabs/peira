import 'package:dio/dio.dart';

import 'media_dio.dart';

class KkTag {
  const KkTag(this.id, this.name, {this.attachedBy, this.count});
  final String id;
  final String name;

  /// `ai` or `human` on a bookmark's tag.
  final String? attachedBy;

  /// Bookmarks carrying the tag (tag listing only).
  final int? count;
}

/// One bookmark (`Bookmark`): a link, a text note, or an uploaded asset.
class KkBookmark {
  const KkBookmark({
    required this.id,
    required this.kind,
    required this.title,
    required this.archived,
    required this.favourited,
    required this.tags,
    this.url,
    this.description,
    this.imageUrl,
    this.text,
    this.note,
    this.summary,
    this.created,
    this.taggingStatus,
  });

  factory KkBookmark.fromJson(Map<String, dynamic> j) {
    final c = (j['content'] as Map?)?.cast<String, dynamic>() ?? const {};
    String? s(Object? v) => v is String && v.isNotEmpty ? v : null;
    return KkBookmark(
      id: j['id'] as String? ?? '',
      kind: s(c['type']) ?? 'unknown',
      title:
          s(j['title']) ??
          s(c['title']) ??
          s(c['url']) ??
          s(c['fileName']) ??
          (s(c['text'])?.split('\n').first ?? 'Untitled'),
      archived: j['archived'] == true,
      favourited: j['favourited'] == true,
      tags: [
        for (final t in (j['tags'] as List?) ?? const [])
          if (t is Map)
            KkTag(
              '${t['id']}',
              '${t['name']}',
              attachedBy: t['attachedBy'] as String?,
            ),
      ],
      url: s(c['url']) ?? s(c['sourceUrl']),
      description: s(c['description']),
      imageUrl: s(c['imageUrl']),
      text: s(c['text']),
      note: s(j['note']),
      summary: s(j['summary']),
      created: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      taggingStatus: s(j['taggingStatus']),
    );
  }

  final String id;

  /// `link`, `text` or `asset`.
  final String kind;
  final String title;
  final bool archived;
  final bool favourited;
  final List<KkTag> tags;
  final String? url;
  final String? description;
  final String? imageUrl;
  final String? text;
  final String? note;
  final String? summary;
  final DateTime? created;
  final String? taggingStatus;
}

class KkPage {
  const KkPage(this.bookmarks, this.nextCursor);
  final List<KkBookmark> bookmarks;
  final String? nextCursor;
}

class KkList {
  const KkList({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    this.description,
    this.query,
    this.parentId,
  });
  final String id;
  final String name;
  final String icon;

  /// `manual` or `smart` (a saved search [query]).
  final String type;
  final String? description;
  final String? query;
  final String? parentId;
}

class KkFeed {
  const KkFeed({
    required this.id,
    required this.name,
    required this.url,
    required this.enabled,
    this.lastStatus,
    this.lastFetched,
  });
  final String id;
  final String name;
  final String url;
  final bool enabled;
  final String? lastStatus;
  final DateTime? lastFetched;
}

class KkHighlight {
  const KkHighlight(this.id, this.bookmarkId, this.text, this.note, this.color);
  final String id;
  final String bookmarkId;
  final String text;
  final String? note;
  final String color;
}

/// Karakeep REST API (`/api/v1`, spec packages/open-api at v0.33.2) with an
/// API key as a Bearer token.
class KarakeepApi {
  KarakeepApi(this._dio, this.baseUrl);

  factory KarakeepApi.fromSettings({
    required String url,
    required String apiKey,
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) => KarakeepApi(
    mediaDio(
      '$url/api/v1',
      headers: {'Authorization': 'Bearer $apiKey'},
      trustSelfSigned: trustSelfSigned,
      adapter: adapter,
    ),
    url,
  );

  final Dio _dio;
  final String baseUrl;

  /// The bookmark's page in Karakeep's web UI.
  String webUrl(String bookmarkId) => '$baseUrl/dashboard/preview/$bookmarkId';

  Future<Map<String, dynamic>> _get(
    String p, [
    Map<String, dynamic>? q,
  ]) async =>
      (await _dio.get<Map<String, dynamic>>(p, queryParameters: q)).data ??
      const {};

  KkPage _page(Map<String, dynamic> d) => KkPage([
    for (final b in (d['bookmarks'] as List?) ?? const [])
      if (b is Map) KkBookmark.fromJson(b.cast<String, dynamic>()),
  ], d['nextCursor'] as String?);

  Future<KkPage> bookmarks({
    bool? archived,
    bool? favourited,
    String? cursor,
    int limit = 40,
  }) async => _page(
    await _get('/bookmarks', {
      'archived': ?archived,
      'favourited': ?favourited,
      'cursor': ?cursor,
      'limit': limit,
      'includeContent': false,
    }),
  );

  /// [mode] is `fts`, `semantic` or `hybrid`.
  Future<KkPage> search(
    String q, {
    String mode = 'fts',
    String? cursor,
  }) async => _page(
    await _get('/bookmarks/search', {
      'q': q,
      'searchMode': mode,
      'cursor': ?cursor,
      'limit': 40,
      'includeContent': false,
    }),
  );

  Future<KkPage> listBookmarks(String listId, {String? cursor}) async => _page(
    await _get('/lists/$listId/bookmarks', {
      'cursor': ?cursor,
      'limit': 40,
      'includeContent': false,
    }),
  );

  Future<KkPage> tagBookmarks(String tagId, {String? cursor}) async => _page(
    await _get('/tags/$tagId/bookmarks', {
      'cursor': ?cursor,
      'limit': 40,
      'includeContent': false,
    }),
  );

  Future<KkBookmark> bookmark(String id) async => KkBookmark.fromJson(
    await _get('/bookmarks/$id', {'includeContent': false}),
  );

  Future<KkBookmark> addLink(String url, {String? title, String? note}) async =>
      KkBookmark.fromJson(
        (await _dio.post<Map<String, dynamic>>(
              '/bookmarks',
              data: {
                'type': 'link',
                'url': url,
                'title': ?title,
                'note': ?note,
              },
            )).data ??
            const {},
      );

  Future<KkBookmark> addNote(String text, {String? title}) async =>
      KkBookmark.fromJson(
        (await _dio.post<Map<String, dynamic>>(
              '/bookmarks',
              data: {'type': 'text', 'text': text, 'title': ?title},
            )).data ??
            const {},
      );

  Future<void> updateBookmark(
    String id, {
    bool? archived,
    bool? favourited,
    String? title,
    String? note,
  }) => _dio.patch<void>(
    '/bookmarks/$id',
    data: {
      'archived': ?archived,
      'favourited': ?favourited,
      'title': ?title,
      'note': ?note,
    },
  );

  Future<void> deleteBookmark(String id) => _dio.delete<void>('/bookmarks/$id');

  /// Asks the configured AI to summarise the page; returns the summary.
  Future<String?> summarize(String id) async => KkBookmark.fromJson(
    (await _dio.post<Map<String, dynamic>>('/bookmarks/$id/summarize')).data ??
        const {},
  ).summary;

  Future<void> attachTags(String id, List<String> names) => _dio.post<void>(
    '/bookmarks/$id/tags',
    data: {
      'tags': [
        for (final n in names) {'tagName': n},
      ],
    },
  );

  Future<void> detachTag(String id, String tagId) => _dio.delete<void>(
    '/bookmarks/$id/tags',
    data: {
      'tags': [
        {'tagId': tagId},
      ],
    },
  );

  Future<List<String>> bookmarkListIds(String id) async => [
    for (final l
        in (await _get('/bookmarks/$id/lists'))['lists'] as List? ?? const [])
      if (l is Map) '${l['id']}',
  ];

  Future<void> addToList(String listId, String bookmarkId) =>
      _dio.put<void>('/lists/$listId/bookmarks/$bookmarkId');

  Future<void> removeFromList(String listId, String bookmarkId) =>
      _dio.delete<void>('/lists/$listId/bookmarks/$bookmarkId');

  Future<List<KkHighlight>> highlights({String? bookmarkId}) async {
    final d = await _get(
      bookmarkId == null ? '/highlights' : '/bookmarks/$bookmarkId/highlights',
      bookmarkId == null ? {'limit': 100} : null,
    );
    return [
      for (final h in (d['highlights'] as List?) ?? const [])
        if (h is Map)
          KkHighlight(
            '${h['id']}',
            '${h['bookmarkId']}',
            '${h['text'] ?? ''}',
            h['note'] as String?,
            '${h['color'] ?? 'yellow'}',
          ),
    ];
  }

  Future<List<KkTag>> tags() async {
    final out = <KkTag>[];
    String? cursor;
    do {
      final d = await _get('/tags', {'cursor': ?cursor, 'limit': 200});
      for (final t in (d['tags'] as List?) ?? const []) {
        if (t is Map) {
          out.add(
            KkTag(
              '${t['id']}',
              '${t['name']}',
              count: (t['numBookmarks'] as num?)?.toInt(),
            ),
          );
        }
      }
      cursor = d['nextCursor'] as String?;
    } while (cursor != null);
    return out..sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));
  }

  Future<void> renameTag(String id, String name) =>
      _dio.patch<void>('/tags/$id', data: {'name': name});

  Future<void> deleteTag(String id) => _dio.delete<void>('/tags/$id');

  Future<List<KkList>> lists() async => [
    for (final l in (await _get('/lists'))['lists'] as List? ?? const [])
      if (l is Map)
        KkList(
          id: '${l['id']}',
          name: '${l['name']}',
          icon: '${l['icon'] ?? ''}',
          type: '${l['type'] ?? 'manual'}',
          description: l['description'] as String?,
          query: l['query'] as String?,
          parentId: l['parentId'] as String?,
        ),
  ];

  /// A manual list, or a smart list when [query] is set.
  Future<void> createList(String name, {String icon = '📚', String? query}) =>
      _dio.post<void>(
        '/lists',
        data: {
          'name': name,
          'icon': icon,
          if (query != null) ...{'type': 'smart', 'query': query},
        },
      );

  Future<void> updateList(String id, {String? name, String? icon}) =>
      _dio.patch<void>('/lists/$id', data: {'name': ?name, 'icon': ?icon});

  Future<void> deleteList(String id) => _dio.delete<void>('/lists/$id');

  Future<List<KkFeed>> feeds() async => [
    for (final f in (await _get('/feeds'))['feeds'] as List? ?? const [])
      if (f is Map)
        KkFeed(
          id: '${f['id']}',
          name: '${f['name']}',
          url: '${f['url']}',
          enabled: f['enabled'] == true,
          lastStatus: f['lastFetchedStatus'] as String?,
          lastFetched: DateTime.tryParse(f['lastFetchedAt'] as String? ?? ''),
        ),
  ];

  Future<void> addFeed(String name, String url) => _dio.post<void>(
    '/feeds',
    data: {'name': name, 'url': url, 'enabled': true},
  );

  Future<void> setFeedEnabled(String id, bool enabled) =>
      _dio.patch<void>('/feeds/$id', data: {'enabled': enabled});

  Future<void> fetchFeed(String id) => _dio.post<void>('/feeds/$id/fetch');

  Future<void> deleteFeed(String id) => _dio.delete<void>('/feeds/$id');

  Future<Map<String, dynamic>> stats() => _get('/users/me/stats');
}
