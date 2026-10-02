import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/jellyfin_api.dart';
import '../api/plex_api.dart';
import '../api/qbittorrent_api.dart';
import '../api/servarr_api.dart';
import '../models/media_server_status.dart';
import '../models/prowlarr_indexer.dart';
import '../models/qbittorrent_torrent.dart';
import '../models/radarr_movie.dart';
import '../models/servarr_queue_item.dart';
import '../models/sonarr_series.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'media_providers.g.dart';

/// Thrown while a media service's URL/key hasn't been entered yet; the UI
/// shows a "configure in settings" state instead of an error.
class MediaNotConfigured implements Exception {
  const MediaNotConfigured(this.service);
  final String service;
  @override
  String toString() => '$service is not configured';
}

// ---- Jellyfin --------------------------------------------------------------

@Riverpod(keepAlive: true)
Future<JellyfinApi> jellyfinApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (!settings.jellyfinConfigured) throw const MediaNotConfigured('Jellyfin');
  return JellyfinApi.fromSettings(settings);
}

@riverpod
Future<MediaServerStatus> jellyfinStatus(Ref ref) async {
  final api = await ref.watch(jellyfinApiProvider.future);
  autoRefresh(ref);
  return api.getStatus();
}

// ---- Plex ------------------------------------------------------------------

@Riverpod(keepAlive: true)
Future<PlexApi> plexApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (!settings.plexConfigured) throw const MediaNotConfigured('Plex');
  return PlexApi.fromSettings(settings);
}

@riverpod
Future<MediaServerStatus> plexStatus(Ref ref) async {
  final api = await ref.watch(plexApiProvider.future);
  autoRefresh(ref);
  return api.getStatus();
}

// ---- Radarr ----------------------------------------------------------------

@Riverpod(keepAlive: true)
Future<RadarrApi> radarrApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (!settings.radarrConfigured) throw const MediaNotConfigured('Radarr');
  return RadarrApi.fromSettings(settings);
}

@riverpod
Future<List<RadarrMovie>> radarrMovies(Ref ref) async {
  final api = await ref.watch(radarrApiProvider.future);
  autoRefresh(ref);
  return api.getMovies();
}

@riverpod
Future<List<ServarrQueueItem>> radarrQueue(Ref ref) async {
  final api = await ref.watch(radarrApiProvider.future);
  autoRefresh(ref);
  return api.getQueue();
}

// ---- Sonarr ----------------------------------------------------------------

@Riverpod(keepAlive: true)
Future<SonarrApi> sonarrApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (!settings.sonarrConfigured) throw const MediaNotConfigured('Sonarr');
  return SonarrApi.fromSettings(settings);
}

@riverpod
Future<List<SonarrSeries>> sonarrSeries(Ref ref) async {
  final api = await ref.watch(sonarrApiProvider.future);
  autoRefresh(ref);
  return api.getSeries();
}

@riverpod
Future<List<ServarrQueueItem>> sonarrQueue(Ref ref) async {
  final api = await ref.watch(sonarrApiProvider.future);
  autoRefresh(ref);
  return api.getQueue();
}

// ---- Prowlarr --------------------------------------------------------------

@Riverpod(keepAlive: true)
Future<ProwlarrApi> prowlarrApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (!settings.prowlarrConfigured) throw const MediaNotConfigured('Prowlarr');
  return ProwlarrApi.fromSettings(settings);
}

@riverpod
Future<List<ProwlarrIndexer>> prowlarrIndexers(Ref ref) async {
  final api = await ref.watch(prowlarrApiProvider.future);
  autoRefresh(ref);
  return api.getIndexers();
}

// ---- qBittorrent -----------------------------------------------------------

@Riverpod(keepAlive: true)
Future<QbittorrentApi> qbittorrentApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (!settings.qbittorrentConfigured) {
    throw const MediaNotConfigured('qBittorrent');
  }
  return QbittorrentApi.fromSettings(settings);
}

@riverpod
Future<List<QbittorrentTorrent>> qbittorrentTorrents(Ref ref) async {
  final api = await ref.watch(qbittorrentApiProvider.future);
  autoRefresh(ref);
  return api.torrents();
}
