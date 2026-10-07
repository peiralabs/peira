# Wayland, dual-deploy, and cross-platform

Status: **experiment run — Path B confirmed.** The on-device test (below) is
done: on a Wayland session the shell runs natively on the Wayland GDK backend,
and the embedded browser renders via XWayland. A pure-Wayland session with no
XWayland degrades gracefully to the "open in browser" notice. So **one binary
serves X11 and Wayland+XWayland** — no separate Wayland build is needed; the
support is a documentation matter, not a code fork. The rest of this document
is the investigation and plan that led there. Claims verified against source
are marked **[verified]**; **[verify on device]** marks the test that has now
been run.

## Outcome (2026-10-07)

Run on openSUSE + GNOME/Wayland (`WAYLAND_DISPLAY=wayland-0`, `DISPLAY=:0`):

- Double-clicking the AppImage launched the full shell natively on Wayland.
- With `DISPLAY` present, an embedded webview (peira.dev in the Wiki tab)
  rendered fully — CEF rode XWayland. **Path B.**
- With `DISPLAY` unset (`env -u DISPLAY … --ozone-platform=wayland`), the app
  correctly showed the graceful "needs an X11 surface" notice instead of
  crashing — phase-0 degradation working as designed.

Decision: ship the single AppImage, documented as supporting X11 and
Wayland-with-XWayland. True no-XWayland rendering (Path A) is not pursued —
every mainstream Wayland desktop ships XWayland, and the fallback covers the
rest.

## TL;DR

- The Flutter/GTK shell is already essentially display-server-agnostic
  **[verified]**. The only hard X11 tie is the embedded browser.
- `webview_cef` 0.5.1 renders by **software offscreen rendering (OSR)**: CEF
  paints into a CPU pixel buffer that the plugin blits into a Flutter texture —
  it is **not** an embedded X11 window **[verified]**. That makes a Wayland
  build far more plausible than the README's flat "Not supported" implies.
- The remaining unknown is whether **CEF's own initialisation** comes up under
  Ozone/Wayland in the pinned Chromium 149 build **[verify on device]**. That
  single test decides which of the two deploy paths below we ship.
- A graceful-degradation path is already in the code (this change): a
  pure-Wayland session with no XWayland shows a clear notice + "open in browser"
  instead of a blank tab or crash.

## What actually binds the app to X11

### Not the shell [verified]

`linux/runner/my_application.cc`:

- The only X11 include is `#include <gdk/gdkx.h>`, already guarded by
  `#ifdef GDK_WINDOWING_X11`.
- Window control uses `gtk_window_begin_move_drag` / `gtk_window_maximize` /
  `gtk_window_iconify` — all GTK calls that work under the Wayland GDK backend.
- GTK picks its backend at runtime (`GDK_BACKEND`), so the shell runs on Wayland
  with no code change.

One stale assumption to fix regardless (see Phase 1): the window background is
hardcoded to `#0E1810` (Brass dark green) and `gtk-application-prefer-dark-theme`
is forced `TRUE`. With selectable light themes and theme families now in the
app, that pre-first-frame flash can be the wrong colour.

### The embedded browser is the whole story

`webview_cef` 0.5.1, Linux:

- **Render path [verified].** `webview_cef_plugin.cc`:
  `onFrame(const void* buffer, w, h)` receives a CPU BGRA buffer, converts it
  (`SwapBufferFromBgraToRgba`) into a `uint8_t[]`, and marks a Flutter external
  texture frame available. This is software OSR — a pixel blit into Flutter's
  compositor. No GLX/EGL-on-X11 shared-texture handshake is in this path.
- **Keyboard mapping [verified].** `webview_cef_keyevent.h` includes
  `<X11/keysym.h>`, `<X11/XF86keysym.h>`, `<X11/Xcursor/Xcursor.h>` and maps via
  `KeyboardCodeFromXKeysym(unsigned int keysym)`. This operates on keysym
  integers; GDK keysyms share X11 keysym values (`GDK_KEY_*` == `XK_*`), so under
  Wayland GTK still delivers usable keysyms. The X11 headers supply constants and
  link `libX11`/`Xcursor`; they do not require an X11 *session* at runtime.
- **CEF init [verify on device].** `CMakeLists.txt` does `find_package(CEF)` and
  links `libcef`, `GL`, GTK3, `xi`. Chromium/CEF on Linux historically initialise
  X11 even for OSR. Whether the pinned build (CEF
  `149.0.4+g2f1bfd8+chromium-149.0.7827.156`, see
  `docs/webview-cef-notes.md`) can initialise under Ozone/Wayland is the one
  thing that cannot be settled from source — it needs a run.

## The decisive experiment [verify on device]

Build once (the first Linux build downloads CEF, a few hundred MB), then from a
**Wayland session**:

1. Baseline — shell on Wayland, CEF via XWayland:
   ```
   GDK_BACKEND=wayland ./peira
   ```
   Open a webview tab. If it renders and takes keyboard input, the shell is
   already Wayland-native and CEF is riding XWayland (DISPLAY is set).

2. CEF on Wayland (no XWayland for CEF):
   ```
   GDK_BACKEND=wayland ./peira --ozone-platform=wayland
   ```
   The runner must forward `--ozone-platform=wayland` into CEF's argv (CEF reads
   its own switches). Open a webview tab and watch for: a painted page, working
   keyboard/mouse input, and no X11 connection (`xtrace`/`WAYLAND_DEBUG=1` or
   simply unset `DISPLAY` for the run).

3. Headless sanity (optional): `--ozone-platform=headless` to confirm OSR works
   with no windowing platform at all.

The outcome of step 2 chooses the deploy path.

## Deploy paths

Both ship from **one codebase**; they differ only in launch wiring and AppImage
dependency manifest. "Separate app is fine" (your call) — but one source tree.

### Path A — CEF initialises on Wayland (best case)

A genuine Wayland-native AppImage:

- Runner forwards `--ozone-platform=wayland` to CEF when the session is Wayland;
  the shell uses the Wayland GDK backend.
- No XWayland dependency. Full functionality, same feature set as X11.
- Package as `Peira-wayland-x86_64.AppImage` alongside the existing
  `Peira-x86_64.AppImage`.

### Path B — CEF still needs X11 (fallback)

A Wayland-session AppImage where the shell is Wayland-native and CEF rides
XWayland:

- Shell on Wayland GDK backend; CEF left on its X11/Ozone default, using the
  session's XWayland (DISPLAY). This is what already works today under a Wayland
  session with XWayland — the change is to make it explicit and documented rather
  than "unsupported".
- Declare XWayland in the AppImage system-deps audit
  (`tool/appimage_system_deps.txt`).
- The graceful-degradation notice (already added) covers the pure-Wayland,
  no-XWayland case honestly.

Either way the README's compatibility table moves from "Wayland-native: Not
supported" to an accurate statement.

## Runtime support detection (landed in this change)

`lib/core/webview/display_server.dart`:

- `detectDisplayServer(env)` → `{x11, wayland, unknown}` using
  `XDG_SESSION_TYPE`, then `WAYLAND_DISPLAY`, then `DISPLAY`.
- `webviewUnavailableReason(env)` returns non-null **only** for a positively
  identified pure-Wayland session with no XWayland (`DISPLAY` unset). X11,
  Wayland+XWayland, and any unknown/headless/CI environment read as available, so
  it never gates a working build or a test pump on a false negative.
- `WebViewScreen` shows `_WebviewUnavailable` (notice + "open in your browser"
  via `xdg-open`) in that one case.

This is the seam the dual build plugs into: Path B uses it as-is; Path A will set
the reason to null for Wayland once CEF-on-Wayland is confirmed.

## Phased roadmap (resume checkpoints)

- **Phase 0 — done (this change).** Display-server detection, graceful
  degradation, unit tests. No behaviour change on X11/XWayland.
- **Phase 1 — done.** Native-runner cleanups: `--ozone-platform` reaches CEF
  via argv (documented); the pre-first-frame window background follows the
  active theme instead of the hardcoded green; the resolved GDK backend is
  logged.
- **Phase 2 — done.** Experiment run on a Wayland+XWayland desktop → **Path B**
  (see Outcome above). One binary serves X11 and Wayland+XWayland.
- **Phase 3 — not needed.** Path B is the same binary, so there is no second
  AppImage to build. `build.yml` already version- and flavor-stamps artifact
  names for clarity. The only remaining work is documentation (Phase 4).
- **Phase 4 — docs.** Update the README compatibility table (done) and, if a
  pure-Wayland caveat is worth calling out, `KNOWN_ISSUES.md`.

## Cross-platform (Windows/macOS) — longer term

The two portability pivots are already favourable:

- **Embedded browser.** `webview_cef` 0.5.1 ships `windows/` and `macos/`
  implementations as well as `linux/` **[verified]**. The webview contract
  (mask/user-script injection, `window.open` rerouting — see
  `docs/webview-cef-notes.md`) is Dart-side and platform-independent, so it
  carries over. iOS already uses a separate `IosWebViewFactory`; the factory
  seam (`webViewFactoryProvider`) is the place to branch per platform.
- **Credential storage.** `flutter_secure_storage` (a direct dependency) backs
  onto DPAPI/Credential Manager on Windows and the Keychain on macOS natively —
  no Secret Service assumption leaks above the repository layer.

Gaps to close when the time comes:

- The repo targets only `ios` and `linux` today; `flutter create --platforms
  windows,macos .` is needed to generate the runners.
- The native window-control channel (`homelab/window`, CSD masthead) is
  implemented in the GTK runner only; Windows and macOS need equivalent handlers
  (or native title bars on those platforms).
- The X11 keysym mapping is a Linux-plugin concern; the Windows/macOS
  `webview_cef` backends have their own input paths.
- `tool/build_appimage.sh` is Linux packaging; Windows/macOS need their own
  (MSIX/signed `.app` + notarisation). These are per-OS, out of scope until the
  Wayland split is settled.

The scope boundary in `MAINTENANCE.md` currently says "no Windows/macOS"; treat
this section as the pre-work for revisiting that, not a commitment.
