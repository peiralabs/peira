// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grafana_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(grafanaApi)
final grafanaApiProvider = GrafanaApiProvider._();

final class GrafanaApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<GrafanaApi>,
          GrafanaApi,
          FutureOr<GrafanaApi>
        >
    with $FutureModifier<GrafanaApi>, $FutureProvider<GrafanaApi> {
  GrafanaApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'grafanaApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$grafanaApiHash();

  @$internal
  @override
  $FutureProviderElement<GrafanaApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GrafanaApi> create(Ref ref) {
    return grafanaApi(ref);
  }
}

String _$grafanaApiHash() => r'200016e80865947c1291db36b51b4eacf85a150b';

@ProviderFor(activeAlerts)
final activeAlertsProvider = ActiveAlertsProvider._();

final class ActiveAlertsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GrafanaAlert>>,
          List<GrafanaAlert>,
          FutureOr<List<GrafanaAlert>>
        >
    with
        $FutureModifier<List<GrafanaAlert>>,
        $FutureProvider<List<GrafanaAlert>> {
  ActiveAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeAlertsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeAlertsHash();

  @$internal
  @override
  $FutureProviderElement<List<GrafanaAlert>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GrafanaAlert>> create(Ref ref) {
    return activeAlerts(ref);
  }
}

String _$activeAlertsHash() => r'd7ab1378f4616ec201dae8ed3d2a0ad989e42d32';
