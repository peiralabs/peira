import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../models/app_settings.dart';
import '../models/prowlarr_indexer.dart';
import '../models/prowlarr_release.dart';
import '../models/radarr_movie.dart';
import '../models/servarr_queue_item.dart';
import '../models/sonarr_series.dart';

/// Builds a Dio client for a *arr (Servarr) service: `X-Api-Key` auth plus the
/// host-scoped self-signed-certificate exception, matching [ProxmoxApi].
Dio _servarrDio(String url, String apiKey, bool trustSelfSigned) {
  final dio = Dio(
    BaseOptions(
      baseUrl: url,
      headers: {'X-Api-Key': apiKey},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  if (trustSelfSigned) {
    final trustedHost = Uri.tryParse(url)?.host;
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback =
            (cert, host, port) => trustedHost != null && host == trustedHost,
    );
  }
  return dio;
}

/// Shared plumbing for the three v3/v1-style *arr JSON APIs.
abstract class _ServarrBase {
  _ServarrBase(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> _getList(String path, [
    Map<String, dynamic>? query,
  ]) async {
    final res = await _dio.get<List<dynamic>>(path, queryParameters: query);
    return (res.data ?? const []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _getMap(String path, [
    Map<String, dynamic>? query,
  ]) async {
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return res.data ?? const {};
  }
}

/// Radarr — movie library, download queue, search/add, monitor toggle.
class RadarrApi extends _ServarrBase {
  RadarrApi(super.dio);

  factory RadarrApi.fromSettings(AppSettings s) => RadarrApi(
    _servarrDio(s.radarrUrl, s.radarrApiKey, s.trustSelfSigned),
  );

  Future<List<RadarrMovie>> getMovies() async {
    final data = await _getList('/api/v3/movie');
    return data.map(RadarrMovie.fromJson).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  Future<List<ServarrQueueItem>> getQueue() async {
    final data = await _getMap('/api/v3/queue', {
      'pageSize': 100,
      'includeUnknownMovieItems': true,
    });
    return ((data['records'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ServarrQueueItem.fromJson)
        .toList();
  }

  Future<List<RadarrMovie>> lookup(String term) async {
    final data = await _getList('/api/v3/movie/lookup', {'term': term});
    return data.map(RadarrMovie.fromJson).toList();
  }

  Future<void> setMonitored(int movieId, bool monitored) => _dio.put(
    '/api/v3/movie/editor',
    data: {
      'movieIds': [movieId],
      'monitored': monitored,
    },
  );

  Future<void> search(int movieId) => _dio.post(
    '/api/v3/command',
    data: {
      'name': 'MoviesSearch',
      'movieIds': [movieId],
    },
  );

  Future<void> deleteQueueItem(int id) => _dio.delete(
    '/api/v3/queue/$id',
    queryParameters: {'removeFromClient': true, 'blocklist': true},
  );

  /// Adds a movie by TMDb id (from [lookup]), using the first quality profile
  /// and root folder, monitored + searched immediately.
  Future<void> add(RadarrMovie movie) async {
    final profiles = await _getList('/api/v3/qualityprofile');
    final roots = await _getList('/api/v3/rootfolder');
    if (profiles.isEmpty || roots.isEmpty) {
      throw const ServarrException('No quality profile or root folder set');
    }
    await _dio.post(
      '/api/v3/movie',
      data: {
        'title': movie.title,
        'tmdbId': movie.tmdbId,
        'year': movie.year,
        'qualityProfileId': profiles.first['id'],
        'rootFolderPath': roots.first['path'],
        'monitored': true,
        'minimumAvailability': 'released',
        'addOptions': {'searchForMovie': true},
      },
    );
  }
}

/// Sonarr — series library, download queue, search/add, monitor toggle.
class SonarrApi extends _ServarrBase {
  SonarrApi(super.dio);

  factory SonarrApi.fromSettings(AppSettings s) => SonarrApi(
    _servarrDio(s.sonarrUrl, s.sonarrApiKey, s.trustSelfSigned),
  );

  Future<List<SonarrSeries>> getSeries() async {
    final data = await _getList('/api/v3/series');
    return data.map(SonarrSeries.fromJson).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  Future<List<ServarrQueueItem>> getQueue() async {
    final data = await _getMap('/api/v3/queue', {
      'pageSize': 100,
      'includeUnknownSeriesItems': true,
    });
    return ((data['records'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ServarrQueueItem.fromJson)
        .toList();
  }

  Future<List<SonarrSeries>> lookup(String term) async {
    final data = await _getList('/api/v3/series/lookup', {'term': term});
    return data.map(SonarrSeries.fromJson).toList();
  }

  Future<void> setMonitored(int seriesId, bool monitored) => _dio.put(
    '/api/v3/series/editor',
    data: {
      'seriesIds': [seriesId],
      'monitored': monitored,
    },
  );

  Future<void> search(int seriesId) => _dio.post(
    '/api/v3/command',
    data: {'name': 'SeriesSearch', 'seriesId': seriesId},
  );

  Future<void> deleteQueueItem(int id) => _dio.delete(
    '/api/v3/queue/$id',
    queryParameters: {'removeFromClient': true, 'blocklist': true},
  );

  /// Adds a series by TVDb id (from [lookup]), first-season-monitored and
  /// searched, matching the NAS Plex-Watchlist behavior.
  Future<void> add(SonarrSeries series) async {
    final profiles = await _getList('/api/v3/qualityprofile');
    final roots = await _getList('/api/v3/rootfolder');
    if (profiles.isEmpty || roots.isEmpty) {
      throw const ServarrException('No quality profile or root folder set');
    }
    await _dio.post(
      '/api/v3/series',
      data: {
        'title': series.title,
        'tvdbId': series.tvdbId,
        'qualityProfileId': profiles.first['id'],
        'rootFolderPath': roots.first['path'],
        'monitored': true,
        'seasonFolder': true,
        'addOptions': {
          'monitor': 'firstSeason',
          'searchForMissingEpisodes': true,
        },
      },
    );
  }
}

/// Prowlarr — indexer list and cross-indexer release search (v1 API).
class ProwlarrApi extends _ServarrBase {
  ProwlarrApi(super.dio);

  factory ProwlarrApi.fromSettings(AppSettings s) => ProwlarrApi(
    _servarrDio(s.prowlarrUrl, s.prowlarrApiKey, s.trustSelfSigned),
  );

  Future<List<ProwlarrIndexer>> getIndexers() async {
    final data = await _getList('/api/v1/indexer');
    return data.map(ProwlarrIndexer.fromJson).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<ProwlarrRelease>> search(String term) async {
    final data = await _getList('/api/v1/search', {
      'query': term,
      'type': 'search',
      'limit': 100,
    });
    return data.map(ProwlarrRelease.fromJson).toList()
      ..sort((a, b) => b.seeders.compareTo(a.seeders));
  }
}

/// Thrown for expected *arr misconfiguration the UI can surface plainly.
class ServarrException implements Exception {
  const ServarrException(this.message);
  final String message;
  @override
  String toString() => message;
}
