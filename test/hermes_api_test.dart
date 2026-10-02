import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/hermes_api.dart';

/// Records every request and serves a fixed OpenAI-style completion (or a
/// bare error body for non-2xx [status]).
class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter({this.status = 200, this.body});

  final int status;

  /// Overrides the default completion body when set.
  final String? body;

  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    final payload = body ??
        jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': ' hi there '}
            }
          ],
        });
    return ResponseBody.fromString(payload, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _endpoint = 'http://ai.example:11434';

void main() {
  test('sends the fixed hermes-agent model by default and trims the reply',
      () async {
    final adapter = _CaptureAdapter();
    final api = HermesApi(_endpoint, 'k3y', adapter: adapter);
    final reply = await api.chat([(role: 'user', content: 'hello')]);
    expect(reply, 'hi there');
    final sent = adapter.last!.data as Map;
    expect(sent['model'], 'hermes-agent');
    expect(sent['messages'], [
      {'role': 'user', 'content': 'hello'},
    ]);
    expect(adapter.last!.headers['Authorization'], 'Bearer k3y');
  });

  test('a configured model reaches the request payload', () async {
    final adapter = _CaptureAdapter();
    final api = HermesApi(_endpoint, 'k3y', model: 'llama3.2', adapter: adapter);
    await api.chat([(role: 'user', content: 'hello')]);
    expect((adapter.last!.data as Map)['model'], 'llama3.2');
  });

  test('an empty key sends no Authorization header (open local daemons)',
      () async {
    final adapter = _CaptureAdapter();
    final api = HermesApi(_endpoint, '', adapter: adapter);
    await api.chat([(role: 'user', content: 'hello')]);
    final headerNames =
        adapter.last!.headers.keys.map((k) => k.toLowerCase());
    expect(headerNames, isNot(contains('authorization')));
  });

  test('401 maps to the auth exception naming the API key', () async {
    final api = HermesApi(_endpoint, 'wrong',
        adapter: _CaptureAdapter(status: 401, body: '{"error":"nope"}'));
    await expectLater(
      api.chat([(role: 'user', content: 'hello')]),
      throwsA(isA<HermesAuthException>()
          .having((e) => e.message, 'message', contains('API key'))),
    );
  });

  test('an empty choices list surfaces a plain no-reply error', () async {
    final api = HermesApi(_endpoint, 'k3y',
        adapter: _CaptureAdapter(body: '{"choices":[]}'));
    await expectLater(
      api.chat([(role: 'user', content: 'hello')]),
      throwsA(isA<HermesException>()
          .having((e) => e.message, 'message', contains('no reply'))),
    );
  });
}
