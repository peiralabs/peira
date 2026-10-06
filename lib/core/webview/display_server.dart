import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Linux session's display server, inferred from the environment the same
/// way GTK/Ozone clients infer it.
enum DisplayServer { x11, wayland, unknown }

/// Detect the display server from [env] (defaults to the process environment).
///
/// `XDG_SESSION_TYPE` is authoritative when set. Otherwise the presence of
/// `WAYLAND_DISPLAY` wins over `DISPLAY`, because a Wayland session typically
/// also exports `DISPLAY` for its XWayland shim — so DISPLAY alone does not
/// prove an X11 session.
DisplayServer detectDisplayServer([Map<String, String>? env]) {
  final e = env ?? Platform.environment;
  switch ((e['XDG_SESSION_TYPE'] ?? '').toLowerCase()) {
    case 'wayland':
      return DisplayServer.wayland;
    case 'x11':
      return DisplayServer.x11;
  }
  if ((e['WAYLAND_DISPLAY'] ?? '').isNotEmpty) return DisplayServer.wayland;
  if ((e['DISPLAY'] ?? '').isNotEmpty) return DisplayServer.x11;
  return DisplayServer.unknown;
}

/// Whether an X11 surface is reachable — a native X11 session, or a Wayland
/// session running XWayland (which exports `DISPLAY`). The embedded CEF
/// browser (webview_cef 0.5.1) needs one.
bool hasX11Surface([Map<String, String>? env]) =>
    ((env ?? Platform.environment)['DISPLAY'] ?? '').isNotEmpty;

/// Why the embedded web views cannot render, or null when they can.
enum WebviewUnavailableReason {
  /// A pure-Wayland session with no XWayland: CEF has no X11 surface to use.
  noXSurface,
}

/// Decide whether the embedded CEF web views can come up in this session.
///
/// Deliberately conservative: it only reports unavailable for a *positively
/// identified* pure-Wayland session with no XWayland fallback. An X11 session,
/// a Wayland session with XWayland, and any unknown/headless environment (CI,
/// `flutter test`) all read as available, so this never gates a working build
/// or a test pump on a false negative.
WebviewUnavailableReason? webviewUnavailableReason([Map<String, String>? env]) {
  if (!Platform.isLinux) return null;
  final server = detectDisplayServer(env);
  if (server == DisplayServer.wayland && !hasX11Surface(env)) {
    return WebviewUnavailableReason.noXSurface;
  }
  return null;
}

/// Process-wide webview availability. Overridable in tests; defaults to the
/// environment-derived [webviewUnavailableReason].
final webviewSupportProvider = Provider<WebviewUnavailableReason?>(
  (ref) => webviewUnavailableReason(),
);
