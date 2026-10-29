// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently selected AppShell tab. Null until something picks one, letting
/// the shell decide the initial tab (Dashboard normally, Settings on first
/// launch). Dashboard tiles set this to jump to other tabs.
///
/// `MOL_INITIAL_TAB` forces the starting tab — a debug aid for launching
/// straight into one tab while debugging it.

@ProviderFor(SelectedTab)
final selectedTabProvider = SelectedTabProvider._();

/// Currently selected AppShell tab. Null until something picks one, letting
/// the shell decide the initial tab (Dashboard normally, Settings on first
/// launch). Dashboard tiles set this to jump to other tabs.
///
/// `MOL_INITIAL_TAB` forces the starting tab — a debug aid for launching
/// straight into one tab while debugging it.
final class SelectedTabProvider extends $NotifierProvider<SelectedTab, int?> {
  /// Currently selected AppShell tab. Null until something picks one, letting
  /// the shell decide the initial tab (Dashboard normally, Settings on first
  /// launch). Dashboard tiles set this to jump to other tabs.
  ///
  /// `MOL_INITIAL_TAB` forces the starting tab — a debug aid for launching
  /// straight into one tab while debugging it.
  SelectedTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTabHash();

  @$internal
  @override
  SelectedTab create() => SelectedTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$selectedTabHash() => r'd1d7674671b915657f747ed0a08be31c47a81588';

/// Currently selected AppShell tab. Null until something picks one, letting
/// the shell decide the initial tab (Dashboard normally, Settings on first
/// launch). Dashboard tiles set this to jump to other tabs.
///
/// `MOL_INITIAL_TAB` forces the starting tab — a debug aid for launching
/// straight into one tab while debugging it.

abstract class _$SelectedTab extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Selected sub-tab per hub destination (AI, Media, Vault). Provider-driven
/// rather than a widget-local DefaultTabController so the command palette
/// (and any deep link) can address a hub's sub-view directly; the hub's
/// strip and this state two-way sync in [HubScaffold].

@ProviderFor(HubSubTab)
final hubSubTabProvider = HubSubTabFamily._();

/// Selected sub-tab per hub destination (AI, Media, Vault). Provider-driven
/// rather than a widget-local DefaultTabController so the command palette
/// (and any deep link) can address a hub's sub-view directly; the hub's
/// strip and this state two-way sync in [HubScaffold].
final class HubSubTabProvider extends $NotifierProvider<HubSubTab, int> {
  /// Selected sub-tab per hub destination (AI, Media, Vault). Provider-driven
  /// rather than a widget-local DefaultTabController so the command palette
  /// (and any deep link) can address a hub's sub-view directly; the hub's
  /// strip and this state two-way sync in [HubScaffold].
  HubSubTabProvider._({
    required HubSubTabFamily super.from,
    required AppTab super.argument,
  }) : super(
         retry: null,
         name: r'hubSubTabProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hubSubTabHash();

  @override
  String toString() {
    return r'hubSubTabProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HubSubTab create() => HubSubTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HubSubTabProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hubSubTabHash() => r'1c5d5cc2c22bb7e088046ed53491780172287576';

/// Selected sub-tab per hub destination (AI, Media, Vault). Provider-driven
/// rather than a widget-local DefaultTabController so the command palette
/// (and any deep link) can address a hub's sub-view directly; the hub's
/// strip and this state two-way sync in [HubScaffold].

final class HubSubTabFamily extends $Family
    with $ClassFamilyOverride<HubSubTab, int, int, int, AppTab> {
  HubSubTabFamily._()
    : super(
        retry: null,
        name: r'hubSubTabProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Selected sub-tab per hub destination (AI, Media, Vault). Provider-driven
  /// rather than a widget-local DefaultTabController so the command palette
  /// (and any deep link) can address a hub's sub-view directly; the hub's
  /// strip and this state two-way sync in [HubScaffold].

  HubSubTabProvider call(AppTab tab) =>
      HubSubTabProvider._(argument: tab, from: this);

  @override
  String toString() => r'hubSubTabProvider';
}

/// Selected sub-tab per hub destination (AI, Media, Vault). Provider-driven
/// rather than a widget-local DefaultTabController so the command palette
/// (and any deep link) can address a hub's sub-view directly; the hub's
/// strip and this state two-way sync in [HubScaffold].

abstract class _$HubSubTab extends $Notifier<int> {
  late final _$args = ref.$arg as AppTab;
  AppTab get tab => _$args;

  int build(AppTab tab);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Whether the guide may open by itself. Off under `flutter test`, where
/// most widget tests boot a configured shell and a surprise dialog would
/// cover it; the guide's own test overrides it.

@ProviderFor(guideAutoOpen)
final guideAutoOpenProvider = GuideAutoOpenProvider._();

/// Whether the guide may open by itself. Off under `flutter test`, where
/// most widget tests boot a configured shell and a surprise dialog would
/// cover it; the guide's own test overrides it.

final class GuideAutoOpenProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the guide may open by itself. Off under `flutter test`, where
  /// most widget tests boot a configured shell and a surprise dialog would
  /// cover it; the guide's own test overrides it.
  GuideAutoOpenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideAutoOpenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideAutoOpenHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return guideAutoOpen(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$guideAutoOpenHash() => r'f5df1a6b3a1a2cd45d64bf6acf4a13c1173020d6';

/// Set once the guide has opened by itself this session, so a rebuild of
/// the shell does not open it again.

@ProviderFor(GuideShown)
final guideShownProvider = GuideShownProvider._();

/// Set once the guide has opened by itself this session, so a rebuild of
/// the shell does not open it again.
final class GuideShownProvider extends $NotifierProvider<GuideShown, bool> {
  /// Set once the guide has opened by itself this session, so a rebuild of
  /// the shell does not open it again.
  GuideShownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideShownProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideShownHash();

  @$internal
  @override
  GuideShown create() => GuideShown();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$guideShownHash() => r'99d6433e8415c31bf4a2c280233b825f3d7e6ba8';

/// Set once the guide has opened by itself this session, so a rebuild of
/// the shell does not open it again.

abstract class _$GuideShown extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
