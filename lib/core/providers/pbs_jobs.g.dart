// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pbs_jobs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PbsJobs)
final pbsJobsProvider = PbsJobsProvider._();

final class PbsJobsProvider
    extends $NotifierProvider<PbsJobs, Map<String, PbsRunningJob>> {
  PbsJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pbsJobsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pbsJobsHash();

  @$internal
  @override
  PbsJobs create() => PbsJobs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, PbsRunningJob> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, PbsRunningJob>>(value),
    );
  }
}

String _$pbsJobsHash() => r'26eb5ada4cdaa7c4317c177380ae924a660fbaf4';

abstract class _$PbsJobs extends $Notifier<Map<String, PbsRunningJob>> {
  Map<String, PbsRunningJob> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, PbsRunningJob>, Map<String, PbsRunningJob>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, PbsRunningJob>,
                Map<String, PbsRunningJob>
              >,
              Map<String, PbsRunningJob>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
