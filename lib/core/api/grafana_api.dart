import 'package:dio/dio.dart';

import '../models/app_settings.dart';
import '../models/grafana_alert.dart';

/// Client for Grafana's Alertmanager-compatible alerts API.
class GrafanaApi {
  GrafanaApi(this._dio);

  factory GrafanaApi.fromSettings(AppSettings settings) {
    return GrafanaApi(
      Dio(
        BaseOptions(
          baseUrl: settings.grafanaUrl,
          headers: {
            if (settings.grafanaApiKey.isNotEmpty)
              'Authorization': 'Bearer ${settings.grafanaApiKey}',
          },
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        ),
      ),
    );
  }

  final Dio _dio;

  /// Firing alerts, newest first; suppressed (silenced) ones excluded.
  Future<List<GrafanaAlert>> getActiveAlerts() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/alertmanager/grafana/api/v2/alerts',
    );
    final alerts =
        (response.data ?? const [])
            .cast<Map<String, dynamic>>()
            .map(GrafanaAlert.fromJson)
            .where((a) => !a.isSuppressed)
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return alerts;
  }
}
