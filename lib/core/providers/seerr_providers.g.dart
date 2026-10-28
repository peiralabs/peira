// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(seerrApi)
final seerrApiProvider = SeerrApiProvider._();

final class SeerrApiProvider
    extends
        $FunctionalProvider<AsyncValue<SeerrApi>, SeerrApi, FutureOr<SeerrApi>>
    with $FutureModifier<SeerrApi>, $FutureProvider<SeerrApi> {
  SeerrApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seerrApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seerrApiHash();

  @$internal
  @override
  $FutureProviderElement<SeerrApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SeerrApi> create(Ref ref) {
    return seerrApi(ref);
  }
}

String _$seerrApiHash() => r'039f865dc62241bc172e9e6f597f0bc733801f06';

/// Title details, kept for the session: the request list resolves its
/// titles through this, one fetch per title.

@ProviderFor(seerrDetails)
final seerrDetailsProvider = SeerrDetailsFamily._();

/// Title details, kept for the session: the request list resolves its
/// titles through this, one fetch per title.

final class SeerrDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SeerrDetails>,
          SeerrDetails,
          FutureOr<SeerrDetails>
        >
    with $FutureModifier<SeerrDetails>, $FutureProvider<SeerrDetails> {
  /// Title details, kept for the session: the request list resolves its
  /// titles through this, one fetch per title.
  SeerrDetailsProvider._({
    required SeerrDetailsFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'seerrDetailsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$seerrDetailsHash();

  @override
  String toString() {
    return r'seerrDetailsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SeerrDetails> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SeerrDetails> create(Ref ref) {
    final argument = this.argument as (String, int);
    return seerrDetails(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SeerrDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seerrDetailsHash() => r'12a0fa1f84559302b195edb9fcac85e1c50b997f';

/// Title details, kept for the session: the request list resolves its
/// titles through this, one fetch per title.

final class SeerrDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SeerrDetails>, (String, int)> {
  SeerrDetailsFamily._()
    : super(
        retry: null,
        name: r'seerrDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Title details, kept for the session: the request list resolves its
  /// titles through this, one fetch per title.

  SeerrDetailsProvider call(String mediaType, int tmdbId) =>
      SeerrDetailsProvider._(argument: (mediaType, tmdbId), from: this);

  @override
  String toString() => r'seerrDetailsProvider';
}

@ProviderFor(seerrRequests)
final seerrRequestsProvider = SeerrRequestsFamily._();

final class SeerrRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<({List<SeerrRequest> requests, int total})>,
          ({List<SeerrRequest> requests, int total}),
          FutureOr<({List<SeerrRequest> requests, int total})>
        >
    with
        $FutureModifier<({List<SeerrRequest> requests, int total})>,
        $FutureProvider<({List<SeerrRequest> requests, int total})> {
  SeerrRequestsProvider._({
    required SeerrRequestsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'seerrRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$seerrRequestsHash();

  @override
  String toString() {
    return r'seerrRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<({List<SeerrRequest> requests, int total})>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<({List<SeerrRequest> requests, int total})> create(Ref ref) {
    final argument = this.argument as String;
    return seerrRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SeerrRequestsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seerrRequestsHash() => r'409c0bf15dcad63e024cc68d9c84b85b9e9ef200';

final class SeerrRequestsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<({List<SeerrRequest> requests, int total})>,
          String
        > {
  SeerrRequestsFamily._()
    : super(
        retry: null,
        name: r'seerrRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SeerrRequestsProvider call(String filter) =>
      SeerrRequestsProvider._(argument: filter, from: this);

  @override
  String toString() => r'seerrRequestsProvider';
}

@ProviderFor(seerrCounts)
final seerrCountsProvider = SeerrCountsProvider._();

final class SeerrCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  SeerrCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seerrCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seerrCountsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return seerrCounts(ref);
  }
}

String _$seerrCountsHash() => r'95ab82b26fbf59611113b43d6caee626cbeebcad';

@ProviderFor(seerrIssues)
final seerrIssuesProvider = SeerrIssuesFamily._();

final class SeerrIssuesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SeerrIssue>>,
          List<SeerrIssue>,
          FutureOr<List<SeerrIssue>>
        >
    with $FutureModifier<List<SeerrIssue>>, $FutureProvider<List<SeerrIssue>> {
  SeerrIssuesProvider._({
    required SeerrIssuesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'seerrIssuesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$seerrIssuesHash();

  @override
  String toString() {
    return r'seerrIssuesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SeerrIssue>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SeerrIssue>> create(Ref ref) {
    final argument = this.argument as String;
    return seerrIssues(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SeerrIssuesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seerrIssuesHash() => r'bb69a252648ed16e281ff2702effc0e56a6bc7a4';

final class SeerrIssuesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SeerrIssue>>, String> {
  SeerrIssuesFamily._()
    : super(
        retry: null,
        name: r'seerrIssuesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SeerrIssuesProvider call(String filter) =>
      SeerrIssuesProvider._(argument: filter, from: this);

  @override
  String toString() => r'seerrIssuesProvider';
}
