// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(jellyfinApi)
final jellyfinApiProvider = JellyfinApiProvider._();

final class JellyfinApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<JellyfinApi>,
          JellyfinApi,
          FutureOr<JellyfinApi>
        >
    with $FutureModifier<JellyfinApi>, $FutureProvider<JellyfinApi> {
  JellyfinApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jellyfinApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jellyfinApiHash();

  @$internal
  @override
  $FutureProviderElement<JellyfinApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JellyfinApi> create(Ref ref) {
    return jellyfinApi(ref);
  }
}

String _$jellyfinApiHash() => r'71852131b1624b3140c9165d684399f63b7ea1d8';

@ProviderFor(jellyfinStatus)
final jellyfinStatusProvider = JellyfinStatusProvider._();

final class JellyfinStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<MediaServerStatus>,
          MediaServerStatus,
          FutureOr<MediaServerStatus>
        >
    with
        $FutureModifier<MediaServerStatus>,
        $FutureProvider<MediaServerStatus> {
  JellyfinStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jellyfinStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jellyfinStatusHash();

  @$internal
  @override
  $FutureProviderElement<MediaServerStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MediaServerStatus> create(Ref ref) {
    return jellyfinStatus(ref);
  }
}

String _$jellyfinStatusHash() => r'a6178160a1cce1980c66abd375127b83f5ab5071';

@ProviderFor(plexApi)
final plexApiProvider = PlexApiProvider._();

final class PlexApiProvider
    extends $FunctionalProvider<AsyncValue<PlexApi>, PlexApi, FutureOr<PlexApi>>
    with $FutureModifier<PlexApi>, $FutureProvider<PlexApi> {
  PlexApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plexApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plexApiHash();

  @$internal
  @override
  $FutureProviderElement<PlexApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PlexApi> create(Ref ref) {
    return plexApi(ref);
  }
}

String _$plexApiHash() => r'c1f11fc94a3b32875e1105de6e3629f0967d24e6';

@ProviderFor(plexStatus)
final plexStatusProvider = PlexStatusProvider._();

final class PlexStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<MediaServerStatus>,
          MediaServerStatus,
          FutureOr<MediaServerStatus>
        >
    with
        $FutureModifier<MediaServerStatus>,
        $FutureProvider<MediaServerStatus> {
  PlexStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plexStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plexStatusHash();

  @$internal
  @override
  $FutureProviderElement<MediaServerStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MediaServerStatus> create(Ref ref) {
    return plexStatus(ref);
  }
}

String _$plexStatusHash() => r'23f4d2b5a07aa795b3c990344d1df2fb6ce4acff';

@ProviderFor(radarrApi)
final radarrApiProvider = RadarrApiProvider._();

final class RadarrApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<RadarrApi>,
          RadarrApi,
          FutureOr<RadarrApi>
        >
    with $FutureModifier<RadarrApi>, $FutureProvider<RadarrApi> {
  RadarrApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarrApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarrApiHash();

  @$internal
  @override
  $FutureProviderElement<RadarrApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RadarrApi> create(Ref ref) {
    return radarrApi(ref);
  }
}

String _$radarrApiHash() => r'2b70d759543d14388b6e818582437d87c4d7fda6';

@ProviderFor(radarrMovies)
final radarrMoviesProvider = RadarrMoviesProvider._();

final class RadarrMoviesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RadarrMovie>>,
          List<RadarrMovie>,
          FutureOr<List<RadarrMovie>>
        >
    with
        $FutureModifier<List<RadarrMovie>>,
        $FutureProvider<List<RadarrMovie>> {
  RadarrMoviesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarrMoviesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarrMoviesHash();

  @$internal
  @override
  $FutureProviderElement<List<RadarrMovie>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RadarrMovie>> create(Ref ref) {
    return radarrMovies(ref);
  }
}

String _$radarrMoviesHash() => r'f392852633fe0a4b985f648dabc309edfd640a59';

@ProviderFor(radarrQueue)
final radarrQueueProvider = RadarrQueueProvider._();

final class RadarrQueueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ServarrQueueItem>>,
          List<ServarrQueueItem>,
          FutureOr<List<ServarrQueueItem>>
        >
    with
        $FutureModifier<List<ServarrQueueItem>>,
        $FutureProvider<List<ServarrQueueItem>> {
  RadarrQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarrQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarrQueueHash();

  @$internal
  @override
  $FutureProviderElement<List<ServarrQueueItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ServarrQueueItem>> create(Ref ref) {
    return radarrQueue(ref);
  }
}

String _$radarrQueueHash() => r'34bbbba9a35b449b94012223e7095b71bb4ee01e';

@ProviderFor(sonarrApi)
final sonarrApiProvider = SonarrApiProvider._();

final class SonarrApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<SonarrApi>,
          SonarrApi,
          FutureOr<SonarrApi>
        >
    with $FutureModifier<SonarrApi>, $FutureProvider<SonarrApi> {
  SonarrApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarrApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarrApiHash();

  @$internal
  @override
  $FutureProviderElement<SonarrApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SonarrApi> create(Ref ref) {
    return sonarrApi(ref);
  }
}

String _$sonarrApiHash() => r'f1d5339708f08389fd354dee5803fb90d60e1bb3';

@ProviderFor(sonarrSeries)
final sonarrSeriesProvider = SonarrSeriesProvider._();

final class SonarrSeriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SonarrSeries>>,
          List<SonarrSeries>,
          FutureOr<List<SonarrSeries>>
        >
    with
        $FutureModifier<List<SonarrSeries>>,
        $FutureProvider<List<SonarrSeries>> {
  SonarrSeriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarrSeriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarrSeriesHash();

  @$internal
  @override
  $FutureProviderElement<List<SonarrSeries>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SonarrSeries>> create(Ref ref) {
    return sonarrSeries(ref);
  }
}

String _$sonarrSeriesHash() => r'53a68a7a4d6b5a837fe2ecb8f55b160ad73af066';

@ProviderFor(sonarrQueue)
final sonarrQueueProvider = SonarrQueueProvider._();

final class SonarrQueueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ServarrQueueItem>>,
          List<ServarrQueueItem>,
          FutureOr<List<ServarrQueueItem>>
        >
    with
        $FutureModifier<List<ServarrQueueItem>>,
        $FutureProvider<List<ServarrQueueItem>> {
  SonarrQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarrQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarrQueueHash();

  @$internal
  @override
  $FutureProviderElement<List<ServarrQueueItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ServarrQueueItem>> create(Ref ref) {
    return sonarrQueue(ref);
  }
}

String _$sonarrQueueHash() => r'f041b93a8ff92fd54e72ff8e53396915bf087acf';

@ProviderFor(prowlarrApi)
final prowlarrApiProvider = ProwlarrApiProvider._();

final class ProwlarrApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProwlarrApi>,
          ProwlarrApi,
          FutureOr<ProwlarrApi>
        >
    with $FutureModifier<ProwlarrApi>, $FutureProvider<ProwlarrApi> {
  ProwlarrApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prowlarrApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prowlarrApiHash();

  @$internal
  @override
  $FutureProviderElement<ProwlarrApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProwlarrApi> create(Ref ref) {
    return prowlarrApi(ref);
  }
}

String _$prowlarrApiHash() => r'5a104a6a939d81575d104ce95802ec20822ae56a';

@ProviderFor(prowlarrIndexers)
final prowlarrIndexersProvider = ProwlarrIndexersProvider._();

final class ProwlarrIndexersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProwlarrIndexer>>,
          List<ProwlarrIndexer>,
          FutureOr<List<ProwlarrIndexer>>
        >
    with
        $FutureModifier<List<ProwlarrIndexer>>,
        $FutureProvider<List<ProwlarrIndexer>> {
  ProwlarrIndexersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prowlarrIndexersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prowlarrIndexersHash();

  @$internal
  @override
  $FutureProviderElement<List<ProwlarrIndexer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProwlarrIndexer>> create(Ref ref) {
    return prowlarrIndexers(ref);
  }
}

String _$prowlarrIndexersHash() => r'aa59d425df10b4008349ca7d5b39ca0d37955e4a';

@ProviderFor(qbittorrentApi)
final qbittorrentApiProvider = QbittorrentApiProvider._();

final class QbittorrentApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<QbittorrentApi>,
          QbittorrentApi,
          FutureOr<QbittorrentApi>
        >
    with $FutureModifier<QbittorrentApi>, $FutureProvider<QbittorrentApi> {
  QbittorrentApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qbittorrentApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qbittorrentApiHash();

  @$internal
  @override
  $FutureProviderElement<QbittorrentApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QbittorrentApi> create(Ref ref) {
    return qbittorrentApi(ref);
  }
}

String _$qbittorrentApiHash() => r'49a3852792fa2c34691fb54bae569874f9c597f7';

@ProviderFor(qbittorrentTorrents)
final qbittorrentTorrentsProvider = QbittorrentTorrentsProvider._();

final class QbittorrentTorrentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<QbittorrentTorrent>>,
          List<QbittorrentTorrent>,
          FutureOr<List<QbittorrentTorrent>>
        >
    with
        $FutureModifier<List<QbittorrentTorrent>>,
        $FutureProvider<List<QbittorrentTorrent>> {
  QbittorrentTorrentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qbittorrentTorrentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qbittorrentTorrentsHash();

  @$internal
  @override
  $FutureProviderElement<List<QbittorrentTorrent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<QbittorrentTorrent>> create(Ref ref) {
    return qbittorrentTorrents(ref);
  }
}

String _$qbittorrentTorrentsHash() =>
    r'd7ead909a7fe64c5dbd8f8d90997943e01516d07';
