// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdm_jobs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs PDM actions independently of screen lifetime and owns every polling
/// timer. Jobs are keyed by `remote/vmid`, which also makes row lookup cheap.

@ProviderFor(PdmJobs)
final pdmJobsProvider = PdmJobsProvider._();

/// Runs PDM actions independently of screen lifetime and owns every polling
/// timer. Jobs are keyed by `remote/vmid`, which also makes row lookup cheap.
final class PdmJobsProvider
    extends $NotifierProvider<PdmJobs, Map<String, PdmJob>> {
  /// Runs PDM actions independently of screen lifetime and owns every polling
  /// timer. Jobs are keyed by `remote/vmid`, which also makes row lookup cheap.
  PdmJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdmJobsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdmJobsHash();

  @$internal
  @override
  PdmJobs create() => PdmJobs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, PdmJob> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, PdmJob>>(value),
    );
  }
}

String _$pdmJobsHash() => r'2120b8b5da8ca226359a3f8faf7547ea0087499b';

/// Runs PDM actions independently of screen lifetime and owns every polling
/// timer. Jobs are keyed by `remote/vmid`, which also makes row lookup cheap.

abstract class _$PdmJobs extends $Notifier<Map<String, PdmJob>> {
  Map<String, PdmJob> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, PdmJob>, Map<String, PdmJob>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, PdmJob>, Map<String, PdmJob>>,
              Map<String, PdmJob>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
