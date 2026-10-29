# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **Instrument kits.** Each theme family draws the shared instruments in its
  own style: readouts, meters, dials, charts, status lamps, switches and
  fasteners (see the README's Instruments section). Brass becomes a working
  instrument panel: split-flap counters, liquid-filled gauge tubes, raised
  dials in recessed ledges, screwed instrument plates, oscilloscope and
  chart-paper traces, a strip-chart recorder for cluster CPU, knurled
  refresh knobs, jewel pilot lamps, and bat-handle toggles.
- Every switch shows a green (on) or red (off) lamp.
- The terminal follows the theme: a CRT housing, and an ANSI colour scheme
  per family (green and amber phosphor, Nord, Catppuccin Mocha, macOS).

### Changed

- Colours that only suited Brass (sub-tab strips, the attention banner,
  header badges, the terminal frame, chat and service palettes) now follow
  the selected theme family.
- Settings-style switches, progress bars and status lights use the theme's
  instruments instead of the stock Material widgets.

### Fixed

- A counter replay arriving mid-count dropped the flip in flight.

## [2.0.0] — 2026-10-29

A major version: the service tabs that showed each service's web page now
use its API, so an upgraded 1.2 setup needs an API key per service before
those tabs work again (Settings, or the setup file below).

### Added

- **Every service tab is native.** Home Assistant, Immich, Paperless-ngx,
  Karakeep, Seerr (Jellyseerr / Overseerr), Open WebUI, Wiki.js, SearXNG and
  changedetection.io now run through each service's own API instead of an
  embedded browser: browse, search, edit, request, approve, upload and
  manage from the app. Every tab keeps an **Open in browser** button for
  whatever the API cannot do, and shows exactly which URL or key is missing
  until it is set. Settings has a key field for each service.
- **Unconfigured tabs are hidden.** The sidebar lists a service tab once
  one of its services has a URL; Settings › Show tabs for services not set
  up lists them all.
- **Setup file.** Fill in `setup/setup.example.json` once and import it
  (Settings › Import setup file, or drop it at
  `~/.config/peira/seed.json` for the next launch, after which it is
  deleted). See `docs/setup-file.md`.
- **In-app guide.** Opens on first launch with a "Don't show this again"
  box: what the app does, connecting Proxmox, where each service's key
  comes from, the setup file, and every tab. Settings › Guide, the About
  sheet and the command palette (Ctrl+K) reopen it.
- **Demo mode covers the service tabs** with fake data, so `--demo` shows
  every tab working.

### Changed

- Peira Labs branding: the masthead reads PEIRA, the dashboard ring and the
  launcher icon read PEIRA LABS, and About links to peiralabs.com.
- The setup wizard suggests the token name `peira` and lists the service
  tabs that light up later.

### Removed

- The embedded browser (CEF via `webview_cef`, and `webview_flutter` on
  iOS). The AppImage is about 300 MB smaller, needs no X11 or XWayland and
  no unprivileged user namespaces. Settings › Web logins went with it;
  stored web logins are deleted from the keychain on first launch.

## [1.2.0] — 2026-10-24

### Added

- **PDM tab** (Proxmox Datacenter Manager): every managed cluster in one
  view. Overview of quorum, nodes, CPU, memory and storage; one guest list
  across clusters with start, shutdown, stop and reboot; cross-cluster
  migrate with VMID, storage and bridge mapping; tasks from every remote.
- **PBS tab** (Proxmox Backup Server), with two server slots: datastore
  usage and garbage collection, backup groups and snapshots, prune, verify
  and sync jobs, and task logs. A stored read/verify token covers browsing
  and verifying. Deleting, pruning, protecting and editing need an unlock
  with the PBS user's password, held in memory for at most 30 minutes and
  never stored. Whole VMs and containers can be restored to an unused VMID
  through the Proxmox VE connection, and single files downloaded from
  container and host archives.
- Named connection profiles: save several Proxmox setups (for example two
  clusters) and switch between them in Settings.
- `docs/pdm-and-pbs.md`: what both tabs do and the roles their tokens need.
- The VM create form validates its inputs; the VM console opens in the app;
  power actions show progress (#18).
- Visual goldens render the same on every machine and gate CI (#15).
- Released AppImages carry build-provenance attestations (#20).

### Changed

- Webview masks follow the selected theme family (#17).
- The Proxmox container and VM code paths share one implementation (#16),
  as does the Hermes and Ask chat screen (#13); more helpers de-duplicated
  (#12).
- Wayland runner cleanups; release assets carry the version in their name
  (#10).
- CI pins `subosito/flutter-action` to a commit SHA (#19).

### Fixed

- **Check for updates** queried a repository that does not exist, so it
  could never report a new release. It now checks `peiralabs/peira`; the
  security link in the issue template pointed at the same wrong repository.
- Saved web logins work on Seerr, whose password box is not always a
  `type=password` input, and survive the page resetting the form during
  load. The login submits once, and only when both fields hold their values.

### Security

- SSH targets built from Proxmox inventory or saved shortcuts can no longer
  be read as ssh options (#11).
- Links opened in the system browser are restricted to http and https
  (#14).

## [1.1.0] — 2026-10-06

### Added

- Eight selectable theme families — Brass (default), Graphite, Terminal,
  Nord, Ember, Obsidian, Aqua, and Catppuccin — each re-skinning the whole
  shell (background, masthead, panels, nav rail, ornaments) through a single
  `ThemeExtension` token set, with per-family typography (serif, monospace,
  or sans). Dark and light variants for every family.
- Wayland groundwork: display-server detection, and embedded webviews that
  degrade gracefully with an "open in your browser" fallback where the CEF
  browser has no X11 surface instead of showing a blank tab. The full
  Wayland-native webview path is scoped in `docs/wayland-and-cross-platform.md`.

### Changed

- Internal elegance pass: service-endpoint fallbacks, the Proxmox API's
  storage-walk and delete helpers, and shared chrome tokens were de-duplicated
  with no change to behaviour or appearance.

## [1.0.0] — 2026-10-02

Initial public release.

- Native Proxmox VE management: dashboard, node detail, container lifecycle
  (create, clone, snapshots, delete), live charts, failed-task drill-in.
- First-run setup wizard with a real connection test; a read-only
  `PVEAuditor` token is enough for everything except management actions.
- Works against a standalone single node as well as a cluster.
- Prometheus-backed Metrics tab (node_exporter; guest panel optionally uses
  prometheus-pve-exporter).
- Media status panels: Jellyfin, Plex, Radarr, Sonarr, Prowlarr, qBittorrent,
  Jellyseerr — each appears once configured.
- AI chat against any OpenAI-compatible endpoint; native Ollama model
  library.
- Embedded terminal with SSH targets built from live Proxmox inventory
  (configurable username; containers entered via `pct enter`).
- Themed embedded webviews (Grafana, Open WebUI, Wiki.js, Jellyseerr); the
  Wiki.js reskin detects its DOM and no-ops on other wikis.
- Credentials live in the system keychain (Secret Service), never in files.
