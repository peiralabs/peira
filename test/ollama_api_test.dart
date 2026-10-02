import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/ollama_api.dart';

/// Serves a fixed body for every request.
class _OkAdapter implements HttpClientAdapter {
  _OkAdapter(this.body);
  final String body;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Fails every request with the given Dio error type, as an unreachable host
/// would.
class _FailAdapter implements HttpClientAdapter {
  _FailAdapter(this.type);
  final DioExceptionType type;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    throw DioException(requestOptions: options, type: type);
  }

  @override
  void close({bool force = false}) {}
}

const _tagsJson = '''
{"models":[
  {"name":"tiny:1b","size":1073741824,
   "details":{"parameter_size":"1B","quantization_level":"Q4_0"}},
  {"name":"big:7b","size":5368709120,
   "details":{"parameter_size":"7B","quantization_level":"Q4_K_M"}}
]}''';

const _endpoint = 'http://10.0.0.9:11434';

void main() {
  test('listModels parses and sorts largest-first', () async {
    final api = OllamaApi(_endpoint, adapter: _OkAdapter(_tagsJson));
    final models = await api.listModels();
    expect(models.map((m) => m.name), ['big:7b', 'tiny:1b']);
    expect(models.first.sizeLabel, '5.0 GB');
  });

  test('transport failure surfaces a friendly, endpoint-aware error', () async {
    final api = OllamaApi(_endpoint,
        adapter: _FailAdapter(DioExceptionType.connectionError));
    await expectLater(
      api.listModels(),
      throwsA(isA<OllamaUnreachable>()
          .having((e) => e.endpoint, 'endpoint', _endpoint)
          .having((e) => e.message, 'message', contains('ollama serve'))
          .having((e) => e.message, 'no raw dump',
              isNot(contains('DioException')))),
    );
  });

  test('connect timeout maps to a "didn’t respond" message', () async {
    final api = OllamaApi(_endpoint,
        adapter: _FailAdapter(DioExceptionType.connectionTimeout));
    await expectLater(
      api.listModels(),
      throwsA(isA<OllamaUnreachable>()
          .having((e) => e.message, 'message', contains('didn’t respond'))),
    );
  });
}
