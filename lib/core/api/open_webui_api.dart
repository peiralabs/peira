import 'package:dio/dio.dart';

import 'media_dio.dart';

class OwModel {
  const OwModel({
    required this.id,
    required this.name,
    required this.ownedBy,
    this.size,
    this.family,
    this.quant,
  });

  factory OwModel.fromJson(Map<String, dynamic> j) {
    final d = ((j['ollama'] as Map?)?['details'] as Map?) ?? const {};
    return OwModel(
      id: '${j['id']}',
      name: '${j['name'] ?? j['id']}',
      ownedBy: '${j['owned_by'] ?? ''}',
      size: d['parameter_size'] as String?,
      family: d['family'] as String?,
      quant: d['quantization_level'] as String?,
    );
  }

  final String id;
  final String name;

  /// `ollama`, `openai`, `arena`, …
  final String ownedBy;
  final String? size;
  final String? family;
  final String? quant;

  /// Embedding models answer chat completions with 400; keep them out of
  /// the chat picker.
  bool get canChat => !id.contains('embed') && !(family ?? '').contains('bert');
}

class OwChatSummary {
  const OwChatSummary(this.id, this.title, this.updated, {this.pinned = false});
  final String id;
  final String title;
  final DateTime? updated;
  final bool pinned;
}

class OwMessage {
  const OwMessage(this.role, this.content, {this.model});
  final String role;
  final String content;
  final String? model;
}

class OwAnswer {
  const OwAnswer(this.content, this.sources);
  final String content;

  /// (title, url) of each web or knowledge source the answer used.
  final List<({String title, String? url})> sources;
}

class OwKnowledge {
  const OwKnowledge(this.id, this.name, this.description, this.files);
  final String id;
  final String name;
  final String description;
  final int files;
}

/// Open WebUI API (its own /openapi.json at 0.12.4) with a user API key as
/// a Bearer token. Chat runs through `/api/chat/completions`, Open WebUI's
/// OpenAI-compatible route, which adds web search and knowledge RAG.
class OpenWebUiApi {
  OpenWebUiApi(this._dio, this.baseUrl);

  factory OpenWebUiApi.fromSettings({
    required String url,
    required String apiKey,
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) {
    final dio = mediaDio(
      url,
      headers: {'Authorization': 'Bearer $apiKey'},
      trustSelfSigned: trustSelfSigned,
      adapter: adapter,
    );
    // Local models and web search can take minutes.
    dio.options.receiveTimeout = const Duration(minutes: 5);
    return OpenWebUiApi(dio, url);
  }

  final Dio _dio;
  final String baseUrl;

  String chatUrl(String id) => '$baseUrl/c/$id';

  Future<List<OwModel>> models() async {
    final d = (await _dio.get<Map<String, dynamic>>('/api/models')).data;
    return [
      for (final m in (d?['data'] as List?) ?? const [])
        if (m is Map) OwModel.fromJson(m.cast<String, dynamic>()),
    ];
  }

  /// One completion. [webSearch] asks Open WebUI to search the web first;
  /// [knowledgeIds] attaches knowledge collections for RAG.
  Future<OwAnswer> complete(
    String model,
    List<OwMessage> messages, {
    bool webSearch = false,
    List<String> knowledgeIds = const [],
  }) async {
    final d = (await _dio.post<Map<String, dynamic>>(
      '/api/chat/completions',
      data: {
        'model': model,
        'stream': false,
        'messages': [
          for (final m in messages) {'role': m.role, 'content': m.content},
        ],
        if (webSearch) 'features': {'web_search': true},
        if (knowledgeIds.isNotEmpty)
          'files': [
            for (final id in knowledgeIds) {'type': 'collection', 'id': id},
          ],
      },
    )).data;
    final choice = ((d?['choices'] as List?)?.firstOrNull as Map?) ?? const {};
    final content = '${(choice['message'] as Map?)?['content'] ?? ''}';
    final sources = <({String title, String? url})>[];
    for (final s in (d?['sources'] as List?) ?? const []) {
      if (s is! Map) continue;
      final metas = (s['metadata'] as List?) ?? const [];
      if (metas.isEmpty) {
        final src = (s['source'] as Map?) ?? const {};
        sources.add((
          title: '${src['name'] ?? src['id'] ?? 'source'}',
          url: null,
        ));
      }
      for (final m in metas) {
        if (m is! Map) continue;
        final url = m['source'] is String && '${m['source']}'.startsWith('http')
            ? m['source'] as String
            : null;
        sources.add((
          title: '${m['title'] ?? m['name'] ?? url ?? 'source'}',
          url: url,
        ));
      }
    }
    return OwAnswer(content, sources);
  }

  Future<List<OwChatSummary>> chats({int page = 1}) async => [
    for (final c
        in (await _dio.get<List<dynamic>>(
              '/api/v1/chats/',
              queryParameters: {'page': page},
            )).data ??
            const [])
      if (c is Map)
        OwChatSummary(
          '${c['id']}',
          '${c['title'] ?? ''}',
          _epoch(c['updated_at']),
        ),
  ];

  Future<List<OwChatSummary>> pinned() async => [
    for (final c
        in (await _dio.get<List<dynamic>>('/api/v1/chats/pinned')).data ??
            const [])
      if (c is Map)
        OwChatSummary(
          '${c['id']}',
          '${c['title'] ?? ''}',
          _epoch(c['updated_at']),
          pinned: true,
        ),
  ];

  Future<List<OwChatSummary>> searchChats(String text) async => [
    for (final c
        in (await _dio.get<List<dynamic>>(
              '/api/v1/chats/search',
              queryParameters: {'text': text},
            )).data ??
            const [])
      if (c is Map)
        OwChatSummary(
          '${c['id']}',
          '${c['title'] ?? ''}',
          _epoch(c['updated_at']),
        ),
  ];

  /// The conversation along its current branch: `chat.history` is a tree
  /// keyed by message id; walk parents from `currentId`. Falls back to the
  /// flat `chat.messages`.
  Future<({String title, bool pinned, List<OwMessage> messages})> chat(
    String id,
  ) async {
    final d =
        (await _dio.get<Map<String, dynamic>>('/api/v1/chats/$id')).data ??
        const {};
    final chat = (d['chat'] as Map?) ?? const {};
    final history = (chat['history'] as Map?) ?? const {};
    final nodes = (history['messages'] as Map?) ?? const {};
    final out = <OwMessage>[];
    var cur = history['currentId'];
    final seen = <Object?>{};
    while (cur != null && nodes[cur] is Map && seen.add(cur)) {
      final m = nodes[cur] as Map;
      out.add(
        OwMessage(
          '${m['role']}',
          '${m['content'] ?? ''}',
          model: m['model'] as String?,
        ),
      );
      cur = m['parentId'];
    }
    final messages = out.isNotEmpty
        ? out.reversed.toList()
        : [
            for (final m in (chat['messages'] as List?) ?? const [])
              if (m is Map)
                OwMessage(
                  '${m['role']}',
                  '${m['content'] ?? ''}',
                  model: m['model'] as String?,
                ),
          ];
    return (
      title: '${d['title'] ?? chat['title'] ?? ''}',
      pinned: d['pinned'] == true,
      messages: messages,
    );
  }

  Future<void> togglePin(String id) => _dio.post<void>('/api/v1/chats/$id/pin');

  /// Renames by posting the title alone; Open WebUI merges the posted chat
  /// fields into the stored chat (verified against 0.12.4).
  Future<void> renameChat(String id, String title) => _dio.post<void>(
    '/api/v1/chats/$id',
    data: {
      'chat': {'title': title},
    },
  );

  Future<void> deleteChat(String id) => _dio.delete<void>('/api/v1/chats/$id');

  Future<List<OwKnowledge>> knowledge() async {
    final d = (await _dio.get<Map<String, dynamic>>('/api/v1/knowledge/')).data;
    return [
      for (final k in (d?['items'] as List?) ?? const [])
        if (k is Map)
          OwKnowledge(
            '${k['id']}',
            '${k['name'] ?? ''}',
            '${k['description'] ?? ''}',
            (k['file_count'] as num?)?.toInt() ?? 0,
          ),
    ];
  }

  Future<void> createKnowledge(String name, String description) =>
      _dio.post<void>(
        '/api/v1/knowledge/create',
        data: {'name': name, 'description': description},
      );

  Future<void> deleteKnowledge(String id) =>
      _dio.delete<void>('/api/v1/knowledge/$id/delete');

  /// [kind]: `prompts`, `tools` or `functions`.
  Future<List<Map<String, dynamic>>> workspace(String kind) async => [
    for (final x
        in (await _dio.get<List<dynamic>>('/api/v1/$kind/')).data ?? const [])
      if (x is Map) x.cast<String, dynamic>(),
  ];

  Future<void> toggleFunction(String id) =>
      _dio.post<void>('/api/v1/functions/id/$id/toggle');

  Future<({int total, List<Map<String, dynamic>> users})> users() async {
    final d = (await _dio.get<Map<String, dynamic>>(
      '/api/v1/users/',
      queryParameters: {'page': 1},
    )).data;
    return (
      total: (d?['total'] as num?)?.toInt() ?? 0,
      users: [
        for (final u in (d?['users'] as List?) ?? const [])
          if (u is Map) u.cast<String, dynamic>(),
      ],
    );
  }

  Future<Map<String, dynamic>> adminConfig() async =>
      (await _dio.get<Map<String, dynamic>>(
        '/api/v1/auths/admin/config',
      )).data ??
      const {};

  Future<Map<String, dynamic>> version() async =>
      (await _dio.get<Map<String, dynamic>>('/api/version')).data ?? const {};

  static DateTime? _epoch(Object? v) => v is num
      ? DateTime.fromMillisecondsSinceEpoch(
          // Open WebUI stores seconds; some fields use nanoseconds.
          v > 1e15 ? v ~/ 1000000 : (v * 1000).toInt(),
        )
      : null;
}
