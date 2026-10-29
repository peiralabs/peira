// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wikijs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wikiJsApi)
final wikiJsApiProvider = WikiJsApiProvider._();

final class WikiJsApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<WikiJsApi>,
          WikiJsApi,
          FutureOr<WikiJsApi>
        >
    with $FutureModifier<WikiJsApi>, $FutureProvider<WikiJsApi> {
  WikiJsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wikiJsApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wikiJsApiHash();

  @$internal
  @override
  $FutureProviderElement<WikiJsApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WikiJsApi> create(Ref ref) {
    return wikiJsApi(ref);
  }
}

String _$wikiJsApiHash() => r'7648a173610e8ad5e858f9f1cefd08776311c35f';

@ProviderFor(wikiPages)
final wikiPagesProvider = WikiPagesFamily._();

final class WikiPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WikiPageItem>>,
          List<WikiPageItem>,
          FutureOr<List<WikiPageItem>>
        >
    with
        $FutureModifier<List<WikiPageItem>>,
        $FutureProvider<List<WikiPageItem>> {
  WikiPagesProvider._({
    required WikiPagesFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'wikiPagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$wikiPagesHash();

  @override
  String toString() {
    return r'wikiPagesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<WikiPageItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WikiPageItem>> create(Ref ref) {
    final argument = this.argument as (String, String?);
    return wikiPages(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WikiPagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wikiPagesHash() => r'3a32d09ac9cabeca1d53cb548b400598dcdebc7e';

final class WikiPagesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<WikiPageItem>>,
          (String, String?)
        > {
  WikiPagesFamily._()
    : super(
        retry: null,
        name: r'wikiPagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WikiPagesProvider call(String orderBy, String? tag) =>
      WikiPagesProvider._(argument: (orderBy, tag), from: this);

  @override
  String toString() => r'wikiPagesProvider';
}

@ProviderFor(wikiPage)
final wikiPageProvider = WikiPageFamily._();

final class WikiPageProvider
    extends
        $FunctionalProvider<AsyncValue<WikiPage>, WikiPage, FutureOr<WikiPage>>
    with $FutureModifier<WikiPage>, $FutureProvider<WikiPage> {
  WikiPageProvider._({
    required WikiPageFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'wikiPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$wikiPageHash();

  @override
  String toString() {
    return r'wikiPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WikiPage> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WikiPage> create(Ref ref) {
    final argument = this.argument as int;
    return wikiPage(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WikiPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wikiPageHash() => r'002bfbd2ed2618e8bb1a33b0cb2f5494ba0e5b3d';

final class WikiPageFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WikiPage>, int> {
  WikiPageFamily._()
    : super(
        retry: null,
        name: r'wikiPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WikiPageProvider call(int id) => WikiPageProvider._(argument: id, from: this);

  @override
  String toString() => r'wikiPageProvider';
}

@ProviderFor(wikiHistory)
final wikiHistoryProvider = WikiHistoryFamily._();

final class WikiHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WikiHistoryEntry>>,
          List<WikiHistoryEntry>,
          FutureOr<List<WikiHistoryEntry>>
        >
    with
        $FutureModifier<List<WikiHistoryEntry>>,
        $FutureProvider<List<WikiHistoryEntry>> {
  WikiHistoryProvider._({
    required WikiHistoryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'wikiHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$wikiHistoryHash();

  @override
  String toString() {
    return r'wikiHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<WikiHistoryEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WikiHistoryEntry>> create(Ref ref) {
    final argument = this.argument as int;
    return wikiHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WikiHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wikiHistoryHash() => r'ed407e018c44652fb8c9480c8f13cbbbeb09c387';

final class WikiHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<WikiHistoryEntry>>, int> {
  WikiHistoryFamily._()
    : super(
        retry: null,
        name: r'wikiHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WikiHistoryProvider call(int id) =>
      WikiHistoryProvider._(argument: id, from: this);

  @override
  String toString() => r'wikiHistoryProvider';
}

@ProviderFor(wikiTags)
final wikiTagsProvider = WikiTagsProvider._();

final class WikiTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WikiTag>>,
          List<WikiTag>,
          FutureOr<List<WikiTag>>
        >
    with $FutureModifier<List<WikiTag>>, $FutureProvider<List<WikiTag>> {
  WikiTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wikiTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wikiTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<WikiTag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WikiTag>> create(Ref ref) {
    return wikiTags(ref);
  }
}

String _$wikiTagsHash() => r'756c76a483111105aab0beab1771517469734e76';

@ProviderFor(wikiSystem)
final wikiSystemProvider = WikiSystemProvider._();

final class WikiSystemProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  WikiSystemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wikiSystemProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wikiSystemHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return wikiSystem(ref);
  }
}

String _$wikiSystemHash() => r'c01fefc4c787e25aefab37ca8b4cf6aac1547b8d';
