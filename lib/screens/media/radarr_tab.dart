import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/radarr_movie.dart';
import '../../core/providers/media_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import 'media_common.dart';

/// Radarr — movie library, active download queue, monitor toggle, search, and
/// add-by-lookup.
class RadarrTab extends ConsumerWidget {
  const RadarrTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(radarrMoviesProvider);
    final queue = ref.watch(radarrQueueProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: movies.hasValue
          ? MediaFab(
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add movie'),
            )
          : null,
      body: movies.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => mediaAsyncState(
          context: context,
          error: e,
          onRetry: () => ref.invalidate(radarrMoviesProvider),
        ),
        data: (list) {
          final monitored = list.where((m) => m.monitored).length;
          final missing = list.where((m) => m.monitored && !m.hasFile).length;
          final size = list.fold<num>(0, (s, m) => s + m.sizeOnDisk);
          final q = queue.value ?? const [];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(radarrMoviesProvider);
              ref.invalidate(radarrQueueProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                mediaSummary(context, [
                  ('Movies', '${list.length}'),
                  ('Monitored', '$monitored'),
                  ('Missing', '$missing'),
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
                          final api = await ref.read(radarrApiProvider.future);
                          await api.deleteQueueItem(item.id);
                          ref.invalidate(radarrQueueProvider);
                        },
                        success: 'Removed from queue',
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                const MediaSectionTitle('Library'),
                const SizedBox(height: 8),
                for (final movie in list)
                  _MovieTile(
                    movie: movie,
                    onToggleMonitor: () => runMediaAction(
                      context,
                      action: () async {
                        final api = await ref.read(radarrApiProvider.future);
                        await api.setMonitored(movie.id, !movie.monitored);
                        ref.invalidate(radarrMoviesProvider);
                      },
                      success: movie.monitored ? 'Unmonitored' : 'Monitored',
                    ),
                    onSearch: () => runMediaAction(
                      context,
                      action: () async {
                        final api = await ref.read(radarrApiProvider.future);
                        await api.search(movie.id);
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

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddMovieDialog(ref: ref),
    );
  }
}

class _MovieTile extends StatelessWidget {
  const _MovieTile({
    required this.movie,
    required this.onToggleMonitor,
    required this.onSearch,
  });

  final RadarrMovie movie;
  final VoidCallback onToggleMonitor;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final subtitle = [
      if (movie.year != null) '${movie.year}',
      if (movie.hasFile) formatBytes(movie.sizeOnDisk) else 'missing',
    ].join('  ·  ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrassPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            movie.hasFile ? Icons.check_circle : Icons.download_for_offline,
            color: movie.hasFile ? brass.ok : brass.ochre,
          ),
          title: Text(movie.title, overflow: TextOverflow.ellipsis),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: movie.monitored ? 'Unmonitor' : 'Monitor',
                icon: Icon(
                  movie.monitored ? Icons.bookmark : Icons.bookmark_border,
                  color: movie.monitored ? brass.copper : null,
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

/// Search-and-add dialog: type a title, pick a lookup result to add it to
/// Radarr (monitored + searched).
class _AddMovieDialog extends StatefulWidget {
  const _AddMovieDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_AddMovieDialog> createState() => _AddMovieDialogState();
}

class _AddMovieDialogState extends State<_AddMovieDialog> {
  final _controller = TextEditingController();
  List<RadarrMovie> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final term = _controller.text.trim();
    if (term.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = await widget.ref.read(radarrApiProvider.future);
      final results = await api.lookup(term);
      setState(() => _results = results);
    } on Object catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(RadarrMovie movie) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = await widget.ref.read(radarrApiProvider.future);
      await api.add(movie);
      widget.ref.invalidate(radarrMoviesProvider);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Added ${movie.title}')));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add movie'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search TMDb…',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null) Text(_error!),
            if (!_loading)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final movie in _results.take(20))
                      ListTile(
                        dense: true,
                        title: Text(
                          movie.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: movie.year == null
                            ? null
                            : Text('${movie.year}'),
                        trailing: const Icon(Icons.add),
                        onTap: () => _add(movie),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
