import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../models/app_settings.dart';
import '../models/qbittorrent_torrent.dart';

/// Thrown for expected qBittorrent failures (auth rejected, unreachable) so
/// the UI shows a message instead of a stack trace.
class QbittorrentException implements Exception {
  const QbittorrentException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Client for the qBittorrent WebUI API (`/api/v2`).
///
/// Auth is cookie-based: POST the WebUI username/password to
/// `/api/v2/auth/login`, then send the returned `SID` cookie on every call.
/// qBittorrent 5.x renamed pause/resume to stop/start, which this uses.
/// If no credentials are configured the client assumes the WebUI allows
/// unauthenticated access (bypass-auth subnet).
class QbittorrentApi {
  QbittorrentApi(this._dio, this._user, this._pass);

  factory QbittorrentApi.fromSettings(AppSettings s) {
    final dio = Dio(
      BaseOptions(
        baseUrl: s.qbittorrentUrl,
        // qBittorrent validates Referer/Origin unless host-header checks are
        // off; send a matching Referer to be safe.
        headers: {'Referer': s.qbittorrentUrl},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    if (s.trustSelfSigned) {
      final trustedHost = Uri.tryParse(s.qbittorrentUrl)?.host;
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => HttpClient()
          ..badCertificateCallback = (cert, host, port) =>
              trustedHost != null && host == trustedHost,
      );
    }
    return QbittorrentApi(dio, s.qbittorrentUser, s.qbittorrentPass);
  }

  final Dio _dio;
  final String _user;
  final String _pass;
  bool _authed = false;

  Future<void> _ensureAuth() async {
    if (_authed || _user.isEmpty) return;
    final Response res;
    try {
      res = await _dio.post<String>(
        '/api/v2/auth/login',
        data: {'username': _user, 'password': _pass},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          // qBit returns 200 "Ok." (v4) or 204 (v5); accept any non-error.
          validateStatus: (s) => s != null && s < 500,
        ),
      );
    } on DioException catch (e) {
      throw QbittorrentException('qBittorrent unreachable: ${e.message}');
    }
    if (res.statusCode == 403 || (res.data is String && res.data == 'Fails.')) {
      throw const QbittorrentException('qBittorrent login rejected');
    }
    final setCookie = res.headers.map['set-cookie'];
    final sid = setCookie
        ?.map((c) => RegExp(r'SID=([^;]+)').firstMatch(c)?.group(1))
        .firstWhere((v) => v != null, orElse: () => null);
    if (sid != null) {
      _dio.options.headers['Cookie'] = 'SID=$sid';
    }
    _authed = true;
  }

  Future<List<QbittorrentTorrent>> torrents() async {
    await _ensureAuth();
    final res = await _dio.get<List<dynamic>>(
      '/api/v2/torrents/info',
      queryParameters: {'sort': 'added_on', 'reverse': true},
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(QbittorrentTorrent.fromJson)
        .toList();
  }

  Future<void> _hashesCommand(String path, String hash) async {
    await _ensureAuth();
    await _dio.post(
      path,
      data: {'hashes': hash},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<void> stop(String hash) => _hashesCommand('/api/v2/torrents/stop', hash);
  Future<void> start(String hash) =>
      _hashesCommand('/api/v2/torrents/start', hash);

  Future<void> delete(String hash, {bool deleteFiles = false}) async {
    await _ensureAuth();
    await _dio.post(
      '/api/v2/torrents/delete',
      data: {'hashes': hash, 'deleteFiles': deleteFiles},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<void> addMagnet(String magnet, {String? category}) async {
    await _ensureAuth();
    await _dio.post(
      '/api/v2/torrents/add',
      data: {'urls': magnet, 'category': ?category},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }
}
