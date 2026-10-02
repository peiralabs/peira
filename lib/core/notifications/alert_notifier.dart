import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/grafana_alert.dart';
import '../providers/grafana_providers.dart';
import '../providers/settings_providers.dart';
import 'desktop_notifier.dart';

part 'alert_notifier.g.dart';

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
@Riverpod(keepAlive: true)
class AlertWatcher extends _$AlertWatcher {
  final _seen = <String>{};
  bool _primed = false;

  @override
  void build() {
    ref.listen(activeAlertsProvider, (_, next) {
      final alerts = next.value;
      if (alerts != null) _process(alerts);
    });
  }

  void _process(List<GrafanaAlert> alerts) {
    // Fingerprint is Alertmanager's stable id; fall back to name+start.
    String key(GrafanaAlert a) =>
        a.fingerprint ?? '${a.name}@${a.startsAt.toIso8601String()}';

    final current = {for (final a in alerts) key(a): a};

    if (!_primed) {
      _seen.addAll(current.keys);
      _primed = true;
      return;
    }

    final enabled = ref.read(settingsControllerProvider).value?.notifyAlerts;
    final fresh = [
      for (final e in current.entries)
        if (!_seen.contains(e.key) && !e.value.isSuppressed) e.value,
    ];
    _seen
      ..clear()
      ..addAll(current.keys);

    if (enabled == false) return;
    final notifier = ref.read(desktopSenderProvider);
    for (final a in fresh) {
      notifier.send(
        '${_severityMark(a.severity)} ${a.name}',
        a.annotations['summary'] ??
            a.annotations['description'] ??
            'Alert firing since ${a.startsAt.toLocal()}',
        urgency: a.severity == 'critical'
            ? NotifyUrgency.critical
            : NotifyUrgency.normal,
      );
    }
  }

  static String _severityMark(String severity) => switch (severity) {
    'critical' => '🔴',
    'warning' => '🟠',
    _ => '🔵',
  };
}
