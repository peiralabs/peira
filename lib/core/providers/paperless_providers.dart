import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/paperless_api.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'paperless_providers.g.dart';

class PaperlessNotConfigured implements Exception {
  const PaperlessNotConfigured();
}

@riverpod
Future<PaperlessApi> paperlessApi(Ref ref) async {
  final s = await ref.watch(settingsControllerProvider.future);
  if (!s.paperlessConfigured) throw const PaperlessNotConfigured();
  return PaperlessApi.fromSettings(
    url: s.paperlessUrl,
    token: s.paperlessToken,
    trustSelfSigned: s.trustSelfSigned,
  );
}

/// `tags`, `correspondents`, `document_types` or `storage_paths`.
@riverpod
Future<List<PlLabel>> plLabels(Ref ref, String kind) async =>
    (await ref.watch(paperlessApiProvider.future)).labels(kind);

@riverpod
Future<PlDocument> plDocument(Ref ref, int id) async =>
    (await ref.watch(paperlessApiProvider.future)).document(id);

@riverpod
Future<({List<PlTask> tasks, int count})> plTasks(Ref ref) async {
  final api = await ref.watch(paperlessApiProvider.future);
  autoRefresh(ref);
  return api.tasks();
}

@riverpod
Future<Map<String, dynamic>> plStats(Ref ref) async =>
    (await ref.watch(paperlessApiProvider.future)).statistics();
