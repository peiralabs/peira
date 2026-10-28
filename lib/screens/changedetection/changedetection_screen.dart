import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/changedetection_api.dart';
import '../../core/providers/changedetection_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/service_frame.dart';

/// Native changedetection.io over its REST API and API key: every watch
/// with its last check, change and error; recheck, pause, mute, add, edit
/// (URL, title, interval, filters) and delete; each watch's snapshot
/// history with text diffs; tags; and the instance status. Visual filter
/// and browser-step setup stay in the web UI ("Open in browser").
class ChangedetectionScreen extends ConsumerWidget {
  const ChangedetectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider).value;
    return ServiceFrame(
      service: 'changedetection.io',
      icon: Ph.eye,
      subtitle: 'RELEASE AND PAGE WATCHES',
      url: s?.changedetectionUrl ?? '',
      configured: s?.changedetectionConfigured ?? false,
      credentialName: 'API key',
      child: const DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Watches'),
                Tab(text: 'Tags'),
                Tab(text: 'Status'),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [_WatchesView(), _TagsView(), _StatusView()],
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
  Future<void> Function(ChangedetectionApi api) body, {
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await body(await ref.read(changedetectionApiProvider.future));
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeServiceError(e))));
    return false;
  }
}

String _ago(DateTime? t) {
  if (t == null) return 'never';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

// ----------------------------------------------------------------- Watches

class _WatchesView extends ConsumerStatefulWidget {
  const _WatchesView();

  @override
  ConsumerState<_WatchesView> createState() => _WatchesViewState();
}

class _WatchesViewState extends ConsumerState<_WatchesView> {
  String _q = '';
  String? _tag;

  Future<void> _add() async {
    final url = TextEditingController();
    final title = TextEditingController();
    final tag = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Watch a page'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: url,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                ),
              ),
              TextField(
                controller: tag,
                decoration: const InputDecoration(labelText: 'Tag (optional)'),
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
            child: const Text('Watch'),
          ),
        ],
      ),
    );
    final (u, t, g) = (url.text.trim(), title.text.trim(), tag.text.trim());
    url.dispose();
    title.dispose();
    tag.dispose();
    if (ok != true || u.isEmpty || !mounted) return;
    if (await _act(
      context,
      ref,
      (api) => api.addWatch(
        u,
        title: t.isEmpty ? null : t,
        tag: g.isEmpty ? null : g,
      ),
      done: 'Watch added; first check queued',
    )) {
      ref.invalidate(cdWatchesProvider);
      ref.invalidate(cdTagsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final watches = ref.watch(cdWatchesProvider);
    final tags = ref.watch(cdTagsProvider).value ?? const <CdTag>[];
    final tagName = {for (final t in tags) t.uuid: t.title};
    final brass = context.brass;
    return watches.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(cdWatchesProvider),
      ),
      data: (all) {
        final q = _q.toLowerCase();
        final shown = [
          for (final w in all)
            if ((_tag == null || w.tags.contains(_tag)) &&
                (q.isEmpty ||
                    w.title.toLowerCase().contains(q) ||
                    w.url.toLowerCase().contains(q)))
              w,
        ];
        final unseen = all.where((w) => !w.viewed).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Filter watches',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _q = v.trim()),
                  ),
                ),
                if (tags.isNotEmpty)
                  DropdownButton<String?>(
                    value: _tag,
                    hint: const Text('All tags'),
                    items: [
                      const DropdownMenuItem(child: Text('All tags')),
                      for (final t in tags)
                        DropdownMenuItem(value: t.uuid, child: Text(t.title)),
                    ],
                    onChanged: (v) => setState(() => _tag = v),
                  ),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Watch a page'),
                  onPressed: _add,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recheck all'),
                  onPressed: () => _act(
                    context,
                    ref,
                    (api) => api.recheckAll(),
                    done: 'All watches queued for a check',
                  ),
                ),
                Text(
                  '${all.length} watches · $unseen unseen changes',
                  style: TextStyle(color: brass.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            BrassPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final w in shown)
                    ListTile(
                      key: ValueKey('cd-${w.uuid}'),
                      leading: Icon(
                        w.lastError != null
                            ? Icons.error_outline
                            : !w.viewed
                            ? Icons.fiber_new
                            : Icons.visibility_outlined,
                        color: w.lastError != null
                            ? brass.crit
                            : !w.viewed
                            ? brass.giltBright
                            : brass.textMuted,
                      ),
                      title: Text(w.title, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [
                          'checked ${_ago(w.lastChecked)}',
                          'changed ${_ago(w.lastChanged)}',
                          for (final t in w.tags) '#${tagName[t] ?? t}',
                          if (w.lastError != null) w.lastError!,
                        ].join('  ·  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: brass.textMuted, fontSize: 12),
                      ),
                      trailing: IconButton(
                        tooltip: 'Recheck now',
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _act(
                          context,
                          ref,
                          (api) => api.recheck(w.uuid),
                          done: 'Check queued',
                        ),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _WatchPage(uuid: w.uuid),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WatchPage extends ConsumerStatefulWidget {
  const _WatchPage({required this.uuid});
  final String uuid;

  @override
  ConsumerState<_WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends ConsumerState<_WatchPage> {
  int? _from;
  int? _to;
  bool _changesOnly = true;
  Future<String>? _diff;

  void _refresh() {
    ref.invalidate(cdWatchProvider(widget.uuid));
    ref.invalidate(cdWatchesProvider);
  }

  void _loadDiff() {
    final (f, t) = (_from, _to);
    if (f == null || t == null || f == t) {
      setState(() => _diff = null);
      return;
    }
    setState(() {
      _diff = ref
          .read(changedetectionApiProvider.future)
          .then(
            (api) =>
                api.difference(widget.uuid, f, t, changesOnly: _changesOnly),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(cdWatchProvider(widget.uuid));
    final history = ref.watch(cdHistoryProvider(widget.uuid));
    final brass = context.brass;
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.watch.title ?? 'Watch'),
        actions: [
          if (detail.value != null) ...[
            IconButton(
              tooltip: 'Recheck now',
              icon: const Icon(Icons.refresh),
              onPressed: () => _act(
                context,
                ref,
                (api) => api.recheck(widget.uuid),
                done: 'Check queued',
              ),
            ),
            IconButton(
              tooltip: detail.value!.watch.paused ? 'Resume' : 'Pause',
              icon: Icon(
                detail.value!.watch.paused ? Icons.play_arrow : Icons.pause,
              ),
              onPressed: () async {
                await _act(
                  context,
                  ref,
                  (api) =>
                      api.setPaused(widget.uuid, !detail.value!.watch.paused),
                );
                _refresh();
              },
            ),
            IconButton(
              tooltip: detail.value!.watch.muted
                  ? 'Unmute notifications'
                  : 'Mute notifications',
              icon: Icon(
                detail.value!.watch.muted
                    ? Icons.notifications_off
                    : Icons.notifications_active_outlined,
              ),
              onPressed: () async {
                await _act(
                  context,
                  ref,
                  (api) =>
                      api.setMuted(widget.uuid, !detail.value!.watch.muted),
                );
                _refresh();
              },
            ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(detail.value!),
            ),
            IconButton(
              tooltip: 'Open the page',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => openInBrowser(context, detail.value!.watch.url),
            ),
            IconButton(
              tooltip: 'Delete watch',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete this watch?'),
                    content: Text(
                      '${detail.value!.watch.title} and its history are removed.',
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
                if (ok != true || !context.mounted) return;
                if (await _act(
                      context,
                      ref,
                      (api) => api.deleteWatch(widget.uuid),
                      done: 'Watch deleted',
                    ) &&
                    context.mounted) {
                  ref.invalidate(cdWatchesProvider);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ServiceError(error: e, onRetry: _refresh),
        data: (d) {
          final w = d.watch;
          final interval = d.intervalMinutes;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            children: [
              SelectableText(w.url, style: TextStyle(color: brass.giltBright)),
              const SizedBox(height: 6),
              Text(
                [
                  'checked ${_ago(w.lastChecked)}',
                  'changed ${_ago(w.lastChanged)}',
                  interval == null ? 'default interval' : 'every $interval min',
                  if (w.paused) 'PAUSED',
                  if (w.muted) 'notifications muted',
                ].join('  ·  '),
                style: TextStyle(color: brass.textMuted),
              ),
              if (w.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    w.lastError!,
                    style: TextStyle(color: brass.crit),
                  ),
                ),
              for (final (label, key) in const [
                ('CSS/XPath/JSON filters', 'include_filters'),
                ('Ignored text', 'ignore_text'),
                ('Trigger text', 'trigger_text'),
              ])
                if (d.list(key).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('$label: ${d.list(key).join(' | ')}'),
                  ),
              const SizedBox(height: 16),
              Text('Snapshots', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              history.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(describeServiceError(e)),
                data: (ts) {
                  if (ts.isEmpty) return const Text('No snapshots yet.');
                  if (_from == null && ts.length >= 2) {
                    _from = ts[ts.length - 2];
                    _to = ts.last;
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _loadDiff(),
                    );
                  }
                  String label(int t) => DateTime.fromMillisecondsSinceEpoch(
                    t * 1000,
                  ).toString().substring(0, 16);
                  DropdownButton<int> pick(int? v, void Function(int) set) =>
                      DropdownButton<int>(
                        value: v,
                        items: [
                          for (final t in ts.reversed)
                            DropdownMenuItem(value: t, child: Text(label(t))),
                        ],
                        onChanged: (x) {
                          if (x == null) return;
                          set(x);
                          _loadDiff();
                        },
                      );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('${ts.length} snapshots. Compare'),
                          pick(_from, (x) => _from = x),
                          const Text('with'),
                          pick(_to, (x) => _to = x),
                          FilterChip(
                            label: const Text('Changes only'),
                            selected: _changesOnly,
                            onSelected: (v) {
                              _changesOnly = v;
                              _loadDiff();
                            },
                          ),
                          TextButton(
                            onPressed: () => _showSnapshot(ts.last),
                            child: const Text('View latest snapshot'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_diff != null)
                        FutureBuilder<String>(
                          future: _diff,
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return Text(describeServiceError(snap.error!));
                            }
                            if (!snap.hasData) {
                              return const LinearProgressIndicator();
                            }
                            return _DiffView(text: snap.data!);
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSnapshot(int ts) async {
    final api = await ref.read(changedetectionApiProvider.future);
    final String text;
    try {
      text = await api.snapshot(widget.uuid, ts);
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(describeServiceError(e))));
      }
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snapshot'),
        content: SizedBox(
          width: 760,
          height: 540,
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

  Future<void> _edit(CdWatchDetail d) async {
    final url = TextEditingController(text: d.watch.url);
    final title = TextEditingController(text: d.raw['title'] as String? ?? '');
    final interval = TextEditingController(
      text: d.intervalMinutes?.toString() ?? '',
    );
    final filters = TextEditingController(
      text: d.list('include_filters').join('\n'),
    );
    final ignore = TextEditingController(
      text: d.list('ignore_text').join('\n'),
    );
    final trigger = TextEditingController(
      text: d.list('trigger_text').join('\n'),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit watch'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: url,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: interval,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Check every N minutes (blank = default)',
                  ),
                ),
                TextField(
                  controller: filters,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Filters (CSS, xpath:, json:), one per line',
                  ),
                ),
                TextField(
                  controller: ignore,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ignore lines containing, one per line',
                  ),
                ),
                TextField(
                  controller: trigger,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Only trigger when text appears, one per line',
                  ),
                ),
              ],
            ),
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
    );
    List<String> lines(TextEditingController c) => [
      for (final l in c.text.split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    final values = (
      url: url.text.trim(),
      title: title.text.trim(),
      interval: int.tryParse(interval.text.trim()) ?? 0,
      filters: lines(filters),
      ignore: lines(ignore),
      trigger: lines(trigger),
    );
    for (final c in [url, title, interval, filters, ignore, trigger]) {
      c.dispose();
    }
    if (ok != true || !mounted) return;
    await _act(
      context,
      ref,
      (api) => api.updateWatch(
        widget.uuid,
        url: values.url,
        title: values.title,
        intervalMinutes: values.interval,
        includeFilters: values.filters,
        ignoreText: values.ignore,
        triggerText: values.trigger,
      ),
      done: 'Saved',
    );
    _refresh();
  }
}

/// A changedetection text diff with added lines green and removed red.
class _DiffView extends StatelessWidget {
  const _DiffView({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final lines = text.split('\n');
    if (text.trim().isEmpty) return const Text('No differences.');
    return BrassPanel(
      child: SelectableText.rich(
        TextSpan(
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
          children: [
            for (final l in lines.take(2000))
              TextSpan(
                text: '$l\n',
                style: TextStyle(
                  color: l.startsWith('(added)') || l.startsWith('(into)')
                      ? brass.ok
                      : l.startsWith('(removed)') || l.startsWith('(changed)')
                      ? brass.crit
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- Tags

class _TagsView extends ConsumerWidget {
  const _TagsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(cdTagsProvider);
    Future<String?> ask(String title, [String initial = '']) async {
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

    return tags.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          ServiceError(error: e, onRetry: () => ref.invalidate(cdTagsProvider)),
      data: (list) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New tag'),
              onPressed: () async {
                final t = await ask('New tag');
                if (t == null || !context.mounted) return;
                await _act(context, ref, (api) => api.addTag(t));
                ref.invalidate(cdTagsProvider);
              },
            ),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty) const Center(child: Text('No tags.')),
          for (final t in list)
            ListTile(
              title: Text(t.title),
              subtitle: t.muted ? const Text('notifications muted') : null,
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'recheck':
                      await _act(
                        context,
                        ref,
                        (api) => api.recheckTag(t.uuid),
                        done: 'Tagged watches queued',
                      );
                    case 'mute':
                      await _act(
                        context,
                        ref,
                        (api) => api.setTagMuted(t.uuid, !t.muted),
                      );
                    case 'rename':
                      final n = await ask('Rename tag', t.title);
                      if (n == null || !context.mounted) return;
                      await _act(
                        context,
                        ref,
                        (api) => api.renameTag(t.uuid, n),
                      );
                    case 'delete':
                      await _act(
                        context,
                        ref,
                        (api) => api.deleteTag(t.uuid),
                        done: 'Tag deleted; its watches stay',
                      );
                  }
                  ref.invalidate(cdTagsProvider);
                  ref.invalidate(cdWatchesProvider);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'recheck',
                    child: Text('Recheck all'),
                  ),
                  PopupMenuItem(
                    value: 'mute',
                    child: Text(t.muted ? 'Unmute' : 'Mute'),
                  ),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Status

class _StatusView extends ConsumerWidget {
  const _StatusView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sys = ref.watch(cdSystemProvider);
    final brass = context.brass;
    return sys.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(cdSystemProvider),
      ),
      data: (s) {
        final up = Duration(seconds: (s['uptime'] as num?)?.toInt() ?? 0);
        final overdue = (s['overdue_watches'] as List?) ?? const [];
        Widget kv(String k, Object? v) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: TextStyle(color: brass.textMuted, fontSize: 12)),
            Text('$v', style: Theme.of(context).textTheme.titleMedium),
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
                  kv('Version', s['version'] ?? '?'),
                  kv('Watches', s['watch_count'] ?? 0),
                  kv('Check queue', s['queue_size'] ?? 0),
                  kv('Overdue', overdue.length),
                  kv('Uptime', '${up.inDays} d ${up.inHours % 24} h'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
