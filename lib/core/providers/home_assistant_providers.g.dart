// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_assistant_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeAssistantApi)
final homeAssistantApiProvider = HomeAssistantApiProvider._();

final class HomeAssistantApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomeAssistantApi>,
          HomeAssistantApi,
          FutureOr<HomeAssistantApi>
        >
    with $FutureModifier<HomeAssistantApi>, $FutureProvider<HomeAssistantApi> {
  HomeAssistantApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeAssistantApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeAssistantApiHash();

  @$internal
  @override
  $FutureProviderElement<HomeAssistantApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomeAssistantApi> create(Ref ref) {
    return homeAssistantApi(ref);
  }
}

String _$homeAssistantApiHash() => r'58226f92deace3c469e506c21f18c145ecbf8357';

@ProviderFor(haConfig)
final haConfigProvider = HaConfigProvider._();

final class HaConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  HaConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'haConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$haConfigHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return haConfig(ref);
  }
}

String _$haConfigHash() => r'a07858280a7e98c0462b4e61b9f5e3a1d4c51631';

/// Every entity, refreshed every 30 s (and right after any service call).

@ProviderFor(haStates)
final haStatesProvider = HaStatesProvider._();

/// Every entity, refreshed every 30 s (and right after any service call).

final class HaStatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HaEntity>>,
          List<HaEntity>,
          FutureOr<List<HaEntity>>
        >
    with $FutureModifier<List<HaEntity>>, $FutureProvider<List<HaEntity>> {
  /// Every entity, refreshed every 30 s (and right after any service call).
  HaStatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'haStatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$haStatesHash();

  @$internal
  @override
  $FutureProviderElement<List<HaEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HaEntity>> create(Ref ref) {
    return haStates(ref);
  }
}

String _$haStatesHash() => r'04c3b20521a55cdf3abd0797232f0c5aeb652e2b';

@ProviderFor(haServices)
final haServicesProvider = HaServicesProvider._();

final class HaServicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HaService>>,
          List<HaService>,
          FutureOr<List<HaService>>
        >
    with $FutureModifier<List<HaService>>, $FutureProvider<List<HaService>> {
  HaServicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'haServicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$haServicesHash();

  @$internal
  @override
  $FutureProviderElement<List<HaService>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HaService>> create(Ref ref) {
    return haServices(ref);
  }
}

String _$haServicesHash() => r'e4c17c46fea6eff0247126f6e14dde0a0021bb25';

@ProviderFor(haLogbook)
final haLogbookProvider = HaLogbookFamily._();

final class HaLogbookProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HaLogbookEntry>>,
          List<HaLogbookEntry>,
          FutureOr<List<HaLogbookEntry>>
        >
    with
        $FutureModifier<List<HaLogbookEntry>>,
        $FutureProvider<List<HaLogbookEntry>> {
  HaLogbookProvider._({
    required HaLogbookFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'haLogbookProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$haLogbookHash();

  @override
  String toString() {
    return r'haLogbookProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<HaLogbookEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HaLogbookEntry>> create(Ref ref) {
    final argument = this.argument as int;
    return haLogbook(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HaLogbookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$haLogbookHash() => r'5ee4d8ceb6e39cfc2256ce837c142e43bb10b3e7';

final class HaLogbookFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<HaLogbookEntry>>, int> {
  HaLogbookFamily._()
    : super(
        retry: null,
        name: r'haLogbookProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HaLogbookProvider call(int hours) =>
      HaLogbookProvider._(argument: hours, from: this);

  @override
  String toString() => r'haLogbookProvider';
}

@ProviderFor(haHistory)
final haHistoryProvider = HaHistoryFamily._();

final class HaHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HaHistoryPoint>>,
          List<HaHistoryPoint>,
          FutureOr<List<HaHistoryPoint>>
        >
    with
        $FutureModifier<List<HaHistoryPoint>>,
        $FutureProvider<List<HaHistoryPoint>> {
  HaHistoryProvider._({
    required HaHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'haHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$haHistoryHash();

  @override
  String toString() {
    return r'haHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<HaHistoryPoint>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HaHistoryPoint>> create(Ref ref) {
    final argument = this.argument as String;
    return haHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HaHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$haHistoryHash() => r'9144c09e193972d54c9a9ee6c563795218375cfa';

final class HaHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<HaHistoryPoint>>, String> {
  HaHistoryFamily._()
    : super(
        retry: null,
        name: r'haHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HaHistoryProvider call(String entityId) =>
      HaHistoryProvider._(argument: entityId, from: this);

  @override
  String toString() => r'haHistoryProvider';
}

@ProviderFor(haTodoItems)
final haTodoItemsProvider = HaTodoItemsFamily._();

final class HaTodoItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HaTodoItem>>,
          List<HaTodoItem>,
          FutureOr<List<HaTodoItem>>
        >
    with $FutureModifier<List<HaTodoItem>>, $FutureProvider<List<HaTodoItem>> {
  HaTodoItemsProvider._({
    required HaTodoItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'haTodoItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$haTodoItemsHash();

  @override
  String toString() {
    return r'haTodoItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<HaTodoItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HaTodoItem>> create(Ref ref) {
    final argument = this.argument as String;
    return haTodoItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HaTodoItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$haTodoItemsHash() => r'b5372a31684163ba9f871809c11e78fc6d07f35c';

final class HaTodoItemsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<HaTodoItem>>, String> {
  HaTodoItemsFamily._()
    : super(
        retry: null,
        name: r'haTodoItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HaTodoItemsProvider call(String entityId) =>
      HaTodoItemsProvider._(argument: entityId, from: this);

  @override
  String toString() => r'haTodoItemsProvider';
}
