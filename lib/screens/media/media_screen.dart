import 'package:flutter/material.dart';

import '../../core/navigation/app_tab.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/hub_scaffold.dart';
import '../webview/webview_screen.dart';
import 'media_server_tab.dart';
import 'prowlarr_tab.dart';
import 'qbittorrent_tab.dart';
import 'radarr_tab.dart';
import 'sonarr_tab.dart';

/// The Media hub: the media servers first (Jellyfin and Plex status — the
/// reason the rest of the stack exists), then Radarr, Sonarr, qBittorrent,
/// and Prowlarr, plus Jellyseerr (Discover) as an embedded web view. Runs on
/// the shared [HubScaffold] since the 2026-08-07 IA restructure (the garnet
/// strip was born here). No NAS assumption anywhere: every service is just a
/// configured URL, wherever it runs.
class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key, required this.railIndex});

  /// This tab's index in the shell's rail — the Discover web view uses it
  /// to activate lazily only once the Media tab is opened.
  final int railIndex;

  /// Strip entries, index-aligned with [build]'s children; the shell's
  /// command palette lists them as jump targets.
  static const specs = [
    (icon: Ph.monitorPlay, label: 'Jellyfin'),
    (icon: Ph.play, label: 'Plex'),
    (icon: Ph.filmSlate, label: 'Radarr'),
    (icon: Ph.televisionSimple, label: 'Sonarr'),
    (icon: Ph.downloadSimple, label: 'qBittorrent'),
    (icon: Ph.detective, label: 'Prowlarr'),
    (icon: Ph.compass, label: 'Discover'),
    (icon: Ph.image, label: 'Photos'),
  ];

  @override
  Widget build(BuildContext context) => HubScaffold(
        hub: AppTab.media,
        tabs: [
          HubTab(
            icon: specs[0].icon,
            label: specs[0].label,
            child: const JellyfinTab(),
          ),
          HubTab(
            icon: specs[1].icon,
            label: specs[1].label,
            child: const PlexTab(),
          ),
          HubTab(
            icon: specs[2].icon,
            label: specs[2].label,
            child: const RadarrTab(),
          ),
          HubTab(
            icon: specs[3].icon,
            label: specs[3].label,
            child: const SonarrTab(),
          ),
          HubTab(
            icon: specs[4].icon,
            label: specs[4].label,
            child: const QbittorrentTab(),
          ),
          HubTab(
            icon: specs[5].icon,
            label: specs[5].label,
            child: const ProwlarrTab(),
          ),
          HubTab(
            icon: specs[6].icon,
            label: specs[6].label,
            child: WebViewScreen(service: 'Jellyseerr', tabIndex: railIndex),
          ),
          // Immich — the photo library is media too; the full frontend rides
          // an embedded webview like Discover.
          HubTab(
            icon: specs[7].icon,
            label: specs[7].label,
            child: WebViewScreen(service: 'Immich', tabIndex: railIndex),
          ),
        ],
      );
}
