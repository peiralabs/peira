// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paperless_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paperlessApi)
final paperlessApiProvider = PaperlessApiProvider._();

final class PaperlessApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaperlessApi>,
          PaperlessApi,
          FutureOr<PaperlessApi>
        >
    with $FutureModifier<PaperlessApi>, $FutureProvider<PaperlessApi> {
  PaperlessApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paperlessApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paperlessApiHash();

  @$internal
  @override
  $FutureProviderElement<PaperlessApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaperlessApi> create(Ref ref) {
    return paperlessApi(ref);
  }
}

String _$paperlessApiHash() => r'24295b6699810d8c00402c459f891d842ee5d083';

/// `tags`, `correspondents`, `document_types` or `storage_paths`.

@ProviderFor(plLabels)
final plLabelsProvider = PlLabelsFamily._();

/// `tags`, `correspondents`, `document_types` or `storage_paths`.

final class PlLabelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlLabel>>,
          List<PlLabel>,
          FutureOr<List<PlLabel>>
        >
    with $FutureModifier<List<PlLabel>>, $FutureProvider<List<PlLabel>> {
  /// `tags`, `correspondents`, `document_types` or `storage_paths`.
  PlLabelsProvider._({
    required PlLabelsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'plLabelsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plLabelsHash();

  @override
  String toString() {
    return r'plLabelsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlLabel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlLabel>> create(Ref ref) {
    final argument = this.argument as String;
    return plLabels(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlLabelsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plLabelsHash() => r'a9babf448e77c1b85925a5f0b46ca0cbb838c90a';

/// `tags`, `correspondents`, `document_types` or `storage_paths`.

final class PlLabelsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlLabel>>, String> {
  PlLabelsFamily._()
    : super(
        retry: null,
        name: r'plLabelsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// `tags`, `correspondents`, `document_types` or `storage_paths`.

  PlLabelsProvider call(String kind) =>
      PlLabelsProvider._(argument: kind, from: this);

  @override
  String toString() => r'plLabelsProvider';
}

@ProviderFor(plDocument)
final plDocumentProvider = PlDocumentFamily._();

final class PlDocumentProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlDocument>,
          PlDocument,
          FutureOr<PlDocument>
        >
    with $FutureModifier<PlDocument>, $FutureProvider<PlDocument> {
  PlDocumentProvider._({
    required PlDocumentFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'plDocumentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plDocumentHash();

  @override
  String toString() {
    return r'plDocumentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlDocument> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PlDocument> create(Ref ref) {
    final argument = this.argument as int;
    return plDocument(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlDocumentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plDocumentHash() => r'4a1c8f1237b70ed2ac823e5ed14e87d730160058';

final class PlDocumentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlDocument>, int> {
  PlDocumentFamily._()
    : super(
        retry: null,
        name: r'plDocumentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlDocumentProvider call(int id) =>
      PlDocumentProvider._(argument: id, from: this);

  @override
  String toString() => r'plDocumentProvider';
}

@ProviderFor(plTasks)
final plTasksProvider = PlTasksProvider._();

final class PlTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<({int count, List<PlTask> tasks})>,
          ({int count, List<PlTask> tasks}),
          FutureOr<({int count, List<PlTask> tasks})>
        >
    with
        $FutureModifier<({int count, List<PlTask> tasks})>,
        $FutureProvider<({int count, List<PlTask> tasks})> {
  PlTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plTasksHash();

  @$internal
  @override
  $FutureProviderElement<({int count, List<PlTask> tasks})> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<({int count, List<PlTask> tasks})> create(Ref ref) {
    return plTasks(ref);
  }
}

String _$plTasksHash() => r'27c942873af3fd51f5e0e1cace37b6251aa8edef';

@ProviderFor(plStats)
final plStatsProvider = PlStatsProvider._();

final class PlStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  PlStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plStatsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return plStats(ref);
  }
}

String _$plStatsHash() => r'7250cbdd0a562f394f593f2615f9f5faec7f3411';
