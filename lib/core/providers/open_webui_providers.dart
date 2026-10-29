import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/open_webui_api.dart';
import 'settings_providers.dart';

part 'open_webui_providers.g.dart';

class OpenWebUiNotConfigured implements Exception {
  const OpenWebUiNotConfigured();
}

@riverpod
Future<OpenWebUiApi> openWebUiApi(Ref ref) async {
  final s = await ref.watch(settingsControllerProvider.future);
  if (!s.openWebuiConfigured) throw const OpenWebUiNotConfigured();
  return OpenWebUiApi.fromSettings(
    url: s.ollamaUrl,
    apiKey: s.openWebuiApiKey,
    trustSelfSigned: s.trustSelfSigned,
  );
}

@riverpod
Future<List<OwModel>> owModels(Ref ref) async =>
    (await ref.watch(openWebUiApiProvider.future)).models();

@riverpod
Future<List<OwKnowledge>> owKnowledge(Ref ref) async =>
    (await ref.watch(openWebUiApiProvider.future)).knowledge();

@riverpod
Future<List<OwChatSummary>> owChats(Ref ref, String query) async {
  final api = await ref.watch(openWebUiApiProvider.future);
  if (query.isNotEmpty) return api.searchChats(query);
  final pinned = await api.pinned();
  final ids = {for (final p in pinned) p.id};
  return [...pinned, ...(await api.chats()).where((c) => !ids.contains(c.id))];
}
