// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'karakeep_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(karakeepApi)
final karakeepApiProvider = KarakeepApiProvider._();

final class KarakeepApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<KarakeepApi>,
          KarakeepApi,
          FutureOr<KarakeepApi>
        >
    with $FutureModifier<KarakeepApi>, $FutureProvider<KarakeepApi> {
  KarakeepApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'karakeepApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$karakeepApiHash();

  @$internal
  @override
  $FutureProviderElement<KarakeepApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<KarakeepApi> create(Ref ref) {
    return karakeepApi(ref);
  }
}

String _$karakeepApiHash() => r'ce2338354aa76f9f9fdf4d8f602a398347129103';

@ProviderFor(kkBookmark)
final kkBookmarkProvider = KkBookmarkFamily._();

final class KkBookmarkProvider
    extends
        $FunctionalProvider<
          AsyncValue<KkBookmark>,
          KkBookmark,
          FutureOr<KkBookmark>
        >
    with $FutureModifier<KkBookmark>, $FutureProvider<KkBookmark> {
  KkBookmarkProvider._({
    required KkBookmarkFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kkBookmarkProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kkBookmarkHash();

  @override
  String toString() {
    return r'kkBookmarkProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<KkBookmark> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<KkBookmark> create(Ref ref) {
    final argument = this.argument as String;
    return kkBookmark(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KkBookmarkProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kkBookmarkHash() => r'2cb75e20b9bcaf679cfd49286c8222dc972fe461';

final class KkBookmarkFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<KkBookmark>, String> {
  KkBookmarkFamily._()
    : super(
        retry: null,
        name: r'kkBookmarkProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KkBookmarkProvider call(String id) =>
      KkBookmarkProvider._(argument: id, from: this);

  @override
  String toString() => r'kkBookmarkProvider';
}

@ProviderFor(kkTags)
final kkTagsProvider = KkTagsProvider._();

final class KkTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KkTag>>,
          List<KkTag>,
          FutureOr<List<KkTag>>
        >
    with $FutureModifier<List<KkTag>>, $FutureProvider<List<KkTag>> {
  KkTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kkTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kkTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<KkTag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KkTag>> create(Ref ref) {
    return kkTags(ref);
  }
}

String _$kkTagsHash() => r'c45b0fdae304d1ccdd40a3221358934cf94036b0';

@ProviderFor(kkLists)
final kkListsProvider = KkListsProvider._();

final class KkListsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KkList>>,
          List<KkList>,
          FutureOr<List<KkList>>
        >
    with $FutureModifier<List<KkList>>, $FutureProvider<List<KkList>> {
  KkListsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kkListsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kkListsHash();

  @$internal
  @override
  $FutureProviderElement<List<KkList>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KkList>> create(Ref ref) {
    return kkLists(ref);
  }
}

String _$kkListsHash() => r'0dbdb046977e19726947ad83855f5c6c77229e42';

@ProviderFor(kkFeeds)
final kkFeedsProvider = KkFeedsProvider._();

final class KkFeedsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KkFeed>>,
          List<KkFeed>,
          FutureOr<List<KkFeed>>
        >
    with $FutureModifier<List<KkFeed>>, $FutureProvider<List<KkFeed>> {
  KkFeedsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kkFeedsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kkFeedsHash();

  @$internal
  @override
  $FutureProviderElement<List<KkFeed>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KkFeed>> create(Ref ref) {
    return kkFeeds(ref);
  }
}

String _$kkFeedsHash() => r'0fa4ac5fc695ef887ac136e27b47dbd8067221db';

@ProviderFor(kkHighlights)
final kkHighlightsProvider = KkHighlightsProvider._();

final class KkHighlightsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KkHighlight>>,
          List<KkHighlight>,
          FutureOr<List<KkHighlight>>
        >
    with
        $FutureModifier<List<KkHighlight>>,
        $FutureProvider<List<KkHighlight>> {
  KkHighlightsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kkHighlightsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kkHighlightsHash();

  @$internal
  @override
  $FutureProviderElement<List<KkHighlight>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KkHighlight>> create(Ref ref) {
    return kkHighlights(ref);
  }
}

String _$kkHighlightsHash() => r'a1fe0879c54cd914b728a9d5e0a19f45297e945d';

@ProviderFor(kkStats)
final kkStatsProvider = KkStatsProvider._();

final class KkStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  KkStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kkStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kkStatsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return kkStats(ref);
  }
}

String _$kkStatsHash() => r'040c74398f2a5de38df2bae4f8f6219822bf7476';
