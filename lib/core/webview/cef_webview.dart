import 'package:flutter/material.dart';
import 'package:webview_cef/webview_cef.dart';

import 'browser_chrome.dart';
import 'webview_factory.dart';

/// Desktop (Linux) web views backed by CEF. Requires the initCEFProcesses /
/// processKeyEventForCEF hooks in linux/runner.
class CefWebViewFactory implements WebViewFactory {
  @override
  Widget build(
    String url, {
    String? maskScript,
    bool controls = false,
    String? controlsLabel,
  }) =>
      CefWebView(
        url: url,
        maskScript: maskScript,
        controls: controls,
        controlsLabel: controlsLabel,
      );
}

/// webview_cef 0.5.1 never wires up CEF's OnBeforePopup, so links that open a
/// new window (`target="_blank"` or `window.open()`) silently do nothing —
/// e.g. Grafana's dashboard links. This script routes those back into the
/// current view. The capturing click listener persists for the document
/// lifetime, so it also covers links a SPA (Grafana, Wiki) adds after load.
/// CEF off-screen rendering delivers a native `<select>` dropdown as a
/// separate PET_POPUP paint layer, but webview_cef 0.5.1 neither implements
/// OnPopupShow/OnPopupSize nor checks the paint element type — the small popup
/// bitmap is pushed through the full-view paint callback, stretching the
/// dropdown across the entire widget with unclickable, giant text. Rather than
/// patch the plugin's C++ (lost on every pub-cache refresh, and popup
/// compositing is invasive), suppress the native popup entirely and render an
/// in-page dropdown in the normal view layer, styled to match the app.
const _selectShimJs = r'''
(function () {
  try {
    if (window.__molSelectShim) return;
    window.__molSelectShim = true;
    var menu = null;
    function closeMenu() {
      if (menu) { menu.remove(); menu = null; }
    }
    function commit(sel, opt) {
      // Set through the prototype setter + fire input/change so React/Vue
      // controlled selects observe the change like a native one.
      var setter = Object.getOwnPropertyDescriptor(
          HTMLSelectElement.prototype, 'value').set;
      setter.call(sel, opt.value);
      sel.dispatchEvent(new Event('input', { bubbles: true }));
      sel.dispatchEvent(new Event('change', { bubbles: true }));
    }
    function openMenu(sel) {
      closeMenu();
      var r = sel.getBoundingClientRect();
      var font = window.getComputedStyle(sel);
      menu = document.createElement('div');
      menu.id = '__mol_select_menu';
      menu.style.cssText =
        'position:fixed;z-index:2147483647;left:' + r.left + 'px;' +
        'min-width:' + r.width + 'px;max-width:90vw;max-height:45vh;' +
        'overflow-y:auto;background:#1E2C1F;color:#E4DCC8;' +
        'border:1px solid rgba(212,169,79,.35);border-radius:10px;' +
        'box-shadow:0 10px 30px rgba(0,0,0,.55);padding:4px;' +
        'font:' + font.fontSize + '/1.5 ' + font.fontFamily + ';';
      for (var i = 0; i < sel.options.length; i++) {
        (function (opt, idx) {
          var row = document.createElement('div');
          row.textContent = opt.textContent;
          row.style.cssText =
            'padding:6px 12px;border-radius:6px;cursor:pointer;' +
            'white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' +
            (opt.disabled ? 'opacity:.4;cursor:default;' : '') +
            (idx === sel.selectedIndex ? 'color:#D4A94F;' : '');
          if (!opt.disabled) {
            row.onmouseenter = function () {
              row.style.background = 'rgba(212,169,79,.12)';
            };
            row.onmouseleave = function () { row.style.background = ''; };
            row.addEventListener('mousedown', function (e) {
              e.preventDefault();
              e.stopPropagation();
              commit(sel, opt);
              closeMenu();
            }, true);
          }
          menu.appendChild(row);
        })(sel.options[i], i);
      }
      document.body.appendChild(menu);
      // Below the select by default; flip above if it would overflow.
      var mh = menu.offsetHeight;
      var top = r.bottom + 4;
      if (top + mh > window.innerHeight - 8) {
        top = Math.max(8, r.top - mh - 4);
      }
      menu.style.top = top + 'px';
      var mw = menu.offsetWidth;
      if (r.left + mw > window.innerWidth - 8) {
        menu.style.left = Math.max(8, window.innerWidth - 8 - mw) + 'px';
      }
    }
    document.addEventListener('mousedown', function (e) {
      if (menu && !menu.contains(e.target)) closeMenu();
      var sel = e.target && e.target.closest && e.target.closest('select');
      // Only single selects popup (multiple/size>1 render inline listboxes).
      if (sel && !sel.disabled && !sel.multiple && sel.size <= 1) {
        e.preventDefault();
        sel.focus();
        openMenu(sel);
      }
    }, true);
    document.addEventListener('keydown', function (e) {
      if (menu && e.key === 'Escape') {
        e.preventDefault();
        closeMenu();
        return;
      }
      var t = document.activeElement;
      if (t && t.tagName === 'SELECT' && !t.multiple && t.size <= 1 &&
          (e.key === ' ' || e.key === 'Enter' ||
           (e.altKey && (e.key === 'ArrowDown' || e.key === 'ArrowUp')))) {
        e.preventDefault();
        if (menu) { closeMenu(); } else { openMenu(t); }
      }
    }, true);
    window.addEventListener('scroll', closeMenu, true);
    window.addEventListener('resize', closeMenu);
  } catch (_) {}
})();
''';

InjectUserScripts _baseScripts() {
  const js = '''
(function () {
  try {
    window.open = function (url) {
      if (url) { window.location.assign(url); }
      return window;
    };
    document.addEventListener('click', function (e) {
      var el = e.target;
      while (el && el.tagName !== 'A') { el = el.parentElement; }
      if (el && el.target && el.target !== '_self') {
        el.removeAttribute('target');
      }
    }, true);
  } catch (_) {}
})();
''';
  return InjectUserScripts()
    ..add(UserScript(js, ScriptInjectTime.LOAD_START))
    ..add(UserScript(js, ScriptInjectTime.LOAD_END))
    // Both times: LOAD_START so early interaction is safe, LOAD_END as a
    // fallback; the shim's window flag makes the second run a no-op.
    ..add(UserScript(_selectShimJs, ScriptInjectTime.LOAD_START))
    ..add(UserScript(_selectShimJs, ScriptInjectTime.LOAD_END));
}

/// Swaps the mask entries inside a live [InjectUserScripts]. WebviewManager
/// keeps the same instance per browser and re-reads it on every load, so
/// mutating the list here re-masks all future navigations — this is how a
/// brightness flip reaches pages the user loads later. [current] is the set of
/// entries a previous call added (removed by identity); returns the new set to
/// track. [mask] runs at both times: LOAD_START avoids a flash of the
/// un-masked page, LOAD_END re-runs it once the DOM is ready.
@visibleForTesting
List<UserScript> replaceMaskScripts(
  InjectUserScripts scripts,
  List<UserScript> current,
  String? mask,
) {
  scripts.userScripts.removeWhere(current.contains);
  if (mask == null) return const [];
  final next = [
    UserScript(mask, ScriptInjectTime.LOAD_START),
    UserScript(mask, ScriptInjectTime.LOAD_END),
  ];
  scripts.userScripts.addAll(next);
  return next;
}

class CefWebView extends StatefulWidget {
  const CefWebView({
    super.key,
    required this.url,
    this.maskScript,
    this.controls = false,
    this.controlsLabel,
  });

  final String url;
  final String? maskScript;

  /// Show the brass browser-chrome bar above the page.
  final bool controls;

  /// Chrome-bar pill text (e.g. `Embedded · Wiki.js`).
  final String? controlsLabel;

  @override
  State<CefWebView> createState() => _CefWebViewState();
}

class _CefWebViewState extends State<CefWebView> {
  // WebviewManager().initialize() must run exactly once per app.
  static Future<void>? _managerReady;

  late final WebViewController _controller;
  late final ValueNotifier<String> _url = ValueNotifier(widget.url);
  late final InjectUserScripts _userScripts;
  List<UserScript> _maskScripts = const [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _userScripts = _baseScripts();
    _maskScripts = replaceMaskScripts(_userScripts, _maskScripts, widget.maskScript);
    // A non-null injectUserScripts is also required to sidestep a webview_cef
    // 0.5.1 bug: createWebView stores it into a map whose runtime value type is
    // non-nullable (`<int, InjectUserScripts>{}`), so passing null throws
    // "Null is not a subtype of InjectUserScripts".
    _controller = WebviewManager().createWebView(
      loading: const Center(child: CircularProgressIndicator()),
      injectUserScripts: _userScripts,
    );
    // Live address readout for the chrome bar (webview_cef 0.5.1 dispatches
    // urlChanged/titleChanged events per browser id to this listener).
    _controller.setWebviewListener(WebviewEventsListener(
      onUrlChanged: (url) {
        if (mounted) _url.value = url;
      },
    ));
    _init();
  }

  Future<void> _init() async {
    try {
      await (_managerReady ??= WebviewManager().initialize());
      await _controller.initialize(widget.url);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void didUpdateWidget(CefWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maskScript == oldWidget.maskScript) return;
    // A brightness flip rebuilt us with a new mask. Swap the load-time user
    // scripts (covers future navigations) and re-run the mask in the page
    // that's already up — WebMasks scripts replace their prior style node,
    // observer, and poller, so re-running is a clean palette swap.
    _maskScripts = replaceMaskScripts(_userScripts, _maskScripts, widget.maskScript);
    final mask = widget.maskScript;
    if (mask != null && _controller.value) {
      _controller.executeJavaScript(mask);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Web view failed to start:\n$_error'));
    }
    final page = ValueListenableBuilder<bool>(
      valueListenable: _controller,
      builder: (_, ready, _) =>
          ready ? _controller.webviewWidget : _controller.loadingWidget,
    );
    if (!widget.controls) return page;
    // CEF has no reliable canGoBack signal in 0.5.1, so the nav buttons are
    // always enabled; goBack/goForward are no-ops at the ends.
    return Column(
      children: [
        BrowserChromeBar(
          url: _url,
          pillLabel: widget.controlsLabel ?? 'Embedded',
          onBack: _controller.goBack,
          onForward: _controller.goForward,
          onReload: _controller.reload,
          onHome: () => _controller.loadUrl(widget.url),
        ),
        Expanded(child: page),
      ],
    );
  }
}
