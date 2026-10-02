# webview_cef pin and workarounds

`webview_cef` is pinned **exactly** in pubspec.yaml (currently `0.5.1`,
which itself pins CEF `149.0.4+g2f1bfd8+chromium-149.0.7827.156` in
`third/download.cmake`). A `pub upgrade` would silently move the embedded
Chromium and invalidate the verification below — bump the pin deliberately
and re-run this checklist.

## App-side workarounds verified against 0.5.1

1. **Non-null `injectUserScripts` on `createWebView`** (`cef_webview.dart`).
   The plugin stores the argument into a map built from a non-nullable
   literal; passing the default `null` throws
   `type 'Null' is not a subtype of type 'InjectUserScripts'` the moment any
   webview opens. We always pass an (empty) instance.
2. **`window.open` / `target=_blank` rerouting user script**
   (`cef_webview.dart` mask plumbing). The plugin never wires CEF's
   `OnBeforePopup`, so popup navigations silently do nothing. An injected
   user script rewrites `window.open` to `location.assign` and strips
   `target` attributes on click (capturing listener, covers SPA-added
   links).

## On every version bump

- Re-test both workarounds (open a Grafana dashboard link; open any webview
  tab and confirm no type error on creation).
- Re-check the mask replace-on-re-run seams (`test/web_masks_test.dart`
  documents the contract; the manager must still re-read the same
  `InjectUserScripts` instance per browser for live mask swapping).
- The CI CEF cache key reads `CEF_VERSION` from the package's
  `third/download.cmake` at run time, so it follows the bump automatically.
- CEF ships Chromium's FFmpeg — see THIRD_PARTY_NOTICES for the licensing
  position; confirm the new CEF build is still the standard (non-proprietary
  codec) distribution.
