import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/prowlarr_indexer.dart';
import '../../core/models/prowlarr_release.dart';
import '../../core/providers/media_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import 'media_common.dart';

/// Prowlarr — configured indexers plus an ad-hoc cross-indexer release search.
class ProwlarrTab extends ConsumerStatefulWidget {
  const ProwlarrTab({super.key});

  @override
  ConsumerState<ProwlarrTab> createState() => _ProwlarrTabState();
}

class _ProwlarrTabState extends ConsumerState<ProwlarrTab> {
  final _controller = TextEditingController();
  List<ProwlarrRelease>? _results;
  bool _searching = false;
  String? _searchError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final term = _controller.text.trim();
    if (term.isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final api = await ref.read(prowlarrApiProvider.future);
      final results = await api.search(term);
      setState(() => _results = results);
    } on Object catch (e) {
      setState(() => _searchError = '$e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indexers = ref.watch(prowlarrIndexersProvider);

    return indexers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => mediaAsyncState(
        context: context,
        error: e,
        onRetry: () => ref.invalidate(prowlarrIndexersProvider),
      ),
      data: (list) {
        final enabled = list.where((i) => i.enable).length;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(prowlarrIndexersProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              mediaSummary(context, [
                ('Indexers', '${list.length}'),
                ('Enabled', '$enabled'),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search all indexers…',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _search,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),
              if (_searching)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )),
              if (_searchError != null) Text('Search failed: $_searchError'),
              if (_results != null && !_searching) ...[
                MediaSectionTitle('Results (${_results!.length})'),
                const SizedBox(height: 8),
                for (final r in _results!.take(50)) _ReleaseTile(release: r),
                const SizedBox(height: 8),
              ],
              const MediaSectionTitle('Indexers'),
              const SizedBox(height: 8),
              for (final indexer in list) _IndexerTile(indexer: indexer),
            ],
          ),
        );
      },
    );
  }
}

class _IndexerTile extends StatelessWidget {
  const _IndexerTile({required this.indexer});
  final ProwlarrIndexer indexer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrassPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            indexer.enable ? Icons.check_circle : Icons.pause_circle_outline,
            color: indexer.enable
                ? context.brass.ok
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: Text(indexer.name, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              indexer.protocol ?? '',
              if (indexer.priority != null) 'priority ${indexer.priority}',
            ].where((s) => s.isNotEmpty).join('  ·  '),
          ),
        ),
      ),
    );
  }
}

class _ReleaseTile extends StatelessWidget {
  const _ReleaseTile({required this.release});
  final ProwlarrRelease release;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final seedColor = release.seeders <= 0
        ? brass.crit
        : release.seeders < 5
            ? brass.ochre
            : brass.ok;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(release.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.arrow_upward, size: 14, color: seedColor),
                Text(
                  ' ${release.seeders}',
                  style: TextStyle(color: seedColor),
                ),
                const SizedBox(width: 12),
                Text(
                  formatBytes(release.size),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (release.indexer != null)
                  Flexible(
                    child: Text(
                      release.indexer!,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
