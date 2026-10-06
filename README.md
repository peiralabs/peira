# Homelab control panel

A Flutter desktop app that puts a whole homelab on one screen: native
Proxmox VE management (nodes, containers, snapshots, live charts), a
Prometheus-backed metrics tab, media-stack status panels, an AI chat for any
OpenAI-compatible endpoint, an embedded terminal whose SSH targets are built
from live Proxmox inventory, and themed embedded views for the web services
that already have great UIs (Grafana, Open WebUI, Wiki.js, Jellyseerr). Eight
theme families restyle the whole interface — each with its own palette and
typography — so it can look like anything from an engraved brass instrument
to a neon-green terminal.

![Dashboard](docs/screenshots/dashboard.png)

| First launch | Container detail |
|---|---|
| ![Setup wizard](docs/screenshots/setup-wizard.png) | ![Container detail](docs/screenshots/container-detail.png) |

## Themes

Eight built-in theme families, each re-skinning the entire shell — background,
masthead, panels, nav rail, and ornaments — with its own colour palette and
typography (serif, sans, or monospace). Every family has dark and light
variants; pick one in Settings. The shots below are demo mode.

| Family | Dark | Light |
|---|---|---|
| **Brass** — green & gold, engraved serif (default) | ![Brass dark](docs/screenshots/themes/screen-brass.png) | ![Brass light](docs/screenshots/themes/screen-brass-light.png) |
| **Graphite** — neutral slate, clean sans | ![Graphite dark](docs/screenshots/themes/screen-graphite.png) | ![Graphite light](docs/screenshots/themes/screen-graphite-light.png) |
| **Terminal** — black & neon-green phosphor, monospace | ![Terminal dark](docs/screenshots/themes/screen-terminal.png) | ![Terminal light](docs/screenshots/themes/screen-terminal-light.png) |
| **Nord** — cool arctic blue | ![Nord dark](docs/screenshots/themes/screen-nord.png) | ![Nord light](docs/screenshots/themes/screen-nord-light.png) |
| **Ember** — warm crimson | ![Ember dark](docs/screenshots/themes/screen-ember.png) | ![Ember light](docs/screenshots/themes/screen-ember-light.png) |
| **Obsidian** — matte black | ![Obsidian dark](docs/screenshots/themes/screen-obsidian.png) | ![Obsidian light](docs/screenshots/themes/screen-obsidian-light.png) |
| **Aqua** — macOS-inspired | ![Aqua dark](docs/screenshots/themes/screen-aqua.png) | ![Aqua light](docs/screenshots/themes/screen-aqua-light.png) |
| **Catppuccin** — soft modern pastel | ![Catppuccin dark](docs/screenshots/themes/screen-catppuccin.png) | ![Catppuccin light](docs/screenshots/themes/screen-catppuccin-light.png) |

## Requirements

- **Proxmox VE and an API token** — that's the only hard requirement. A
  read-only token (`PVEAuditor`) lights up everything except management
  actions; the first-run wizard shows the exact `pveum` commands.
- A Linux desktop with GTK 3, an X11 or XWayland session, and a Secret
  Service (GNOME Keyring or KWallet) for credential storage.
- Everything else — Prometheus, Grafana, media services, AI endpoints — is
  optional; panels appear as you configure them.

## Install

Download the AppImage from the releases page, then:

```bash
chmod +x Peira-x86_64.AppImage
./Peira-x86_64.AppImage
```

Verify a release before running it:

```bash
sha256sum -c SHA256SUMS
gpg --verify SHA256SUMS.asc SHA256SUMS
```

Updates are manual by design — an AppImage cannot replace itself in place.
The public build's Settings › Updates checks the releases API when you ask
it to (a single GET; no telemetry of any kind).

**Want to look around without a Proxmox cluster?**

```bash
./Peira-x86_64.AppImage --demo
```

Demo mode boots a fully populated, obviously-fake lab — no configuration,
no keyring writes, no network access — with a persistent banner so demo
screenshots can never pass as real. (`MOL_DEMO=1` works too.) It's also the
reproduction environment for bug reports: if it happens in `--demo`, it's
not your setup.

## What this assumes about your setup

The app was built against a real homelab, and some of that lab's shape shows
through. Here is exactly what it expects, what is configurable, and what
degrades gracefully:

- **Proxmox VE is the center.** First launch is a setup wizard that needs
  only your Proxmox URL and an API token (ID like `user@pve!token`). A
  read-only token (`PVEAuditor` role) lights up the dashboard and inventory;
  management actions — start/stop, snapshots, create/delete — need a token
  with write privileges. A standalone single node and a multi-node cluster
  both render correctly.
- **Self-signed certificates are trusted for the Proxmox host only.** That is
  a deliberate boundary with a settings toggle, not a global bypass. Other
  services presenting self-signed certs need OS-level trust or plain HTTP.
- **The terminal connects as `root` by default.** Node and container targets
  come from live Proxmox inventory as `<user>@<node-ip>`; the username is
  configurable (Settings › Terminal) for setups that disable root SSH per
  Proxmox's own hardening guidance. Container entry runs `pct enter` on the
  owning node, which requires root there — a non-root username is wrapped in
  `sudo`, so that user needs sudo rights on the node. Nodes must be
  SSH-reachable from the machine running the app.
- **The Wiki tab targets Wiki.js v2 specifically.** The native reskin detects
  Wiki.js's DOM and switches itself off on anything else — BookStack,
  Outline, or Confluence load with their own styling rather than a
  half-applied mask.
- **Metrics needs Prometheus** scraping `node_exporter` on your nodes. The
  guest-metrics panel additionally needs
  [prometheus-pve-exporter](https://github.com/prometheus-pve/prometheus-pve-exporter)
  — an optional install, separate from `node_exporter`; the rest of the tab
  works without it. Grafana (with a Viewer-role API key) powers the alerts
  feed and its embedded view; both are optional.
- **Media services are optional and live wherever you run them** — NAS,
  containers, VMs. Jellyfin, Plex, Radarr, Sonarr, Prowlarr, qBittorrent, and
  Jellyseerr each appear once configured; nothing assumes a NAS.
- **AI Chat speaks to any OpenAI-compatible endpoint** (Ollama, LiteLLM,
  vLLM, OpenRouter…) — endpoint, model name, and optional API key are
  settings. The Ollama tab is a native model library for a local Ollama
  daemon.

Every endpoint and credential is stored in the system keychain via
`flutter_secure_storage` — never in plain files.

## Compatibility — what was actually tested

| Environment | Status |
|---|---|
| openSUSE Tumbleweed, GNOME on X11 (1.15 text scaling) | Daily-driven by the maintainer |
| Ubuntu 24.04 | Automated acceptance: launch, wizard + token round-trip through GNOME Keyring, CEF webview rendering |
| Fedora 44 | Same automated acceptance |
| Arch (2026-04 base) | Same automated acceptance |
| Wayland-native (no XWayland) | **Partial** — the app runs; embedded webviews detect the missing X11 surface and offer to open in your browser instead of failing. Full Wayland-native webviews are [roadmapped](docs/wayland-and-cross-platform.md). |
| Windows / macOS | Never; out of scope |

Two honest footnotes: the automated acceptance ran under headless X11 with
software rendering (it verifies function, not GPU paths), and the window has
a 1100×700 desktop minimum — small screens are not the target.

Known problems live in [KNOWN_ISSUES.md](KNOWN_ISSUES.md) — read the
keyring section before filing a startup bug. Security reporting and the
threat model live in [SECURITY.md](SECURITY.md); contribution mechanics in
[CONTRIBUTING.md](CONTRIBUTING.md); third-party licensing in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Project status: maintained, best-effort

A personal project with a written [maintenance policy](MAINTENANCE.md) —
weekly triage window, honest scope boundary (no Windows/macOS, no
non-Proxmox hypervisors, no telemetry, no auto-update), and a pre-agreed
degradation plan so the repo never silently rots. Read it before filing
feature requests.

## Building

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build linux --release
```

The Flutter version is pinned in `.tool-versions`. The first Linux build
downloads the Chromium Embedded Framework for the embedded webviews (a few
hundred MB, one time). `tool/build_appimage.sh` packages the release bundle
as an AppImage and audits the binary's full link closure against
`tool/appimage_system_deps.txt`.
