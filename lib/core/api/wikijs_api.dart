import 'package:dio/dio.dart';

import 'media_dio.dart';

class WikiPageItem {
  const WikiPageItem({
    required this.id,
    required this.path,
    required this.locale,
    required this.title,
    required this.description,
    required this.tags,
    this.updated,
  });

  factory WikiPageItem.fromJson(Map<String, dynamic> j) => WikiPageItem(
    // search() returns ids as strings, list() and single() as ints.
    id: switch (j['id']) {
      final num n => n.toInt(),
      final other => int.tryParse('$other') ?? 0,
    },
    path: j['path'] as String? ?? '',
    locale: j['locale'] as String? ?? 'en',
    title: (j['title'] as String?)?.trim().isNotEmpty == true
        ? j['title'] as String
        : j['path'] as String? ?? '',
    description: j['description'] as String? ?? '',
    tags: [
      for (final t in (j['tags'] as List?) ?? const [])
        if (t is String) t else if (t is Map) '${t['tag']}',
    ],
    updated: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
  );

  final int id;
  final String path;
  final String locale;
  final String title;
  final String description;
  final List<String> tags;
  final DateTime? updated;
}

class WikiPage extends WikiPageItem {
  const WikiPage({
    required super.id,
    required super.path,
    required super.locale,
    required super.title,
    required super.description,
    required super.tags,
    required this.content,
    required this.contentType,
    required this.editor,
    required this.isPublished,
    required this.isPrivate,
    super.updated,
    this.render,
    this.authorName,
  });

  factory WikiPage.fromJson(Map<String, dynamic> j) {
    final base = WikiPageItem.fromJson(j);
    return WikiPage(
      id: base.id,
      path: base.path,
      locale: base.locale,
      title: base.title,
      description: base.description,
      tags: base.tags,
      updated: base.updated,
      content: j['content'] as String? ?? '',
      contentType: j['contentType'] as String? ?? 'markdown',
      editor: j['editor'] as String? ?? 'markdown',
      isPublished: j['isPublished'] != false,
      isPrivate: j['isPrivate'] == true,
      render: j['render'] as String?,
      authorName: j['authorName'] as String?,
    );
  }

  /// Source text; Markdown when [editor] is `markdown`.
  final String content;
  final String contentType;
  final String editor;
  final bool isPublished;
  final bool isPrivate;

  /// Wiki.js's rendered HTML.
  final String? render;
  final String? authorName;
}

class WikiHistoryEntry {
  const WikiHistoryEntry(this.versionId, this.date, this.author, this.action);
  final int versionId;
  final DateTime? date;
  final String author;

  /// `initial`, `edit`, `move`, …
  final String action;
}

class WikiTag {
  const WikiTag(this.id, this.tag, this.title);
  final int id;
  final String tag;
  final String title;
}

/// Thrown when GraphQL answers with `errors` or a failed `responseResult`.
class WikiJsException implements Exception {
  const WikiJsException(this.message);
  final String message;
  @override
  String toString() => 'Wiki.js: $message';
}

/// Wiki.js 2.x GraphQL API (schema server/graph/schemas at v2.5.314) with an
/// API key as a Bearer token.
class WikiJsApi {
  WikiJsApi(this._dio, this.baseUrl);

  factory WikiJsApi.fromSettings({
    required String url,
    required String apiKey,
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) => WikiJsApi(
    mediaDio(
      url,
      headers: {'Authorization': 'Bearer $apiKey'},
      trustSelfSigned: trustSelfSigned,
      adapter: adapter,
    ),
    url,
  );

  final Dio _dio;
  final String baseUrl;

  String webUrl(String locale, String path) => '$baseUrl/$locale/$path';

  Future<Map<String, dynamic>> _gql(
    String query, [
    Map<String, dynamic> variables = const {},
  ]) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/graphql',
      data: {'query': query, 'variables': variables},
    );
    final body = res.data ?? const {};
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw WikiJsException('${(errors.first as Map)['message']}');
    }
    return (body['data'] as Map?)?.cast<String, dynamic>() ?? const {};
  }

  /// Checks a mutation's `responseResult` and returns its payload.
  Map<String, dynamic> _ok(Map<String, dynamic> data, String group, String op) {
    final r =
        ((data[group] as Map?)?[op] as Map?)?.cast<String, dynamic>() ??
        const {};
    final rr = (r['responseResult'] as Map?) ?? const {};
    if (rr['succeeded'] != true) {
      throw WikiJsException('${rr['message'] ?? 'request failed'}');
    }
    return r;
  }

  /// [orderBy]: `UPDATED`, `TITLE`, `PATH`, `CREATED` or `ID`.
  Future<List<WikiPageItem>> pages({
    String orderBy = 'UPDATED',
    List<String>? tags,
    int limit = 1000,
  }) async {
    final d = await _gql(
      r'query($o: PageOrderBy, $dir: PageOrderByDirection, $t: [String!], '
      r'$l: Int) { pages { '
      r'list(limit: $l, orderBy: $o, orderByDirection: $dir, tags: $t) '
      r'{ id path locale title description updatedAt tags } } }',
      {
        'o': orderBy,
        // Newest first for dates, A→Z for titles and paths.
        'dir': orderBy == 'UPDATED' || orderBy == 'CREATED' ? 'DESC' : 'ASC',
        't': tags,
        'l': limit,
      },
    );
    return [
      for (final p in (d['pages'] as Map?)?['list'] as List? ?? const [])
        if (p is Map) WikiPageItem.fromJson(p.cast<String, dynamic>()),
    ];
  }

  Future<({List<WikiPageItem> results, List<String> suggestions, int total})>
  search(String query) async {
    final d = await _gql(
      r'query($q: String!) { pages { search(query: $q) '
      r'{ results { id title description path locale } suggestions totalHits } } }',
      {'q': query},
    );
    final s = ((d['pages'] as Map?)?['search'] as Map?) ?? const {};
    return (
      results: [
        for (final r in (s['results'] as List?) ?? const [])
          if (r is Map) WikiPageItem.fromJson(r.cast<String, dynamic>()),
      ],
      suggestions: [
        for (final x in (s['suggestions'] as List?) ?? const [])
          if (x is String) x,
      ],
      total: (s['totalHits'] as num?)?.toInt() ?? 0,
    );
  }

  static const _pageFields =
      'id path locale title description content contentType editor '
      'isPublished isPrivate render updatedAt authorName tags { tag }';

  Future<WikiPage> page(int id) async {
    final d = await _gql(
      'query(\$id: Int!) { pages { single(id: \$id) { $_pageFields } } }',
      {'id': id},
    );
    final p = (d['pages'] as Map?)?['single'];
    if (p is! Map) throw const WikiJsException('page not found');
    return WikiPage.fromJson(p.cast<String, dynamic>());
  }

  Future<WikiPage?> pageByPath(String path, {String locale = 'en'}) async {
    final d = await _gql(
      'query(\$p: String!, \$l: String!) { pages { '
      'singleByPath(path: \$p, locale: \$l) { $_pageFields } } }',
      {'p': path, 'l': locale},
    );
    final p = (d['pages'] as Map?)?['singleByPath'];
    return p is Map ? WikiPage.fromJson(p.cast<String, dynamic>()) : null;
  }

  Future<List<WikiHistoryEntry>> history(int id) async {
    final d = await _gql(
      r'query($id: Int!) { pages { history(id: $id, offsetSize: 100) '
      r'{ trail { versionId versionDate authorName actionType } total } } }',
      {'id': id},
    );
    final trail =
        (((d['pages'] as Map?)?['history'] as Map?)?['trail'] as List?) ??
        const [];
    return [
      for (final t in trail)
        if (t is Map)
          WikiHistoryEntry(
            (t['versionId'] as num?)?.toInt() ?? 0,
            DateTime.tryParse('${t['versionDate']}'),
            '${t['authorName'] ?? ''}',
            '${t['actionType'] ?? ''}',
          ),
    ];
  }

  /// The source of one past version.
  Future<String> versionContent(int pageId, int versionId) async {
    final d = await _gql(
      r'query($p: Int!, $v: Int!) { pages { version(pageId: $p, versionId: $v) '
      r'{ content } } }',
      {'p': pageId, 'v': versionId},
    );
    return '${((d['pages'] as Map?)?['version'] as Map?)?['content'] ?? ''}';
  }

  Future<List<WikiTag>> tags() async {
    final d = await _gql('{ pages { tags { id tag title } } }');
    return [
      for (final t in (d['pages'] as Map?)?['tags'] as List? ?? const [])
        if (t is Map)
          WikiTag(
            (t['id'] as num?)?.toInt() ?? 0,
            '${t['tag']}',
            '${t['title'] ?? t['tag']}',
          ),
    ]..sort((a, b) => a.tag.compareTo(b.tag));
  }

  Future<Map<String, dynamic>> systemInfo() async {
    final d = await _gql(
      '{ system { info { currentVersion latestVersion pagesTotal usersTotal '
      'groupsTotal tagsTotal dbType dbVersion nodeVersion hostname '
      'operatingSystem cpuCores ramTotal } } }',
    );
    return ((d['system'] as Map?)?['info'] as Map?)?.cast<String, dynamic>() ??
        const {};
  }

  // ---- Writes (publicly; the personal build's wiki is a read-only
  // projection of a git vault, so its screen never calls these).

  Future<int> createPage({
    required String path,
    required String title,
    required String content,
    String description = '',
    String locale = 'en',
    List<String> tags = const [],
  }) async {
    final d = await _gql(
      r'mutation($c: String!, $d: String!, $l: String!, $p: String!, '
      r'$t: [String]!, $ti: String!) { pages { create(content: $c, '
      r'description: $d, editor: "markdown", isPublished: true, '
      r'isPrivate: false, locale: $l, path: $p, tags: $t, title: $ti) '
      r'{ responseResult { succeeded message } page { id } } } }',
      {
        'c': content,
        'd': description,
        'l': locale,
        'p': path,
        't': tags,
        'ti': title,
      },
    );
    return ((_ok(d, 'pages', 'create')['page'] as Map?)?['id'] as num?)
            ?.toInt() ??
        0;
  }

  Future<void> updatePage(
    int id, {
    String? content,
    String? title,
    String? description,
    List<String>? tags,
  }) async => _ok(
    await _gql(
      r'mutation($id: Int!, $c: String, $ti: String, $d: String, '
      r'$t: [String]) { pages { update(id: $id, content: $c, title: $ti, '
      r'description: $d, tags: $t) { responseResult { succeeded message } } } }',
      {'id': id, 'c': content, 'ti': title, 'd': description, 't': tags},
    ),
    'pages',
    'update',
  );

  Future<void> movePage(int id, String path, {String locale = 'en'}) async =>
      _ok(
        await _gql(
          r'mutation($id: Int!, $p: String!, $l: String!) { pages { '
          r'move(id: $id, destinationPath: $p, destinationLocale: $l) '
          r'{ responseResult { succeeded message } } } }',
          {'id': id, 'p': path, 'l': locale},
        ),
        'pages',
        'move',
      );

  Future<void> deletePage(int id) async => _ok(
    await _gql(
      r'mutation($id: Int!) { pages { delete(id: $id) '
      r'{ responseResult { succeeded message } } } }',
      {'id': id},
    ),
    'pages',
    'delete',
  );

  Future<void> restoreVersion(int pageId, int versionId) async => _ok(
    await _gql(
      r'mutation($p: Int!, $v: Int!) { pages { restore(pageId: $p, '
      r'versionId: $v) { responseResult { succeeded message } } } }',
      {'p': pageId, 'v': versionId},
    ),
    'pages',
    'restore',
  );

  Future<void> rebuildTree() async => _ok(
    await _gql(
      'mutation { pages { rebuildTree { responseResult { succeeded message } } } }',
    ),
    'pages',
    'rebuildTree',
  );

  Future<void> flushCache() async => _ok(
    await _gql(
      'mutation { pages { flushCache { responseResult { succeeded message } } } }',
    ),
    'pages',
    'flushCache',
  );
}
