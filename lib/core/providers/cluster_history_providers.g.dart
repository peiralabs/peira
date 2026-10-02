// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cluster_history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rolling in-memory history of the cluster-average CPU %, sampled each time
/// the nodes provider emits (every 30s). Backs the dashboard sparkline. Kept
/// alive so the trend survives tab switches; capped so it can't grow forever.

@ProviderFor(ClusterCpuHistory)
final clusterCpuHistoryProvider = ClusterCpuHistoryProvider._();

/// Rolling in-memory history of the cluster-average CPU %, sampled each time
/// the nodes provider emits (every 30s). Backs the dashboard sparkline. Kept
/// alive so the trend survives tab switches; capped so it can't grow forever.
final class ClusterCpuHistoryProvider
    extends $NotifierProvider<ClusterCpuHistory, List<double>> {
  /// Rolling in-memory history of the cluster-average CPU %, sampled each time
  /// the nodes provider emits (every 30s). Backs the dashboard sparkline. Kept
  /// alive so the trend survives tab switches; capped so it can't grow forever.
  ClusterCpuHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clusterCpuHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clusterCpuHistoryHash();

  @$internal
  @override
  ClusterCpuHistory create() => ClusterCpuHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<double>>(value),
    );
  }
}

String _$clusterCpuHistoryHash() => r'9b9e260d40e390b2323737a5b05fb0c1b6d57deb';

/// Rolling in-memory history of the cluster-average CPU %, sampled each time
/// the nodes provider emits (every 30s). Backs the dashboard sparkline. Kept
/// alive so the trend survives tab switches; capped so it can't grow forever.

abstract class _$ClusterCpuHistory extends $Notifier<List<double>> {
  List<double> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<double>, List<double>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<double>, List<double>>,
              List<double>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Rolling per-node CPU % history, keyed by node name, sampled alongside the
/// cluster average. Backs the micro-sparkline behind each node card's gauge.

@ProviderFor(NodeCpuHistory)
final nodeCpuHistoryProvider = NodeCpuHistoryProvider._();

/// Rolling per-node CPU % history, keyed by node name, sampled alongside the
/// cluster average. Backs the micro-sparkline behind each node card's gauge.
final class NodeCpuHistoryProvider
    extends $NotifierProvider<NodeCpuHistory, Map<String, List<double>>> {
  /// Rolling per-node CPU % history, keyed by node name, sampled alongside the
  /// cluster average. Backs the micro-sparkline behind each node card's gauge.
  NodeCpuHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nodeCpuHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nodeCpuHistoryHash();

  @$internal
  @override
  NodeCpuHistory create() => NodeCpuHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<double>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<double>>>(value),
    );
  }
}

String _$nodeCpuHistoryHash() => r'1a5ec7c2162e473451f7e6437c51422292329ef4';

/// Rolling per-node CPU % history, keyed by node name, sampled alongside the
/// cluster average. Backs the micro-sparkline behind each node card's gauge.

abstract class _$NodeCpuHistory extends $Notifier<Map<String, List<double>>> {
  Map<String, List<double>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, List<double>>, Map<String, List<double>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, List<double>>, Map<String, List<double>>>,
              Map<String, List<double>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
