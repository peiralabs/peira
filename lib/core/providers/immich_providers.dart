import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/immich_api.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'immich_providers.g.dart';

class ImmichNotConfigured implements Exception {
  const ImmichNotConfigured();
}

@riverpod
Future<ImmichApi> immichApi(Ref ref) async {
  final s = await ref.watch(settingsControllerProvider.future);
  if (!s.immichConfigured) throw const ImmichNotConfigured();
  return ImmichApi.fromSettings(
    url: s.immichUrl,
    apiKey: s.immichApiKey,
    trustSelfSigned: s.trustSelfSigned,
  );
}

@riverpod
Future<ImmichServer> immichServer(Ref ref) async {
  final api = await ref.watch(immichApiProvider.future);
  autoRefresh(ref);
  return api.server();
}

@riverpod
Future<List<ImmichQueue>> immichQueues(Ref ref) async {
  final api = await ref.watch(immichApiProvider.future);
  autoRefresh(ref);
  return api.queues();
}

@riverpod
Future<List<ImmichAlbum>> immichAlbums(Ref ref) async =>
    (await ref.watch(immichApiProvider.future)).albums();

@riverpod
Future<ImmichAlbum> immichAlbum(Ref ref, String id) async =>
    (await ref.watch(immichApiProvider.future)).album(id);

@riverpod
Future<List<ImmichPerson>> immichPeople(Ref ref) async =>
    (await ref.watch(immichApiProvider.future)).people();

@riverpod
Future<List<ImmichMemory>> immichMemories(Ref ref) async =>
    (await ref.watch(immichApiProvider.future)).memories();

@riverpod
Future<List<ImmichDuplicateGroup>> immichDuplicates(Ref ref) async =>
    (await ref.watch(immichApiProvider.future)).duplicates();

@riverpod
Future<ImmichAsset> immichAsset(Ref ref, String id) async =>
    (await ref.watch(immichApiProvider.future)).asset(id);
