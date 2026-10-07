/// Persists the active theme's base background colour so the native Linux
/// runner can paint the window that colour *before* Flutter's first frame —
/// otherwise a non-default theme flashes the Brass green on launch.
///
/// Written to `$XDG_CONFIG_HOME/peira/window_background` (falling back to
/// `~/.config/...`) as a `#RRGGBB` string; read by
/// `linux/runner/my_application.cc` at window creation. The value is only
/// available on the *next* launch, which is exactly what a pre-first-frame
/// paint needs. Best-effort and Linux-only — any failure is swallowed, since
/// this is cosmetic and must never affect the running app.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';

String? _lastHex;

void persistWindowBackground(Color bg) {
  if (!Platform.isLinux) return;
  final hex = _hex(bg);
  // In-memory guard: the app rebuilds often but the theme rarely changes, so
  // skip the disk entirely when the colour is unchanged this session.
  if (hex == _lastHex) return;
  _lastHex = hex;
  try {
    final home = Platform.environment['HOME'];
    final base = Platform.environment['XDG_CONFIG_HOME'] ??
        (home == null ? null : '$home${Platform.pathSeparator}.config');
    if (base == null) return;
    final sep = Platform.pathSeparator;
    final file = File('$base${sep}peira${sep}window_background');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(hex);
  } catch (_) {
    // Cosmetic only.
  }
}

String _hex(Color c) {
  String h(double v) =>
      (v * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${h(c.r)}${h(c.g)}${h(c.b)}';
}
