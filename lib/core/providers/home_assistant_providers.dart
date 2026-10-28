import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/home_assistant_api.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'home_assistant_providers.g.dart';

/// Thrown by the Home Assistant providers until a URL and long-lived token
/// are saved; the tab renders its setup prompt on it.
class HomeAssistantNotConfigured implements Exception {
  const HomeAssistantNotConfigured();
}

@riverpod
Future<HomeAssistantApi> homeAssistantApi(Ref ref) async {
  final s = await ref.watch(settingsControllerProvider.future);
  if (!s.homeAssistantConfigured) throw const HomeAssistantNotConfigured();
  return HomeAssistantApi.fromSettings(
    url: s.homeAssistantUrl,
    token: s.homeAssistantToken,
    trustSelfSigned: s.trustSelfSigned,
  );
}

@riverpod
Future<Map<String, dynamic>> haConfig(Ref ref) async =>
    (await ref.watch(homeAssistantApiProvider.future)).config();

/// Every entity, refreshed every 30 s (and right after any service call).
@riverpod
Future<List<HaEntity>> haStates(Ref ref) async {
  final api = await ref.watch(homeAssistantApiProvider.future);
  autoRefresh(ref);
  return api.states();
}

@riverpod
Future<List<HaService>> haServices(Ref ref) async =>
    (await ref.watch(homeAssistantApiProvider.future)).services();

@riverpod
Future<List<HaLogbookEntry>> haLogbook(Ref ref, int hours) async {
  final api = await ref.watch(homeAssistantApiProvider.future);
  autoRefresh(ref);
  return api.logbook(since: DateTime.now().subtract(Duration(hours: hours)));
}

@riverpod
Future<List<HaHistoryPoint>> haHistory(Ref ref, String entityId) async =>
    (await ref.watch(homeAssistantApiProvider.future)).history(
      entityId,
      since: DateTime.now().subtract(const Duration(hours: 24)),
    );

@riverpod
Future<List<HaTodoItem>> haTodoItems(Ref ref, String entityId) async =>
    (await ref.watch(homeAssistantApiProvider.future)).todoItems(entityId);
