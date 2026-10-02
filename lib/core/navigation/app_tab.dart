import 'package:flutter/widgets.dart';

import '../build_config.dart';
import '../theme/phosphor.dart';

/// The canonical AppShell tab order and identity — the single source of truth
/// for label, icon, rail section, accent, and desktop-only-ness. The integer
/// [index] is what [SelectedTab] stores and what indexes the shell's page
/// stack.
///
/// Eleven destinations (left-top-top IA, 2026-08-07; Home Assistant added
/// 2026-08-12; Library added 2026-08-18): four of them — [ai], [media],
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
  // Native Docker Engine control (containers + images) over a LAN TCP socket.
  docker('Docker', Ph.cube, 'Control'),
  metrics('Metrics', Ph.chartLineUp, 'Control'),
  // AI hub: Chat (Hermes personally), Models (Ollama library), Open WebUI.
  ai('AI', Ph.brain, 'Services'),
  media('Media', Ph.monitorPlay, 'Services'),
  // The full Home Assistant frontend (device control, automations, add /
  // remove integrations) as an embedded webview — HA's UI already does
  // everything, so the tab needs only a URL.
  homeAssistant('Home Assistant', Ph.house, 'Services'),
  // Vault hub: Wiki + Ask. The public build has no Ask, so the hub collapses
  // to the bare wiki webview and the label follows suit.
  vault(kPublicBuild ? 'Wiki' : 'Vault', Ph.bookOpenText, 'Services'),
  // Library hub: Karakeep bookmarks + Paperless documents — the reading/
  // records shelf beside the Vault's knowledge base.
  library('Library', Ph.books, 'Services'),
  tailscale('Tailscale', Ph.shieldCheck, 'System', desktopOnly: true),
  terminal('Terminal', Ph.terminalWindow, 'System', desktopOnly: true),
  settings('Settings', Ph.gearSix, 'System');

  const AppTab(this.label, this.icon, this.section,
      {this.desktopOnly = false});

  final String label;
  final IconData icon;

  /// Rail grouping — Control (green/gold), Services (garnet), System (navy).
  /// The flat accent colour lives in the theme: `brass.sectionAccent(section)`
  /// (enum constants can't hold brightness-resolved colors).
  final String section;
  final bool desktopOnly;

  /// Position in the desktop rail. Deep links and webview lazy-activation go
  /// through this rather than [index] — it is the indirection point that let
  /// the public build hide tabs before the 2026-08-07 hub restructure moved
  /// personal-only gating to the sub-tab level, and it stays so any future
  /// tab-level filtering has one place to live.
  int get railIndex => index;
}
