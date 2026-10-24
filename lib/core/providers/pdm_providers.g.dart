// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdm_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pdmApi)
final pdmApiProvider = PdmApiProvider._();

final class PdmApiProvider
    extends $FunctionalProvider<AsyncValue<PdmApi>, PdmApi, FutureOr<PdmApi>>
    with $FutureModifier<PdmApi>, $FutureProvider<PdmApi> {
  PdmApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdmApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdmApiHash();

  @$internal
  @override
  $FutureProviderElement<PdmApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PdmApi> create(Ref ref) {
    return pdmApi(ref);
  }
}

String _$pdmApiHash() => r'abdf648528e64d47669f41ac9630994b26b1d4b6';

@ProviderFor(pdmPanel)
final pdmPanelProvider = PdmPanelProvider._();

final class PdmPanelProvider
    extends
        $FunctionalProvider<
          AsyncValue<PdmPanelState>,
          PdmPanelState,
          FutureOr<PdmPanelState>
        >
    with $FutureModifier<PdmPanelState>, $FutureProvider<PdmPanelState> {
  PdmPanelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdmPanelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdmPanelHash();

  @$internal
  @override
  $FutureProviderElement<PdmPanelState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PdmPanelState> create(Ref ref) {
    return pdmPanel(ref);
  }
}

String _$pdmPanelHash() => r'e634163e9333f0782325dcdecbe60a40133dbe1a';

@ProviderFor(pdmOverview)
final pdmOverviewProvider = PdmOverviewProvider._();

final class PdmOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PdmRemoteOverview>>,
          List<PdmRemoteOverview>,
          FutureOr<List<PdmRemoteOverview>>
        >
    with
        $FutureModifier<List<PdmRemoteOverview>>,
        $FutureProvider<List<PdmRemoteOverview>> {
  PdmOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdmOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdmOverviewHash();

  @$internal
  @override
  $FutureProviderElement<List<PdmRemoteOverview>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PdmRemoteOverview>> create(Ref ref) {
    return pdmOverview(ref);
  }
}

String _$pdmOverviewHash() => r'26c3ec61cd7d199bebdde68e883ea04aee04e21f';

@ProviderFor(pdmTasks)
final pdmTasksProvider = PdmTasksFamily._();

final class PdmTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PdmTask>>,
          List<PdmTask>,
          FutureOr<List<PdmTask>>
        >
    with $FutureModifier<List<PdmTask>>, $FutureProvider<List<PdmTask>> {
  PdmTasksProvider._({
    required PdmTasksFamily super.from,
    required PdmTaskFilter super.argument,
  }) : super(
         retry: null,
         name: r'pdmTasksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pdmTasksHash();

  @override
  String toString() {
    return r'pdmTasksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PdmTask>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PdmTask>> create(Ref ref) {
    final argument = this.argument as PdmTaskFilter;
    return pdmTasks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PdmTasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pdmTasksHash() => r'f583a59de7c722fe3039b1064c5cb3bcc7de8967';

final class PdmTasksFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PdmTask>>, PdmTaskFilter> {
  PdmTasksFamily._()
    : super(
        retry: null,
        name: r'pdmTasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PdmTasksProvider call(PdmTaskFilter filter) =>
      PdmTasksProvider._(argument: filter, from: this);

  @override
  String toString() => r'pdmTasksProvider';
}
