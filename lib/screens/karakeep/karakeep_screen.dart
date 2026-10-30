import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/karakeep_api.dart';
import '../../core/providers/karakeep_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/mechanical.dart';
import '../../core/widgets/service_frame.dart';

/// Native Karakeep over its REST API and an API key: bookmarks with
/// favourite/archive filters, full-text / semantic / hybrid search, adding
/// links and notes, per-bookmark tags, lists, notes, AI summaries and
/// highlights, plus tag, list and RSS-feed management and usage stats.
/// Reading archived pages stays in Karakeep's web UI ("Open in browser").
class KarakeepScreen extends ConsumerWidget {
  const KarakeepScreen({super.key});

  static const views = [
    'Bookmarks',
    'Search',
    'Tags',
    'Lists',
    'Highlights',
    'Feeds',
    'Stats',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider).value;
    return ServiceFrame(
      service: 'Karakeep',
      icon: Ph.bookmarkSimple,
      subtitle: 'BOOKMARKS AND READ-LATER',
      url: s?.karakeepUrl ?? '',
      configured: s?.karakeepConfigured ?? false,
      credentialName: 'API key',
      child: DefaultTabController(
        length: views.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final v in views) Tab(text: v)],
            ),
            const SizedBox(height: 8),
            const Expanded(
              child: TabBarView(
                children: [
                  _BookmarksView(),
                  _SearchView(),
                  _TagsView(),
                  _ListsView(),
                  _HighlightsView(),
                  _FeedsView(),
                  _StatsView(),
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
  Future<void> Function(KarakeepApi api) body, {
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await body(await ref.read(karakeepApiProvider.future));
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeServiceError(e))));
    return false;
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
    ) ??
    false;

Future<String?> _ask(
  BuildContext context,
  String title,
  String label, {
  String initial = '',
  int lines = 1,
}) async {
  final c = TextEditingController(text: initial);
  final v = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 460,
        child: TextField(
          controller: c,
          autofocus: true,
          maxLines: lines,
          decoration: InputDecoration(labelText: label),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, c.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  c.dispose();
  final t = v?.trim() ?? '';
  return t.isEmpty ? null : t;
}

/// A cursor-paged bookmark list. [load] fetches the page after [cursor].
class _BookmarkList extends ConsumerStatefulWidget {
  const _BookmarkList({
    super.key,
    required this.load,
    this.header,
    this.empty = 'No bookmarks.',
  });
  final Future<KkPage> Function(KarakeepApi api, String? cursor) load;
  final Widget? header;
  final String empty;

  @override
  ConsumerState<_BookmarkList> createState() => _BookmarkListState();
}

class _BookmarkListState extends ConsumerState<_BookmarkList> {
  final _items = <KkBookmark>[];
  String? _cursor;
  bool _done = false;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _more();
  }

  void reload() {
    setState(() {
      _items.clear();
      _cursor = null;
      _done = false;
      _error = null;
    });
    _more();
  }

  Future<void> _more() async {
    if (_done || _loading) return;
    setState(() => _loading = true);
    try {
      final page = await widget.load(
        await ref.read(karakeepApiProvider.future),
        _cursor,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.bookmarks);
        _cursor = page.nextCursor;
        _done = page.nextCursor == null;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return ServiceError(error: _error!, onRetry: reload);
    }
    return RefreshIndicator(
      onRefresh: () async => reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          if (widget.header != null) ...[
            widget.header!,
            const SizedBox(height: 10),
          ],
          if (_items.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(widget.empty)),
            ),
          for (final b in _items) _BookmarkTile(bookmark: b, onChanged: reload),
          const SizedBox(height: 10),
          Center(
            child: _loading
                ? const CircularProgressIndicator()
                : !_done
                ? OutlinedButton(
                    onPressed: _more,
                    child: const Text('Load more'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends ConsumerWidget {
  const _BookmarkTile({required this.bookmark, required this.onChanged});
  final KkBookmark bookmark;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = bookmark;
    final brass = context.brass;
    final host = b.url == null ? null : Uri.tryParse(b.url!)?.host;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrassPanel(
        padding: EdgeInsets.zero,
        screws: true,
        child: ListTile(
          key: ValueKey('kk-${b.id}'),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: SizedBox(
            width: 64,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: b.imageUrl == null
                  ? Icon(
                      b.kind == 'text'
                          ? Icons.notes
                          : b.kind == 'asset'
                          ? Icons.attach_file
                          : Icons.link,
                      color: brass.textMuted,
                    )
                  : Image.network(
                      b.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.link, color: brass.textMuted),
                    ),
            ),
          ),
          title: Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              ?host,
              if (b.tags.isNotEmpty) b.tags.map((t) => '#${t.name}').join(' '),
            ].join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: brass.textMuted, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: b.favourited ? 'Unfavourite' : 'Favourite',
                icon: Icon(b.favourited ? Icons.star : Icons.star_border),
                onPressed: () async {
                  if (await _act(
                    context,
                    ref,
                    (api) => api.updateBookmark(b.id, favourited: !b.favourited),
                  )) {
                    onChanged();
                  }
                },
              ),
              IconButton(
                tooltip: b.archived ? 'Unarchive' : 'Archive',
                icon: Icon(
                  b.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
                ),
                onPressed: () async {
                  if (await _act(
                    context,
                    ref,
                    (api) => api.updateBookmark(b.id, archived: !b.archived),
                  )) {
                    onChanged();
                  }
                },
              ),
            ],
          ),
          onTap: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.8,
                builder: (context, scroll) =>
                    _BookmarkDetail(id: b.id, scroll: scroll),
              ),
            );
            onChanged();
          },
    ),
      ),
    );
  }
}

class _BookmarkDetail extends ConsumerWidget {
  const _BookmarkDetail({required this.id, required this.scroll});
  final String id;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bm = ref.watch(kkBookmarkProvider(id));
    final brass = context.brass;
    void refresh() => ref.invalidate(kkBookmarkProvider(id));
    return bm.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(error: e, onRetry: refresh),
      data: (b) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        children: [
          Text(b.title, style: Theme.of(context).textTheme.titleLarge),
          if (b.url != null)
            InkWell(
              onTap: () => openInBrowser(context, b.url!),
              child: Text(b.url!, style: TextStyle(color: brass.giltBright)),
            ),
          if (b.created != null)
            Text(
              'Saved ${b.created!.toLocal().toString().substring(0, 16)}'
              '${b.taggingStatus == 'pending' ? ' · AI tagging pending' : ''}',
              style: TextStyle(color: brass.textMuted),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: Icon(b.favourited ? Icons.star : Icons.star_border),
                label: Text(b.favourited ? 'Favourited' : 'Favourite'),
                onPressed: () async {
                  await _act(
                    context,
                    ref,
                    (api) =>
                        api.updateBookmark(b.id, favourited: !b.favourited),
                  );
                  refresh();
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.archive_outlined),
                label: Text(b.archived ? 'Unarchive' : 'Archive'),
                onPressed: () async {
                  await _act(
                    context,
                    ref,
                    (api) => api.updateBookmark(b.id, archived: !b.archived),
                  );
                  refresh();
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Title'),
                onPressed: () async {
                  final t = await _ask(
                    context,
                    'Title',
                    'Title',
                    initial: b.title,
                  );
                  if (t == null || !context.mounted) return;
                  await _act(
                    context,
                    ref,
                    (api) => api.updateBookmark(b.id, title: t),
                  );
                  refresh();
                },
              ),
              if (b.kind == 'link')
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Summarise'),
                  onPressed: () async {
                    await _act(
                      context,
                      ref,
                      (api) => api.summarize(b.id),
                      done: 'Summary ready',
                    );
                    refresh();
                  },
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.playlist_add),
                label: const Text('Lists'),
                onPressed: () => _editLists(context, ref, b),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in Karakeep'),
                onPressed: () async {
                  final api = await ref.read(karakeepApiProvider.future);
                  if (context.mounted) {
                    await openInBrowser(context, api.webUrl(b.id));
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                onPressed: () async {
                  if (!await _confirm(
                        context,
                        'Delete this bookmark?',
                        '${b.title} is removed with its archive.',
                      ) ||
                      !context.mounted) {
                    return;
                  }
                  if (await _act(
                        context,
                        ref,
                        (api) => api.deleteBookmark(b.id),
                        done: 'Deleted',
                      ) &&
                      context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Tags', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in b.tags)
                InputChip(
                  label: Text(t.name),
                  avatar: t.attachedBy == 'ai'
                      ? const Icon(Icons.auto_awesome, size: 14)
                      : null,
                  onDeleted: () async {
                    await _act(
                      context,
                      ref,
                      (api) => api.detachTag(b.id, t.id),
                    );
                    refresh();
                  },
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Add tag'),
                onPressed: () async {
                  final t = await _ask(
                    context,
                    'Add tags',
                    'Tag names, comma separated',
                  );
                  if (t == null || !context.mounted) return;
                  await _act(
                    context,
                    ref,
                    (api) => api.attachTags(b.id, [
                      for (final n in t.split(','))
                        if (n.trim().isNotEmpty) n.trim(),
                    ]),
                  );
                  refresh();
                  ref.invalidate(kkTagsProvider);
                },
              ),
            ],
          ),
          if (b.summary != null) ...[
            const SizedBox(height: 14),
            Text('Summary', style: Theme.of(context).textTheme.titleMedium),
            SelectableText(b.summary!),
          ],
          if (b.description != null) ...[
            const SizedBox(height: 14),
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            SelectableText(b.description!),
          ],
          if (b.text != null) ...[
            const SizedBox(height: 14),
            Text('Note text', style: Theme.of(context).textTheme.titleMedium),
            SelectableText(b.text!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Your note', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                tooltip: 'Edit note',
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () async {
                  final n = await _ask(
                    context,
                    'Note',
                    'Note',
                    initial: b.note ?? '',
                    lines: 5,
                  );
                  if (n == null || !context.mounted) return;
                  await _act(
                    context,
                    ref,
                    (api) => api.updateBookmark(b.id, note: n),
                  );
                  refresh();
                },
              ),
            ],
          ),
          Text(
            b.note ?? 'No note.',
            style: b.note == null ? TextStyle(color: brass.textMuted) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _editLists(
    BuildContext context,
    WidgetRef ref,
    KkBookmark b,
  ) async {
    final api = await ref.read(karakeepApiProvider.future);
    final List<KkList> lists;
    final Set<String> member;
    try {
      lists = [
        for (final l in await api.lists())
          if (l.type == 'manual') l,
      ];
      member = (await api.bookmarkListIds(b.id)).toSet();
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(describeServiceError(e))));
      }
      return;
    }
    if (!context.mounted) return;
    final picked = Set<String>.of(member);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Lists'),
          content: SizedBox(
            width: 360,
            child: lists.isEmpty
                ? const Text('No manual lists yet. Create one in Lists.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final l in lists)
                        CheckboxListTile(
                          value: picked.contains(l.id),
                          title: Text('${l.icon} ${l.name}'),
                          onChanged: (v) => setLocal(
                            () => v == true
                                ? picked.add(l.id)
                                : picked.remove(l.id),
                          ),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    await _act(context, ref, (api) async {
      for (final id in picked.difference(member)) {
        await api.addToList(id, b.id);
      }
      for (final id in member.difference(picked)) {
        await api.removeFromList(id, b.id);
      }
    }, done: 'Lists updated');
  }
}

// --------------------------------------------------------------- Bookmarks

enum _Shelf { all, favourites, archived }

class _BookmarksView extends ConsumerStatefulWidget {
  const _BookmarksView();

  @override
  ConsumerState<_BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends ConsumerState<_BookmarksView>
    with AutomaticKeepAliveClientMixin {
  _Shelf _shelf = _Shelf.all;
  final _list = GlobalKey<_BookmarkListState>();

  @override
  bool get wantKeepAlive => true;

  Future<void> _add(bool link) async {
    final v = await _ask(
      context,
      link ? 'Save a link' : 'New note',
      link ? 'URL' : 'Text',
      lines: link ? 1 : 6,
    );
    if (v == null || !mounted) return;
    if (await _act(
      context,
      ref,
      (api) => link ? api.addLink(v) : api.addNote(v),
      done: link ? 'Saved; Karakeep is crawling it' : 'Note saved',
    )) {
      _list.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _BookmarkList(
      key: _list,
      header: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<_Shelf>(
            segments: const [
              ButtonSegment(value: _Shelf.all, label: Text('All')),
              ButtonSegment(
                value: _Shelf.favourites,
                label: Text('Favourites'),
              ),
              ButtonSegment(value: _Shelf.archived, label: Text('Archived')),
            ],
            selected: {_shelf},
            onSelectionChanged: (v) {
              setState(() => _shelf = v.single);
              _list.currentState?.reload();
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add_link),
            label: const Text('Save link'),
            onPressed: () => _add(true),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('New note'),
            onPressed: () => _add(false),
          ),
        ],
      ),
      empty: 'No bookmarks here yet.',
      load: (api, cursor) => api.bookmarks(
        cursor: cursor,
        favourited: _shelf == _Shelf.favourites ? true : null,
        archived: switch (_shelf) {
          _Shelf.archived => true,
          _Shelf.all => false,
          _Shelf.favourites => null,
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ Search

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView>
    with AutomaticKeepAliveClientMixin {
  final _q = TextEditingController();
  String _mode = 'hybrid';
  String _query = '';
  int _gen = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _run() => setState(() {
    _query = _q.text.trim();
    _gen++;
  });

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search bookmarks (supports is:fav, #tag, url:…)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _run(),
                ),
              ),
              const SizedBox(width: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'fts', label: Text('Text')),
                  ButtonSegment(value: 'semantic', label: Text('Meaning')),
                  ButtonSegment(value: 'hybrid', label: Text('Both')),
                ],
                selected: {_mode},
                onSelectionChanged: (v) {
                  setState(() => _mode = v.single);
                  if (_query.isNotEmpty) _run();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? const Center(child: Text('Search your bookmarks.'))
              : _BookmarkList(
                  key: ValueKey('$_gen-$_mode'),
                  empty: 'No matches.',
                  load: (api, cursor) =>
                      api.search(_query, mode: _mode, cursor: cursor),
                ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------- Tags

class _TagsView extends ConsumerWidget {
  const _TagsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(kkTagsProvider);
    return tags.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          ServiceError(error: e, onRetry: () => ref.invalidate(kkTagsProvider)),
      data: (list) => list.isEmpty
          ? const Center(child: Text('No tags yet.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                for (final t in list)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.sell_outlined, size: 18),
                    title: Text(t.name),
                    subtitle: Text('${t.count ?? 0} bookmarks'),
                    onTap: () => _open(
                      context,
                      '#${t.name}',
                      (api, c) => api.tagBookmarks(t.id, cursor: c),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'rename') {
                          final n = await _ask(
                            context,
                            'Rename tag',
                            'Name',
                            initial: t.name,
                          );
                          if (n == null || !context.mounted) return;
                          await _act(
                            context,
                            ref,
                            (api) => api.renameTag(t.id, n),
                          );
                        } else {
                          if (!await _confirm(
                                context,
                                'Delete #${t.name}?',
                                'The tag is removed from ${t.count ?? 0} '
                                    'bookmarks; the bookmarks stay.',
                              ) ||
                              !context.mounted) {
                            return;
                          }
                          await _act(
                            context,
                            ref,
                            (api) => api.deleteTag(t.id),
                          );
                        }
                        ref.invalidate(kkTagsProvider);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

void _open(
  BuildContext context,
  String title,
  Future<KkPage> Function(KarakeepApi api, String? cursor) load,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _BookmarkList(load: load),
    ),
  ),
);

// ------------------------------------------------------------------- Lists

class _ListsView extends ConsumerWidget {
  const _ListsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(kkListsProvider);
    return lists.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(kkListsProvider),
      ),
      data: (all) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          Wrap(
            spacing: 10,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New list'),
                onPressed: () async {
                  final n = await _ask(context, 'New list', 'Name');
                  if (n == null || !context.mounted) return;
                  await _act(context, ref, (api) => api.createList(n));
                  ref.invalidate(kkListsProvider);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('New smart list'),
                onPressed: () async {
                  final n = await _ask(context, 'Smart list', 'Name');
                  if (n == null || !context.mounted) return;
                  final q = await _ask(
                    context,
                    'Smart list query',
                    'Search query, e.g. #homelab is:fav',
                  );
                  if (q == null || !context.mounted) return;
                  await _act(
                    context,
                    ref,
                    (api) => api.createList(n, icon: '✨', query: q),
                  );
                  ref.invalidate(kkListsProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (all.isEmpty) const Center(child: Text('No lists yet.')),
          for (final l in all)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BrassPanel(
                padding: EdgeInsets.zero,
                screws: true,
                child: ListTile(
                  leading: Text(l.icon, style: const TextStyle(fontSize: 22)),
                  title: Text(l.name),
                  subtitle: Text(
                    l.type == 'smart' ? 'Smart: ${l.query ?? ''}' : 'Manual list',
                  ),
                  onTap: () => _open(
                    context,
                    l.name,
                    (api, c) => api.listBookmarks(l.id, cursor: c),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'rename') {
                        final n = await _ask(
                          context,
                          'Rename list',
                          'Name',
                          initial: l.name,
                        );
                        if (n == null || !context.mounted) return;
                        await _act(
                          context,
                          ref,
                          (api) => api.updateList(l.id, name: n),
                        );
                      } else {
                        if (!await _confirm(
                              context,
                              'Delete ${l.name}?',
                              'The list is removed; its bookmarks stay.',
                            ) ||
                            !context.mounted) {
                          return;
                        }
                        await _act(context, ref, (api) => api.deleteList(l.id));
                      }
                      ref.invalidate(kkListsProvider);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
            ),
              ),
            ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Highlights

class _HighlightsView extends ConsumerWidget {
  const _HighlightsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hl = ref.watch(kkHighlightsProvider);
    return hl.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(kkHighlightsProvider),
      ),
      data: (list) => list.isEmpty
          ? const Center(
              child: Text(
                'No highlights. Highlight text in Karakeep\'s reader.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                for (final h in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BrassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText('“${h.text}”'),
                          if (h.note != null && h.note!.isNotEmpty)
                            Text(
                              h.note!,
                              style: TextStyle(color: context.brass.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ------------------------------------------------------------------- Feeds

class _FeedsView extends ConsumerWidget {
  const _FeedsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeds = ref.watch(kkFeedsProvider);
    final brass = context.brass;
    return feeds.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(kkFeedsProvider),
      ),
      data: (list) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          Text(
            'RSS feeds Karakeep polls; new entries become bookmarks.',
            style: TextStyle(color: brass.textMuted),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.rss_feed),
              label: const Text('Add feed'),
              onPressed: () async {
                final url = await _ask(context, 'Add feed', 'Feed URL');
                if (url == null || !context.mounted) return;
                final name = await _ask(
                  context,
                  'Feed name',
                  'Name',
                  initial: Uri.tryParse(url)?.host ?? url,
                );
                if (name == null || !context.mounted) return;
                await _act(context, ref, (api) => api.addFeed(name, url));
                ref.invalidate(kkFeedsProvider);
              },
            ),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty) const Center(child: Text('No feeds.')),
          for (final f in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BrassPanel(
                padding: EdgeInsets.zero,
                screws: true,
                child: ListTile(
                  title: Text(f.name),
                  subtitle: Text(
                    '${f.url}\n'
                    '${f.lastFetched == null ? 'Never fetched' : 'Last fetch ${f.lastFetched!.toLocal().toString().substring(0, 16)} · ${f.lastStatus ?? ''}'}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrassToggle(
                        value: f.enabled,
                        onChanged: (v) async {
                          await _act(
                            context,
                            ref,
                            (api) => api.setFeedEnabled(f.id, v),
                          );
                          ref.invalidate(kkFeedsProvider);
                        },
                      ),
                      KnurledKnob(
                        icon: Ph.arrowsClockwise,
                        tooltip: 'Fetch now',
                        size: 26,
                        onPressed: () => _act(
                          context,
                          ref,
                          (api) => api.fetchFeed(f.id),
                          done: 'Fetch queued',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete feed',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (!await _confirm(
                                context,
                                'Delete ${f.name}?',
                                'Bookmarks it already created stay.',
                              ) ||
                              !context.mounted) {
                            return;
                          }
                          await _act(context, ref, (api) => api.deleteFeed(f.id));
                          ref.invalidate(kkFeedsProvider);
                        },
                      ),
                    ],
                  ),
            ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- Stats

class _StatsView extends ConsumerWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(kkStatsProvider);
    final brass = context.brass;
    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(kkStatsProvider),
      ),
      data: (s) {
        Widget n(String label, String key) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: brass.textMuted, fontSize: 12)),
            Text(
              '${s[key] ?? 0}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        );
        final domains = (s['topDomains'] as List?) ?? const [];
        final size = (s['totalAssetSize'] as num?) ?? 0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          children: [
            BrassPanel(
              child: Wrap(
                spacing: 32,
                runSpacing: 12,
                children: [
                  n('Bookmarks', 'numBookmarks'),
                  n('Favourites', 'numFavorites'),
                  n('Archived', 'numArchived'),
                  n('Tags', 'numTags'),
                  n('Lists', 'numLists'),
                  n('Highlights', 'numHighlights'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stored assets',
                        style: TextStyle(color: brass.textMuted, fontSize: 12),
                      ),
                      Text(
                        '${(size / 1048576).toStringAsFixed(1)} MB',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (domains.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Top sites', style: Theme.of(context).textTheme.titleMedium),
              for (final d in domains.take(15))
                if (d is Map)
                  ListTile(
                    dense: true,
                    title: Text('${d['domain']}'),
                    trailing: Text('${d['count']}'),
                  ),
            ],
          ],
        );
      },
    );
  }
}
