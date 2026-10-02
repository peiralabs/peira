import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/models/grafana_alert.dart';
import 'package:peira/core/notifications/alert_notifier.dart';
import 'package:peira/core/notifications/desktop_notifier.dart';
import 'package:peira/core/providers/grafana_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);
  AppSettings _settings;
  @override
  Future<AppSettings> load() async => _settings;
  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

class _CapturingNotifier implements DesktopNotifier {
  final sent = <String>[];
  @override
  Future<void> send(
    String title,
    String body, {
    NotifyUrgency urgency = NotifyUrgency.normal,
  }) async {
    sent.add(title);
  }
}

GrafanaAlert _alert(String fp, {String severity = 'critical'}) => GrafanaAlert(
  labels: {'alertname': fp, 'severity': severity},
  startsAt: DateTime(2026),
  fingerprint: fp,
);

void main() {
  ProviderContainer makeContainer({
    required List<GrafanaAlert> alerts,
    required _CapturingNotifier notifier,
    bool notifyAlerts = true,
  }) {
    return ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(
            AppSettings(
              proxmoxUrl: 'https://x',
              proxmoxTokenId: 'a',
              proxmoxTokenSecret: 'b',
              notifyAlerts: notifyAlerts,
            ),
          ),
        ),
        activeAlertsProvider.overrideWith((ref) async => alerts),
        desktopSenderProvider.overrideWithValue(notifier),
      ],
    );
  }

  test('first load primes without notifying; later alerts notify', () async {
    final alerts = [_alert('cpu')];
    final notifier = _CapturingNotifier();
    final c = makeContainer(alerts: alerts, notifier: notifier);
    addTearDown(c.dispose);
    // Ensure settings are loaded so the watcher can read notifyAlerts.
    await c.read(settingsControllerProvider.future);
    c.read(alertWatcherProvider);

    await c.read(activeAlertsProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.sent, isEmpty, reason: 'startup alert should be primed');

    // A new alert appears on the next refresh.
    alerts.add(_alert('disk'));
    c.invalidate(activeAlertsProvider);
    await c.read(activeAlertsProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.sent, hasLength(1));
    expect(notifier.sent.single, contains('disk'));
  });

  test('honours the notifyAlerts=false gate', () async {
    final alerts = <GrafanaAlert>[];
    final notifier = _CapturingNotifier();
    final c = makeContainer(
      alerts: alerts,
      notifier: notifier,
      notifyAlerts: false,
    );
    addTearDown(c.dispose);
    await c.read(settingsControllerProvider.future);
    c.read(alertWatcherProvider);
    await c.read(activeAlertsProvider.future);
    await Future<void>.delayed(Duration.zero);

    alerts.add(_alert('mem'));
    c.invalidate(activeAlertsProvider);
    await c.read(activeAlertsProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.sent, isEmpty);
  });
}
