import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/webview/web_logins.dart';

// The autofill script isn't executed in tests (no webview), so it's verified
// at the seams: credentials round-trip through the settings blob, the built
// script carries the marker + safely-escaped values, and the no-credential /
// no-submit paths behave.
void main() {
  group('AppSettings.webLogins', () {
    test('round-trips a stored login through the JSON blob', () {
      final s = const AppSettings().withWebLogin(
        'Karakeep',
        (username: 'user', password: 'p@ss"w`ord'),
      );
      expect(s.webLoginsJson, isNotEmpty);
      final login = s.webLoginFor('Karakeep');
      expect(login?.username, 'user');
      expect(login?.password, 'p@ss"w`ord');
    });

    test('blank credentials remove the entry', () {
      var s = const AppSettings().withWebLogin(
        'Immich',
        (username: 'a', password: 'b'),
      );
      expect(s.webLoginFor('Immich'), isNotNull);
      s = s.withWebLogin('Immich', (username: '', password: ''));
      expect(s.webLoginFor('Immich'), isNull);
      expect(s.webLoginsJson, isEmpty);
    });

    test('malformed JSON degrades to no logins', () {
      const s = AppSettings(webLoginsJson: 'not json');
      expect(s.webLogins, isEmpty);
    });

    test('an entry with no password is skipped', () {
      const s = AppSettings(webLoginsJson: '{"Karakeep":{"u":"x","p":""}}');
      expect(s.webLoginFor('Karakeep'), isNull);
    });
  });

  group('WebLogins.scriptFor', () {
    test('null when no credential is stored', () {
      expect(
        WebLogins.scriptFor('Karakeep', login: null, autoSubmit: true),
        isNull,
      );
      expect(
        WebLogins.scriptFor(
          'Karakeep',
          login: (username: 'x', password: ''),
          autoSubmit: true,
        ),
        isNull,
      );
    });

    test('carries the marker, escaped values, and submit mode', () {
      final script = WebLogins.scriptFor(
        'Jellyseerr',
        login: (username: 'user', password: r'a"b\c'),
        autoSubmit: false,
      )!;
      expect(script, contains('__MOL_LOGIN__ Jellyseerr submit=false'));
      // jsonEncode escapes the quote + backslash into a valid JS literal.
      expect(script, contains(r'"a\"b\\c"'));
      expect(script, contains('AUTOSUBMIT = false'));
    });

    test('Home Assistant is offered and pierces shadow DOM', () {
      expect(WebLogins.services, contains('Home Assistant'));
      final script = WebLogins.scriptFor(
        'Home Assistant',
        login: (username: 'admin', password: 'pw'),
        autoSubmit: true,
      )!;
      // HA nests its login inputs in shadow roots — the script must recurse.
      expect(script, contains('shadowRoot'));
      expect(script, contains('deepQueryAll'));
    });

    test('auto-submit path is session-capped', () {
      final script = WebLogins.scriptFor(
        'Paperless',
        login: (username: 'u', password: 'p'),
        autoSubmit: true,
      )!;
      expect(script, contains('sessionStorage'));
      expect(script, contains('submit=true'));
    });
  });
}
