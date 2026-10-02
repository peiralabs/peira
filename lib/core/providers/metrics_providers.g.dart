// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metrics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedMetricsRange)
final selectedMetricsRangeProvider = SelectedMetricsRangeProvider._();

final class SelectedMetricsRangeProvider
    extends $NotifierProvider<SelectedMetricsRange, MetricsRange> {
  SelectedMetricsRangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedMetricsRangeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedMetricsRangeHash();

  @$internal
  @override
  SelectedMetricsRange create() => SelectedMetricsRange();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetricsRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetricsRange>(value),
    );
  }
}

String _$selectedMetricsRangeHash() =>
    r'8931a628626759acefc347b2dc102f97e1a9b3e7';

abstract class _$SelectedMetricsRange extends $Notifier<MetricsRange> {
  MetricsRange build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MetricsRange, MetricsRange>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MetricsRange, MetricsRange>,
              MetricsRange,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(prometheusApi)
final prometheusApiProvider = PrometheusApiProvider._();

final class PrometheusApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrometheusApi>,
          PrometheusApi,
          FutureOr<PrometheusApi>
        >
    with $FutureModifier<PrometheusApi>, $FutureProvider<PrometheusApi> {
  PrometheusApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prometheusApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prometheusApiHash();

  @$internal
  @override
  $FutureProviderElement<PrometheusApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PrometheusApi> create(Ref ref) {
    return prometheusApi(ref);
  }
}

String _$prometheusApiHash() => r'baf69025e90f24c11645ae10c0f34eebcdf9e8b8';

@ProviderFor(clusterMetrics)
final clusterMetricsProvider = ClusterMetricsProvider._();

final class ClusterMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClusterMetrics>,
          ClusterMetrics,
          FutureOr<ClusterMetrics>
        >
    with $FutureModifier<ClusterMetrics>, $FutureProvider<ClusterMetrics> {
  ClusterMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clusterMetricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clusterMetricsHash();

  @$internal
  @override
  $FutureProviderElement<ClusterMetrics> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClusterMetrics> create(Ref ref) {
    return clusterMetrics(ref);
  }
}

String _$clusterMetricsHash() => r'0510e915a9dab23fed624aa1d321b5ccfce32c5c';

@ProviderFor(metricsInsights)
final metricsInsightsProvider = MetricsInsightsProvider._();

final class MetricsInsightsProvider
    extends
        $FunctionalProvider<
          AsyncValue<MetricsInsights>,
          MetricsInsights,
          FutureOr<MetricsInsights>
        >
    with $FutureModifier<MetricsInsights>, $FutureProvider<MetricsInsights> {
  MetricsInsightsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metricsInsightsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsInsightsHash();

  @$internal
  @override
  $FutureProviderElement<MetricsInsights> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MetricsInsights> create(Ref ref) {
    return metricsInsights(ref);
  }
}

String _$metricsInsightsHash() => r'cd2e32efbb97e316ce86b2fe6db5257c8bc3372d';

@ProviderFor(aiMetrics)
final aiMetricsProvider = AiMetricsProvider._();

final class AiMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AiMetrics>,
          AiMetrics,
          FutureOr<AiMetrics>
        >
    with $FutureModifier<AiMetrics>, $FutureProvider<AiMetrics> {
  AiMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiMetricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiMetricsHash();

  @$internal
  @override
  $FutureProviderElement<AiMetrics> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AiMetrics> create(Ref ref) {
    return aiMetrics(ref);
  }
}

String _$aiMetricsHash() => r'b53ec66d76ffe61673fc6ddf9eddc4793fc6fb95';

@ProviderFor(powerMetrics)
final powerMetricsProvider = PowerMetricsProvider._();

final class PowerMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PowerMetrics>,
          PowerMetrics,
          FutureOr<PowerMetrics>
        >
    with $FutureModifier<PowerMetrics>, $FutureProvider<PowerMetrics> {
  PowerMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'powerMetricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$powerMetricsHash();

  @$internal
  @override
  $FutureProviderElement<PowerMetrics> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PowerMetrics> create(Ref ref) {
    return powerMetrics(ref);
  }
}

String _$powerMetricsHash() => r'e42dd5eaee212770ae9a51e3d0600df3f8d8e188';

@ProviderFor(smartHealth)
final smartHealthProvider = SmartHealthProvider._();

final class SmartHealthProvider
    extends
        $FunctionalProvider<
          AsyncValue<SmartHealth>,
          SmartHealth,
          FutureOr<SmartHealth>
        >
    with $FutureModifier<SmartHealth>, $FutureProvider<SmartHealth> {
  SmartHealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartHealthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartHealthHash();

  @$internal
  @override
  $FutureProviderElement<SmartHealth> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SmartHealth> create(Ref ref) {
    return smartHealth(ref);
  }
}

String _$smartHealthHash() => r'dd9c50e85d377f3f6d8e20cbbee0bdb0bf9e82a2';

@ProviderFor(wanMetrics)
final wanMetricsProvider = WanMetricsProvider._();

final class WanMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<WanMetrics>,
          WanMetrics,
          FutureOr<WanMetrics>
        >
    with $FutureModifier<WanMetrics>, $FutureProvider<WanMetrics> {
  WanMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wanMetricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wanMetricsHash();

  @$internal
  @override
  $FutureProviderElement<WanMetrics> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WanMetrics> create(Ref ref) {
    return wanMetrics(ref);
  }
}

String _$wanMetricsHash() => r'f923ee388c03e6fc2e065f4de0dfe8c4bcadba71';

/// The homelab-twin simulator lives beside Prometheus on the monitoring CT
/// (:9112), so its URL derives from the Prometheus endpoint — no extra
/// setting to seed.

@ProviderFor(twinApi)
final twinApiProvider = TwinApiProvider._();

/// The homelab-twin simulator lives beside Prometheus on the monitoring CT
/// (:9112), so its URL derives from the Prometheus endpoint — no extra
/// setting to seed.

final class TwinApiProvider
    extends $FunctionalProvider<AsyncValue<TwinApi>, TwinApi, FutureOr<TwinApi>>
    with $FutureModifier<TwinApi>, $FutureProvider<TwinApi> {
  /// The homelab-twin simulator lives beside Prometheus on the monitoring CT
  /// (:9112), so its URL derives from the Prometheus endpoint — no extra
  /// setting to seed.
  TwinApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'twinApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$twinApiHash();

  @$internal
  @override
  $FutureProviderElement<TwinApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TwinApi> create(Ref ref) {
    return twinApi(ref);
  }
}

String _$twinApiHash() => r'1e0445af0240ea85579f9fa13989021365a7f394';

@ProviderFor(twinData)
final twinDataProvider = TwinDataProvider._();

final class TwinDataProvider
    extends
        $FunctionalProvider<AsyncValue<TwinData>, TwinData, FutureOr<TwinData>>
    with $FutureModifier<TwinData>, $FutureProvider<TwinData> {
  TwinDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'twinDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$twinDataHash();

  @$internal
  @override
  $FutureProviderElement<TwinData> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TwinData> create(Ref ref) {
    return twinData(ref);
  }
}

String _$twinDataHash() => r'a86f3e12465f4493d80fd5b4d64827e65fb036ca';
