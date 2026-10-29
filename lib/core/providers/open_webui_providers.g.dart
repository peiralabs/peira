// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_webui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(openWebUiApi)
final openWebUiApiProvider = OpenWebUiApiProvider._();

final class OpenWebUiApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<OpenWebUiApi>,
          OpenWebUiApi,
          FutureOr<OpenWebUiApi>
        >
    with $FutureModifier<OpenWebUiApi>, $FutureProvider<OpenWebUiApi> {
  OpenWebUiApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openWebUiApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openWebUiApiHash();

  @$internal
  @override
  $FutureProviderElement<OpenWebUiApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OpenWebUiApi> create(Ref ref) {
    return openWebUiApi(ref);
  }
}

String _$openWebUiApiHash() => r'ce3b4aee8d40af51d23714336cf64586aa4505be';

@ProviderFor(owModels)
final owModelsProvider = OwModelsProvider._();

final class OwModelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OwModel>>,
          List<OwModel>,
          FutureOr<List<OwModel>>
        >
    with $FutureModifier<List<OwModel>>, $FutureProvider<List<OwModel>> {
  OwModelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'owModelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$owModelsHash();

  @$internal
  @override
  $FutureProviderElement<List<OwModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OwModel>> create(Ref ref) {
    return owModels(ref);
  }
}

String _$owModelsHash() => r'4232368682d31704b738d9ba96d0dd5ab3ac098e';

@ProviderFor(owKnowledge)
final owKnowledgeProvider = OwKnowledgeProvider._();

final class OwKnowledgeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OwKnowledge>>,
          List<OwKnowledge>,
          FutureOr<List<OwKnowledge>>
        >
    with
        $FutureModifier<List<OwKnowledge>>,
        $FutureProvider<List<OwKnowledge>> {
  OwKnowledgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'owKnowledgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$owKnowledgeHash();

  @$internal
  @override
  $FutureProviderElement<List<OwKnowledge>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OwKnowledge>> create(Ref ref) {
    return owKnowledge(ref);
  }
}

String _$owKnowledgeHash() => r'914f3cba93ac0c03692983e0a7a00b87ab5a9795';

@ProviderFor(owChats)
final owChatsProvider = OwChatsFamily._();

final class OwChatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OwChatSummary>>,
          List<OwChatSummary>,
          FutureOr<List<OwChatSummary>>
        >
    with
        $FutureModifier<List<OwChatSummary>>,
        $FutureProvider<List<OwChatSummary>> {
  OwChatsProvider._({
    required OwChatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'owChatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$owChatsHash();

  @override
  String toString() {
    return r'owChatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<OwChatSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OwChatSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return owChats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OwChatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$owChatsHash() => r'c8f01497d490948b6166638ed41b0435c7b24c23';

final class OwChatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<OwChatSummary>>, String> {
  OwChatsFamily._()
    : super(
        retry: null,
        name: r'owChatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OwChatsProvider call(String query) =>
      OwChatsProvider._(argument: query, from: this);

  @override
  String toString() => r'owChatsProvider';
}
