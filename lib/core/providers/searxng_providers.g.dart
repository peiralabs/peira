// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'searxng_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(searxngApi)
final searxngApiProvider = SearxngApiProvider._();

final class SearxngApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<SearxngApi>,
          SearxngApi,
          FutureOr<SearxngApi>
        >
    with $FutureModifier<SearxngApi>, $FutureProvider<SearxngApi> {
  SearxngApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searxngApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searxngApiHash();

  @$internal
  @override
  $FutureProviderElement<SearxngApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SearxngApi> create(Ref ref) {
    return searxngApi(ref);
  }
}

String _$searxngApiHash() => r'ed350d5a94c6b17ddee58aa85afc2beb34c2e632';

/// Categories, engines and locales the instance offers.

@ProviderFor(searxConfig)
final searxConfigProvider = SearxConfigProvider._();

/// Categories, engines and locales the instance offers.

final class SearxConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<SearxConfig>,
          SearxConfig,
          FutureOr<SearxConfig>
        >
    with $FutureModifier<SearxConfig>, $FutureProvider<SearxConfig> {
  /// Categories, engines and locales the instance offers.
  SearxConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searxConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searxConfigHash();

  @$internal
  @override
  $FutureProviderElement<SearxConfig> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SearxConfig> create(Ref ref) {
    return searxConfig(ref);
  }
}

String _$searxConfigHash() => r'90f5ea45d720ba065cd378c99d28632af85a4a37';
