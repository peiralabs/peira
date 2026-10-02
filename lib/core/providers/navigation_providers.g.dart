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
/// straight into a webview tab (e.g. to attach CEF DevTools to Grafana).

@ProviderFor(SelectedTab)
final selectedTabProvider = SelectedTabProvider._();

/// Currently selected AppShell tab. Null until something picks one, letting
/// the shell decide the initial tab (Dashboard normally, Settings on first
/// launch). Dashboard tiles set this to jump to other tabs.
///
/// `MOL_INITIAL_TAB` forces the starting tab — a debug aid for launching
/// straight into a webview tab (e.g. to attach CEF DevTools to Grafana).
final class SelectedTabProvider extends $NotifierProvider<SelectedTab, int?> {
  /// Currently selected AppShell tab. Null until something picks one, letting
  /// the shell decide the initial tab (Dashboard normally, Settings on first
  /// launch). Dashboard tiles set this to jump to other tabs.
  ///
  /// `MOL_INITIAL_TAB` forces the starting tab — a debug aid for launching
  /// straight into a webview tab (e.g. to attach CEF DevTools to Grafana).
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
/// straight into a webview tab (e.g. to attach CEF DevTools to Grafana).

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
