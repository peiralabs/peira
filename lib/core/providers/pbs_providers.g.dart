// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pbs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedPbsSlot)
final selectedPbsSlotProvider = SelectedPbsSlotProvider._();

final class SelectedPbsSlotProvider
    extends $AsyncNotifierProvider<SelectedPbsSlot, PbsSlot> {
  SelectedPbsSlotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedPbsSlotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedPbsSlotHash();

  @$internal
  @override
  SelectedPbsSlot create() => SelectedPbsSlot();
}

String _$selectedPbsSlotHash() => r'11aba9c033993d01487698f0511dcc241113aea1';

abstract class _$SelectedPbsSlot extends $AsyncNotifier<PbsSlot> {
  FutureOr<PbsSlot> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PbsSlot>, PbsSlot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PbsSlot>, PbsSlot>,
              AsyncValue<PbsSlot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(pbsConfig)
final pbsConfigProvider = PbsConfigFamily._();

final class PbsConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<PbsServerConfig>,
          PbsServerConfig,
          FutureOr<PbsServerConfig>
        >
    with $FutureModifier<PbsServerConfig>, $FutureProvider<PbsServerConfig> {
  PbsConfigProvider._({
    required PbsConfigFamily super.from,
    required PbsSlot super.argument,
  }) : super(
         retry: null,
         name: r'pbsConfigProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pbsConfigHash();

  @override
  String toString() {
    return r'pbsConfigProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PbsServerConfig> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PbsServerConfig> create(Ref ref) {
    final argument = this.argument as PbsSlot;
    return pbsConfig(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PbsConfigProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pbsConfigHash() => r'bb952cca0cac3fa7fc550c90b457c2bb99c1e4bd';

final class PbsConfigFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PbsServerConfig>, PbsSlot> {
  PbsConfigFamily._()
    : super(
        retry: null,
        name: r'pbsConfigProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PbsConfigProvider call(PbsSlot slot) =>
      PbsConfigProvider._(argument: slot, from: this);

  @override
  String toString() => r'pbsConfigProvider';
}

@ProviderFor(pbsApi)
final pbsApiProvider = PbsApiFamily._();

final class PbsApiProvider
    extends $FunctionalProvider<AsyncValue<PbsApi>, PbsApi, FutureOr<PbsApi>>
    with $FutureModifier<PbsApi>, $FutureProvider<PbsApi> {
  PbsApiProvider._({
    required PbsApiFamily super.from,
    required PbsSlot super.argument,
  }) : super(
         retry: null,
         name: r'pbsApiProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pbsApiHash();

  @override
  String toString() {
    return r'pbsApiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PbsApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PbsApi> create(Ref ref) {
    final argument = this.argument as PbsSlot;
    return pbsApi(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PbsApiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pbsApiHash() => r'19a7d98a234d70df3ad9368bd47aff10b5e4365f';

final class PbsApiFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PbsApi>, PbsSlot> {
  PbsApiFamily._()
    : super(
        retry: null,
        name: r'pbsApiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PbsApiProvider call(PbsSlot slot) =>
      PbsApiProvider._(argument: slot, from: this);

  @override
  String toString() => r'pbsApiProvider';
}

@ProviderFor(PbsElevation)
final pbsElevationProvider = PbsElevationProvider._();

final class PbsElevationProvider
    extends $NotifierProvider<PbsElevation, Map<PbsSlot, PbsTicket>> {
  PbsElevationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pbsElevationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pbsElevationHash();

  @$internal
  @override
  PbsElevation create() => PbsElevation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<PbsSlot, PbsTicket> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<PbsSlot, PbsTicket>>(value),
    );
  }
}

String _$pbsElevationHash() => r'3f86607f69d078763cf8a4e91d86ea27fa7ecd94';

abstract class _$PbsElevation extends $Notifier<Map<PbsSlot, PbsTicket>> {
  Map<PbsSlot, PbsTicket> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<PbsSlot, PbsTicket>, Map<PbsSlot, PbsTicket>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<PbsSlot, PbsTicket>, Map<PbsSlot, PbsTicket>>,
              Map<PbsSlot, PbsTicket>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(pbsOverview)
final pbsOverviewProvider = PbsOverviewFamily._();

final class PbsOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<PbsOverviewData>,
          PbsOverviewData,
          FutureOr<PbsOverviewData>
        >
    with $FutureModifier<PbsOverviewData>, $FutureProvider<PbsOverviewData> {
  PbsOverviewProvider._({
    required PbsOverviewFamily super.from,
    required PbsSlot super.argument,
  }) : super(
         retry: null,
         name: r'pbsOverviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pbsOverviewHash();

  @override
  String toString() {
    return r'pbsOverviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PbsOverviewData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PbsOverviewData> create(Ref ref) {
    final argument = this.argument as PbsSlot;
    return pbsOverview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PbsOverviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pbsOverviewHash() => r'cbdbe783ad63ff919813ee6aa985272833539fe0';

final class PbsOverviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PbsOverviewData>, PbsSlot> {
  PbsOverviewFamily._()
    : super(
        retry: null,
        name: r'pbsOverviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PbsOverviewProvider call(PbsSlot slot) =>
      PbsOverviewProvider._(argument: slot, from: this);

  @override
  String toString() => r'pbsOverviewProvider';
}

@ProviderFor(pbsNamespaces)
final pbsNamespacesProvider = PbsNamespacesFamily._();

final class PbsNamespacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  PbsNamespacesProvider._({
    required PbsNamespacesFamily super.from,
    required (PbsSlot, String) super.argument,
  }) : super(
         retry: null,
         name: r'pbsNamespacesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pbsNamespacesHash();

  @override
  String toString() {
    return r'pbsNamespacesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as (PbsSlot, String);
    return pbsNamespaces(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is PbsNamespacesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pbsNamespacesHash() => r'215acac3644b17bc6ee1f6c1e73f7f00272e5175';

final class PbsNamespacesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, (PbsSlot, String)> {
  PbsNamespacesFamily._()
    : super(
        retry: null,
        name: r'pbsNamespacesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PbsNamespacesProvider call(PbsSlot slot, String store) =>
      PbsNamespacesProvider._(argument: (slot, store), from: this);

  @override
  String toString() => r'pbsNamespacesProvider';
}

@ProviderFor(pbsGroups)
final pbsGroupsProvider = PbsGroupsFamily._();

final class PbsGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PbsGroup>>,
          List<PbsGroup>,
          FutureOr<List<PbsGroup>>
        >
    with $FutureModifier<List<PbsGroup>>, $FutureProvider<List<PbsGroup>> {
  PbsGroupsProvider._({
    required PbsGroupsFamily super.from,
    required (PbsSlot, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'pbsGroupsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pbsGroupsHash();

  @override
  String toString() {
    return r'pbsGroupsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PbsGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PbsGroup>> create(Ref ref) {
    final argument = this.argument as (PbsSlot, String, String);
    return pbsGroups(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is PbsGroupsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pbsGroupsHash() => r'c420e298bb84d6967df46a199d8868c4dd594e19';

final class PbsGroupsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PbsGroup>>,
          (PbsSlot, String, String)
        > {
  PbsGroupsFamily._()
    : super(
        retry: null,
        name: r'pbsGroupsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PbsGroupsProvider call(PbsSlot slot, String store, String ns) =>
      PbsGroupsProvider._(argument: (slot, store, ns), from: this);

  @override
  String toString() => r'pbsGroupsProvider';
}

@ProviderFor(pbsSnapshots)
final pbsSnapshotsProvider = PbsSnapshotsFamily._();

final class PbsSnapshotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PbsSnapshot>>,
          List<PbsSnapshot>,
          FutureOr<List<PbsSnapshot>>
        >
    with
        $FutureModifier<List<PbsSnapshot>>,
        $FutureProvider<List<PbsSnapshot>> {
  PbsSnapshotsProvider._({
    required PbsSnapshotsFamily super.from,
    required (PbsSlot, String, String, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'pbsSnapshotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pbsSnapshotsHash();

  @override
  String toString() {
    return r'pbsSnapshotsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PbsSnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PbsSnapshot>> create(Ref ref) {
    final argument = this.argument as (PbsSlot, String, String, String, String);
    return pbsSnapshots(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      argument.$4,
      argument.$5,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PbsSnapshotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pbsSnapshotsHash() => r'63bbe00bb4f078127daffd4de39d2396aae91583';

final class PbsSnapshotsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PbsSnapshot>>,
          (PbsSlot, String, String, String, String)
        > {
  PbsSnapshotsFamily._()
    : super(
        retry: null,
        name: r'pbsSnapshotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PbsSnapshotsProvider call(
    PbsSlot slot,
    String store,
    String ns,
    String type,
    String id,
  ) =>
      PbsSnapshotsProvider._(argument: (slot, store, ns, type, id), from: this);

  @override
  String toString() => r'pbsSnapshotsProvider';
}

@ProviderFor(pbsTasks)
final pbsTasksProvider = PbsTasksFamily._();

final class PbsTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PbsTask>>,
          List<PbsTask>,
          FutureOr<List<PbsTask>>
        >
    with $FutureModifier<List<PbsTask>>, $FutureProvider<List<PbsTask>> {
  PbsTasksProvider._({
    required PbsTasksFamily super.from,
    required (PbsSlot, PbsTaskFilter) super.argument,
  }) : super(
         retry: null,
         name: r'pbsTasksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pbsTasksHash();

  @override
  String toString() {
    return r'pbsTasksProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PbsTask>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PbsTask>> create(Ref ref) {
    final argument = this.argument as (PbsSlot, PbsTaskFilter);
    return pbsTasks(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is PbsTasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pbsTasksHash() => r'af51bde9dd240a7207220316fc0ab11d3ab2b8b3';

final class PbsTasksFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PbsTask>>,
          (PbsSlot, PbsTaskFilter)
        > {
  PbsTasksFamily._()
    : super(
        retry: null,
        name: r'pbsTasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PbsTasksProvider call(PbsSlot slot, PbsTaskFilter filter) =>
      PbsTasksProvider._(argument: (slot, filter), from: this);

  @override
  String toString() => r'pbsTasksProvider';
}
