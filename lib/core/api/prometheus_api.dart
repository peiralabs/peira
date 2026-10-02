import 'package:dio/dio.dart';

import '../models/app_settings.dart';

/// One labelled time series from a Prometheus range query.
class MetricSeries {
  const MetricSeries({required this.label, required this.points});

  /// Display label — the node name once relabelled, else the raw instance.
  final String label;

  /// (unix seconds, value) pairs, ascending.
  final List<(double, double)> points;
}

/// Minimal read-only Prometheus HTTP API client for the Metrics tab.
class PrometheusApi {
  PrometheusApi(this._dio);

  factory PrometheusApi.fromSettings(AppSettings settings) {
    return PrometheusApi(
      Dio(
        BaseOptions(
          baseUrl: '${settings.prometheusEndpoint}/api/v1',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 20),
        ),
      ),
    );
  }

  final Dio _dio;

  /// Range query over the trailing [range], sized to ~[samples] points.
  ///
  /// [labelOf] overrides the default instance-based series labelling — for
  /// series whose identity lives in other labels (pushed NAS metrics carry
  /// no scrape instance; disks label by host+device, speedtests by site).
  Future<List<MetricSeries>> rangeQuery(
    String promql, {
    required Duration range,
    int samples = 120,
    Map<String, String> relabel = const {},
    String Function(Map<String, dynamic> metric)? labelOf,
  }) async {
    final end = DateTime.now().toUtc();
    final start = end.subtract(range);
    final step = (range.inSeconds / samples).ceil().clamp(15, 86400);
    final res = await _dio.get<Map<String, dynamic>>(
      '/query_range',
      queryParameters: {
        'query': promql,
        'start': start.millisecondsSinceEpoch / 1000,
        'end': end.millisecondsSinceEpoch / 1000,
        'step': step,
      },
    );
    final result = (res.data?['data']?['result'] as List?) ?? const <dynamic>[];
    return [
      for (final r in result.cast<Map<String, dynamic>>())
        MetricSeries(
          label: labelOf != null
              ? labelOf((r['metric'] as Map<String, dynamic>?) ?? const {})
              : _labelFor(r['metric'] as Map<String, dynamic>?, relabel),
          points: [
            // Skip non-finite samples: histogram_quantile emits literal
            // "NaN" over idle windows (tryParse parses it to double.nan),
            // and fl_chart draws NaN spots — corrupt gradient rects.
            for (final v in (r['values'] as List? ?? const []))
              if (double.tryParse('${v[1]}') case final y? when y.isFinite)
                ((v[0] as num).toDouble(), y),
          ],
        ),
    ]..sort((a, b) => a.label.compareTo(b.label));
  }

  /// Instant query: (labels, value) per series.
  Future<List<(Map<String, dynamic>, double)>> instantQuery(
    String promql,
  ) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/query',
      queryParameters: {'query': promql},
    );
    final result = (res.data?['data']?['result'] as List?) ?? const <dynamic>[];
    return [
      for (final r in result.cast<Map<String, dynamic>>())
        (
          r['metric'] as Map<String, dynamic>? ?? const {},
          double.tryParse('${(r['value'] as List)[1]}') ?? 0,
        ),
    ];
  }

  /// instance → nodename map from node_uname_info, so series can be labelled
  /// with real node names instead of scrape addresses (no hardcoded IPs).
  Future<Map<String, String>> nodeNames() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/query',
      queryParameters: {'query': 'node_uname_info'},
    );
    final result = (res.data?['data']?['result'] as List?) ?? const <dynamic>[];
    return {
      for (final r in result.cast<Map<String, dynamic>>())
        if (r['metric'] case {
          'instance': final String instance,
          'nodename': final String nodename,
        })
          instance: nodename,
    };
  }

  static String _labelFor(
    Map<String, dynamic>? metric,
    Map<String, String> relabel,
  ) {
    final instance = '${metric?['instance'] ?? ''}';
    return relabel[instance] ?? instance;
  }
}
