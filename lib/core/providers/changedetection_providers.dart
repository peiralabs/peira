import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/changedetection_api.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'changedetection_providers.g.dart';

class ChangedetectionNotConfigured implements Exception {
  const ChangedetectionNotConfigured();
}

@riverpod
Future<ChangedetectionApi> changedetectionApi(Ref ref) async {
  final s = await ref.watch(settingsControllerProvider.future);
  if (!s.changedetectionConfigured) throw const ChangedetectionNotConfigured();
  return ChangedetectionApi.fromSettings(
    url: s.changedetectionUrl,
    apiKey: s.changedetectionApiKey,
    trustSelfSigned: s.trustSelfSigned,
  );
}

@riverpod
Future<List<CdWatch>> cdWatches(Ref ref) async {
  final api = await ref.watch(changedetectionApiProvider.future);
  autoRefresh(ref);
  return api.watches();
}

@riverpod
Future<CdWatchDetail> cdWatch(Ref ref, String uuid) async =>
    (await ref.watch(changedetectionApiProvider.future)).watch(uuid);

@riverpod
Future<List<int>> cdHistory(Ref ref, String uuid) async =>
    (await ref.watch(changedetectionApiProvider.future)).history(uuid);

@riverpod
Future<List<CdTag>> cdTags(Ref ref) async =>
    (await ref.watch(changedetectionApiProvider.future)).tags();

@riverpod
Future<Map<String, dynamic>> cdSystem(Ref ref) async {
  final api = await ref.watch(changedetectionApiProvider.future);
  autoRefresh(ref);
  return api.systemInfo();
}
