import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Window controls for the Linux CSD shell: the GTK titlebar is a zero-height
/// widget (see linux/runner/my_application.cc), so the in-app masthead owns
/// move / close / maximize. Every call is a no-op off-desktop and in tests,
/// and swallows MissingPluginException so goldens/widget tests never trip.
class WindowChannel {
  WindowChannel._();

  static const _channel = MethodChannel('homelab/window');

  static final bool enabled =
      Platform.isLinux && !Platform.environment.containsKey('FLUTTER_TEST');

  static Future<void> _call(String method) async {
    if (!enabled) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Runner without the channel (old binary) — ignore.
    }
  }

  /// Start an interactive window move (call from a pan-start on the masthead).
  static Future<void> beginMove() => _call('move');

  static Future<void> close() => _call('close');

  static Future<void> minimize() => _call('minimize');

  static Future<void> toggleMaximize() => _call('toggleMaximize');
}
