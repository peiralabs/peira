import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/sonarr_series.dart';
import '../../core/providers/media_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import 'media_common.dart';

/// Sonarr — series library, active download queue, monitor toggle, search, and
/// add-by-lookup.
class SonarrTab extends ConsumerWidget {
  const SonarrTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(sonarrSeriesProvider);
    final queue = ref.watch(sonarrQueueProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: series.hasValue
          ? MediaFab(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => MediaLookupDialog<SonarrSeries>(
                  title: 'Add series',
                  hintText: 'Search TVDb…',
                  lookup: (term) async {
                    final api = await ref.read(sonarrApiProvider.future);
                    return api.lookup(term);
                  },
                  add: (series) async {
                    final api = await ref.read(sonarrApiProvider.future);
                    await api.add(series);
                    ref.invalidate(sonarrSeriesProvider);
                  },
                  itemTitle: (series) => series.title,
                  itemSubtitle: (series) =>
                      series.year == null ? null : '${series.year}',
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add series'),
            )
          : null,
      body: series.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => mediaAsyncState(
          context: context,
          error: e,
          onRetry: () => ref.invalidate(sonarrSeriesProvider),
        ),
        data: (list) {
          final monitored = list.where((s) => s.monitored).length;
          final size = list.fold<num>(
            0,
            (s, item) => s + (item.statistics?.sizeOnDisk ?? 0),
          );
          final q = queue.value ?? const [];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sonarrSeriesProvider);
              ref.invalidate(sonarrQueueProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                mediaSummary(context, [
                  ('Series', '${list.length}'),
                  ('Monitored', '$monitored'),
                  ('On disk', formatBytes(size)),
                ]),
                if (q.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  MediaSectionTitle('Downloading (${q.length})'),
                  const SizedBox(height: 8),
                  for (final item in q)
                    MediaQueueTile(
                      title: item.title,
                      progress: item.progress,
                      subtitle: [
                        if (item.status != null) item.status!,
                        if (item.timeleft != null) item.timeleft!,
                      ].join('  ·  '),
                      onDelete: () => runMediaAction(
                        context,
                        action: () async {
                          final api = await ref.read(sonarrApiProvider.future);
                          await api.deleteQueueItem(item.id);
                          ref.invalidate(sonarrQueueProvider);
                        },
                        success: 'Removed from queue',
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                const MediaSectionTitle('Library'),
                const SizedBox(height: 8),
                for (final show in list)
                  _SeriesTile(
                    series: show,
                    onToggleMonitor: () => runMediaAction(
                      context,
                      action: () async {
                        final api = await ref.read(sonarrApiProvider.future);
                        await api.setMonitored(show.id, !show.monitored);
                        ref.invalidate(sonarrSeriesProvider);
                      },
                      success: show.monitored ? 'Unmonitored' : 'Monitored',
                    ),
                    onSearch: () => runMediaAction(
                      context,
                      action: () async {
                        final api = await ref.read(sonarrApiProvider.future);
                        await api.search(show.id);
                      },
                      success: 'Search triggered',
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SeriesTile extends StatelessWidget {
  const _SeriesTile({
    required this.series,
    required this.onToggleMonitor,
    required this.onSearch,
  });

  final SonarrSeries series;
  final VoidCallback onToggleMonitor;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final stats = series.statistics;
    final complete =
        stats != null &&
        stats.episodeCount > 0 &&
        stats.episodeFileCount >= stats.episodeCount;
    final subtitle = [
      if (series.year != null) '${series.year}',
      if (stats != null) '${stats.episodeFileCount}/${stats.episodeCount} eps',
      if (stats != null && stats.sizeOnDisk > 0) formatBytes(stats.sizeOnDisk),
      if (series.seriesType == 'anime') 'anime',
    ].join('  ·  ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrassPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            complete ? Icons.check_circle : Icons.live_tv_outlined,
            color: complete ? brass.ok : brass.ochre,
          ),
          title: Text(series.title, overflow: TextOverflow.ellipsis),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: series.monitored ? 'Unmonitor' : 'Monitor',
                icon: Icon(
                  series.monitored ? Icons.bookmark : Icons.bookmark_border,
                  color: series.monitored ? brass.copper : null,
                ),
                onPressed: onToggleMonitor,
              ),
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: onSearch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
