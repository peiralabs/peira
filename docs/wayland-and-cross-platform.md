# Wayland and cross-platform

Status (2026-10-28): **one binary runs on X11 and on Wayland, with or
without XWayland.** The app is a Flutter GTK 3 window and nothing else; it
uses GDK's Wayland backend natively on a Wayland session.

This used to be more involved. Until 2026-10-28 several tabs embedded
service web UIs through CEF (Chromium Embedded Framework, via
`webview_cef`), which renders through X11, so Wayland sessions needed
XWayland and a pure-Wayland session fell back to an "open in browser"
notice. Every service tab is now native over the service's own API and
opens the system browser for anything the API cannot do, so CEF, its
X11 requirement, its user-namespace sandbox requirement and its ~300 MB
download are gone. The CEF-era investigation (render path, Ozone, the
2026-10-07 on-device test) is in this file's git history.

## What the AppImage needs from the host

`tool/appimage_system_deps.txt` is the audited list; in short:

- glibc at least as new as the build host's;
- an X11 or Wayland session with GTK 3;
- a D-Bus session bus and a Secret Service provider (GNOME Keyring,
  KWallet 5.97+, or KeePassXC) for stored credentials;
- `xdg-open` for "Open in browser".

## Other platforms

iOS was a planned second target (TestFlight via Codemagic) and Windows and
macOS are out of scope; see MAINTENANCE.md. Nothing in the service tabs is
Linux-specific except "Open in browser", which calls `xdg-open`.
