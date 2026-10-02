import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/ask_api.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, {this.status = 200});

  final String body;
  final int status;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AskApi _api(_FakeAdapter adapter) => AskApi(
  Dio(BaseOptions(baseUrl: 'http://ask.example:9113'))
    ..httpClientAdapter = adapter,
);

// The ask-homelab endpoint's /ask response shape (see
// ~/Projects/ask-homelab/README.md).
const _replyJson = '''
{
  "answer": "The heartbeat paged after Plex Cloud returned 522s [1].",
  "sources": [
    {
      "n": 1,
      "wiki_path": "journal/2026-07-22-media-sync-plex-cloud-denoise",
      "anchor": "alert",
      "title": "Media-sync Plex-cloud flap de-noise",
      "heading": "Alert",
      "region": ["nas"],
      "score": 0.7,
      "snippet": "Uptime Kuma media-sync heartbeat paged down."
    }
  ],
  "revision": "1e76a95bb35ee6bfa70529c5b6d7388ebc408006",
  "canonical_head": "1e76a95bb35ee6bfa70529c5b6d7388ebc408006",
  "stale": false,
  "backend": "hosted",
  "model": "claude-haiku-4-5-20251001",
  "usage": {"input_tokens": 4000, "output_tokens": 60},
  "timings_ms": {"embed": 344, "retrieve": 4, "generate": 3241, "total": 3590}
}
''';

void main() {
  test('ask parses answer, citations, and the revision label; sends the '
      'question + prior history', () async {
    final adapter = _FakeAdapter(_replyJson);
    final reply = await _api(adapter).ask(
      'Why did media-sync page at 5am?',
      history: const [
        (role: 'user', content: 'earlier question'),
        (role: 'assistant', content: 'earlier answer'),
      ],
    );

    expect(reply.answer, contains('Plex Cloud'));
    expect(reply.sources, hasLength(1));
    expect(reply.sources.first.n, 1);
    expect(
      reply.sources.first.ref,
      'journal/2026-07-22-media-sync-plex-cloud-denoise#alert',
    );
    expect(reply.revision, startsWith('1e76a95b'));
    expect(reply.stale, isFalse);
    expect(reply.backend, 'hosted');
    expect(reply.model, 'claude-haiku-4-5-20251001');

    final req = adapter.requests.single;
    expect(req.path, '/ask');
    final sent = req.data as Map<String, dynamic>;
    expect(sent['question'], 'Why did media-sync page at 5am?');
    expect(sent['history'], hasLength(2));
    expect((sent['history'] as List).first, {
      'role': 'user',
      'content': 'earlier question',
    });
  });

  test('a stale index is labeled, never silent', () {
    final j = jsonDecode(_replyJson) as Map<String, dynamic>
      ..['stale'] = true;
    expect(AskReply.fromJson(j).stale, isTrue);
  });

  test('endpoint validation errors surface as AskException with the '
      'server message', () async {
    final adapter = _FakeAdapter(
      '{"error": "question: non-empty string, max 2000 chars"}',
      status: 400,
    );
    expect(
      () => _api(adapter).ask('x'),
      throwsA(
        isA<AskException>().having(
          (e) => e.message,
          'message',
          contains('non-empty string'),
        ),
      ),
    );
  });

  test('a bodyless reply maps to AskException', () async {
    final adapter = _FakeAdapter('{"sources": []}');
    expect(
      () => _api(adapter).ask('x'),
      throwsA(isA<AskException>()),
    );
  });
}
