import 'package:dio/dio.dart';

import 'media_dio.dart';

/// A tag, correspondent, document type or storage path: Paperless gives
/// all four the same id/name/document_count shape.
class PlLabel {
  const PlLabel(this.id, this.name, this.count, {this.color, this.isInbox});
  final int id;
  final String name;
  final int count;

  /// Tags only.
  final String? color;
  final bool? isInbox;
}

class PlDocument {
  const PlDocument({
    required this.id,
    required this.title,
    required this.tags,
    this.correspondent,
    this.documentType,
    this.created,
    this.added,
    this.asn,
    this.pageCount,
    this.originalName,
    this.content,
    this.notes = const [],
    this.mimeType,
  });

  factory PlDocument.fromJson(Map<String, dynamic> j) => PlDocument(
    id: (j['id'] as num?)?.toInt() ?? 0,
    title: j['title'] as String? ?? '',
    tags: [
      for (final t in (j['tags'] as List?) ?? const [])
        if (t is num) t.toInt(),
    ],
    correspondent: (j['correspondent'] as num?)?.toInt(),
    documentType: (j['document_type'] as num?)?.toInt(),
    created: DateTime.tryParse(
      j['created_date'] as String? ?? j['created'] as String? ?? '',
    ),
    added: DateTime.tryParse(j['added'] as String? ?? ''),
    asn: (j['archive_serial_number'] as num?)?.toInt(),
    pageCount: (j['page_count'] as num?)?.toInt(),
    originalName: j['original_file_name'] as String?,
    content: j['content'] as String?,
    mimeType: j['mime_type'] as String?,
    notes: [
      for (final n in (j['notes'] as List?) ?? const [])
        if (n is Map)
          (
            id: (n['id'] as num?)?.toInt() ?? 0,
            note: '${n['note'] ?? ''}',
            created: DateTime.tryParse('${n['created']}'),
          ),
    ],
  );

  final int id;
  final String title;
  final List<int> tags;
  final int? correspondent;
  final int? documentType;
  final DateTime? created;
  final DateTime? added;
  final int? asn;
  final int? pageCount;
  final String? originalName;

  /// OCR text (detail reads only).
  final String? content;
  final String? mimeType;
  final List<({int id, String note, DateTime? created})> notes;
}

class PlPage {
  const PlPage(this.documents, this.count, this.hasNext);
  final List<PlDocument> documents;
  final int count;
  final bool hasNext;
}

class PlTask {
  const PlTask({
    required this.id,
    required this.name,
    required this.status,
    this.result,
    this.created,
    this.documentId,
  });
  final int id;
  final String name;

  /// `pending`, `started`, `success`, `failure` or `revoked` (API v10).
  final String status;
  final String? result;
  final DateTime? created;
  final int? documentId;
}

/// Paperless-ngx REST API (schema served at /api/schema/, checked against
/// 3.0.5, API version 10) with a per-user token.
class PaperlessApi {
  PaperlessApi(this._dio, this.baseUrl, this.token);

  factory PaperlessApi.fromSettings({
    required String url,
    required String token,
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) => PaperlessApi(
    mediaDio(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Accept': 'application/json; version=10',
      },
      trustSelfSigned: trustSelfSigned,
      adapter: adapter,
    ),
    url,
    token,
  );

  final Dio _dio;
  final String baseUrl;
  final String token;

  Map<String, String> get imageHeaders => {'Authorization': 'Token $token'};
  String thumbUrl(int id) => '$baseUrl/api/documents/$id/thumb/';
  String webUrl(int id) => '$baseUrl/documents/$id/details';

  Future<Map<String, dynamic>> _get(
    String p, [
    Map<String, dynamic>? q,
  ]) async =>
      (await _dio.get<Map<String, dynamic>>(p, queryParameters: q)).data ??
      const {};

  /// [query] is Paperless full-text search (whoosh syntax); [ordering]
  /// e.g. `-created`, `title`, `-added`.
  Future<PlPage> documents({
    int page = 1,
    String? query,
    String ordering = '-created',
    List<int> tagsAll = const [],
    int? correspondent,
    int? documentType,
    bool inboxOnly = false,
  }) async {
    final d = await _get('/api/documents/', {
      'page': page,
      'page_size': 50,
      'query': ?query,
      // A full-text query ranks by relevance unless ordered explicitly.
      if (query == null) 'ordering': ordering,
      if (tagsAll.isNotEmpty) 'tags__id__all': tagsAll.join(','),
      'correspondent__id': ?correspondent,
      'document_type__id': ?documentType,
      if (inboxOnly) 'is_in_inbox': true,
      'fields':
          'id,title,tags,correspondent,document_type,created,created_date,'
          'added,archive_serial_number,page_count,original_file_name,mime_type',
    });
    return PlPage(
      [
        for (final r in (d['results'] as List?) ?? const [])
          if (r is Map) PlDocument.fromJson(r.cast<String, dynamic>()),
      ],
      (d['count'] as num?)?.toInt() ?? 0,
      d['next'] != null,
    );
  }

  Future<PlDocument> document(int id) async =>
      PlDocument.fromJson(await _get('/api/documents/$id/'));

  /// Sets only the fields given; `clearCorrespondent` / `clearType` unset.
  Future<void> updateDocument(
    int id, {
    String? title,
    List<int>? tags,
    int? correspondent,
    bool clearCorrespondent = false,
    int? documentType,
    bool clearType = false,
    int? asn,
    String? createdDate,
  }) => _dio.patch<void>(
    '/api/documents/$id/',
    data: {
      'title': ?title,
      'tags': ?tags,
      if (clearCorrespondent)
        'correspondent': null
      else
        'correspondent': ?correspondent,
      if (clearType) 'document_type': null else 'document_type': ?documentType,
      'archive_serial_number': ?asn,
      'created_date': ?createdDate,
    },
  );

  /// Moves documents to the trash (Paperless keeps them for its trash
  /// retention period).
  Future<void> deleteDocuments(List<int> ids) => bulkEdit(ids, 'delete');

  /// `bulk_edit` [method] from MethodEnum, e.g. `add_tag` with
  /// `{'tag': id}`, `reprocess`, `rotate` with `{'degrees': 90}`.
  Future<void> bulkEdit(
    List<int> ids,
    String method, [
    Map<String, dynamic> parameters = const {},
  ]) => _dio.post<void>(
    '/api/documents/bulk_edit/',
    data: {'documents': ids, 'method': method, 'parameters': parameters},
  );

  Future<void> addNote(int id, String note) =>
      _dio.post<void>('/api/documents/$id/notes/', data: {'note': note});

  Future<void> deleteNote(int docId, int noteId) => _dio.delete<void>(
    '/api/documents/$docId/notes/',
    queryParameters: {'id': noteId},
  );

  /// Matching suggestions: label ids per kind plus dates.
  Future<Map<String, dynamic>> suggestions(int id) =>
      _get('/api/documents/$id/suggestions/');

  /// Uploads a file for consumption; returns the consume task id.
  Future<String> upload(
    String path, {
    String? title,
    List<int> tags = const [],
    int? correspondent,
    int? documentType,
  }) async {
    final form = FormData.fromMap({
      'document': await MultipartFile.fromFile(path),
      'title': ?title,
      'correspondent': ?correspondent,
      'document_type': ?documentType,
    });
    for (final t in tags) {
      form.fields.add(MapEntry('tags', '$t'));
    }
    final res = await _dio.post<dynamic>(
      '/api/documents/post_document/',
      data: form,
    );
    return '${res.data}'.replaceAll('"', '');
  }

  /// [kind] is `tags`, `correspondents`, `document_types` or
  /// `storage_paths`.
  Future<List<PlLabel>> labels(String kind) async {
    final out = <PlLabel>[];
    var page = 1;
    while (true) {
      final d = await _get('/api/$kind/', {
        'page': page,
        'page_size': 100,
        'ordering': 'name',
      });
      for (final r in (d['results'] as List?) ?? const []) {
        if (r is! Map) continue;
        out.add(
          PlLabel(
            (r['id'] as num?)?.toInt() ?? 0,
            '${r['name']}',
            (r['document_count'] as num?)?.toInt() ?? 0,
            color: r['color'] as String?,
            isInbox: r['is_inbox_tag'] as bool?,
          ),
        );
      }
      if (d['next'] == null) break;
      page++;
    }
    return out;
  }

  Future<void> createLabel(String kind, String name, {bool inbox = false}) =>
      _dio.post<void>(
        '/api/$kind/',
        data: {'name': name, if (kind == 'tags' && inbox) 'is_inbox_tag': true},
      );

  Future<void> renameLabel(String kind, int id, String name) =>
      _dio.patch<void>('/api/$kind/$id/', data: {'name': name});

  Future<void> deleteLabel(String kind, int id) =>
      _dio.delete<void>('/api/$kind/$id/');

  Future<PlPage> trash({int page = 1}) async {
    final d = await _get('/api/trash/', {'page': page, 'page_size': 50});
    return PlPage(
      [
        for (final r in (d['results'] as List?) ?? const [])
          if (r is Map) PlDocument.fromJson(r.cast<String, dynamic>()),
      ],
      (d['count'] as num?)?.toInt() ?? 0,
      d['next'] != null,
    );
  }

  /// [action] `restore` or `empty`; no [ids] means the whole trash.
  Future<void> trashAction(String action, {List<int>? ids}) => _dio.post<void>(
    '/api/trash/',
    data: {'action': action, 'documents': ?ids},
  );

  /// Newest first; [unacknowledged] hides tasks already dismissed.
  Future<({List<PlTask> tasks, int count})> tasks({
    bool unacknowledged = true,
    String? status,
  }) async {
    final res = await _dio.get<dynamic>(
      '/api/tasks/',
      queryParameters: {
        'page_size': 50,
        'ordering': '-date_created',
        if (unacknowledged) 'acknowledged': false,
        'status': ?status,
      },
    );
    final d = res.data;
    // Older servers answer a bare list; v10 pages.
    final list = d is Map ? (d['results'] as List?) ?? const [] : d as List;
    final count = d is Map
        ? (d['count'] as num?)?.toInt() ?? list.length
        : list.length;
    String? file(Object? input) {
      if (input is! Map) return null;
      for (final k in const ['filename', 'original_filename', 'file_name']) {
        final v = input[k];
        if (v is String && v.isNotEmpty) return v.split('/').last;
      }
      return null;
    }

    String? result(Object? data) => switch (data) {
      null => null,
      final String s => s,
      final Map m => '${m['message'] ?? m['error'] ?? m['detail'] ?? m}',
      final other => '$other',
    };

    // v10 task fields (TaskSerializerV10): task_type(_display), status,
    // input_data, result_data, related_document_ids.
    return (
      tasks: [
        for (final t in list)
          if (t is Map)
            PlTask(
              id: (t['id'] as num?)?.toInt() ?? 0,
              name: [
                '${t['task_type_display'] ?? t['task_type'] ?? 'Task'}',
                ?file(t['input_data']),
              ].join(': '),
              status: '${t['status'] ?? ''}'.toLowerCase(),
              result: result(t['result_data']),
              created: DateTime.tryParse('${t['date_created']}'),
              documentId:
                  ((t['related_document_ids'] as List?)?.firstOrNull as num?)
                      ?.toInt(),
            ),
      ],
      count: count,
    );
  }

  Future<void> acknowledgeTasks({List<int>? ids}) => _dio.post<void>(
    '/api/tasks/acknowledge/',
    data: ids == null ? {'all': true} : {'tasks': ids},
  );

  Future<Map<String, dynamic>> statistics() => _get('/api/statistics/');

  Future<Map<String, dynamic>> remoteVersion() => _get('/api/remote_version/');
}
