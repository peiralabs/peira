import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Builds a Dio client for a media server: caller-supplied auth [headers]
/// plus the host-scoped self-signed-certificate exception, matching the
/// servarr/Proxmox clients. [adapter] (tests) replaces the transport and
/// skips the trust wiring.
Dio mediaDio(
  String url, {
  required Map<String, String> headers,
  bool trustSelfSigned = false,
  HttpClientAdapter? adapter,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: url,
      headers: headers,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  if (adapter != null) {
    dio.httpClientAdapter = adapter;
  } else if (trustSelfSigned) {
    final trustedHost = Uri.tryParse(url)?.host;
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback =
            (cert, host, port) => trustedHost != null && host == trustedHost,
    );
  }
  return dio;
}
