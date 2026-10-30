import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/immich_api.dart';
import '../../core/providers/immich_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/mechanical.dart';
import '../../core/widgets/recessed_bar.dart';
import '../../core/widgets/service_frame.dart';
import 'immich_widgets.dart';

/// Native Immich over its REST API and an API key: the library with
/// filters, smart (CLIP) and file-name search, albums, people, memories,
/// duplicates, the trash, and the server's storage and job queues. Video
/// playback and uploads stay in Immich's web UI ("Open in browser").
class ImmichScreen extends ConsumerWidget {
  const ImmichScreen({super.key});

  static const views = [
    'Library',
    'Search',
    'Albums',
    'People',
    'Memories',
    'Duplicates',
    'Trash',
    'Server',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider).value;
    return ServiceFrame(
      service: 'Immich',
      icon: Ph.image,
      subtitle: 'PHOTOS AND VIDEOS',
      url: s?.immichUrl ?? '',
      configured: s?.immichConfigured ?? false,
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
                  _LibraryView(),
                  _SearchView(),
                  _AlbumsView(),
                  _PeopleView(),
                  _MemoriesView(),
                  _DuplicatesView(),
                  _TrashView(),
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

// ----------------------------------------------------------------- Library

enum _Filter { all, favorites, videos, archive }

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView>
    with AutomaticKeepAliveClientMixin {
  _Filter _filter = _Filter.all;
  final _grid = GlobalKey<ImmichAssetGridState>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ImmichAssetGrid(
      key: _grid,
      header: SegmentedButton<_Filter>(
        segments: const [
          ButtonSegment(value: _Filter.all, label: Text('All')),
          ButtonSegment(value: _Filter.favorites, label: Text('Favourites')),
          ButtonSegment(value: _Filter.videos, label: Text('Videos')),
          ButtonSegment(value: _Filter.archive, label: Text('Archive')),
        ],
        selected: {_filter},
        onSelectionChanged: (v) {
          setState(() => _filter = v.single);
          _grid.currentState?.reload();
        },
      ),
      load: (api, page) => api.assets(
        page: page,
        favorites: _filter == _Filter.favorites ? true : null,
        type: _filter == _Filter.videos ? 'VIDEO' : null,
        visibility: _filter == _Filter.archive ? 'archive' : 'timeline',
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
  bool _smart = true;
  String _query = '';
  int _generation = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _run() => setState(() {
    _query = _q.text.trim();
    _generation++;
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
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: _smart
                        ? 'Describe the photo: "dog on a beach"'
                        : 'File name contains…',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _run(),
                ),
              ),
              const SizedBox(width: 10),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Smart')),
                  ButtonSegment(value: false, label: Text('File name')),
                ],
                selected: {_smart},
                onSelectionChanged: (v) {
                  setState(() => _smart = v.single);
                  if (_query.isNotEmpty) _run();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? const Center(child: Text('Search your library.'))
              : ImmichAssetGrid(
                  key: ValueKey('$_generation-$_smart-$_query'),
                  empty: 'No matches.',
                  load: (api, page) => _smart
                      ? api.smartSearch(_query, page: page)
                      : api.assets(page: page, fileName: _query),
                ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Albums

class _AlbumsView extends ConsumerWidget {
  const _AlbumsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(immichAlbumsProvider);
    return albums.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(immichAlbumsProvider),
      ),
      data: (list) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New album'),
              onPressed: () async {
                final name = await _ask(context, 'New album', 'Name');
                if (name == null || !context.mounted) return;
                await immichAct(
                  context,
                  (api) => api.createAlbum(name),
                  done: 'Album created',
                  ref: ref,
                );
                ref.invalidate(immichAlbumsProvider);
              },
            ),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty) const Center(child: Text('No albums yet.')),
          for (final a in list)
            ListTile(
              leading: SizedBox(
                width: 56,
                height: 56,
                child: a.thumbnailAssetId == null
                    ? const Icon(Icons.photo_album_outlined)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ImmichImage(
                          url: (api) => api.thumbnailUrl(a.thumbnailAssetId!),
                        ),
                      ),
              ),
              title: Text(a.name),
              subtitle: Text(
                '${a.assetCount} items'
                '${a.description.isEmpty ? '' : ' · ${a.description}'}',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => _AlbumPage(album: a)),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'rename') {
                    final name = await _ask(
                      context,
                      'Rename album',
                      'Name',
                      initial: a.name,
                    );
                    if (name == null || !context.mounted) return;
                    await immichAct(
                      context,
                      (api) => api.updateAlbum(a.id, name: name),
                      ref: ref,
                    );
                  } else if (v == 'delete') {
                    if (!await immichConfirm(
                          context,
                          'Delete "${a.name}"?',
                          'The album is removed; its photos stay in the '
                              'library.',
                          'Delete album',
                        ) ||
                        !context.mounted) {
                      return;
                    }
                    await immichAct(
                      context,
                      (api) => api.deleteAlbum(a.id),
                      done: 'Album deleted',
                      ref: ref,
                    );
                  }
                  ref.invalidate(immichAlbumsProvider);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete album')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AlbumPage extends ConsumerWidget {
  const _AlbumPage({required this.album});
  final ImmichAlbum album;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(album.name)),
    body: ImmichAssetGrid(
      empty: 'This album is empty.',
      // Every asset of the album in one page (the timeline API is not
      // paged per album).
      load: (api, page) async => page > 1
          ? const ImmichAssetPage([], null)
          : ImmichAssetPage(await api.albumAssets(album.id), null),
      onChanged: () => ref.invalidate(immichAlbumsProvider),
    ),
  );
}

// ------------------------------------------------------------------ People

class _PeopleView extends ConsumerWidget {
  const _PeopleView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(immichPeopleProvider);
    return people.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(immichPeopleProvider),
      ),
      data: (list) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final p = list[i];
          return InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: Text(p.name.isEmpty ? 'Unnamed person' : p.name),
                  ),
                  body: ImmichAssetGrid(
                    load: (api, page) =>
                        api.assets(page: page, personIds: [p.id]),
                  ),
                ),
              ),
            ),
            onLongPress: () => _editPerson(context, ref, p),
            child: Opacity(
              opacity: p.isHidden ? 0.45 : 1,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipOval(
                      child: ImmichImage(
                        url: (api) => api.personThumbnailUrl(p.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (p.isFavorite) const Icon(Icons.favorite, size: 14),
                      Flexible(
                        child: Text(
                          p.name.isEmpty ? 'Add a name' : p.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editPerson(context, ref, p),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editPerson(
    BuildContext context,
    WidgetRef ref,
    ImmichPerson p,
  ) async {
    final name = TextEditingController(text: p.name);
    var hidden = p.isHidden;
    var favorite = p.isFavorite;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              BrassSwitchTile(
                title: const Text('Favourite'),
                value: favorite,
                onChanged: (v) => setLocal(() => favorite = v),
              ),
              BrassSwitchTile(
                title: const Text('Hidden'),
                value: hidden,
                onChanged: (v) => setLocal(() => hidden = v),
              ),
            ],
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
    final newName = name.text.trim();
    name.dispose();
    if (ok != true || !context.mounted) return;
    await immichAct(
      context,
      (api) => api.updatePerson(
        p.id,
        name: newName == p.name ? null : newName,
        isHidden: hidden == p.isHidden ? null : hidden,
        isFavorite: favorite == p.isFavorite ? null : favorite,
      ),
      done: 'Saved',
      ref: ref,
    );
    ref.invalidate(immichPeopleProvider);
  }
}

// ---------------------------------------------------------------- Memories

class _MemoriesView extends ConsumerWidget {
  const _MemoriesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(immichMemoriesProvider);
    final now = DateTime.now().year;
    return memories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(immichMemoriesProvider),
      ),
      data: (list) => list.isEmpty
          ? const Center(child: Text('No memories today.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                for (final m in list) ...[
                  Text(
                    m.year == null
                        ? 'Memory'
                        : '${now - m.year!} year${now - m.year! == 1 ? '' : 's'} ago · ${m.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: m.assets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, i) => InkWell(
                        onTap: () => showImmichViewer(context, m.assets[i]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 140,
                            child: ImmichImage(
                              url: (api) => api.thumbnailUrl(m.assets[i].id),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}

// -------------------------------------------------------------- Duplicates

class _DuplicatesView extends ConsumerWidget {
  const _DuplicatesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(immichDuplicatesProvider);
    final brass = context.brass;
    return groups.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(immichDuplicatesProvider),
      ),
      data: (list) => list.isEmpty
          ? const Center(child: Text('No duplicates found.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                Text(
                  '${list.length} groups. Immich suggests which copy to keep '
                  '(marked); the others can go to the trash.',
                  style: TextStyle(color: brass.textMuted),
                ),
                const SizedBox(height: 10),
                for (final g in list)
                  BrassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 130,
                          child: Row(
                            children: [
                              for (final a in g.assets) ...[
                                InkWell(
                                  onTap: () => showImmichViewer(context, a),
                                  child: Container(
                                    width: 130,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 3,
                                        color: g.keepIds.contains(a.id)
                                            ? brass.ok
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: ImmichImage(
                                      url: (api) => api.thumbnailUrl(a.id),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton(
                              onPressed: g.keepIds.isEmpty
                                  ? null
                                  : () async {
                                      final drop = [
                                        for (final a in g.assets)
                                          if (!g.keepIds.contains(a.id)) a.id,
                                      ];
                                      if (!await immichConfirm(
                                            context,
                                            'Keep the suggested copy?',
                                            'Moves ${drop.length} other '
                                                'cop${drop.length == 1 ? 'y' : 'ies'} '
                                                'to the trash.',
                                            'Keep and trash others',
                                          ) ||
                                          !context.mounted) {
                                        return;
                                      }
                                      await immichAct(
                                        context,
                                        (api) => api.deleteAssets(drop),
                                        done: 'Moved to trash',
                                        ref: ref,
                                      );
                                      ref.invalidate(immichDuplicatesProvider);
                                    },
                              child: const Text('Keep suggested'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await immichAct(
                                  context,
                                  (api) => api.dismissDuplicate(g.id),
                                  done: 'Marked as not duplicates',
                                  ref: ref,
                                );
                                ref.invalidate(immichDuplicatesProvider);
                              },
                              child: const Text('Not duplicates'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ------------------------------------------------------------------- Trash

class _TrashView extends ConsumerStatefulWidget {
  const _TrashView();

  @override
  ConsumerState<_TrashView> createState() => _TrashViewState();
}

class _TrashViewState extends ConsumerState<_TrashView> {
  final _grid = GlobalKey<ImmichAssetGridState>();

  @override
  Widget build(BuildContext context) => ImmichAssetGrid(
    key: _grid,
    empty: 'The trash is empty.',
    header: Wrap(
      spacing: 10,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.restore),
          label: const Text('Restore all'),
          onPressed: () async {
            await immichAct(
              context,
              (api) => api.restoreTrash(),
              done: 'Restored the trash',
              ref: ref,
            );
            _grid.currentState?.reload();
          },
        ),
        FilledButton.icon(
          icon: const Icon(Icons.delete_forever),
          label: const Text('Empty trash'),
          onPressed: () async {
            if (!await immichConfirm(
                  context,
                  'Empty the trash?',
                  'Everything in the trash is deleted permanently.',
                  'Empty trash',
                ) ||
                !context.mounted) {
              return;
            }
            await immichAct(
              context,
              (api) => api.emptyTrash(),
              done: 'Trash emptied',
              ref: ref,
            );
            _grid.currentState?.reload();
          },
        ),
      ],
    ),
    load: (api, page) => api.assets(page: page, trashed: true),
  );
}

// ------------------------------------------------------------------ Server

class _ServerView extends ConsumerWidget {
  const _ServerView();

  static String _gib(int bytes) =>
      '${(bytes / (1 << 30)).toStringAsFixed(1)} GiB';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.watch(immichServerProvider);
    final queues = ref.watch(immichQueuesProvider);
    final brass = context.brass;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      children: [
        server.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(describeServiceError(e)),
          data: (s) => BrassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Immich ${s.version}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.photos} photos · ${s.videos} videos · '
                  '${_gib(s.usageBytes)} in the library',
                ),
                const SizedBox(height: 10),
                RecessedBar(
                  fraction: (s.diskPercent / 100).clamp(0, 1).toDouble(),
                  gradient: context.brass
                      .loadGradient((s.diskPercent / 100).clamp(0, 1).toDouble()),
                  height: 12,
                ),
                const SizedBox(height: 6),
                Text(
                  'Disk ${s.diskUse} of ${s.diskSize} '
                  '(${s.diskPercent.toStringAsFixed(1)}%)',
                  style: TextStyle(color: brass.textMuted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in s.features.entries)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          f.value ? Icons.check : Icons.close,
                          size: 14,
                        ),
                        label: Text(f.key),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Job queues', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        queues.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(describeServiceError(e)),
          data: (list) => BrassPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [for (final q in list) _QueueTile(queue: q)],
            ),
          ),
        ),
      ],
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile({required this.queue});
  final ImmichQueue queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = queue;
    final c = q.counts;
    Future<void> run(String command, {bool force = false}) async {
      await immichAct(
        context,
        (api) => api.queueCommand(q.name, command, force: force),
        done: '${q.name}: $command',
        ref: ref,
      );
      ref.invalidate(immichQueuesProvider);
    }

    return ListTile(
      dense: true,
      title: Text(q.name),
      subtitle: Text(
        '${q.isPaused ? 'paused · ' : ''}'
        'active ${c['active'] ?? 0} · waiting ${c['waiting'] ?? 0} · '
        'failed ${c['failed'] ?? 0} · delayed ${c['delayed'] ?? 0}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'all') {
            if (!await immichConfirm(
                  context,
                  'Re-run ${q.name} for everything?',
                  'Every asset is processed again, not just missing ones. '
                      'This can take hours on a large library.',
                  'Run on all',
                ) ||
                !context.mounted) {
              return;
            }
            await run('start', force: true);
          } else {
            await run(v);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'start', child: Text('Run missing')),
          const PopupMenuItem(value: 'all', child: Text('Run on all…')),
          PopupMenuItem(
            value: q.isPaused ? 'resume' : 'pause',
            child: Text(q.isPaused ? 'Resume' : 'Pause'),
          ),
          const PopupMenuItem(
            value: 'clear-failed',
            child: Text('Clear failed'),
          ),
          const PopupMenuItem(value: 'empty', child: Text('Empty waiting')),
        ],
      ),
    );
  }
}

Future<String?> _ask(
  BuildContext context,
  String title,
  String label, {
  String initial = '',
}) async {
  final c = TextEditingController(text: initial);
  final v = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (t) => Navigator.pop(context, t),
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
