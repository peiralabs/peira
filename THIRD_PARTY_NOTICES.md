# Third-party notices

This project is licensed under Apache-2.0 (see LICENSE). It bundles or
depends on the third-party components below. Flutter's build additionally
embeds the license text of every pub dependency into the application bundle
(`flutter_assets/NOTICES.Z`), which is the authoritative per-package
aggregation for anything not called out here.

**Not all dependencies are permissive** — two transitive packages are
MPL-2.0 (weak file-level copyleft); see below. Do not claim otherwise in
marketing or docs.

## Bundled fonts (shipped as assets)

| Component | License | Text shipped at |
|---|---|---|
| EB Garamond | SIL OFL 1.1 | assets/fonts/OFL.txt |
| Playfair Display | SIL OFL 1.1 | assets/fonts/OFL.txt |
| JetBrains Mono | SIL OFL 1.1 | assets/fonts/OFL.txt |
| Phosphor Icons | MIT | assets/fonts/LICENSE-Phosphor.txt |

The OFL fonts are unmodified, so the Reserved Font Name clause is satisfied
(the names are used only to refer to the unmodified fonts). Phosphor's MIT
notice ships in full because MIT requires the copyright notice with all
substantial portions.

## Frameworks and plugins

| Component | License |
|---|---|
| Flutter (framework + engine) | BSD-3-Clause |
| CEF (Chromium Embedded Framework, via webview_cef) | BSD-3-Clause (Chromium components under their own licenses — see FFmpeg below) |
| flutter_secure_storage | BSD-3-Clause |
| url_launcher | BSD-3-Clause |
| connectivity_plus | BSD-3-Clause |
| webview_cef | Apache-2.0 |
| dio, riverpod family, fl_chart, xterm, flutter_pty, freezed, alchemist | MIT |
| **dbus** (transitive via connectivity_plus) | **MPL-2.0** |
| **nm** (transitive via connectivity_plus) | **MPL-2.0** |

MPL-2.0 position: both packages are used unmodified as published on
pub.dev, which also hosts their source — that satisfies MPL-2.0's source
availability requirement for the covered files. No MPL-covered file is
modified by this project.

## CEF's bundled FFmpeg (investigated 2026-08-09)

webview_cef downloads the **standard** CEF distribution from the public CEF
automated-build CDN (`cef-builds.spotifycdn.com`, exact version pinned in
the package's `third/download.cmake`). Standard builds ship with
**proprietary codecs disabled** (no H.264/AAC — those exist only in
self-compiled builds with `proprietary_codecs=true`), so no patent-pool
licensing applies to this distribution.

FFmpeg itself (open-codec configuration: VP8/VP9/AV1, Opus, Vorbis, FLAC,
PCM…) is **LGPL-2.1+** and is statically linked into `libcef.so`, as in
Chromium. LGPL obligations are discharged as follows:

- This notice identifies the component and its license; the LGPL text is
  part of the CEF/Chromium credits embedded in the CEF distribution
  (`chrome://credits` equivalent data ships inside the binary's resources).
- Corresponding source is public at the pinned version: Chromium's FFmpeg
  tree and the CEF build configuration for the exact build are published by
  the CEF project; the version string in `third/download.cmake` identifies
  the build precisely.
- Relinking/replacement: `libcef.so` ships as a **discrete, replaceable
  file** in the AppImage (`usr/bin/lib/libcef.so`). A user can extract the
  AppImage, substitute their own build of the same CEF version (including a
  relinked FFmpeg), and repack — no part of this application links FFmpeg
  directly.

**Standing obligation:** on every webview_cef/CEF bump, re-confirm the
build is the standard (non-proprietary-codec) distribution
(docs/webview-cef-notes.md carries this in its bump checklist).

## Trademarks

Proxmox, Tailscale, Grafana, Prometheus, Ollama, Radarr, Sonarr, Prowlarr,
qBittorrent, Jellyfin, Jellyseerr, Plex, and Wiki.js are trademarks of
their respective owners. This project uses those names **nominatively
only** — to state what the app can connect to. The application's own name,
icon, and desktop entry contain none of them, and no endorsement by any of
those projects is implied.
