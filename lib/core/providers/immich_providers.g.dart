// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'immich_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(immichApi)
final immichApiProvider = ImmichApiProvider._();

final class ImmichApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<ImmichApi>,
          ImmichApi,
          FutureOr<ImmichApi>
        >
    with $FutureModifier<ImmichApi>, $FutureProvider<ImmichApi> {
  ImmichApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'immichApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$immichApiHash();

  @$internal
  @override
  $FutureProviderElement<ImmichApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ImmichApi> create(Ref ref) {
    return immichApi(ref);
  }
}

String _$immichApiHash() => r'982e6de205b3d6cd116ff40bfa4dbf1efd22eafc';

@ProviderFor(immichServer)
final immichServerProvider = ImmichServerProvider._();

final class ImmichServerProvider
    extends
        $FunctionalProvider<
          AsyncValue<ImmichServer>,
          ImmichServer,
          FutureOr<ImmichServer>
        >
    with $FutureModifier<ImmichServer>, $FutureProvider<ImmichServer> {
  ImmichServerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'immichServerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$immichServerHash();

  @$internal
  @override
  $FutureProviderElement<ImmichServer> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ImmichServer> create(Ref ref) {
    return immichServer(ref);
  }
}

String _$immichServerHash() => r'0df108a3059b639479827a1364e88c48a89569df';

@ProviderFor(immichQueues)
final immichQueuesProvider = ImmichQueuesProvider._();

final class ImmichQueuesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ImmichQueue>>,
          List<ImmichQueue>,
          FutureOr<List<ImmichQueue>>
        >
    with
        $FutureModifier<List<ImmichQueue>>,
        $FutureProvider<List<ImmichQueue>> {
  ImmichQueuesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'immichQueuesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$immichQueuesHash();

  @$internal
  @override
  $FutureProviderElement<List<ImmichQueue>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ImmichQueue>> create(Ref ref) {
    return immichQueues(ref);
  }
}

String _$immichQueuesHash() => r'4816ccc4bc3b44fc07acbf21da65e34eb695e2e4';

@ProviderFor(immichAlbums)
final immichAlbumsProvider = ImmichAlbumsProvider._();

final class ImmichAlbumsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ImmichAlbum>>,
          List<ImmichAlbum>,
          FutureOr<List<ImmichAlbum>>
        >
    with
        $FutureModifier<List<ImmichAlbum>>,
        $FutureProvider<List<ImmichAlbum>> {
  ImmichAlbumsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'immichAlbumsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$immichAlbumsHash();

  @$internal
  @override
  $FutureProviderElement<List<ImmichAlbum>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ImmichAlbum>> create(Ref ref) {
    return immichAlbums(ref);
  }
}

String _$immichAlbumsHash() => r'9c33eeb9987ffcbbd24d4ea4ecb3645045bb70f1';

@ProviderFor(immichAlbum)
final immichAlbumProvider = ImmichAlbumFamily._();

final class ImmichAlbumProvider
    extends
        $FunctionalProvider<
          AsyncValue<ImmichAlbum>,
          ImmichAlbum,
          FutureOr<ImmichAlbum>
        >
    with $FutureModifier<ImmichAlbum>, $FutureProvider<ImmichAlbum> {
  ImmichAlbumProvider._({
    required ImmichAlbumFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'immichAlbumProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$immichAlbumHash();

  @override
  String toString() {
    return r'immichAlbumProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ImmichAlbum> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ImmichAlbum> create(Ref ref) {
    final argument = this.argument as String;
    return immichAlbum(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImmichAlbumProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$immichAlbumHash() => r'8cac14ec342f5fad7efd6e1c8cf74978ab06a178';

final class ImmichAlbumFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ImmichAlbum>, String> {
  ImmichAlbumFamily._()
    : super(
        retry: null,
        name: r'immichAlbumProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ImmichAlbumProvider call(String id) =>
      ImmichAlbumProvider._(argument: id, from: this);

  @override
  String toString() => r'immichAlbumProvider';
}

@ProviderFor(immichPeople)
final immichPeopleProvider = ImmichPeopleProvider._();

final class ImmichPeopleProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ImmichPerson>>,
          List<ImmichPerson>,
          FutureOr<List<ImmichPerson>>
        >
    with
        $FutureModifier<List<ImmichPerson>>,
        $FutureProvider<List<ImmichPerson>> {
  ImmichPeopleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'immichPeopleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$immichPeopleHash();

  @$internal
  @override
  $FutureProviderElement<List<ImmichPerson>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ImmichPerson>> create(Ref ref) {
    return immichPeople(ref);
  }
}

String _$immichPeopleHash() => r'f3d7cf740c10e8b8baf5a9293298f3e6b051a282';

@ProviderFor(immichMemories)
final immichMemoriesProvider = ImmichMemoriesProvider._();

final class ImmichMemoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ImmichMemory>>,
          List<ImmichMemory>,
          FutureOr<List<ImmichMemory>>
        >
    with
        $FutureModifier<List<ImmichMemory>>,
        $FutureProvider<List<ImmichMemory>> {
  ImmichMemoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'immichMemoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$immichMemoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<ImmichMemory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ImmichMemory>> create(Ref ref) {
    return immichMemories(ref);
  }
}

String _$immichMemoriesHash() => r'06b09010147db99ecc57148eca953f1738c2f21a';

@ProviderFor(immichDuplicates)
final immichDuplicatesProvider = ImmichDuplicatesProvider._();

final class ImmichDuplicatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ImmichDuplicateGroup>>,
          List<ImmichDuplicateGroup>,
          FutureOr<List<ImmichDuplicateGroup>>
        >
    with
        $FutureModifier<List<ImmichDuplicateGroup>>,
        $FutureProvider<List<ImmichDuplicateGroup>> {
  ImmichDuplicatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'immichDuplicatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$immichDuplicatesHash();

  @$internal
  @override
  $FutureProviderElement<List<ImmichDuplicateGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ImmichDuplicateGroup>> create(Ref ref) {
    return immichDuplicates(ref);
  }
}

String _$immichDuplicatesHash() => r'69b0a44c5e8d18938fc5ed93bc5ff094a37779e7';

@ProviderFor(immichAsset)
final immichAssetProvider = ImmichAssetFamily._();

final class ImmichAssetProvider
    extends
        $FunctionalProvider<
          AsyncValue<ImmichAsset>,
          ImmichAsset,
          FutureOr<ImmichAsset>
        >
    with $FutureModifier<ImmichAsset>, $FutureProvider<ImmichAsset> {
  ImmichAssetProvider._({
    required ImmichAssetFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'immichAssetProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$immichAssetHash();

  @override
  String toString() {
    return r'immichAssetProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ImmichAsset> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ImmichAsset> create(Ref ref) {
    final argument = this.argument as String;
    return immichAsset(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImmichAssetProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$immichAssetHash() => r'a6b33bab2e263b587509e19ab52b2ca41904c39f';

final class ImmichAssetFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ImmichAsset>, String> {
  ImmichAssetFamily._()
    : super(
        retry: null,
        name: r'immichAssetProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ImmichAssetProvider call(String id) =>
      ImmichAssetProvider._(argument: id, from: this);

  @override
  String toString() => r'immichAssetProvider';
}
