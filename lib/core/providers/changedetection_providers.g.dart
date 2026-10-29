// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changedetection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(changedetectionApi)
final changedetectionApiProvider = ChangedetectionApiProvider._();

final class ChangedetectionApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChangedetectionApi>,
          ChangedetectionApi,
          FutureOr<ChangedetectionApi>
        >
    with
        $FutureModifier<ChangedetectionApi>,
        $FutureProvider<ChangedetectionApi> {
  ChangedetectionApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changedetectionApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changedetectionApiHash();

  @$internal
  @override
  $FutureProviderElement<ChangedetectionApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChangedetectionApi> create(Ref ref) {
    return changedetectionApi(ref);
  }
}

String _$changedetectionApiHash() =>
    r'1430b118103e25b26caa35eab2746bd543773c75';

@ProviderFor(cdWatches)
final cdWatchesProvider = CdWatchesProvider._();

final class CdWatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CdWatch>>,
          List<CdWatch>,
          FutureOr<List<CdWatch>>
        >
    with $FutureModifier<List<CdWatch>>, $FutureProvider<List<CdWatch>> {
  CdWatchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cdWatchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cdWatchesHash();

  @$internal
  @override
  $FutureProviderElement<List<CdWatch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CdWatch>> create(Ref ref) {
    return cdWatches(ref);
  }
}

String _$cdWatchesHash() => r'4f19d019ffe149bb44d916f5917a5354b12ee4b7';

@ProviderFor(cdWatch)
final cdWatchProvider = CdWatchFamily._();

final class CdWatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<CdWatchDetail>,
          CdWatchDetail,
          FutureOr<CdWatchDetail>
        >
    with $FutureModifier<CdWatchDetail>, $FutureProvider<CdWatchDetail> {
  CdWatchProvider._({
    required CdWatchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cdWatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cdWatchHash();

  @override
  String toString() {
    return r'cdWatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CdWatchDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CdWatchDetail> create(Ref ref) {
    final argument = this.argument as String;
    return cdWatch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CdWatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cdWatchHash() => r'10458be5bcc52410b382fed15b67031119326893';

final class CdWatchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CdWatchDetail>, String> {
  CdWatchFamily._()
    : super(
        retry: null,
        name: r'cdWatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CdWatchProvider call(String uuid) =>
      CdWatchProvider._(argument: uuid, from: this);

  @override
  String toString() => r'cdWatchProvider';
}

@ProviderFor(cdHistory)
final cdHistoryProvider = CdHistoryFamily._();

final class CdHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<int>>,
          List<int>,
          FutureOr<List<int>>
        >
    with $FutureModifier<List<int>>, $FutureProvider<List<int>> {
  CdHistoryProvider._({
    required CdHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cdHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cdHistoryHash();

  @override
  String toString() {
    return r'cdHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<int>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<int>> create(Ref ref) {
    final argument = this.argument as String;
    return cdHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CdHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cdHistoryHash() => r'0da9d3373b32cf0aa9a8622ef6a590f7123ed9ff';

final class CdHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<int>>, String> {
  CdHistoryFamily._()
    : super(
        retry: null,
        name: r'cdHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CdHistoryProvider call(String uuid) =>
      CdHistoryProvider._(argument: uuid, from: this);

  @override
  String toString() => r'cdHistoryProvider';
}

@ProviderFor(cdTags)
final cdTagsProvider = CdTagsProvider._();

final class CdTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CdTag>>,
          List<CdTag>,
          FutureOr<List<CdTag>>
        >
    with $FutureModifier<List<CdTag>>, $FutureProvider<List<CdTag>> {
  CdTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cdTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cdTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<CdTag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CdTag>> create(Ref ref) {
    return cdTags(ref);
  }
}

String _$cdTagsHash() => r'abb5955eb53467ca0e306d1325c8718ae20fe9c5';

@ProviderFor(cdSystem)
final cdSystemProvider = CdSystemProvider._();

final class CdSystemProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  CdSystemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cdSystemProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cdSystemHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return cdSystem(ref);
  }
}

String _$cdSystemHash() => r'd653e09df9f59e491ac6f24a5aa525a6e0d92691';
