import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/wikijs_api.dart';
import 'settings_providers.dart';

part 'wikijs_providers.g.dart';

class WikiJsNotConfigured implements Exception {
  const WikiJsNotConfigured();
}

@riverpod
Future<WikiJsApi> wikiJsApi(Ref ref) async {
  final s = await ref.watch(settingsControllerProvider.future);
  if (!s.wikiConfigured) throw const WikiJsNotConfigured();
  return WikiJsApi.fromSettings(
    url: s.wikiUrl,
    apiKey: s.wikiApiKey,
    trustSelfSigned: s.trustSelfSigned,
  );
}

@riverpod
Future<List<WikiPageItem>> wikiPages(
  Ref ref,
  String orderBy,
  String? tag,
) async => (await ref.watch(
  wikiJsApiProvider.future,
)).pages(orderBy: orderBy, tags: tag == null ? null : [tag]);

@riverpod
Future<WikiPage> wikiPage(Ref ref, int id) async =>
    (await ref.watch(wikiJsApiProvider.future)).page(id);

@riverpod
Future<List<WikiHistoryEntry>> wikiHistory(Ref ref, int id) async =>
    (await ref.watch(wikiJsApiProvider.future)).history(id);

@riverpod
Future<List<WikiTag>> wikiTags(Ref ref) async =>
    (await ref.watch(wikiJsApiProvider.future)).tags();

@riverpod
Future<Map<String, dynamic>> wikiSystem(Ref ref) async =>
    (await ref.watch(wikiJsApiProvider.future)).systemInfo();
