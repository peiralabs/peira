// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdm_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$pdmPanelHash() => r'a029b667ba7f1ff020d7b9d7118df2a31b78a1c1';
