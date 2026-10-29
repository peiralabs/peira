import 'package:flutter/widgets.dart';

import '../build_config.dart';
import '../models/app_settings.dart';
import '../theme/phosphor.dart';

/// The canonical AppShell tab order and identity — the single source of truth
/// for label, icon, rail section, accent, and desktop-only-ness. The integer
/// [index] is what [SelectedTab] stores and what indexes the shell's page
/// stack.
///
/// Thirteen destinations (left-top-top IA, 2026-08-07; Home Assistant added
/// 2026-08-12; Library added 2026-08-18): five of them — [pdm], [ai], [media],
/// [vault], [library] — are domain hubs whose sub-views live in a garnet
/// sub-tab strip ([HubScaffold]), and [metrics] hosts its own hub (native
/// Metrics / Logs / Watches), so one domain never spends more than one rail
/// slot. Personal-only gating lives at the sub-tab level now; the rail
/// itself is the same shape in both builds.
///
/// Tailscale and Terminal are desktop-only (iOS has no CLI / process
/// spawning); on iOS they're dropped from the rail. iOS isn't a current ship
/// target, so callers deep-link by the desktop index.
enum AppTab {
  dashboard('Dashboard', Ph.squaresFour, 'Control'),
  proxmox('Proxmox', Ph.hardDrives, 'Control'),
  // Proxmox Datacenter Manager: every cluster in one view, with power actions and cross-cluster migrate.
  pdm('PDM', Ph.treeStructure, 'Control'),
  // Proxmox Backup Server: datastore health, backup inventory, jobs, and tasks.
  pbs('PBS', Ph.database, 'Control'),
  // Native Docker Engine control (containers + images) over a LAN TCP socket.
  docker('Docker', Ph.cube, 'Control'),
  metrics('Metrics', Ph.chartLineUp, 'Control'),
  // AI hub: Chat (Hermes personally), Models (Ollama library), Open WebUI.
  ai('AI', Ph.brain, 'Services'),
  media('Media', Ph.monitorPlay, 'Services'),
  // Native Home Assistant over its REST API (entities and their controls,
  // any service call, logbook, to-do lists, system tools); the HA frontend
  // opens in the browser for dashboards and config editors.
  homeAssistant('Home Assistant', Ph.house, 'Services'),
  // Vault hub: Wiki + Ask. The public build has no Ask, so the hub collapses
  // to the bare Wiki view and the label follows suit.
  vault(kPublicBuild ? 'Wiki' : 'Vault', Ph.bookOpenText, 'Services'),
  // Library hub: Karakeep bookmarks + Paperless documents — the reading/
  // records shelf beside the Vault's knowledge base.
  library('Library', Ph.books, 'Services'),
  tailscale('Tailscale', Ph.shieldCheck, 'System', desktopOnly: true),
  terminal('Terminal', Ph.terminalWindow, 'System', desktopOnly: true),
  settings('Settings', Ph.gearSix, 'System');

  const AppTab(this.label, this.icon, this.section, {this.desktopOnly = false});

  final String label;
  final IconData icon;

  /// Rail grouping — Control (green/gold), Services (garnet), System (navy).
  /// The flat accent colour lives in the theme: `brass.sectionAccent(section)`
  /// (enum constants can't hold brightness-resolved colors).
  final String section;
  final bool desktopOnly;

  /// Position in the desktop rail. Deep links and hub activation go
  /// through this rather than [index] — it is the indirection point that let
  /// the public build hide tabs before the 2026-08-07 hub restructure moved
  /// personal-only gating to the sub-tab level, and it stays so any future
  /// tab-level filtering has one place to live.
  int get railIndex => index;

  /// Whether the rail lists this tab for [s]: a service tab appears once any
  /// of its services has a URL (a missing API credential then shows the
  /// tab's own setup prompt, not a hidden tab). Settings
  /// `showUnconfiguredTabs` overrides this in the shell.
  bool isAvailable(AppSettings s) => switch (this) {
    dashboard || proxmox || tailscale || terminal || settings => true,
    pdm => s.pdmUrl.isNotEmpty,
    pbs => s.pbs1Url.isNotEmpty || s.pbs2Url.isNotEmpty,
    docker => s.dockerUrl.isNotEmpty,
    metrics =>
      s.prometheusEndpoint.isNotEmpty ||
          s.lokiUrl.isNotEmpty ||
          s.changedetectionUrl.isNotEmpty,
    ai =>
      s.hermesApiEndpoint.isNotEmpty ||
          s.ollamaApiEndpoint.isNotEmpty ||
          s.ollamaUrl.isNotEmpty ||
          s.searxngUrl.isNotEmpty,
    media => [
      s.jellyfinUrl,
      s.plexUrl,
      s.radarrUrl,
      s.sonarrUrl,
      s.qbittorrentUrl,
      s.prowlarrUrl,
      s.jellyseerrUrl,
      s.immichUrl,
    ].any((u) => u.isNotEmpty),
    homeAssistant => s.homeAssistantUrl.isNotEmpty,
    vault => s.wikiUrl.isNotEmpty || (!kPublicBuild && s.askUrl.isNotEmpty),
    library => s.karakeepUrl.isNotEmpty || s.paperlessUrl.isNotEmpty,
  };
}
