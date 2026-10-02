import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/grafana_api.dart';
import '../models/grafana_alert.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'grafana_providers.g.dart';

/// Thrown while no Grafana URL has been entered yet.
class GrafanaNotConfigured implements Exception {
  const GrafanaNotConfigured();
}

@riverpod
Future<GrafanaApi> grafanaApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (settings.grafanaUrl.isEmpty) throw const GrafanaNotConfigured();
  return GrafanaApi.fromSettings(settings);
}

@riverpod
Future<List<GrafanaAlert>> activeAlerts(Ref ref) async {
  final api = await ref.watch(grafanaApiProvider.future);
  autoRefresh(ref);
  return api.getActiveAlerts();
}
