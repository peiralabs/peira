import 'package:freezed_annotation/freezed_annotation.dart';

part 'node_status.freezed.dart';
part 'node_status.g.dart';

/// GET /api2/json/nodes/{node}/status.
@freezed
abstract class NodeStatus with _$NodeStatus {
  const NodeStatus._();

  const factory NodeStatus({
    double? cpu,
    int? uptime,
    String? kversion,
    String? pveversion,
    // 1m/5m/15m; the live API sends them as strings ("0.92") — kept dynamic
    // so a numeric backend change can't break parsing.
    List<dynamic>? loadavg,
    UsageInfo? memory,
    UsageInfo? rootfs,
    UsageInfo? swap,
  }) = _NodeStatus;

  factory NodeStatus.fromJson(Map<String, dynamic> json) =>
      _$NodeStatusFromJson(json);

  /// "0.92 · 1.05 · 0.99", or null when the API omits loadavg.
  String? get loadDisplay {
    final l = loadavg;
    if (l == null || l.isEmpty) return null;
    return l.map((e) => '$e').join(' · ');
  }
}

/// Shared shape of the memory / rootfs / swap sub-objects.
@freezed
abstract class UsageInfo with _$UsageInfo {
  const UsageInfo._();

  const factory UsageInfo({int? total, int? used, int? free, int? avail}) =
      _UsageInfo;

  factory UsageInfo.fromJson(Map<String, dynamic> json) =>
      _$UsageInfoFromJson(json);

  double? get usedFraction {
    final t = total, u = used;
    if (t == null || u == null || t == 0) return null;
    return u / t;
  }
}
