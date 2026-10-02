import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_server_status.dart';
import '../../core/providers/media_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/recessed_bar.dart';
import '../../core/widgets/status_light.dart';
import 'media_common.dart';

/// Jellyfin server status — identity, now playing, library counts, recently
/// added. Same panel as Plex; only the provider differs.
class JellyfinTab extends ConsumerWidget {
  const JellyfinTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _MediaServerView(
        state: ref.watch(jellyfinStatusProvider),
        onRefresh: () => ref.invalidate(jellyfinStatusProvider),
      );
}

/// Plex server status.
class PlexTab extends ConsumerWidget {
  const PlexTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _MediaServerView(
        state: ref.watch(plexStatusProvider),
        onRefresh: () => ref.invalidate(plexStatusProvider),
      );
}

/// Shared presentation for a [MediaServerStatus]: identity panel with a
/// breathing health light, stat strip, now-playing rows with progress bars,
/// and a recently-added list.
class _MediaServerView extends StatelessWidget {
  const _MediaServerView({required this.state, required this.onRefresh});

  final AsyncValue<MediaServerStatus> state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => mediaAsyncState(
        context: context,
        error: e,
        onRetry: onRefresh,
      ),
      data: (s) {
        final brass = context.brass;
        final caption = Theme.of(context).textTheme.bodySmall;
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BrassPanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const StatusLight(health: Health.ok),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.serverName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: brass.textHeading,
                        ),
                      ),
                    ),
                    if (s.version.isNotEmpty)
                      Text('v${s.version}', style: caption),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              mediaSummary(context, [
                ('Playing', '${s.sessions.length}'),
                for (final lib in s.libraries.take(3))
                  (lib.name, '${lib.count}'),
              ]),
              const SizedBox(height: 16),
              const MediaSectionTitle('Now playing'),
              const SizedBox(height: 8),
              if (s.sessions.isEmpty)
                Text('Nothing is playing right now.', style: caption)
              else
                for (final session in s.sessions) _SessionTile(session),
              if (s.recent.isNotEmpty) ...[
                const SizedBox(height: 16),
                const MediaSectionTitle('Recently added'),
                const SizedBox(height: 8),
                for (final item in s.recent) _RecentTile(item),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile(this.session);

  final MediaSession session;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final caption = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.subtitle.isEmpty
                        ? session.title
                        : '${session.title} — ${session.subtitle}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  session.paused ? Icons.pause : Icons.play_arrow,
                  size: 16,
                  color: session.paused ? brass.ochre : brass.ok,
                ),
              ],
            ),
            const SizedBox(height: 6),
            RecessedBar(
              fraction: session.progress,
              height: 6,
              gradient: [brass.sparkGreenDeep, brass.sparkGreen],
            ),
            const SizedBox(height: 5),
            Text(
              [
                if (session.user.isNotEmpty) session.user,
                '${(session.progress * 100).toStringAsFixed(0)}%',
              ].join('  ·  '),
              style: caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile(this.item);

  final MediaRecentItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrassPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          dense: true,
          title: Text(item.title, overflow: TextOverflow.ellipsis),
          subtitle: item.subtitle.isEmpty
              ? null
              : Text(item.subtitle, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
