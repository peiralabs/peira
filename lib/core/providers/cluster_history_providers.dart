import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cluster_history_providers.g.dart';

/// Rolling in-memory history of the cluster-average CPU %, sampled each time
/// the nodes provider emits (every 30s). Backs the dashboard sparkline. Kept
/// alive so the trend survives tab switches; capped so it can't grow forever.
@Riverpod(keepAlive: true)
class ClusterCpuHistory extends _$ClusterCpuHistory {
  static const _maxSamples = 30;

  @override
  List<double> build() => const [];

  void add(double avgCpuPercent) {
    final next = [...state, avgCpuPercent];
    state = next.length > _maxSamples
        ? next.sublist(next.length - _maxSamples)
        : next;
  }
}

/// Rolling per-node CPU % history, keyed by node name, sampled alongside the
/// cluster average. Backs the micro-sparkline behind each node card's gauge.
@Riverpod(keepAlive: true)
class NodeCpuHistory extends _$NodeCpuHistory {
  static const _maxSamples = 24;

  @override
  Map<String, List<double>> build() => const {};

  void add(String node, double cpuPercent) {
    final prev = state[node] ?? const [];
    final next = [...prev, cpuPercent];
    final capped = next.length > _maxSamples
        ? next.sublist(next.length - _maxSamples)
        : next;
    state = {...state, node: capped};
  }
}
