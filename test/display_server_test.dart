import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/webview/display_server.dart';

void main() {
  group('detectDisplayServer', () {
    test('XDG_SESSION_TYPE is authoritative', () {
      expect(
        detectDisplayServer({'XDG_SESSION_TYPE': 'wayland', 'DISPLAY': ':0'}),
        DisplayServer.wayland,
      );
      expect(
        detectDisplayServer({
          'XDG_SESSION_TYPE': 'x11',
          'WAYLAND_DISPLAY': 'wayland-0',
        }),
        DisplayServer.x11,
      );
    });

    test('WAYLAND_DISPLAY wins over DISPLAY when session type is unset', () {
      expect(
        detectDisplayServer({'WAYLAND_DISPLAY': 'wayland-0', 'DISPLAY': ':0'}),
        DisplayServer.wayland,
      );
    });

    test('DISPLAY alone reads as x11', () {
      expect(detectDisplayServer({'DISPLAY': ':0'}), DisplayServer.x11);
    });

    test('empty environment is unknown', () {
      expect(detectDisplayServer({}), DisplayServer.unknown);
    });
  });

  group('hasX11Surface', () {
    test('true when DISPLAY is set (native X11 or XWayland)', () {
      expect(hasX11Surface({'DISPLAY': ':0'}), isTrue);
    });
    test('false when DISPLAY is absent or empty', () {
      expect(hasX11Surface({}), isFalse);
      expect(hasX11Surface({'DISPLAY': ''}), isFalse);
    });
  });

  group('webviewUnavailableReason', () {
    // These assertions only hold on Linux; the function short-circuits to null
    // on other platforms.
    test('pure Wayland without XWayland is unavailable', () {
      final reason = webviewUnavailableReason({
        'XDG_SESSION_TYPE': 'wayland',
      });
      expect(
        reason,
        Platform.isLinux ? WebviewUnavailableReason.noXSurface : isNull,
      );
    });

    test('Wayland WITH XWayland (DISPLAY set) is available', () {
      expect(
        webviewUnavailableReason({
          'XDG_SESSION_TYPE': 'wayland',
          'DISPLAY': ':0',
        }),
        isNull,
      );
    });

    test('X11 session is available', () {
      expect(
        webviewUnavailableReason({'XDG_SESSION_TYPE': 'x11', 'DISPLAY': ':0'}),
        isNull,
      );
    });

    test('unknown/headless environment is available (never a false gate)', () {
      expect(webviewUnavailableReason({}), isNull);
    });
  });
}
