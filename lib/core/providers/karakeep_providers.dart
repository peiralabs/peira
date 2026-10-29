import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/karakeep_api.dart';
import 'settings_providers.dart';

part 'karakeep_providers.g.dart';

class KarakeepNotConfigured implements Exception {
  const KarakeepNotConfigured();
}

@riverpod
Future<KarakeepApi> karakeepApi(Ref ref) async {
  final s = await ref.watch(settingsControllerProvider.future);
  if (!s.karakeepConfigured) throw const KarakeepNotConfigured();
  return KarakeepApi.fromSettings(
    url: s.karakeepUrl,
    apiKey: s.karakeepApiKey,
    trustSelfSigned: s.trustSelfSigned,
  );
}

@riverpod
Future<KkBookmark> kkBookmark(Ref ref, String id) async =>
    (await ref.watch(karakeepApiProvider.future)).bookmark(id);

@riverpod
Future<List<KkTag>> kkTags(Ref ref) async =>
    (await ref.watch(karakeepApiProvider.future)).tags();

@riverpod
Future<List<KkList>> kkLists(Ref ref) async =>
    (await ref.watch(karakeepApiProvider.future)).lists();

@riverpod
Future<List<KkFeed>> kkFeeds(Ref ref) async =>
    (await ref.watch(karakeepApiProvider.future)).feeds();

@riverpod
Future<List<KkHighlight>> kkHighlights(Ref ref) async =>
    (await ref.watch(karakeepApiProvider.future)).highlights();

@riverpod
Future<Map<String, dynamic>> kkStats(Ref ref) async =>
    (await ref.watch(karakeepApiProvider.future)).stats();
