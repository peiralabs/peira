import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/seerr_api.dart';
import '../../core/providers/seerr_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/service_frame.dart';

/// Native Seerr (Jellyseerr / Overseerr) over its API key: discover
/// (trending, popular films and shows, upcoming, watchlist) and search with
/// availability, title details with per-season requests and issue reports;
/// the request queue with approve, decline, retry and delete; issues with
/// comments and resolve; and server status with its scheduled jobs.
class SeerrScreen extends ConsumerWidget {
  const SeerrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider).value;
    return ServiceFrame(
      service: 'Seerr',
      icon: Ph.compass,
      subtitle: 'DISCOVER AND REQUEST',
      url: s?.jellyseerrUrl ?? '',
      configured: s?.jellyseerrConfigured ?? false,
      credentialName: 'API key',
      child: const DefaultTabController(
        length: 4,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Discover'),
                Tab(text: 'Requests'),
                Tab(text: 'Issues'),
                Tab(text: 'Server'),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _DiscoverView(),
                  _RequestsView(),
                  _IssuesView(),
                  _ServerView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _act(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(SeerrApi api) body, {
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await body(await ref.read(seerrApiProvider.future));
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeServiceError(e))));
    return false;
  }
}

Color _statusColor(BuildContext context, int? s) => switch (s) {
  5 => context.brass.ok,
  4 || 3 || 2 => context.brass.giltBright,
  6 || 7 => context.brass.crit,
  _ => context.brass.textMuted,
};

class _Poster extends StatelessWidget {
  const _Poster({required this.url, this.width = 120});
  final String? url;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: url == null
            ? const ColoredBox(
                color: Colors.black26,
                child: Icon(Icons.movie_outlined),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Colors.black26,
                  child: Icon(Icons.movie_outlined),
                ),
              ),
      ),
    ),
  );
}

void _openTitle(BuildContext context, String mediaType, int tmdbId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (context, scroll) =>
            _TitleSheet(mediaType: mediaType, tmdbId: tmdbId, scroll: scroll),
      ),
    );

// ---------------------------------------------------------------- Discover

class _DiscoverView extends ConsumerStatefulWidget {
  const _DiscoverView();

  @override
  ConsumerState<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends ConsumerState<_DiscoverView>
    with AutomaticKeepAliveClientMixin {
  String _kind = 'trending';
  final _q = TextEditingController();
  String _query = '';
  int _page = 1;
  int _pages = 1;
  final _items = <SeerrTitle>[];
  bool _loading = false;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _items.clear();
      _page = 1;
      _error = null;
    }
    setState(() => _loading = true);
    try {
      final api = await ref.read(seerrApiProvider.future);
      final r = _query.isEmpty
          ? await api.discover(_kind, page: _page)
          : await api.search(_query, page: _page);
      if (!mounted) return;
      setState(() {
        _items.addAll(r.results);
        _pages = r.pages;
        _page++;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final brass = context.brass;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _q,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search films and shows',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _q.clear();
                              _query = '';
                              _load(reset: true);
                            },
                          ),
                  ),
                  onSubmitted: (v) {
                    _query = v.trim();
                    _load(reset: true);
                  },
                ),
              ),
              if (_query.isEmpty)
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'trending', label: Text('Trending')),
                    ButtonSegment(value: 'movies', label: Text('Films')),
                    ButtonSegment(value: 'tv', label: Text('Shows')),
                    ButtonSegment(value: 'upcoming', label: Text('Upcoming')),
                    ButtonSegment(value: 'watchlist', label: Text('Watchlist')),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (v) {
                    _kind = v.single;
                    _load(reset: true);
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _error != null && _items.isEmpty
              ? ServiceError(error: _error!, onRetry: () => _load(reset: true))
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 160,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.52,
                            ),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final t = _items[i];
                          return InkWell(
                            key: ValueKey('sr-${t.mediaType}-${t.tmdbId}'),
                            onTap: () =>
                                _openTitle(context, t.mediaType, t.tmdbId),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Poster(url: t.posterUrl, width: 160),
                                const SizedBox(height: 4),
                                Text(
                                  t.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${t.mediaType == 'tv' ? 'Show' : 'Film'}'
                                  '${t.year == null ? '' : ' · ${t.year}'}',
                                  style: TextStyle(
                                    color: brass.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (t.status != null && t.status! > 1)
                                  Text(
                                    seerrMediaStatus(t.status),
                                    style: TextStyle(
                                      color: _statusColor(context, t.status),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: _loading
                              ? const CircularProgressIndicator()
                              : _page <= _pages && _items.isNotEmpty
                              ? OutlinedButton(
                                  onPressed: _load,
                                  child: const Text('Load more'),
                                )
                              : _items.isEmpty
                              ? const Text('Nothing found.')
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TitleSheet extends ConsumerStatefulWidget {
  const _TitleSheet({
    required this.mediaType,
    required this.tmdbId,
    required this.scroll,
  });
  final String mediaType;
  final int tmdbId;
  final ScrollController scroll;

  @override
  ConsumerState<_TitleSheet> createState() => _TitleSheetState();
}

class _TitleSheetState extends ConsumerState<_TitleSheet> {
  final _seasons = <int>{};
  bool _is4k = false;

  void _refresh() =>
      ref.invalidate(seerrDetailsProvider(widget.mediaType, widget.tmdbId));

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(
      seerrDetailsProvider(widget.mediaType, widget.tmdbId),
    );
    final brass = context.brass;
    return details.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(error: e, onRetry: _refresh),
      data: (d) {
        final t = d.title;
        final requestable = t.status == null || t.status == 1 || t.status == 7;
        final isTv = widget.mediaType == 'tv';
        return ListView(
          controller: widget.scroll,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Poster(url: t.posterUrl, width: 160),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.title}${t.year == null ? '' : ' (${t.year})'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (d.tagline.isNotEmpty)
                        Text(
                          d.tagline,
                          style: TextStyle(
                            color: brass.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          isTv ? 'Show' : 'Film',
                          if (d.runtime != null) '${d.runtime} min',
                          ...d.genres.take(3),
                          if (t.vote != null) '★ ${t.vote!.toStringAsFixed(1)}',
                        ].join('  ·  '),
                        style: TextStyle(color: brass.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        seerrMediaStatus(t.status),
                        style: TextStyle(
                          color: _statusColor(context, t.status),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(t.overview),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isTv && d.seasons.isNotEmpty) ...[
              Text('Seasons', style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in d.seasons)
                    FilterChip(
                      label: Text('${s.name} (${s.episodes})'),
                      selected: _seasons.contains(s.number),
                      onSelected: (v) => setState(
                        () => v
                            ? _seasons.add(s.number)
                            : _seasons.remove(s.number),
                      ),
                    ),
                ],
              ),
              Text(
                _seasons.isEmpty ? 'No seasons picked: requests all.' : '',
                style: TextStyle(color: brass.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add_task),
                  label: Text(
                    isTv && _seasons.isNotEmpty
                        ? 'Request ${_seasons.length} season(s)'
                        : 'Request',
                  ),
                  onPressed: !requestable && !isTv
                      ? null
                      : () async {
                          if (await _act(
                            context,
                            ref,
                            (api) => api.request(
                              widget.mediaType,
                              widget.tmdbId,
                              seasons: _seasons.toList()..sort(),
                              is4k: _is4k,
                            ),
                            done: 'Requested',
                          )) {
                            _refresh();
                            ref.invalidate(seerrRequestsProvider);
                          }
                        },
                ),
                FilterChip(
                  label: const Text('4K'),
                  selected: _is4k,
                  onSelected: (v) => setState(() => _is4k = v),
                ),
                if (t.mediaId != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.report_outlined),
                    label: const Text('Report an issue'),
                    onPressed: () => _report(t.mediaId!),
                  ),
                if (t.mediaId != null && t.status != 5)
                  OutlinedButton(
                    onPressed: () async {
                      await _act(
                        context,
                        ref,
                        (api) => api.setMediaStatus(t.mediaId!, 'available'),
                        done: 'Marked available',
                      );
                      _refresh();
                    },
                    child: const Text('Mark available'),
                  ),
                if (t.mediaId != null)
                  OutlinedButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Seerr data?'),
                          content: const Text(
                            'Removes Seerr\'s record and requests for this '
                            'title. Files in Radarr/Sonarr are not touched.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true || !context.mounted) return;
                      await _act(
                        context,
                        ref,
                        (api) => api.deleteMedia(t.mediaId!),
                        done: 'Cleared',
                      );
                      _refresh();
                      ref.invalidate(seerrRequestsProvider);
                    },
                    child: const Text('Clear data'),
                  ),
                IconButton(
                  tooltip: 'Open in Seerr',
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final api = await ref.read(seerrApiProvider.future);
                    if (context.mounted) {
                      await openInBrowser(
                        context,
                        api.webUrl(widget.mediaType, widget.tmdbId),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _report(int mediaId) async {
    var type = 1;
    final msg = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Report an issue'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Problem with'),
                  items: [
                    for (final e in seerrIssueTypes.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setLocal(() => type = v ?? 1),
                ),
                TextField(
                  controller: msg,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'What is wrong'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
    final text = msg.text.trim();
    msg.dispose();
    if (ok != true || text.isEmpty || !mounted) return;
    await _act(
      context,
      ref,
      (api) => api.reportIssue(mediaId, type, text),
      done: 'Issue reported',
    );
    ref.invalidate(seerrIssuesProvider);
  }
}

// ---------------------------------------------------------------- Requests

class _RequestsView extends ConsumerStatefulWidget {
  const _RequestsView();

  @override
  ConsumerState<_RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends ConsumerState<_RequestsView> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final reqs = ref.watch(seerrRequestsProvider(_filter));
    final brass = context.brass;
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              for (final f in const [
                'all',
                'pending',
                'approved',
                'processing',
                'available',
                'completed',
                'failed',
                'unavailable',
                'deleted',
              ]) ...[
                ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        Expanded(
          child: reqs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ServiceError(
              error: e,
              onRetry: () => ref.invalidate(seerrRequestsProvider(_filter)),
            ),
            data: (r) => r.requests.isEmpty
                ? const Center(child: Text('No requests here.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
                    children: [
                      Text(
                        '${r.total} requests'
                        '${r.total > r.requests.length ? ' (newest ${r.requests.length})' : ''}',
                        style: TextStyle(color: brass.textMuted),
                      ),
                      for (final q in r.requests) _RequestTile(request: q),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile({required this.request});
  final SeerrRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = request;
    final t = ref
        .watch(seerrDetailsProvider(q.mediaType, q.tmdbId))
        .value
        ?.title;
    final brass = context.brass;
    Future<void> run(Future<void> Function(SeerrApi) f, String done) async {
      await _act(context, ref, f, done: done);
      ref.invalidate(seerrRequestsProvider);
      ref.invalidate(seerrCountsProvider);
    }

    return ListTile(
      key: ValueKey('req-${q.id}'),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: _Poster(url: t?.posterUrl, width: 40),
      title: Text(
        t == null
            ? '${q.mediaType} ${q.tmdbId}'
            : '${t.title} (${t.year ?? '?'})',
      ),
      subtitle: Text(
        [
          seerrRequestStatus(q.status),
          seerrMediaStatus(q.mediaStatus),
          if (q.seasons.isNotEmpty) 'seasons ${q.seasons.join(', ')}',
          if (q.is4k) '4K',
          'by ${q.requestedBy}',
          if (q.created != null)
            q.created!.toLocal().toString().substring(0, 10),
        ].join('  ·  '),
        style: TextStyle(color: brass.textMuted, fontSize: 12),
      ),
      onTap: () => _openTitle(context, q.mediaType, q.tmdbId),
      trailing: Wrap(
        children: [
          if (q.status == 1) ...[
            IconButton(
              tooltip: 'Approve',
              icon: Icon(Icons.check_circle_outline, color: brass.ok),
              onPressed: () =>
                  run((api) => api.setRequest(q.id, 'approve'), 'Approved'),
            ),
            IconButton(
              tooltip: 'Decline',
              icon: Icon(Icons.cancel_outlined, color: brass.crit),
              onPressed: () =>
                  run((api) => api.setRequest(q.id, 'decline'), 'Declined'),
            ),
          ],
          if (q.status == 4)
            IconButton(
              tooltip: 'Retry',
              icon: const Icon(Icons.replay),
              onPressed: () => run((api) => api.retryRequest(q.id), 'Retrying'),
            ),
          IconButton(
            tooltip: 'Delete request',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete this request?'),
                  content: const Text(
                    'Removes the request from Seerr; downloaded files stay.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await run((api) => api.deleteRequest(q.id), 'Request deleted');
              }
            },
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Issues

class _IssuesView extends ConsumerStatefulWidget {
  const _IssuesView();

  @override
  ConsumerState<_IssuesView> createState() => _IssuesViewState();
}

class _IssuesViewState extends ConsumerState<_IssuesView> {
  String _filter = 'open';

  @override
  Widget build(BuildContext context) {
    final issues = ref.watch(seerrIssuesProvider(_filter));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'open', label: Text('Open')),
                ButtonSegment(value: 'resolved', label: Text('Resolved')),
                ButtonSegment(value: 'all', label: Text('All')),
              ],
              selected: {_filter},
              onSelectionChanged: (v) => setState(() => _filter = v.single),
            ),
          ),
        ),
        Expanded(
          child: issues.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ServiceError(
              error: e,
              onRetry: () => ref.invalidate(seerrIssuesProvider(_filter)),
            ),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No issues.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    children: [for (final i in list) _IssueCard(issue: i)],
                  ),
          ),
        ),
      ],
    );
  }
}

class _IssueCard extends ConsumerWidget {
  const _IssueCard({required this.issue});
  final SeerrIssue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = issue;
    final t = ref
        .watch(seerrDetailsProvider(i.mediaType, i.tmdbId))
        .value
        ?.title;
    final brass = context.brass;
    void refresh() => ref.invalidate(seerrIssuesProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BrassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${seerrIssueTypes[i.type] ?? 'Other'} issue · ${t?.title ?? i.tmdbId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${i.open ? 'Open' : 'Resolved'} · by ${i.createdBy}',
              style: TextStyle(color: brass.textMuted),
            ),
            for (final c in i.comments)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${c.user}: ${c.message}'),
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () async {
                    final c = TextEditingController();
                    final v = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Comment'),
                        content: TextField(
                          controller: c,
                          maxLines: 3,
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(context, c.text.trim()),
                            child: const Text('Post'),
                          ),
                        ],
                      ),
                    );
                    c.dispose();
                    if (v == null || v.isEmpty || !context.mounted) return;
                    await _act(
                      context,
                      ref,
                      (api) => api.commentIssue(i.id, v),
                    );
                    refresh();
                  },
                  child: const Text('Comment'),
                ),
                TextButton(
                  onPressed: () async {
                    await _act(
                      context,
                      ref,
                      (api) => api.setIssue(i.id, i.open ? 'resolved' : 'open'),
                    );
                    refresh();
                  },
                  child: Text(i.open ? 'Resolve' : 'Reopen'),
                ),
                TextButton(
                  onPressed: () async {
                    await _act(context, ref, (api) => api.deleteIssue(i.id));
                    refresh();
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Server

class _ServerView extends ConsumerStatefulWidget {
  const _ServerView();

  @override
  ConsumerState<_ServerView> createState() => _ServerViewState();
}

class _ServerViewState extends ConsumerState<_ServerView> {
  late Future<
    (
      Map<String, dynamic>,
      List<({String id, String name, bool running, DateTime? next})>,
    )
  >
  _data = _fetch();

  Future<
    (
      Map<String, dynamic>,
      List<({String id, String name, bool running, DateTime? next})>,
    )
  >
  _fetch() async {
    final api = await ref.read(seerrApiProvider.future);
    return (await api.status(), await api.jobs());
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(seerrCountsProvider).value ?? const {};
    final brass = context.brass;
    return FutureBuilder(
      future: _data,
      builder: (context, snap) {
        if (snap.hasError) {
          return ServiceError(
            error: snap.error!,
            onRetry: () => setState(() => _data = _fetch()),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (status, jobs) = snap.data!;
        Widget kv(String k, Object? v) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: TextStyle(color: brass.textMuted, fontSize: 12)),
            Text('${v ?? 0}', style: Theme.of(context).textTheme.titleMedium),
          ],
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          children: [
            BrassPanel(
              child: Wrap(
                spacing: 32,
                runSpacing: 12,
                children: [
                  kv('Version', status['version']),
                  kv(
                    'Update',
                    status['updateAvailable'] == true ? 'available' : 'none',
                  ),
                  kv('Requests', counts['total']),
                  kv('Pending', counts['pending']),
                  kv('Processing', counts['processing']),
                  kv('Completed', counts['completed']),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Scheduled jobs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final j in jobs)
              ListTile(
                dense: true,
                title: Text(j.name),
                subtitle: Text(
                  j.running
                      ? 'running'
                      : j.next == null
                      ? ''
                      : 'next ${j.next!.toLocal().toString().substring(0, 16)}',
                ),
                trailing: TextButton(
                  onPressed: j.running
                      ? null
                      : () async {
                          await _act(
                            context,
                            ref,
                            (api) => api.runJob(j.id),
                            done: '${j.name} started',
                          );
                          setState(() => _data = _fetch());
                        },
                  child: const Text('Run now'),
                ),
              ),
          ],
        );
      },
    );
  }
}
