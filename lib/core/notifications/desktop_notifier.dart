import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../build_config.dart';

part 'desktop_notifier.g.dart';

/// Urgency maps to `notify-send --urgency`.
enum NotifyUrgency { low, normal, critical }

/// Sends a desktop notification. The default implementation shells out to
/// `notify-send` (present on essentially every Linux desktop), so no native
/// notification plugin is added to the fragile CEF build. Tests and iOS get a
/// no-op override.
abstract class DesktopNotifier {
  Future<void> send(
    String title,
    String body, {
    NotifyUrgency urgency = NotifyUrgency.normal,
  });
}

class NotifySendNotifier implements DesktopNotifier {
  const NotifySendNotifier();

  @override
  Future<void> send(
    String title,
    String body, {
    NotifyUrgency urgency = NotifyUrgency.normal,
  }) async {
    if (!Platform.isLinux) return;
    try {
      await Process.run('notify-send', [
        '--app-name=$kAppName',
        '--urgency=${urgency.name}',
        title,
        body,
      ]);
    } on ProcessException {
      // notify-send absent (headless / minimal desktop) — silently skip.
    }
  }
}

class _NoopNotifier implements DesktopNotifier {
  const _NoopNotifier();
  @override
  Future<void> send(
    String title,
    String body, {
    NotifyUrgency urgency = NotifyUrgency.normal,
  }) async {}
}

@riverpod
DesktopNotifier desktopSender(Ref ref) {
  // Non-Linux (iOS) has no notify-send equivalent wired up yet.
  return Platform.isLinux ? const NotifySendNotifier() : const _NoopNotifier();
}
