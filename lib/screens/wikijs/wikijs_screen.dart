import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/wikijs_api.dart';
import '../../core/build_config.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/providers/wikijs_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/service_frame.dart';

/// Whether the tab may change pages. The personal lab's Wiki.js is a
/// read-only projection of the canonical git vault (edits there are
/// overwritten by the next projection refresh), so only the public build
/// edits.
const wikiEditable = kPublicBuild;

/// Native Wiki.js over its GraphQL API and an API key: every page with
/// order, tag filter and full-text search, a Markdown reader that follows
/// wiki links in place, version history, tags and system information;
/// publicly also create, edit, move, restore and delete.
class WikiJsScreen extends ConsumerWidget {
  const WikiJsScreen({super.key});

  static const views = ['Pages', 'Tags', 'System'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider).value;
    return ServiceFrame(
      service: 'Wiki.js',
      icon: Ph.bookOpenText,
      subtitle: wikiEditable
          ? 'KNOWLEDGE BASE'
          : 'VAULT PROJECTION · READ-ONLY',
      url: s?.wikiUrl ?? '',
      configured: s?.wikiConfigured ?? false,
      credentialName: 'API key',
      trailing: [
        if (wikiEditable)
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('New page'),
            onPressed: () => _editPage(context, ref, null),
          ),
      ],
      child: const DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Pages'),
                Tab(text: 'Tags'),
                Tab(text: 'System'),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [_PagesView(), _TagsView(), _SystemView()],
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
  Future<void> Function(WikiJsApi api) body, {
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await body(await ref.read(wikiJsApiProvider.future));
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on WikiJsException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeServiceError(e))));
    return false;
  }
}

void openWikiPage(BuildContext context, int id) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => _PageReader(id: id)));

// ------------------------------------------------------------------- Pages

class _PagesView extends ConsumerStatefulWidget {
  const _PagesView({this.tag});
  final String? tag;

  @override
  ConsumerState<_PagesView> createState() => _PagesViewState();
}

class _PagesViewState extends ConsumerState<_PagesView>
    with AutomaticKeepAliveClientMixin {
  String _order = 'UPDATED';
  String _filter = '';
  final _search = TextEditingController();
  Future<({List<WikiPageItem> results, List<String> suggestions, int total})>?
  _searchResults;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = _search.text.trim();
    setState(() {
      _searchResults = q.isEmpty
          ? null
          : ref.read(wikiJsApiProvider.future).then((api) => api.search(q));
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final pages = ref.watch(wikiPagesProvider(_order, widget.tag));
    final brass = context.brass;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Full-text search, or type to filter titles',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchResults == null
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() {
                                _searchResults = null;
                                _filter = '';
                              });
                            },
                          ),
                  ),
                  onChanged: (v) => setState(() => _filter = v.trim()),
                  onSubmitted: (_) => _runSearch(),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                tooltip: 'Order',
                initialValue: _order,
                onSelected: (v) => setState(() => _order = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'UPDATED',
                    child: Text('Recently updated'),
                  ),
                  PopupMenuItem(value: 'TITLE', child: Text('Title')),
                  PopupMenuItem(value: 'PATH', child: Text('Path')),
                  PopupMenuItem(value: 'CREATED', child: Text('Created')),
                ],
                child: const Chip(
                  avatar: Icon(Icons.sort, size: 16),
                  label: Text('Order'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchResults != null
              ? FutureBuilder(
                  future: _searchResults,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return ServiceError(
                        error: snap.error!,
                        onRetry: _runSearch,
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final r = snap.data!;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      children: [
                        Text(
                          '${r.total} matches',
                          style: TextStyle(color: brass.textMuted),
                        ),
                        if (r.suggestions.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final s in r.suggestions)
                                ActionChip(
                                  label: Text(s),
                                  onPressed: () {
                                    _search.text = s;
                                    _runSearch();
                                  },
                                ),
                            ],
                          ),
                        for (final p in r.results) _PageTile(page: p),
                      ],
                    );
                  },
                )
              : pages.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ServiceError(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(wikiPagesProvider(_order, widget.tag)),
                  ),
                  data: (all) {
                    final f = _filter.toLowerCase();
                    final shown = [
                      for (final p in all)
                        if (f.isEmpty ||
                            p.title.toLowerCase().contains(f) ||
                            p.path.toLowerCase().contains(f))
                          p,
                    ];
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      itemCount: shown.length + 1,
                      itemBuilder: (context, i) => i == 0
                          ? Text(
                              '${shown.length} of ${all.length} pages'
                              '${widget.tag == null ? '' : ' tagged ${widget.tag}'}'
                              ' · Enter searches page text',
                              style: TextStyle(color: brass.textMuted),
                            )
                          : _PageTile(page: shown[i - 1]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({required this.page});
  final WikiPageItem page;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrassPanel(
        padding: EdgeInsets.zero,
        screws: true,
        child: ListTile(
          key: ValueKey('wiki-${page.id}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          title: Text(page.title),
          subtitle: Text(
            [
              '/${page.locale}/${page.path}',
              if (page.description.isNotEmpty) page.description,
            ].join('  ·  '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: brass.textMuted, fontSize: 12),
          ),
          trailing: page.updated == null
              ? null
              : Text(
                  page.updated!.toLocal().toString().substring(0, 10),
                  style: TextStyle(color: brass.textMuted, fontSize: 12),
                ),
          onTap: () => openWikiPage(context, page.id),
    ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Reader

class _PageReader extends ConsumerWidget {
  const _PageReader({required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(wikiPageProvider(id));
    final brass = context.brass;
    return Scaffold(
      appBar: AppBar(
        title: Text(page.value?.title ?? 'Page'),
        actions: [
          if (page.value != null) ...[
            IconButton(
              tooltip: 'History',
              icon: const Icon(Icons.history),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (_) => _History(page: page.value!),
              ),
            ),
            if (wikiEditable) ...[
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editPage(context, ref, page.value),
              ),
              IconButton(
                tooltip: 'Move',
                icon: const Icon(Icons.drive_file_move_outline),
                onPressed: () => _movePage(context, ref, page.value!),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deletePage(context, ref, page.value!),
              ),
            ],
            IconButton(
              tooltip: 'Open in browser',
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                final api = await ref.read(wikiJsApiProvider.future);
                if (context.mounted) {
                  await openInBrowser(
                    context,
                    api.webUrl(page.value!.locale, page.value!.path),
                  );
                }
              },
            ),
          ],
        ],
      ),
      body: page.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ServiceError(
          error: e,
          onRetry: () => ref.invalidate(wikiPageProvider(id)),
        ),
        data: (p) => Markdown(
          data: p.editor == 'markdown' || p.contentType == 'markdown'
              ? p.content
              : _htmlToText(p.render ?? p.content),
          selectable: true,
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 40),
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            a: TextStyle(color: brass.giltBright),
            code: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: brass.giltBright, width: 3),
              ),
            ),
          ),
          onTapLink: (text, href, title) => _followLink(context, ref, p, href),
        ),
      ),
    );
  }

  /// Wiki links open in the reader; anything else goes to the browser.
  Future<void> _followLink(
    BuildContext context,
    WidgetRef ref,
    WikiPage from,
    String? href,
  ) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (uri.hasScheme) {
      await openInBrowser(context, href);
      return;
    }
    final target = resolveWikiLink(from.path, href);
    if (target == null) return;
    final api = await ref.read(wikiJsApiProvider.future);
    final page = await api.pageByPath(
      target.path,
      locale: target.locale ?? from.locale,
    );
    if (!context.mounted) return;
    if (page == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No page at /${target.path}')));
      return;
    }
    openWikiPage(context, page.id);
  }
}

/// Resolves a Markdown link from the page at [fromPath] to a wiki path:
/// absolute (`/en/a/b`, `/a/b`) or relative (`../b`, `c`), dropping a
/// `.md` suffix and any `#anchor`. Null for an anchor-only link.
({String path, String? locale})? resolveWikiLink(String fromPath, String href) {
  var h = href.split('#').first;
  if (h.isEmpty) return null;
  h = Uri.decodeFull(h);
  if (h.endsWith('.md')) h = h.substring(0, h.length - 3);
  List<String> parts;
  String? locale;
  if (h.startsWith('/')) {
    parts = h.substring(1).split('/');
    if (parts.isNotEmpty && RegExp(r'^[a-z]{2}$').hasMatch(parts.first)) {
      locale = parts.removeAt(0);
    }
  } else {
    final base = fromPath.split('/')..removeLast();
    parts = [...base, ...h.split('/')];
  }
  final out = <String>[];
  for (final s in parts) {
    if (s.isEmpty || s == '.') continue;
    if (s == '..') {
      if (out.isNotEmpty) out.removeLast();
    } else {
      out.add(s);
    }
  }
  return (path: out.join('/'), locale: locale);
}

String _htmlToText(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>|</p>|</h\d>|</li>'), '\n\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');

class _History extends ConsumerWidget {
  const _History({required this.page});
  final WikiPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(wikiHistoryProvider(page.id));
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: h.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(describeServiceError(e))),
        data: (trail) => trail.isEmpty
            ? const Center(child: Text('No earlier versions.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  for (final v in trail)
                    ListTile(
                      title: Text('${v.action} by ${v.author}'),
                      subtitle: Text(
                        v.date?.toLocal().toString().substring(0, 16) ?? '',
                      ),
                      onTap: () => _showVersion(context, ref, v),
                      trailing: wikiEditable
                          ? TextButton(
                              child: const Text('Restore'),
                              onPressed: () async {
                                if (await _act(
                                  context,
                                  ref,
                                  (api) =>
                                      api.restoreVersion(page.id, v.versionId),
                                  done: 'Restored',
                                )) {
                                  ref.invalidate(wikiPageProvider(page.id));
                                  ref.invalidate(wikiHistoryProvider(page.id));
                                }
                              },
                            )
                          : null,
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _showVersion(
    BuildContext context,
    WidgetRef ref,
    WikiHistoryEntry v,
  ) async {
    final api = await ref.read(wikiJsApiProvider.future);
    final String text;
    try {
      text = await api.versionContent(page.id, v.versionId);
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(describeServiceError(e))));
      }
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Version ${v.versionId}'),
        content: SizedBox(
          width: 720,
          height: 520,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- Edits

Future<void> _editPage(BuildContext context, WidgetRef ref, WikiPage? page) =>
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => _Editor(page: page)));

Future<void> _movePage(BuildContext context, WidgetRef ref, WikiPage p) async {
  final c = TextEditingController(text: p.path);
  final to = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Move page'),
      content: TextField(
        controller: c,
        decoration: const InputDecoration(labelText: 'New path'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, c.text.trim()),
          child: const Text('Move'),
        ),
      ],
    ),
  );
  c.dispose();
  if (to == null || to.isEmpty || to == p.path || !context.mounted) return;
  if (await _act(
    context,
    ref,
    (api) => api.movePage(p.id, to, locale: p.locale),
    done: 'Moved',
  )) {
    ref.invalidate(wikiPageProvider(p.id));
    ref.invalidate(wikiPagesProvider);
  }
}

Future<void> _deletePage(
  BuildContext context,
  WidgetRef ref,
  WikiPage p,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete ${p.title}?'),
      content: Text('/${p.locale}/${p.path} is deleted.'),
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
  if (ok != true || !context.mounted) return;
  if (await _act(
        context,
        ref,
        (api) => api.deletePage(p.id),
        done: 'Deleted',
      ) &&
      context.mounted) {
    ref.invalidate(wikiPagesProvider);
    Navigator.pop(context);
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({this.page});
  final WikiPage? page;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final _title = TextEditingController(text: widget.page?.title ?? '');
  late final _path = TextEditingController(text: widget.page?.path ?? '');
  late final _desc = TextEditingController(
    text: widget.page?.description ?? '',
  );
  late final _tags = TextEditingController(
    text: widget.page?.tags.join(', ') ?? '',
  );
  late final _body = TextEditingController(text: widget.page?.content ?? '');
  bool _preview = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _path, _desc, _tags, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final tags = [
      for (final t in _tags.text.split(','))
        if (t.trim().isNotEmpty) t.trim(),
    ];
    if (_title.text.trim().isEmpty ||
        (widget.page == null && _path.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A title and a path are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    final p = widget.page;
    final ok = await _act(context, ref, (api) async {
      if (p == null) {
        await api.createPage(
          path: _path.text.trim(),
          title: _title.text.trim(),
          content: _body.text,
          description: _desc.text.trim(),
          tags: tags,
        );
      } else {
        await api.updatePage(
          p.id,
          content: _body.text,
          title: _title.text.trim(),
          description: _desc.text.trim(),
          tags: tags,
        );
      }
    }, done: p == null ? 'Page created' : 'Saved');
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ref.invalidate(wikiPagesProvider);
      if (p != null) ref.invalidate(wikiPageProvider(p.id));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.page == null ? 'New page' : 'Edit ${widget.page!.title}',
      ),
      actions: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Write')),
            ButtonSegment(value: true, label: Text('Preview')),
          ],
          selected: {_preview},
          onSelectionChanged: (v) => setState(() => _preview = v.single),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
        const SizedBox(width: 16),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _path,
                  enabled: widget.page == null,
                  decoration: const InputDecoration(
                    labelText: 'Path (e.g. guides/backups)',
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags, comma separated',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _preview
                ? BrassPanel(
                    child: Markdown(data: _body.text, selectable: true),
                  )
                : TextField(
                    controller: _body,
                    expands: true,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Markdown',
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

// -------------------------------------------------------------------- Tags

class _TagsView extends ConsumerWidget {
  const _TagsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(wikiTagsProvider);
    return tags.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(wikiTagsProvider),
      ),
      data: (list) => list.isEmpty
          ? const Center(child: Text('No tags.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in list)
                    ActionChip(
                      label: Text(t.tag),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: Text('Tagged ${t.tag}')),
                            body: _PagesView(tag: t.tag),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ------------------------------------------------------------------ System

class _SystemView extends ConsumerWidget {
  const _SystemView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(wikiSystemProvider);
    final brass = context.brass;
    return info.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(wikiSystemProvider),
      ),
      data: (i) {
        Widget kv(String k, Object? v) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: TextStyle(color: brass.textMuted, fontSize: 12)),
            Text('${v ?? '–'}', style: Theme.of(context).textTheme.titleMedium),
          ],
        );
        final current = '${i['currentVersion'] ?? ''}';
        final latest = '${i['latestVersion'] ?? ''}';
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          children: [
            BrassPanel(
              child: Wrap(
                spacing: 32,
                runSpacing: 12,
                children: [
                  kv('Version', current),
                  kv(
                    'Latest',
                    latest.isEmpty || latest == current
                        ? latest
                        : '$latest (update available)',
                  ),
                  kv('Pages', i['pagesTotal']),
                  kv('Tags', i['tagsTotal']),
                  kv('Users', i['usersTotal']),
                  kv('Groups', i['groupsTotal']),
                  kv(
                    'Database',
                    '${i['dbType'] ?? ''} ${i['dbVersion'] ?? ''}',
                  ),
                  kv('Node.js', i['nodeVersion']),
                  kv('Host', i['hostname']),
                  kv('OS', i['operatingSystem']),
                  kv('CPU cores', i['cpuCores']),
                  kv('RAM', i['ramTotal']),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('Rebuild page tree'),
                  onPressed: () => _act(
                    context,
                    ref,
                    (api) => api.rebuildTree(),
                    done: 'Page tree rebuilt',
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('Flush page cache'),
                  onPressed: () => _act(
                    context,
                    ref,
                    (api) => api.flushCache(),
                    done: 'Cache flushed',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
