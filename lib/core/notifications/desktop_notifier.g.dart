// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(desktopSender)
final desktopSenderProvider = DesktopSenderProvider._();

final class DesktopSenderProvider
    extends
        $FunctionalProvider<DesktopNotifier, DesktopNotifier, DesktopNotifier>
    with $Provider<DesktopNotifier> {
  DesktopSenderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopSenderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopSenderHash();

  @$internal
  @override
  $ProviderElement<DesktopNotifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DesktopNotifier create(Ref ref) {
    return desktopSender(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopNotifier>(value),
    );
  }
}

String _$desktopSenderHash() => r'62a5cf3343baebe0a4e69f8c5a6658f5cae6ecd8';
