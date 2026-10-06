# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/).

## [1.1.0] — unreleased

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
