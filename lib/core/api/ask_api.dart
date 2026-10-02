import 'package:dio/dio.dart';

/// One prior conversation turn sent back to the Ask endpoint for follow-up
/// retrieval + generation context.
typedef AskTurn = ({String role, String content});

/// One cited vault section behind an answer.
class AskSource {
  const AskSource({
    required this.n,
    required this.wikiPath,
    required this.anchor,
    required this.title,
    required this.heading,
    required this.score,
    required this.snippet,
  });

  factory AskSource.fromJson(Map<String, dynamic> j) => AskSource(
    n: (j['n'] as num?)?.toInt() ?? 0,
    wikiPath: '${j['wiki_path']}',
    anchor: j['anchor'] as String?,
    title: '${j['title'] ?? ''}',
    heading: '${j['heading'] ?? ''}',
    score: (j['score'] as num?)?.toDouble() ?? 0,
    snippet: '${j['snippet'] ?? ''}',
  );

  final int n;
  final String wikiPath;
  final String? anchor;
  final String title;
  final String heading;
  final double score;
  final String snippet;

  /// `wiki_path#anchor` — the stable section reference the vault uses.
  String get ref => anchor == null ? wikiPath : '$wikiPath#$anchor';
}

/// A generated answer with its citations and the revision label the
/// ask-homelab consumer contract guarantees (stale answers are labeled,
/// never silently served as current).
class AskReply {
  const AskReply({
    required this.answer,
    required this.sources,
    required this.revision,
    required this.stale,
    required this.backend,
    required this.model,
  });

  factory AskReply.fromJson(Map<String, dynamic> j) => AskReply(
    answer: '${j['answer'] ?? ''}',
    sources: [
      for (final s in (j['sources'] as List? ?? const []))
        AskSource.fromJson(s as Map<String, dynamic>),
    ],
    revision: '${j['revision'] ?? ''}',
    stale: j['stale'] == true,
    backend: '${j['backend'] ?? ''}',
    model: '${j['model'] ?? ''}',
  );

  final String answer;
  final List<AskSource> sources;
  final String revision;
  final bool stale;
  final String backend;
  final String model;
}

/// Client for the ask-homelab retrieve-then-generate endpoint on CT 106
/// (`:9113/ask`). Non-streaming; the hosted backend answers in seconds, so
/// the UI shows a thinking bubble rather than tokens.
class AskApi {
  AskApi(this._dio);

  factory AskApi.fromBase(String baseUrl) => AskApi(
    Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        // Hosted answers land in ~3-8s; leave headroom for a slow
        // retrieval + generation without hanging the tab forever.
        receiveTimeout: const Duration(seconds: 120),
      ),
    ),
  );

  final Dio _dio;

  Future<AskReply> ask(
    String question, {
    List<AskTurn> history = const [],
  }) async {
    final Response<Map<String, dynamic>> res;
    try {
      res = await _dio.post<Map<String, dynamic>>(
        '/ask',
        data: {
          'question': question,
          if (history.isNotEmpty)
            'history': [
              for (final t in history) {'role': t.role, 'content': t.content},
            ],
        },
      );
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? '${(e.response!.data as Map)['error'] ?? e.message}'
          : null;
      throw AskException(switch (e.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout =>
          'Cannot reach the Ask endpoint — is ask-homelab up on CT 106?',
        DioExceptionType.receiveTimeout =>
          'The Ask endpoint took too long to answer.',
        _ => detail ?? 'Ask call failed: ${e.message}',
      });
    }
    final data = res.data;
    if (data == null || data['answer'] == null) {
      throw const AskException('The Ask endpoint returned no answer.');
    }
    return AskReply.fromJson(data);
  }
}

/// Expected endpoint-side failures the UI surfaces plainly.
class AskException implements Exception {
  const AskException(this.message);
  final String message;
  @override
  String toString() => message;
}
