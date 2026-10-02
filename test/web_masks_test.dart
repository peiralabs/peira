import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/webview/cef_webview.dart';
import 'package:peira/core/webview/web_masks.dart';
import 'package:webview_cef/webview_cef.dart';

// Webviews don't render in tests, so the live-re-injection path is verified
// at the seams: the script text must have replace (not append/skip) semantics,
// and the CEF user-script swap must mutate the manager-held list in place.
void main() {
  group('WebMasks.scriptFor', () {
    test('resolves a distinct palette per brightness', () {
      for (final service in ['Wiki', 'Open WebUI', 'Jellyseerr']) {
        final dark = WebMasks.scriptFor(service, isDark: true)!;
        final light = WebMasks.scriptFor(service, isDark: false)!;
        expect(dark, isNot(equals(light)));
        expect(dark, contains('color-scheme: dark'));
        expect(light, contains('color-scheme: light'));
      }
      expect(WebMasks.scriptFor('Grafana', isDark: true), isNull);
    });

    test('re-running replaces the injected style node content', () {
      // The injector must overwrite #__mol_mask unconditionally — an
      // only-if-absent guard would make a live brightness flip a no-op
      // (the creation-time palette would win forever).
      final script = WebMasks.scriptFor('Wiki', isDark: true)!;
      expect(script, contains("getElementById('__mol_mask')"));
      expect(script, contains('s.textContent ='));
      expect(
        script,
        isNot(contains("if (!document.getElementById('__mol_mask'))")),
      );
    });

    test('Wiki mask is gated on the Vuetify root — no-op on other wikis', () {
      // The selectors are Wiki.js v2 (Vuetify) specific; on BookStack/Outline/
      // Confluence they would half-apply. The whole mask (style node, theme
      // poller, brass observer) must sit inside the DOM-detection gate, and a
      // superseded gate's poller must stop on re-injection.
      final script = WebMasks.scriptFor('Wiki', isDark: true)!;
      final gate = script.indexOf("document.querySelector('.v-application')");
      expect(gate, greaterThanOrEqualTo(0));
      expect(script.indexOf("getElementById('__mol_mask')"), greaterThan(gate));
      expect(script.indexOf('__molThemeGen'), greaterThan(gate));
      expect(script.indexOf('__molBrassMo'), greaterThan(gate));
      expect(script, contains('if (gen !== window.__molWikiGateGen) return;'));
      // The generic base-only services stay ungated.
      expect(WebMasks.scriptFor('Open WebUI', isDark: true),
          isNot(contains('__molWikiGateGen')));
    });

    test('Wiki script replaces its observer and theme poller on re-run', () {
      final script = WebMasks.scriptFor('Wiki', isDark: false)!;
      // The previous injection's MutationObserver closed over its own palette
      // and would keep re-painting it; and a superseded vuetify-theme poll
      // must stop instead of racing its stale value in.
      expect(script, contains('window.__molBrassMo.disconnect()'));
      expect(script, contains('window.__molBrassMo = mo'));
      expect(script, contains('if (gen !== window.__molThemeGen) return;'));
    });
  });

  group('replaceMaskScripts', () {
    test('swaps mask entries in place, preserving base scripts', () {
      final scripts = InjectUserScripts()
        ..add(UserScript('base', ScriptInjectTime.LOAD_START));

      var tracked = replaceMaskScripts(scripts, const [], 'dark-mask');
      expect(
        scripts.retrieveLoadStartInjectScripts().map((s) => s.script),
        ['base', 'dark-mask'],
      );
      expect(
        scripts.retrieveLoadEndInjectScripts().map((s) => s.script),
        ['dark-mask'],
      );

      // Flip: the old entries go, the base scripts stay untouched.
      tracked = replaceMaskScripts(scripts, tracked, 'light-mask');
      expect(
        scripts.retrieveLoadStartInjectScripts().map((s) => s.script),
        ['base', 'light-mask'],
      );
      expect(
        scripts.retrieveLoadEndInjectScripts().map((s) => s.script),
        ['light-mask'],
      );

      tracked = replaceMaskScripts(scripts, tracked, null);
      expect(tracked, isEmpty);
      expect(scripts.userScripts.map((s) => s.script), ['base']);
    });
  });
}
