// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches [activeAlertsProvider] and fires a desktop notification the first
/// time each alert appears, so the app surfaces problems while running in the
/// background instead of only when the operator opens it.
///
/// The first successful load "primes" the seen-set without notifying — so
/// launching the app doesn't dump a toast for every already-firing alert;
/// only alerts that start *after* launch notify. Gated on
/// [AppSettings.notifyAlerts].
///
/// Kept alive by [AppShell] watching it once; it does no rendering.

@ProviderFor(AlertWatcher)
final alertWatcherProvider = AlertWatcherProvider._();

/// Watches [activeAlertsProvider] and fires a desktop notification the first
/// time each alert appears, so the app surfaces problems while running in the
/// background instead of only when the operator opens it.
///
/// The first successful load "primes" the seen-set without notifying — so
/// launching the app doesn't dump a toast for every already-firing alert;
/// only alerts that start *after* launch notify. Gated on
/// [AppSettings.notifyAlerts].
///
/// Kept alive by [AppShell] watching it once; it does no rendering.
final class AlertWatcherProvider extends $NotifierProvider<AlertWatcher, void> {
  /// Watches [activeAlertsProvider] and fires a desktop notification the first
  /// time each alert appears, so the app surfaces problems while running in the
  /// background instead of only when the operator opens it.
  ///
  /// The first successful load "primes" the seen-set without notifying — so
  /// launching the app doesn't dump a toast for every already-firing alert;
  /// only alerts that start *after* launch notify. Gated on
  /// [AppSettings.notifyAlerts].
  ///
  /// Kept alive by [AppShell] watching it once; it does no rendering.
  AlertWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertWatcherHash();

  @$internal
  @override
  AlertWatcher create() => AlertWatcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$alertWatcherHash() => r'adb2fb65688a5f494e7dda66c7e3a192afe26247';

/// Watches [activeAlertsProvider] and fires a desktop notification the first
/// time each alert appears, so the app surfaces problems while running in the
/// background instead of only when the operator opens it.
///
/// The first successful load "primes" the seen-set without notifying — so
/// launching the app doesn't dump a toast for every already-firing alert;
/// only alerts that start *after* launch notify. Gated on
/// [AppSettings.notifyAlerts].
///
/// Kept alive by [AppShell] watching it once; it does no rendering.

abstract class _$AlertWatcher extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
