import 'dart:convert';

import '../models/app_settings.dart';

/// Generates the autofill/auto-login JavaScript injected into an embedded
/// service webview so the operator isn't re-typing the service's own login
/// each session.
///
/// The script is deliberately service-agnostic: rather than per-service DOM
/// selectors (which drift with every upstream release), it locates the first
/// visible `input[type=password]` and the nearest preceding username-ish
/// field, fills them the way React/Vue require (native value setter + input/
/// change events), and — when [WebLogin] auto-submit is on — submits once.
///
/// Safety properties (this string is injected on every page load AND re-run
/// into live pages when the theme flips, so it must be idempotent):
///   * Fills only empty fields, and backs off once the password box holds
///     anything but the saved password, so it never clobbers typing.
///   * SPA login forms render after load, so it watches the DOM briefly with
///     a MutationObserver and gives up after a few seconds.
///   * Auto-submit is capped at ONE attempt per browser session per URL via
///     `sessionStorage`, so a wrong password can't spin a submit → reload →
///     submit lockout loop.
class WebLogins {
  WebLogins._();

  /// The embedded services that carry their own login form and can be
  /// autofilled. Keyed by the service label the webview screen dispatches on.
  /// changedetection.io is password-only (no username field).
  static const services = <String>[
    'Open WebUI',
    'Jellyseerr',
    'Karakeep',
    'Paperless',
    'Immich',
    'Home Assistant',
    'changedetection.io',
  ];

  /// The autofill script for [service] given its stored [login], or null when
  /// no usable credential is stored. [autoSubmit] mirrors
  /// [AppSettings.webAutoLogin].
  static String? scriptFor(
    String service, {
    required WebLogin? login,
    required bool autoSubmit,
  }) {
    if (login == null || login.password.isEmpty) return null;
    // jsonEncode yields a valid, fully-escaped JS string literal — the safe
    // way to carry an arbitrary password (quotes, backslashes, `$`, backticks)
    // into the page.
    final u = jsonEncode(login.username);
    final p = jsonEncode(login.password);
    final submit = autoSubmit ? 'true' : 'false';
    // Marker in a comment so tests can assert which service/mode was built
    // without depending on the (opaque) escaped credential.
    return '''
/* __MOL_LOGIN__ $service submit=$submit */
(function () {
  var USER = $u, PASS = $p, AUTOSUBMIT = $submit;
  var KEY = '__molLoginTried:' + location.pathname;

  // Deep query that descends into open shadow roots — Home Assistant (and any
  // web-component login form) nests its <input> elements inside shadow DOM
  // where a plain querySelector can't reach them.
  function deepQueryAll(selector) {
    var out = [];
    function walk(root) {
      try { out.push.apply(out, root.querySelectorAll(selector)); } catch (e) {}
      var all = root.querySelectorAll('*');
      for (var i = 0; i < all.length; i++) {
        if (all[i].shadowRoot) walk(all[i].shadowRoot);
      }
    }
    walk(document);
    return out;
  }

  function setValue(el, value) {
    var proto = el.tagName === 'TEXTAREA'
      ? window.HTMLTextAreaElement.prototype
      : window.HTMLInputElement.prototype;
    var setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
    setter.call(el, value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }

  function visible(el) {
    return !!(el && (el.offsetWidth || el.offsetHeight || el.getClientRects().length));
  }

  function firstVisible(list) {
    for (var i = 0; i < list.length; i++) if (visible(list[i])) return list[i];
    return null;
  }

  // A password box is not always type=password: Seerr renders a type=text
  // input masked with CSS, so match on the name/autocomplete hints too.
  var PASSWORD_SELECTOR =
    'input[type="password"], input[autocomplete="current-password"], input[name*="pass" i]';

  function passwordField() {
    return firstVisible(deepQueryAll(PASSWORD_SELECTOR));
  }

  function usernameField(pw) {
    // Prefer explicit username/email inputs; otherwise the first visible plain
    // text input (document + shadow DOM order).
    function notPw(list) {
      return list.filter(function (el) { return el !== pw; });
    }
    var explicit = firstVisible(notPw(deepQueryAll(
      'input[autocomplete="username"], input[type="email"], input[name*="user" i], input[name*="email" i]')));
    if (explicit) return explicit;
    return firstVisible(notPw(deepQueryAll('input[type="text"], input:not([type])')));
  }

  // Fills our saved values into whatever is still empty. Returns null when
  // there is no password box yet, 'operator' when someone typed a different
  // password (never touch it), otherwise the fields.
  function fillFields() {
    var pw = passwordField();
    if (!pw) return null;
    if (pw.value && pw.value !== PASS) return 'operator';
    var user = USER ? usernameField(pw) : null;
    if (user && !user.value) setValue(user, USER);
    if (!pw.value) setValue(pw, PASS);
    return { pw: pw, user: user };
  }

  function fill() {
    var r = fillFields();
    if (!r) return false;
    if (r === 'operator') return true;
    // Server-rendered SPAs (Seerr/Next.js) show the form before their
    // framework starts; its first render resets the fields to its own empty
    // state. Re-check for a few seconds and put our values back.
    [400, 1000, 2000, 3500].forEach(function (ms) { setTimeout(fillFields, ms); });

    if (AUTOSUBMIT) {
      try {
        if (sessionStorage.getItem(KEY)) return true; // already tried once
        sessionStorage.setItem(KEY, '1');
      } catch (e) { /* private mode — skip the guard, still cap below */ }
      // Submit once, after the framework has had time to start, and only if
      // both fields still hold our values (an empty submit only earns an
      // error and burns the one attempt).
      setTimeout(function () {
        var s = fillFields();
        if (!s || s === 'operator') return;
        if (USER && s.user && !s.user.value) return;
        var btn = firstVisible(deepQueryAll(
          'button[type="submit"], input[type="submit"], mwc-button, ha-progress-button, form button'));
        var form = s.pw.form;
        setTimeout(function () {
          if (btn) { btn.click(); }
          else if (form) { form.requestSubmit ? form.requestSubmit() : form.submit(); }
        }, 150);
      }, 1200);
    }
    return true;
  }

  if (fill()) return;
  // SPA: the form mounts after load. Watch briefly, then give up.
  var obs = new MutationObserver(function () { if (fill()) done(); });
  obs.observe(document.documentElement, { childList: true, subtree: true });
  function done() { obs.disconnect(); clearTimeout(t); }
  var t = setTimeout(done, 8000);
})();
''';
  }
}
