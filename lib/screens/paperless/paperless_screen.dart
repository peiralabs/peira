import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/paperless_api.dart';
import '../../core/providers/paperless_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/service_frame.dart';

/// Native Paperless-ngx over its REST API (v10) and a user token: documents
/// with full-text search, tag/correspondent/type/inbox filters and paging;
/// upload; per-document metadata edits, OCR text, notes, suggestions,
/// reprocess, rotate and trash; label management; the trash; the task
/// queue; and statistics. Page-level PDF editing stays in the web UI.
class PaperlessScreen extends ConsumerWidget {
  const PaperlessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider).value;
    return ServiceFrame(
      service: 'Paperless-ngx',
      icon: Ph.fileText,
      subtitle: 'DOCUMENTS WITH OCR SEARCH',
      url: s?.paperlessUrl ?? '',
      configured: s?.paperlessConfigured ?? false,
      credentialName: 'API token',
      child: const DefaultTabController(
        length: 5,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Documents'),
                Tab(text: 'Labels'),
                Tab(text: 'Tasks'),
                Tab(text: 'Trash'),
                Tab(text: 'Statistics'),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _DocumentsView(),
                  _LabelsView(),
                  _TasksView(),
                  _TrashView(),
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
  Future<void> Function(PaperlessApi api) body, {
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await body(await ref.read(paperlessApiProvider.future));
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeServiceError(e))));
    return false;
  }
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String body,
  String action,
) async =>
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
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

String _date(DateTime? d) => d == null ? '' : d.toString().substring(0, 10);

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.id, this.width = 56, this.height = 72});
  final int id;
  final double width, height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(paperlessApiProvider).value;
    return SizedBox(
      width: width,
      height: height,
      child: api == null
          ? const SizedBox.shrink()
          : ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                api.thumbUrl(id),
                headers: api.imageHeaders,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.description_outlined),
              ),
            ),
    );
  }
}

// --------------------------------------------------------------- Documents

class _DocumentsView extends ConsumerStatefulWidget {
  const _DocumentsView();

  @override
  ConsumerState<_DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends ConsumerState<_DocumentsView>
    with AutomaticKeepAliveClientMixin {
  final _q = TextEditingController();
  String _query = '';
  String _ordering = '-created';
  int? _tag, _correspondent, _type;
  bool _inbox = false;
  final _docs = <PlDocument>[];
  int _page = 0;
  int _count = 0;
  bool _hasNext = true;
  bool _loading = false;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _more();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _docs.clear();
      _page = 0;
      _hasNext = true;
      _error = null;
    });
    _more();
  }

  Future<void> _more() async {
    if (!_hasNext || _loading) return;
    setState(() => _loading = true);
    try {
      final api = await ref.read(paperlessApiProvider.future);
      final p = await api.documents(
        page: _page + 1,
        query: _query.isEmpty ? null : _query,
        ordering: _ordering,
        tagsAll: [?_tag],
        correspondent: _correspondent,
        documentType: _type,
        inboxOnly: _inbox,
      );
      if (!mounted) return;
      setState(() {
        _docs.addAll(p.documents);
        _page++;
        _count = p.count;
        _hasNext = p.hasNext;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    final files = await openFiles(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Documents',
          extensions: [
            'pdf',
            'png',
            'jpg',
            'jpeg',
            'tif',
            'tiff',
            'webp',
            'gif',
            'txt',
            'eml',
            'docx',
            'odt',
          ],
        ),
      ],
    );
    if (files.isEmpty || !mounted) return;
    var ok = 0;
    for (final f in files) {
      if (await _act(context, ref, (api) => api.upload(f.path))) ok++;
      if (!mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$ok of ${files.length} uploaded; Paperless is consuming them '
          '(see Tasks).',
        ),
      ),
    );
    ref.invalidate(plTasksProvider);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tags = ref.watch(plLabelsProvider('tags')).value ?? const [];
    final corr =
        ref.watch(plLabelsProvider('correspondents')).value ?? const [];
    final types =
        ref.watch(plLabelsProvider('document_types')).value ?? const [];
    final tagName = {for (final t in tags) t.id: t.name};
    final corrName = {for (final c in corr) c.id: c.name};
    final typeName = {for (final t in types) t.id: t.name};
    final brass = context.brass;

    Widget filter(
      String hint,
      int? value,
      List<PlLabel> items,
      void Function(int?) set,
    ) => items.isEmpty
        ? const SizedBox.shrink()
        : DropdownButton<int?>(
            value: value,
            hint: Text(hint),
            items: [
              DropdownMenuItem(child: Text('Any ${hint.toLowerCase()}')),
              for (final l in items)
                DropdownMenuItem(value: l.id, child: Text(l.name)),
            ],
            onChanged: (v) {
              set(v);
              _reload();
            },
          );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 340,
                child: TextField(
                  controller: _q,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search document text',
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
                              _reload();
                            },
                          ),
                  ),
                  onSubmitted: (v) {
                    _query = v.trim();
                    _reload();
                  },
                ),
              ),
              filter('Tag', _tag, tags, (v) => _tag = v),
              filter(
                'Correspondent',
                _correspondent,
                corr,
                (v) => _correspondent = v,
              ),
              filter('Type', _type, types, (v) => _type = v),
              FilterChip(
                label: const Text('Inbox'),
                selected: _inbox,
                onSelected: (v) {
                  _inbox = v;
                  _reload();
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Order',
                initialValue: _ordering,
                onSelected: (v) {
                  _ordering = v;
                  _reload();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: '-created',
                    child: Text('Newest created'),
                  ),
                  PopupMenuItem(
                    value: 'created',
                    child: Text('Oldest created'),
                  ),
                  PopupMenuItem(value: '-added', child: Text('Recently added')),
                  PopupMenuItem(value: 'title', child: Text('Title')),
                  PopupMenuItem(
                    value: 'archive_serial_number',
                    child: Text('ASN'),
                  ),
                ],
                child: const Chip(
                  avatar: Icon(Icons.sort, size: 16),
                  label: Text('Order'),
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload'),
                onPressed: _upload,
              ),
            ],
          ),
        ),
        Expanded(
          child: _error != null && _docs.isEmpty
              ? ServiceError(error: _error!, onRetry: _reload)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  children: [
                    Text(
                      '$_count documents',
                      style: TextStyle(color: brass.textMuted),
                    ),
                    if (_docs.isEmpty && !_loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No documents match.')),
                      ),
                    for (final d in _docs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BrassPanel(
                          padding: EdgeInsets.zero,
                          screws: true,
                          child: ListTile(
                            key: ValueKey('pl-${d.id}'),
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: _Thumb(id: d.id),
                            title: Text(d.title),
                            subtitle: Text(
                              [
                                _date(d.created),
                                ?corrName[d.correspondent],
                                ?typeName[d.documentType],
                                if (d.asn != null) 'ASN ${d.asn}',
                                for (final t in d.tags) '#${tagName[t] ?? t}',
                              ].join('  ·  '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: brass.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _DocumentPage(id: d.id),
                                ),
                              );
                              _reload();
                            },
                      ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Center(
                      child: _loading
                          ? const CircularProgressIndicator()
                          : _hasNext
                          ? OutlinedButton(
                              onPressed: _more,
                              child: const Text('Load more'),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DocumentPage extends ConsumerWidget {
  const _DocumentPage({required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(plDocumentProvider(id));
    final tags = ref.watch(plLabelsProvider('tags')).value ?? const [];
    final corr =
        ref.watch(plLabelsProvider('correspondents')).value ?? const [];
    final types =
        ref.watch(plLabelsProvider('document_types')).value ?? const [];
    final brass = context.brass;
    void refresh() => ref.invalidate(plDocumentProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.value?.title ?? 'Document'),
        actions: [
          IconButton(
            tooltip: 'Open in Paperless',
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final api = await ref.read(paperlessApiProvider.future);
              if (context.mounted) await openInBrowser(context, api.webUrl(id));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'reprocess':
                  await _act(
                    context,
                    ref,
                    (api) => api.bulkEdit([id], 'reprocess'),
                    done: 'Reprocessing queued',
                  );
                case 'rotate':
                  await _act(
                    context,
                    ref,
                    (api) => api.bulkEdit([id], 'rotate', {'degrees': 90}),
                    done: 'Rotation queued',
                  );
                case 'delete':
                  if (!await _confirm(
                        context,
                        'Move to trash?',
                        'The document can be restored from Trash.',
                        'Move to trash',
                      ) ||
                      !context.mounted) {
                    return;
                  }
                  if (await _act(
                        context,
                        ref,
                        (api) => api.deleteDocuments([id]),
                        done: 'Moved to trash',
                      ) &&
                      context.mounted) {
                    Navigator.pop(context);
                  }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'reprocess',
                child: Text('Reprocess (OCR again)'),
              ),
              PopupMenuItem(value: 'rotate', child: Text('Rotate 90°')),
              PopupMenuItem(value: 'delete', child: Text('Move to trash')),
            ],
          ),
        ],
      ),
      body: doc.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ServiceError(error: e, onRetry: refresh),
        data: (d) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(id: d.id, width: 180, height: 240),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        label: 'Title',
                        value: d.title,
                        onEdit: (v) => _act(
                          context,
                          ref,
                          (api) => api.updateDocument(id, title: v),
                        ).then((_) => refresh()),
                      ),
                      _Pick(
                        label: 'Correspondent',
                        value: d.correspondent,
                        items: corr,
                        onPick: (v) => _act(
                          context,
                          ref,
                          (api) => api.updateDocument(
                            id,
                            correspondent: v,
                            clearCorrespondent: v == null,
                          ),
                        ).then((_) => refresh()),
                      ),
                      _Pick(
                        label: 'Document type',
                        value: d.documentType,
                        items: types,
                        onPick: (v) => _act(
                          context,
                          ref,
                          (api) => api.updateDocument(
                            id,
                            documentType: v,
                            clearType: v == null,
                          ),
                        ).then((_) => refresh()),
                      ),
                      _Field(
                        label: 'Created (YYYY-MM-DD)',
                        value: _date(d.created),
                        onEdit: (v) => _act(
                          context,
                          ref,
                          (api) => api.updateDocument(id, createdDate: v),
                        ).then((_) => refresh()),
                      ),
                      _Field(
                        label: 'Archive serial number',
                        value: d.asn?.toString() ?? '',
                        onEdit: (v) => _act(
                          context,
                          ref,
                          (api) => api.updateDocument(id, asn: int.tryParse(v)),
                        ).then((_) => refresh()),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in d.tags)
                            InputChip(
                              label: Text(
                                tags
                                        .where((x) => x.id == t)
                                        .firstOrNull
                                        ?.name ??
                                    '#$t',
                              ),
                              onDeleted: () => _act(
                                context,
                                ref,
                                (api) => api.updateDocument(
                                  id,
                                  tags: [...d.tags]..remove(t),
                                ),
                              ).then((_) => refresh()),
                            ),
                          PopupMenuButton<int>(
                            tooltip: 'Add tag',
                            onSelected: (t) => _act(
                              context,
                              ref,
                              (api) =>
                                  api.updateDocument(id, tags: [...d.tags, t]),
                            ).then((_) => refresh()),
                            itemBuilder: (_) => [
                              for (final t in tags)
                                if (!d.tags.contains(t.id))
                                  PopupMenuItem(
                                    value: t.id,
                                    child: Text(t.name),
                                  ),
                            ],
                            child: const Chip(
                              avatar: Icon(Icons.add, size: 16),
                              label: Text('Tag'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (d.pageCount != null) '${d.pageCount} pages',
                          ?d.originalName,
                          ?d.mimeType,
                          'added ${_date(d.added)}',
                        ].join('  ·  '),
                        style: TextStyle(color: brass.textMuted),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Show suggestions'),
                        onPressed: () =>
                            _suggest(context, ref, d, corr, types, tags),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  tooltip: 'Add note',
                  icon: const Icon(Icons.add_comment_outlined),
                  onPressed: () async {
                    final c = TextEditingController();
                    final v = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add note'),
                        content: TextField(
                          controller: c,
                          maxLines: 4,
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
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                    c.dispose();
                    if (v == null || v.isEmpty || !context.mounted) return;
                    await _act(context, ref, (api) => api.addNote(id, v));
                    refresh();
                  },
                ),
              ],
            ),
            if (d.notes.isEmpty)
              Text('No notes.', style: TextStyle(color: brass.textMuted)),
            for (final n in d.notes)
              ListTile(
                dense: true,
                title: Text(n.note),
                subtitle: Text(_date(n.created)),
                trailing: IconButton(
                  tooltip: 'Delete note',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _act(context, ref, (api) => api.deleteNote(id, n.id));
                    refresh();
                  },
                ),
              ),
            const SizedBox(height: 16),
            Text('Text (OCR)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            BrassPanel(
              child: SelectableText(
                (d.content ?? '').isEmpty ? 'No text.' : d.content!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _suggest(
    BuildContext context,
    WidgetRef ref,
    PlDocument d,
    List<PlLabel> corr,
    List<PlLabel> types,
    List<PlLabel> tags,
  ) async {
    final api = await ref.read(paperlessApiProvider.future);
    final Map<String, dynamic> s;
    try {
      s = await api.suggestions(d.id);
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(describeServiceError(e))));
      }
      return;
    }
    if (!context.mounted) return;
    List<int> ids(String k) => [
      for (final v in (s[k] as List?) ?? const [])
        if (v is num) v.toInt(),
    ];
    String names(List<int> i, List<PlLabel> l) => i
        .map((x) => l.where((y) => y.id == x).firstOrNull?.name ?? '#$x')
        .join(', ');
    final sc = ids('correspondents'),
        st = ids('document_types'),
        sg = ids('tags');
    final dates = [for (final v in (s['dates'] as List?) ?? const []) '$v'];
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Suggestions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correspondents: ${sc.isEmpty ? '–' : names(sc, corr)}'),
            Text('Types: ${st.isEmpty ? '–' : names(st, types)}'),
            Text('Tags: ${sg.isEmpty ? '–' : names(sg, tags)}'),
            Text('Dates: ${dates.isEmpty ? '–' : dates.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Close'),
          ),
          if (sc.isNotEmpty || st.isNotEmpty || sg.isNotEmpty)
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialog);
                await _act(
                  context,
                  ref,
                  (api) => api.updateDocument(
                    d.id,
                    correspondent: sc.firstOrNull,
                    documentType: st.firstOrNull,
                    tags: {...d.tags, ...sg}.toList(),
                  ),
                  done: 'Suggestions applied',
                );
                ref.invalidate(plDocumentProvider(d.id));
              },
              child: const Text('Apply'),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.onEdit,
  });
  final String label;
  final String value;
  final Future<void> Function(String) onEdit;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: TextStyle(color: context.brass.textMuted)),
    subtitle: Text(value.isEmpty ? '–' : value),
    trailing: IconButton(
      tooltip: 'Edit $label',
      icon: const Icon(Icons.edit_outlined, size: 18),
      onPressed: () async {
        final c = TextEditingController(text: value);
        final v = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(label),
            content: TextField(controller: c, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        c.dispose();
        if (v != null && v != value) await onEdit(v);
      },
    ),
  );
}

class _Pick extends StatelessWidget {
  const _Pick({
    required this.label,
    required this.value,
    required this.items,
    required this.onPick,
  });
  final String label;
  final int? value;
  final List<PlLabel> items;
  final Future<void> Function(int?) onPick;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: DropdownButtonFormField<int?>(
      initialValue: items.any((i) => i.id == value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(child: Text('None')),
        for (final i in items)
          DropdownMenuItem(value: i.id, child: Text(i.name)),
      ],
      onChanged: (v) {
        if (v != value) onPick(v);
      },
    ),
  );
}

// ------------------------------------------------------------------ Labels

class _LabelsView extends ConsumerStatefulWidget {
  const _LabelsView();

  @override
  ConsumerState<_LabelsView> createState() => _LabelsViewState();
}

class _LabelsViewState extends ConsumerState<_LabelsView> {
  String _kind = 'tags';

  static const _names = {
    'tags': 'Tags',
    'correspondents': 'Correspondents',
    'document_types': 'Document types',
    'storage_paths': 'Storage paths',
  };

  Future<String?> _ask(String title, [String initial = '']) async {
    final c = TextEditingController(text: initial);
    final v = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final labels = ref.watch(plLabelsProvider(_kind));
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            SegmentedButton<String>(
              segments: [
                for (final e in _names.entries)
                  ButtonSegment(value: e.key, label: Text(e.value)),
              ],
              selected: {_kind},
              onSelectionChanged: (v) => setState(() => _kind = v.single),
            ),
            if (_kind != 'storage_paths')
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New'),
                onPressed: () async {
                  final n = await _ask('New ${_names[_kind]!.toLowerCase()}');
                  if (n == null || !context.mounted) return;
                  await _act(context, ref, (api) => api.createLabel(_kind, n));
                  ref.invalidate(plLabelsProvider(_kind));
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        labels.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(describeServiceError(e)),
          data: (list) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('None yet.')),
                )
              : Column(
                  children: [
                    for (final l in list)
                      ListTile(
                        dense: true,
                        title: Text(l.name),
                        subtitle: Text(
                          '${l.count} documents'
                          '${l.isInbox == true ? ' · inbox tag' : ''}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'rename') {
                              final n = await _ask('Rename', l.name);
                              if (n == null || !context.mounted) return;
                              await _act(
                                context,
                                ref,
                                (api) => api.renameLabel(_kind, l.id, n),
                              );
                            } else {
                              if (!await _confirm(
                                    context,
                                    'Delete ${l.name}?',
                                    'It is removed from ${l.count} documents; '
                                        'the documents stay.',
                                    'Delete',
                                  ) ||
                                  !context.mounted) {
                                return;
                              }
                              await _act(
                                context,
                                ref,
                                (api) => api.deleteLabel(_kind, l.id),
                              );
                            }
                            ref.invalidate(plLabelsProvider(_kind));
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- Tasks

class _TasksView extends ConsumerWidget {
  const _TasksView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(plTasksProvider);
    final brass = context.brass;
    return tasks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(plTasksProvider),
      ),
      data: (r) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          Row(
            children: [
              Text(
                '${r.count} unacknowledged tasks (newest 50 shown)',
                style: TextStyle(color: brass.textMuted),
              ),
              const Spacer(),
              if (r.count > 0)
                OutlinedButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: const Text('Dismiss all'),
                  onPressed: () async {
                    if (!await _confirm(
                          context,
                          'Dismiss all ${r.count} tasks?',
                          'They are marked acknowledged and leave this list; '
                              'nothing is undone.',
                          'Dismiss',
                        ) ||
                        !context.mounted) {
                      return;
                    }
                    await _act(
                      context,
                      ref,
                      (api) => api.acknowledgeTasks(),
                      done: 'Tasks dismissed',
                    );
                    ref.invalidate(plTasksProvider);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final t in r.tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BrassPanel(
                padding: EdgeInsets.zero,
                screws: true,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    switch (t.status) {
                      'success' => Icons.check_circle_outline,
                      'failure' || 'revoked' => Icons.error_outline,
                      _ => Icons.hourglass_empty,
                    },
                    color: switch (t.status) {
                      'success' => brass.ok,
                      'failure' || 'revoked' => brass.crit,
                      _ => brass.textMuted,
                    },
                  ),
                  title: Text(t.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      t.status,
                      if (t.created != null)
                        t.created!.toLocal().toString().substring(0, 16),
                      ?t.result,
                    ].join('  ·  '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: t.documentId == null
                      ? null
                      : IconButton(
                          tooltip: 'Open document',
                          icon: const Icon(Icons.description_outlined),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _DocumentPage(id: t.documentId!),
                            ),
                          ),
                        ),
            ),
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
  late Future<PlPage> _page = _fetch();

  Future<PlPage> _fetch() =>
      ref.read(paperlessApiProvider.future).then((api) => api.trash());

  void _reload() => setState(() => _page = _fetch());

  @override
  Widget build(BuildContext context) => FutureBuilder<PlPage>(
    future: _page,
    builder: (context, snap) {
      if (snap.hasError) {
        return ServiceError(error: snap.error!, onRetry: _reload);
      }
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final p = snap.data!;
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Restore all'),
                onPressed: p.count == 0
                    ? null
                    : () async {
                        await _act(
                          context,
                          ref,
                          (api) => api.trashAction('restore'),
                          done: 'Restored',
                        );
                        _reload();
                      },
              ),
              FilledButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Empty trash'),
                onPressed: p.count == 0
                    ? null
                    : () async {
                        if (!await _confirm(
                              context,
                              'Empty the trash?',
                              '${p.count} documents are deleted permanently.',
                              'Empty trash',
                            ) ||
                            !context.mounted) {
                          return;
                        }
                        await _act(
                          context,
                          ref,
                          (api) => api.trashAction('empty'),
                          done: 'Trash emptied',
                        );
                        _reload();
                      },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (p.documents.isEmpty)
            const Center(child: Text('The trash is empty.')),
          for (final d in p.documents)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BrassPanel(
                padding: EdgeInsets.zero,
                screws: true,
                child: ListTile(
                  title: Text(d.title),
                  subtitle: Text(_date(d.created)),
                  trailing: TextButton(
                    child: const Text('Restore'),
                    onPressed: () async {
                      await _act(
                        context,
                        ref,
                        (api) => api.trashAction('restore', ids: [d.id]),
                      );
                      _reload();
                    },
                  ),
            ),
              ),
            ),
        ],
      );
    },
  );
}

// -------------------------------------------------------------- Statistics

class _StatsView extends ConsumerWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(plStatsProvider);
    final brass = context.brass;
    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(plStatsProvider),
      ),
      data: (s) {
        Widget kv(String k, Object? v) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: TextStyle(color: brass.textMuted, fontSize: 12)),
            Text('${v ?? 0}', style: Theme.of(context).textTheme.headlineSmall),
          ],
        );
        final types = (s['document_file_type_counts'] as List?) ?? const [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          children: [
            BrassPanel(
              child: Wrap(
                spacing: 32,
                runSpacing: 12,
                children: [
                  kv('Documents', s['documents_total']),
                  kv('In inbox', s['documents_inbox']),
                  kv('Tags', s['tag_count']),
                  kv('Correspondents', s['correspondent_count']),
                  kv('Types', s['document_type_count']),
                  kv('Characters', s['character_count']),
                  kv('Next ASN', s['current_asn']),
                ],
              ),
            ),
            if (types.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'File types',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final t in types)
                if (t is Map)
                  ListTile(
                    dense: true,
                    title: Text('${t['mime_type']}'),
                    trailing: Text('${t['mime_type_count']}'),
                  ),
            ],
          ],
        );
      },
    );
  }
}
