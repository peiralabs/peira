// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'docker_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dockerApi)
final dockerApiProvider = DockerApiProvider._();

final class DockerApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<DockerApi>,
          DockerApi,
          FutureOr<DockerApi>
        >
    with $FutureModifier<DockerApi>, $FutureProvider<DockerApi> {
  DockerApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dockerApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dockerApiHash();

  @$internal
  @override
  $FutureProviderElement<DockerApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DockerApi> create(Ref ref) {
    return dockerApi(ref);
  }
}

String _$dockerApiHash() => r'b71366c2cb43b135eeb9b60c6d52c20b914192dc';

@ProviderFor(dockerContainers)
final dockerContainersProvider = DockerContainersProvider._();

final class DockerContainersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DockerContainer>>,
          List<DockerContainer>,
          FutureOr<List<DockerContainer>>
        >
    with
        $FutureModifier<List<DockerContainer>>,
        $FutureProvider<List<DockerContainer>> {
  DockerContainersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dockerContainersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dockerContainersHash();

  @$internal
  @override
  $FutureProviderElement<List<DockerContainer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DockerContainer>> create(Ref ref) {
    return dockerContainers(ref);
  }
}

String _$dockerContainersHash() => r'885eed20778949f8947a4d825eb712a109360bca';

@ProviderFor(dockerImages)
final dockerImagesProvider = DockerImagesProvider._();

final class DockerImagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DockerImage>>,
          List<DockerImage>,
          FutureOr<List<DockerImage>>
        >
    with
        $FutureModifier<List<DockerImage>>,
        $FutureProvider<List<DockerImage>> {
  DockerImagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dockerImagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dockerImagesHash();

  @$internal
  @override
  $FutureProviderElement<List<DockerImage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DockerImage>> create(Ref ref) {
    return dockerImages(ref);
  }
}

String _$dockerImagesHash() => r'dea397c97e95493831bc5cd038163d5f067ced2b';
