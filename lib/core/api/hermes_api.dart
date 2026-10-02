import 'package:dio/dio.dart';

import '../build_config.dart';

/// One chat turn sent to the assistant endpoint.
typedef HermesMessage = ({String role, String content});

/// Native client for an OpenAI-compatible `/v1/chat/completions` endpoint.
///
/// In the personal build this is the Hermes agent (`:8642`) on its fixed
/// `hermes-agent` model route. The public build ships the same client as
/// "AI Chat" against any such server — Ollama `/v1`, LiteLLM, OpenRouter,
/// vLLM — with an operator-configured [model], and no Authorization header
/// when the key is empty (local daemons are typically unauthenticated).
/// Non-streaming by design — an agent can take 10–60s to answer, so the call
/// gets a generous receive timeout and the UI shows a thinking bubble instead
/// of tokens.
class HermesApi {
  HermesApi(
    String baseUrl,
    String apiKey, {
    this.model = 'hermes-agent',
    HttpClientAdapter? adapter,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {
              if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
            },
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 180),
          ),
        ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  final Dio _dio;

  /// Model name sent with every completion request.
  final String model;

  /// Sends the whole transcript and returns the assistant's reply text.
  Future<String> chat(List<HermesMessage> messages) async {
    final Response<Map<String, dynamic>> res;
    try {
      res = await _dio.post<Map<String, dynamic>>(
        '/v1/chat/completions',
        data: {
          'model': model,
          'messages': [
            for (final m in messages) {'role': m.role, 'content': m.content},
          ],
          'stream': false,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const HermesAuthException();
      }
      rethrow;
    }
    final choices = (res.data?['choices'] as List?) ?? const [];
    if (choices.isEmpty) {
      throw const HermesException(
        kPublicBuild
            ? 'The AI endpoint returned no reply.'
            : 'Hermes returned no reply.',
      );
    }
    final message =
        (choices.first as Map?)?['message'] as Map?;
    return (message?['content'] as String?)?.trim() ?? '';
  }
}

/// Expected endpoint-side failures the UI can surface plainly.
class HermesException implements Exception {
  const HermesException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 401 from the endpoint — the stored key is wrong or missing.
class HermesAuthException extends HermesException {
  const HermesAuthException()
      : super(
          kPublicBuild
              ? 'The AI endpoint rejected the request — check the API key '
                  'in Settings.'
              : 'Hermes rejected the request — check the Hermes API key in '
                  'Settings.',
        );
}
