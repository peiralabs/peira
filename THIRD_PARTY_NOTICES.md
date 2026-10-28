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
| flutter_secure_storage | BSD-3-Clause |
| url_launcher | BSD-3-Clause |
| connectivity_plus | BSD-3-Clause |
| dio, riverpod family, fl_chart, xterm, flutter_pty, freezed, alchemist | MIT |
| file_selector, flutter_markdown_plus | BSD-3-Clause |
| **dbus** (transitive via connectivity_plus) | **MPL-2.0** |
| **nm** (transitive via connectivity_plus) | **MPL-2.0** |

MPL-2.0 position: both packages are used unmodified as published on
pub.dev, which also hosts their source — that satisfies MPL-2.0's source
availability requirement for the covered files. No MPL-covered file is
modified by this project.

## Trademarks

Proxmox, Tailscale, Grafana, Prometheus, Ollama, Radarr, Sonarr, Prowlarr,
qBittorrent, Jellyfin, Jellyseerr, Plex, and Wiki.js are trademarks of
their respective owners. This project uses those names **nominatively
only** — to state what the app can connect to. The application's own name,
icon, and desktop entry contain none of them, and no endorsement by any of
those projects is implied.
