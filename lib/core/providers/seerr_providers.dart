import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/seerr_api.dart';
import 'settings_providers.dart';

part 'seerr_providers.g.dart';

class SeerrNotConfigured implements Exception {
  const SeerrNotConfigured();
}

@riverpod
Future<SeerrApi> seerrApi(Ref ref) async {
  final s = await ref.watch(settingsControllerProvider.future);
  if (!s.jellyseerrConfigured) throw const SeerrNotConfigured();
  return SeerrApi.fromSettings(
    url: s.jellyseerrUrl,
    apiKey: s.jellyseerrApiKey,
    trustSelfSigned: s.trustSelfSigned,
  );
}

/// Title details, kept for the session: the request list resolves its
/// titles through this, one fetch per title.
@Riverpod(keepAlive: true)
Future<SeerrDetails> seerrDetails(
  Ref ref,
  String mediaType,
  int tmdbId,
) async =>
    (await ref.watch(seerrApiProvider.future)).details(mediaType, tmdbId);

@riverpod
Future<({List<SeerrRequest> requests, int total})> seerrRequests(
  Ref ref,
  String filter,
) async => (await ref.watch(seerrApiProvider.future)).requests(filter: filter);

@riverpod
Future<Map<String, dynamic>> seerrCounts(Ref ref) async =>
    (await ref.watch(seerrApiProvider.future)).requestCounts();

@riverpod
Future<List<SeerrIssue>> seerrIssues(Ref ref, String filter) async =>
    (await ref.watch(seerrApiProvider.future)).issues(filter: filter);
