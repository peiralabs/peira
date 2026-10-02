import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/loki_api.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'loki_providers.g.dart';

/// Thrown while no Loki URL is configured — the Logs sub-tab renders its
/// configure hint instead of an error card.
class LokiNotConfigured implements Exception {
  const LokiNotConfigured();
}

@riverpod
Future<LokiApi> lokiApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (settings.lokiUrl.isEmpty) {
    throw const LokiNotConfigured();
  }
  return LokiApi.fromBase(settings.lokiUrl);
}

/// Host-label values for the filter chips. Fetched once per session; the
/// screen's refresh action invalidates it alongside the tail.
@Riverpod(keepAlive: true)
Future<List<String>> lokiHosts(Ref ref) async {
  final api = await ref.watch(lokiApiProvider.future);
  return api.hostValues();
}

/// Newest-first tail for the current filter, refreshed every 30 s like the
/// other telemetry providers.
@riverpod
Future<List<LokiEntry>> lokiTail(
  Ref ref,
  ({String host, String contains}) filter,
) async {
  final api = await ref.watch(lokiApiProvider.future);
  autoRefresh(ref);
  return api.tail(host: filter.host, contains: filter.contains);
}
