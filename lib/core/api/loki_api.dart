import 'package:dio/dio.dart';

/// One log line from a Loki stream, flattened out of its stream envelope.
class LokiEntry {
  const LokiEntry({
    required this.ts,
    required this.host,
    required this.unit,
    required this.line,
  });

  final DateTime ts;

  /// The shipper's `host` label (every lab stream carries one).
  final String host;

  /// Secondary origin when the stream labels one (systemd unit, container).
  final String unit;

  final String line;
}

/// Minimal read-only Loki HTTP API client for the Logs sub-tab.
///
/// Live-verified against Loki 3.x: `query_range` on a *log* selector returns
/// `data.result[]` items shaped `{stream: {labels}, values: [[ns, line]…]}`
/// — `stream`, not the `metric` key Prometheus uses. `/ready` can 503
/// transiently while queries answer fine, so reachability is judged by the
/// query itself, never the readiness probe.
class LokiApi {
  LokiApi(this._dio);

  factory LokiApi.fromBase(String base) => LokiApi(
        Dio(
          BaseOptions(
            baseUrl: '$base/loki/api/v1',
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ),
      );

  final Dio _dio;

  /// Values of the `host` label — the per-machine filter chips.
  Future<List<String>> hostValues() async {
    final res = await _dio.get<Map<String, dynamic>>('/label/host/values');
    final data = (res.data?['data'] as List?) ?? const [];
    return [for (final v in data) '$v']..sort();
  }

  /// Newest-first log lines over the trailing [since] window. [host] narrows
  /// to one machine ('' = all streams); [contains] becomes a `|=` line
  /// filter.
  Future<List<LokiEntry>> tail({
    String host = '',
    String contains = '',
    Duration since = const Duration(hours: 1),
    int limit = 200,
  }) async {
    // Loki requires a non-empty matcher; `host=~".+"` selects every lab
    // stream (all shippers attach a host label).
    final selector =
        host.isEmpty ? '{host=~".+"}' : '{host="${_escape(host)}"}';
    final filter =
        contains.trim().isEmpty ? '' : ' |= "${_escape(contains.trim())}"';
    final end = DateTime.now().toUtc();
    final start = end.subtract(since);
    final res = await _dio.get<Map<String, dynamic>>(
      '/query_range',
      queryParameters: {
        'query': '$selector$filter',
        // Nanosecond epoch strings.
        'start': '${start.millisecondsSinceEpoch}000000',
        'end': '${end.millisecondsSinceEpoch}000000',
        'limit': limit,
        'direction': 'backward',
      },
    );
    final result = (res.data?['data']?['result'] as List?) ?? const <dynamic>[];
    final entries = <LokiEntry>[
      for (final r in result.cast<Map<String, dynamic>>())
        ..._streamEntries(r),
    ]..sort((a, b) => b.ts.compareTo(a.ts));
    return entries.length > limit ? entries.sublist(0, limit) : entries;
  }

  static Iterable<LokiEntry> _streamEntries(Map<String, dynamic> r) sync* {
    final labels = r['stream'] as Map<String, dynamic>? ?? const {};
    final host = '${labels['host'] ?? ''}';
    final unit =
        '${labels['unit'] ?? labels['container'] ?? labels['service_name'] ?? ''}';
    for (final v in (r['values'] as List? ?? const [])) {
      final ns = int.tryParse('${v[0]}');
      if (ns == null) continue;
      yield LokiEntry(
        ts: DateTime.fromMillisecondsSinceEpoch(ns ~/ 1000000, isUtc: true),
        host: host,
        unit: unit,
        line: '${v[1]}',
      );
    }
  }

  /// Escapes a value for use inside a double-quoted LogQL string.
  static String _escape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
