import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../models/app_settings.dart';
import '../models/docker_container.dart';
import '../models/docker_image.dart';

/// Dio-based client for a Docker Engine API exposed over a LAN TCP socket.
class DockerApi {
  DockerApi(this._dio);

  /// Builds an unauthenticated client for the configured Docker daemon.
  ///
  /// When TLS verification is disabled, the certificate exception is still
  /// restricted to the configured host rather than trusted globally.
  factory DockerApi.fromSettings(AppSettings settings) {
    final dio = Dio(
      BaseOptions(
        baseUrl: settings.dockerUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    if (!settings.dockerTlsVerify) {
      final trustedHost = Uri.tryParse(settings.dockerUrl)?.host;
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () =>
            HttpClient()
              ..badCertificateCallback = (cert, host, port) =>
                  trustedHost != null && host == trustedHost,
      );
    }
    return DockerApi(dio);
  }

  final Dio _dio;

  Future<List<DockerContainer>> getContainers() async {
    final data = await _getList('/containers/json?all=1');
    return data.map(DockerContainer.fromJson).toList();
  }

  Future<Map<String, dynamic>> inspectContainer(String id) =>
      _getMap('/containers/$id/json');

  Future<void> startContainer(String id) => _post('/containers/$id/start');

  Future<void> stopContainer(String id) => _post('/containers/$id/stop');

  Future<void> restartContainer(String id) => _post('/containers/$id/restart');

  Future<String> getContainerLogs(String id) async {
    final response = await _dio.get<String>(
      '/containers/$id/logs?stdout=1&stderr=1&tail=200',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  Future<List<DockerImage>> getImages() async {
    final data = await _getList('/images/json');
    return data.map(DockerImage.fromJson).toList();
  }

  Future<Map<String, dynamic>> getVersion() => _getMap('/version');

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _dio.get<List<dynamic>>(path);
    return (response.data ?? const []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    return response.data ?? const {};
  }

  Future<void> _post(String path) async {
    await _dio.post<void>(path);
  }
}
