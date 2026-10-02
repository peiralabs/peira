import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ollama_api.dart';
import 'refresh.dart';
import 'settings_providers.dart';

/// Thrown while no Ollama endpoint can be derived from settings; the UI
/// shows a "configure in settings" state instead of an error.
class OllamaNotConfigured implements Exception {
  const OllamaNotConfigured();
}

/// Plain providers (no codegen — the payloads are two tiny lists) mirroring
/// the proxmox_providers idiom: autoDispose + [autoRefresh] for the 30s
/// periodic re-fetch.
final ollamaApiProvider = FutureProvider.autoDispose<OllamaApi>((ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  final endpoint = settings.ollamaApiEndpoint;
  if (endpoint.isEmpty) throw const OllamaNotConfigured();
  return OllamaApi(endpoint);
});

final ollamaModelsProvider =
    FutureProvider.autoDispose<List<OllamaModel>>((ref) async {
  final api = await ref.watch(ollamaApiProvider.future);
  autoRefresh(ref);
  return api.listModels();
});

final ollamaRunningProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final api = await ref.watch(ollamaApiProvider.future);
  autoRefresh(ref);
  return api.listRunning();
});
