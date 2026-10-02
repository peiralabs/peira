// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webview_factory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(webViewFactory)
final webViewFactoryProvider = WebViewFactoryProvider._();

final class WebViewFactoryProvider
    extends $FunctionalProvider<WebViewFactory, WebViewFactory, WebViewFactory>
    with $Provider<WebViewFactory> {
  WebViewFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webViewFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webViewFactoryHash();

  @$internal
  @override
  $ProviderElement<WebViewFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WebViewFactory create(Ref ref) {
    return webViewFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebViewFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebViewFactory>(value),
    );
  }
}

String _$webViewFactoryHash() => r'63a52bb5039b76131d6ab53f4f0b7acec0293263';
