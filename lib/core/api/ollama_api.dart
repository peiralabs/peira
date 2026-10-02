import 'dart:convert';

import 'package:dio/dio.dart';

/// One locally-installed model as reported by the Ollama daemon's
/// `/api/tags`. Plain class + manual JSON (like the Proxmox storages /
/// templates maps) — no codegen for this small, stable payload.
class OllamaModel {
  const OllamaModel({
    required this.name,
    required this.sizeBytes,
    required this.parameterSize,
    required this.quantization,
  });

  factory OllamaModel.fromJson(Map<String, dynamic> json) {
    final details = (json['details'] as Map?)?.cast<String, dynamic>();
    return OllamaModel(
      name: (json['name'] as String?) ?? '',
      sizeBytes: (json['size'] as num?)?.toInt() ?? 0,
      parameterSize: (details?['parameter_size'] as String?) ?? '',
      quantization: (details?['quantization_level'] as String?) ?? '',
    );
  }

  final String name;
  final int sizeBytes;
  final String parameterSize;
  final String quantization;

  /// Human size: GB with one decimal, or MB below 1 GB.
  String get sizeLabel {
    if (sizeBytes <= 0) return '—';
    const gb = 1 << 30;
    if (sizeBytes >= gb) return '${(sizeBytes / gb).toStringAsFixed(1)} GB';
    return '${(sizeBytes / (1 << 20)).round()} MB';
  }
}

/// A `/api/pull` streaming progress line.
typedef OllamaPullProgress = ({String status, int? completed, int? total});

/// Native client for the Ollama daemon API (`:11434`), Dio-based like
/// the other service clients.
class OllamaApi {
  OllamaApi(this.baseUrl, {HttpClientAdapter? adapter})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            // Fail fast when the daemon host is unreachable — a wrong endpoint
            // (e.g. the derived Open WebUI host that isn't running the daemon)
            // should surface an actionable error in a few seconds, not hang.
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ) {
    // Test seam: inject a fake transport without exposing the Dio.
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  /// The daemon URL this client targets, surfaced in error messages so a
  /// misconfigured endpoint is diagnosable.
  final String baseUrl;
  final Dio _dio;

  /// Installed models from `/api/tags`, largest first.
  Future<List<OllamaModel>> listModels() async {
    final res = await _get('/api/tags');
    final models = (res.data?['models'] as List?) ?? const [];
    return models
        .cast<Map<String, dynamic>>()
        .map(OllamaModel.fromJson)
        .toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
  }

  /// Names of models currently loaded in memory, from `/api/ps`.
  Future<Set<String>> listRunning() async {
    final res = await _get('/api/ps');
    final models = (res.data?['models'] as List?) ?? const [];
    return {
      for (final m in models.cast<Map<String, dynamic>>())
        if (m['name'] is String) m['name'] as String,
    };
  }

  /// GET wrapper that maps Dio transport failures to a friendly, endpoint-aware
  /// [OllamaUnreachable] so the UI never shows a raw `DioException […]` dump.
  Future<Response<Map<String, dynamic>>> _get(String path) async {
    try {
      return await _dio.get<Map<String, dynamic>>(path);
    } on DioException catch (e) {
      throw OllamaUnreachable(baseUrl, e);
    }
  }

  /// Pulls [name], streaming `/api/pull` JSON progress lines to [onProgress].
  /// Completes when the stream ends; throws on transport errors or an
  /// `error` status line.
  Future<void> pullModel(
    String name,
    void Function(OllamaPullProgress progress) onProgress,
  ) async {
    final Response<ResponseBody> res;
    try {
      res = await _dio.post<ResponseBody>(
        '/api/pull',
        data: {'name': name, 'stream': true},
        options: Options(
          responseType: ResponseType.stream,
          // Large pulls stream for a long time between our reads.
          receiveTimeout: const Duration(minutes: 30),
        ),
      );
    } on DioException catch (e) {
      throw OllamaUnreachable(baseUrl, e);
    }
    final lines = utf8.decoder
        .bind(res.data!.stream)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(line) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
      final error = json['error'];
      if (error is String && error.isNotEmpty) {
        throw OllamaPullException(error);
      }
      onProgress((
        status: (json['status'] as String?) ?? '',
        completed: (json['completed'] as num?)?.toInt(),
        total: (json['total'] as num?)?.toInt(),
      ));
    }
  }
}

/// A pull the daemon rejected (unknown model, disk full, …).
class OllamaPullException implements Exception {
  const OllamaPullException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A transport failure reaching the Ollama daemon, translated from a
/// [DioException] into a human, endpoint-aware message. Carries [endpoint] so
/// the UI can show which URL it tried (making a wrong/derived host obvious).
class OllamaUnreachable implements Exception {
  OllamaUnreachable(this.endpoint, DioException cause)
      : message = _friendly(endpoint, cause);

  final String endpoint;
  final String message;

  static String _friendly(String endpoint, DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The Ollama daemon didn’t respond in time. Check that '
            'ollama serve is running and reachable at this address.';
      case DioExceptionType.connectionError:
        return 'Couldn’t connect to the Ollama daemon. Is ollama serve '
            'running on that host, and is the port open?';
      case DioExceptionType.badCertificate:
        return 'The Ollama daemon presented a certificate that couldn’t be '
            'verified.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return 'The Ollama daemon returned '
            '${code == null ? 'an error' : 'HTTP $code'}.';
      case DioExceptionType.transformTimeout:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return 'Couldn’t reach the Ollama daemon.';
    }
  }

  @override
  String toString() => message;
}
