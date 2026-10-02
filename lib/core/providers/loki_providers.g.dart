// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loki_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lokiApi)
final lokiApiProvider = LokiApiProvider._();

final class LokiApiProvider
    extends $FunctionalProvider<AsyncValue<LokiApi>, LokiApi, FutureOr<LokiApi>>
    with $FutureModifier<LokiApi>, $FutureProvider<LokiApi> {
  LokiApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lokiApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lokiApiHash();

  @$internal
  @override
  $FutureProviderElement<LokiApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LokiApi> create(Ref ref) {
    return lokiApi(ref);
  }
}

String _$lokiApiHash() => r'361f4dfea68b08295ceffc7c425870d23e6a18a3';

/// Host-label values for the filter chips. Fetched once per session; the
/// screen's refresh action invalidates it alongside the tail.

@ProviderFor(lokiHosts)
final lokiHostsProvider = LokiHostsProvider._();

/// Host-label values for the filter chips. Fetched once per session; the
/// screen's refresh action invalidates it alongside the tail.

final class LokiHostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Host-label values for the filter chips. Fetched once per session; the
  /// screen's refresh action invalidates it alongside the tail.
  LokiHostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lokiHostsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lokiHostsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return lokiHosts(ref);
  }
}

String _$lokiHostsHash() => r'b9ad68fb159b6fc4099b22a1e265e29ecac74c29';

/// Newest-first tail for the current filter, refreshed every 30 s like the
/// other telemetry providers.

@ProviderFor(lokiTail)
final lokiTailProvider = LokiTailFamily._();

/// Newest-first tail for the current filter, refreshed every 30 s like the
/// other telemetry providers.

final class LokiTailProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LokiEntry>>,
          List<LokiEntry>,
          FutureOr<List<LokiEntry>>
        >
    with $FutureModifier<List<LokiEntry>>, $FutureProvider<List<LokiEntry>> {
  /// Newest-first tail for the current filter, refreshed every 30 s like the
  /// other telemetry providers.
  LokiTailProvider._({
    required LokiTailFamily super.from,
    required ({String contains, String host}) super.argument,
  }) : super(
         retry: null,
         name: r'lokiTailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lokiTailHash();

  @override
  String toString() {
    return r'lokiTailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<LokiEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LokiEntry>> create(Ref ref) {
    final argument = this.argument as ({String contains, String host});
    return lokiTail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LokiTailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lokiTailHash() => r'f6003f53865e51223d877318e16169bbfcc93068';

/// Newest-first tail for the current filter, refreshed every 30 s like the
/// other telemetry providers.

final class LokiTailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<LokiEntry>>,
          ({String contains, String host})
        > {
  LokiTailFamily._()
    : super(
        retry: null,
        name: r'lokiTailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Newest-first tail for the current filter, refreshed every 30 s like the
  /// other telemetry providers.

  LokiTailProvider call(({String contains, String host}) filter) =>
      LokiTailProvider._(argument: filter, from: this);

  @override
  String toString() => r'lokiTailProvider';
}
