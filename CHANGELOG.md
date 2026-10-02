# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — unreleased

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
