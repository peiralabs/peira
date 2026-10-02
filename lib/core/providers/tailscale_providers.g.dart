// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tailscale_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tailscaleCli)
final tailscaleCliProvider = TailscaleCliProvider._();

final class TailscaleCliProvider
    extends $FunctionalProvider<TailscaleCli, TailscaleCli, TailscaleCli>
    with $Provider<TailscaleCli> {
  TailscaleCliProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tailscaleCliProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tailscaleCliHash();

  @$internal
  @override
  $ProviderElement<TailscaleCli> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TailscaleCli create(Ref ref) {
    return tailscaleCli(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TailscaleCli value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TailscaleCli>(value),
    );
  }
}

String _$tailscaleCliHash() => r'e7d360dd4df58a61431960bfcdd8fa2045ee3f9c';

@ProviderFor(tailscaleStatus)
final tailscaleStatusProvider = TailscaleStatusProvider._();

final class TailscaleStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<TailscaleStatus>,
          TailscaleStatus,
          FutureOr<TailscaleStatus>
        >
    with $FutureModifier<TailscaleStatus>, $FutureProvider<TailscaleStatus> {
  TailscaleStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tailscaleStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tailscaleStatusHash();

  @$internal
  @override
  $FutureProviderElement<TailscaleStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TailscaleStatus> create(Ref ref) {
    return tailscaleStatus(ref);
  }
}

String _$tailscaleStatusHash() => r'a711cff0afda63c7f7dc0b193309ac0c3b86eb3c';
