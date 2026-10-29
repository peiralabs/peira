import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/open_webui_api.dart';
import '../../core/providers/open_webui_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/mechanical.dart';
import '../../core/widgets/service_frame.dart';

/// Native Open WebUI over its API key: chat with any of its models (web
/// search and knowledge collections optional, sources listed), the chat
/// history (search, read, pin, rename, delete), models, knowledge
/// collections, workspace prompts / tools / functions, and the admin view
/// of users and auth settings. Chats started here are not saved to Open
/// WebUI's history; its web UI stays one click away for that.
class OpenWebUiScreen extends ConsumerWidget {
  const OpenWebUiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider).value;
    return ServiceFrame(
      service: 'Open WebUI',
      icon: Ph.robot,
      subtitle: 'MODELS, CHATS AND KNOWLEDGE',
      url: s?.ollamaUrl ?? '',
      configured: s?.openWebuiConfigured ?? false,
      credentialName: 'API key',
      child: const DefaultTabController(
        length: 5,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Chat'),
                Tab(text: 'History'),
                Tab(text: 'Models'),
                Tab(text: 'Knowledge'),
                Tab(text: 'Workspace'),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _ChatView(),
                  _HistoryView(),
                  _ModelsView(),
                  _KnowledgeView(),
                  _WorkspaceView(),
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
  Future<void> Function(OpenWebUiApi api) body, {
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await body(await ref.read(openWebUiApiProvider.future));
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(_owError(e))));
    return false;
  }
}

/// Open WebUI puts its reason in the response's `detail`; show it rather
/// than the bare status.
String _owError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    final detail = data is Map ? data['detail'] : null;
    if (detail is String && detail.isNotEmpty) return detail;
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'No reply within 5 minutes.';
    }
  }
  return describeServiceError(e);
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.sources = const []});
  final OwMessage message;
  final List<({String title, String? url})> sources;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final mine = message.role == 'user';
    final error = message.role == 'error';
    final parts = stripThinking(message.content);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: error
                ? brass.crit.withValues(alpha: 0.12)
                : mine
                ? brass.giltBright.withValues(alpha: 0.12)
                : brass.textMuted.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine && message.model != null)
                Text(
                  message.model!,
                  style: TextStyle(color: brass.textMuted, fontSize: 11),
                ),
              if (error)
                SelectableText(
                  'No answer: ${message.content}',
                  style: TextStyle(color: brass.crit),
                )
              else ...[
                if (parts.thinking != null)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'Reasoning',
                      style: TextStyle(color: brass.textMuted, fontSize: 12),
                    ),
                    children: [
                      SelectableText(
                        parts.thinking!,
                        style: TextStyle(color: brass.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                MarkdownBody(data: parts.answer, selectable: true),
              ],
              if (sources.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (i, s) in sources.indexed)
                      ActionChip(
                        label: Text('${i + 1}. ${s.title}'),
                        onPressed: s.url == null
                            ? null
                            : () => openInBrowser(context, s.url!),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- Chat

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView();

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView>
    with AutomaticKeepAliveClientMixin {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <OwMessage>[];
  final _sources = <int, List<({String title, String? url})>>{};
  String? _model;
  bool _web = false;
  final _kb = <String>{};
  bool _busy = false;
  int _waited = 0;
  Timer? _ticker;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ticker?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final model = _model;
    if (text.isEmpty || model == null || _busy) return;
    _input.clear();
    setState(() {
      _messages.add(OwMessage('user', text));
      _busy = true;
      _waited = 0;
    });
    // Local models can take a while to load; show how long we have waited.
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() => _waited++) : null,
    );
    try {
      final api = await ref.read(openWebUiApiProvider.future);
      final a = await api.complete(
        model,
        [
          for (final m in _messages)
            if (m.role != 'error')
              OwMessage(m.role, stripThinking(m.content).answer),
        ],
        webSearch: _web,
        knowledgeIds: _kb.toList(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(OwMessage('assistant', a.content, model: model));
        _sources[_messages.length - 1] = a.sources;
      });
    } on Object catch (e) {
      // In the conversation, not a passing snackbar: a failed answer must
      // be visible where the answer was expected.
      if (mounted) {
        setState(
          () => _messages.add(OwMessage('error', _owError(e), model: model)),
        );
      }
    } finally {
      _ticker?.cancel();
      if (mounted) setState(() => _busy = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final models = ref.watch(owModelsProvider);
    final kb = ref.watch(owKnowledgeProvider).value ?? const [];
    final chatModels = [
      for (final m in models.value ?? const <OwModel>[])
        if (m.canChat) m,
    ];
    _model ??= chatModels.firstOrNull?.id;
    final brass = context.brass;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (models.hasError)
                Text(
                  _owError(models.error!),
                  style: TextStyle(color: brass.crit),
                )
              else
                DropdownButton<String>(
                  value: _model,
                  hint: const Text('Model'),
                  items: [
                    for (final m in chatModels)
                      DropdownMenuItem(
                        value: m.id,
                        child: Text(
                          '${m.name}${m.size == null ? '' : ' · ${m.size}'}',
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _model = v),
                ),
              FilterChip(
                avatar: const Icon(Icons.travel_explore, size: 16),
                label: const Text('Web search'),
                selected: _web,
                onSelected: (v) => setState(() => _web = v),
              ),
              for (final k in kb)
                FilterChip(
                  avatar: const Icon(Icons.library_books_outlined, size: 16),
                  label: Text(k.name),
                  selected: _kb.contains(k.id),
                  onSelected: (v) =>
                      setState(() => v ? _kb.add(k.id) : _kb.remove(k.id)),
                ),
              if (_messages.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('New chat'),
                  onPressed: () => setState(() {
                    _messages.clear();
                    _sources.clear();
                  }),
                ),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'Ask any Open WebUI model. Chats here are not saved to '
                    'its history.',
                    style: TextStyle(color: brass.textMuted),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _messages.length + (_busy ? 1 : 0),
                  itemBuilder: (context, i) => i == _messages.length
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$_model is answering… ${_waited}s'
                                '${_web ? ' (searching the web first)' : ''}',
                                style: TextStyle(color: brass.textMuted),
                              ),
                            ],
                          ),
                        )
                      : _Bubble(
                          message: _messages[i],
                          sources: _sources[i] ?? const [],
                        ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
          child: Row(
            children: [
              Expanded(
                // Enter sends, Shift+Enter breaks the line — as in the Hermes
                // chat (ChatScaffold). A multi-line TextField never fires
                // onSubmitted on Enter.
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _send();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Message (Enter sends, Shift+Enter new line)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _busy || _model == null ? null : _send,
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- History

class _HistoryView extends ConsumerStatefulWidget {
  const _HistoryView();

  @override
  ConsumerState<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<_HistoryView> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(owChatsProvider(_q));
    final brass = context.brass;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search chats',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => setState(() => _q = v.trim()),
          ),
        ),
        Expanded(
          child: chats.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ServiceError(
              error: e,
              onRetry: () => ref.invalidate(owChatsProvider(_q)),
            ),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No chats.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    children: [
                      for (final c in list)
                        ListTile(
                          key: ValueKey('ow-${c.id}'),
                          leading: Icon(
                            c.pinned ? Icons.push_pin : Icons.chat_outlined,
                            color: c.pinned
                                ? brass.giltBright
                                : brass.textMuted,
                          ),
                          title: Text(c.title.isEmpty ? 'Untitled' : c.title),
                          subtitle: c.updated == null
                              ? null
                              : Text(
                                  c.updated!.toLocal().toString().substring(
                                    0,
                                    16,
                                  ),
                                ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _ChatPage(id: c.id),
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              switch (v) {
                                case 'pin':
                                  await _act(
                                    context,
                                    ref,
                                    (api) => api.togglePin(c.id),
                                  );
                                case 'rename':
                                  final ctl = TextEditingController(
                                    text: c.title,
                                  );
                                  final t = await showDialog<String>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Rename chat'),
                                      content: TextField(
                                        controller: ctl,
                                        autofocus: true,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(
                                            context,
                                            ctl.text.trim(),
                                          ),
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  );
                                  ctl.dispose();
                                  if (t == null ||
                                      t.isEmpty ||
                                      !context.mounted) {
                                    return;
                                  }
                                  await _act(
                                    context,
                                    ref,
                                    (api) => api.renameChat(c.id, t),
                                  );
                                case 'delete':
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete "${c.title}"?'),
                                      content: const Text(
                                        'The chat is deleted in Open WebUI.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true || !context.mounted) return;
                                  await _act(
                                    context,
                                    ref,
                                    (api) => api.deleteChat(c.id),
                                  );
                              }
                              ref.invalidate(owChatsProvider);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'pin',
                                child: Text(c.pinned ? 'Unpin' : 'Pin'),
                              ),
                              const PopupMenuItem(
                                value: 'rename',
                                child: Text('Rename'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ChatPage extends ConsumerStatefulWidget {
  const _ChatPage({required this.id});
  final String id;

  @override
  ConsumerState<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<_ChatPage> {
  late final _chat = ref
      .read(openWebUiApiProvider.future)
      .then((api) => api.chat(widget.id));

  String get id => widget.id;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _chat,
    builder: (context, snap) => Scaffold(
      appBar: AppBar(
        title: Text(snap.data?.title ?? 'Chat'),
        actions: [
          IconButton(
            tooltip: 'Continue in Open WebUI',
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final api = await ref.read(openWebUiApiProvider.future);
              if (context.mounted) {
                await openInBrowser(context, api.chatUrl(id));
              }
            },
          ),
        ],
      ),
      body: snap.hasError
          ? Center(child: Text(_owError(snap.error!)))
          : !snap.hasData
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (final m in snap.data!.messages) _Bubble(message: m),
              ],
            ),
    ),
  );
}

// ------------------------------------------------------------------ Models

class _ModelsView extends ConsumerWidget {
  const _ModelsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(owModelsProvider);
    final brass = context.brass;
    return models.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(owModelsProvider),
      ),
      data: (list) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        children: [
          for (final m in list)
            ListTile(
              leading: Icon(
                m.canChat
                    ? Icons.smart_toy_outlined
                    : Icons.scatter_plot_outlined,
              ),
              title: Text(m.name),
              subtitle: Text(
                [
                  m.ownedBy,
                  ?m.family,
                  ?m.size,
                  ?m.quant,
                  if (!m.canChat) 'embedding model',
                ].join('  ·  '),
                style: TextStyle(color: brass.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- Knowledge

class _KnowledgeView extends ConsumerWidget {
  const _KnowledgeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kb = ref.watch(owKnowledgeProvider);
    return kb.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(owKnowledgeProvider),
      ),
      data: (list) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New collection'),
              onPressed: () async {
                final name = TextEditingController();
                final desc = TextEditingController();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('New knowledge collection'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        TextField(
                          controller: desc,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
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
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                );
                final (n, d) = (name.text.trim(), desc.text.trim());
                name.dispose();
                desc.dispose();
                if (ok != true || n.isEmpty || !context.mounted) return;
                await _act(
                  context,
                  ref,
                  (api) => api.createKnowledge(n, d),
                  done: 'Collection created; add files in Open WebUI',
                );
                ref.invalidate(owKnowledgeProvider);
              },
            ),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Center(child: Text('No knowledge collections.')),
          for (final k in list)
            ListTile(
              leading: const Icon(Icons.library_books_outlined),
              title: Text(k.name),
              subtitle: Text(
                '${k.files} files${k.description.isEmpty ? '' : ' · ${k.description}'}',
              ),
              trailing: IconButton(
                tooltip: 'Delete collection',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete ${k.name}?'),
                      content: const Text(
                        'The collection and its index are removed.',
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
                  await _act(context, ref, (api) => api.deleteKnowledge(k.id));
                  ref.invalidate(owKnowledgeProvider);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- Workspace

class _WorkspaceView extends ConsumerStatefulWidget {
  const _WorkspaceView();

  @override
  ConsumerState<_WorkspaceView> createState() => _WorkspaceViewState();
}

class _WorkspaceViewState extends ConsumerState<_WorkspaceView> {
  late Future<_Workspace> _data = _fetch();

  Future<_Workspace> _fetch() async {
    final api = await ref.read(openWebUiApiProvider.future);
    final results = await Future.wait([
      api.workspace('prompts'),
      api.workspace('tools'),
      api.workspace('functions'),
    ]);
    // Admin-only; a non-admin key just gets no admin panel.
    ({int total, List<Map<String, dynamic>> users})? users;
    Map<String, dynamic>? config;
    try {
      users = await api.users();
      config = await api.adminConfig();
    } on Object {
      users = null;
    }
    return _Workspace(
      results[0],
      results[1],
      results[2],
      users,
      config,
      await api.version(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return FutureBuilder<_Workspace>(
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
        final w = snap.data!;
        Widget section(
          String title,
          List<Map<String, dynamic>> items,
          String empty,
        ) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (items.isEmpty)
              Text(empty, style: TextStyle(color: brass.textMuted)),
            for (final x in items)
              ListTile(
                dense: true,
                title: Text(
                  '${x['name'] ?? x['title'] ?? x['command'] ?? x['id']}',
                ),
                subtitle: Text(
                  '${(x['meta'] as Map?)?['description'] ?? x['command'] ?? ''}',
                ),
                trailing: title == 'Functions'
                    ? BrassToggle(
                        value: x['is_active'] == true,
                        onChanged: (_) async {
                          await _act(
                            context,
                            ref,
                            (api) => api.toggleFunction('${x['id']}'),
                          );
                          setState(() => _data = _fetch());
                        },
                      )
                    : null,
              ),
          ],
        );
        final cfg = w.config;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          children: [
            Text(
              'Open WebUI ${w.version['version'] ?? ''}',
              style: TextStyle(color: brass.textMuted),
            ),
            section('Prompts', w.prompts, 'No saved prompts.'),
            section('Tools', w.tools, 'No tools.'),
            section('Functions', w.functions, 'No functions.'),
            if (w.users != null) ...[
              const SizedBox(height: 12),
              Text(
                'Users (${w.users!.total})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final u in w.users!.users)
                ListTile(
                  dense: true,
                  title: Text('${u['name'] ?? ''}'),
                  subtitle: Text('${u['email'] ?? ''} · ${u['role'] ?? ''}'),
                ),
            ],
            if (cfg != null) ...[
              const SizedBox(height: 12),
              Text(
                'Auth settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              BrassPanel(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 6,
                  children: [
                    for (final e in cfg.entries)
                      if (e.value is bool ||
                          e.value is String ||
                          e.value is num)
                        Text('${e.key}: ${e.value}'),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Workspace {
  const _Workspace(
    this.prompts,
    this.tools,
    this.functions,
    this.users,
    this.config,
    this.version,
  );
  final List<Map<String, dynamic>> prompts;
  final List<Map<String, dynamic>> tools;
  final List<Map<String, dynamic>> functions;
  final ({int total, List<Map<String, dynamic>> users})? users;
  final Map<String, dynamic>? config;
  final Map<String, dynamic> version;
}

/// Splits a reasoning model's `<think>…</think>` block from its answer.
({String answer, String? thinking}) stripThinking(String content) {
  final m = RegExp(r'<think>([\s\S]*?)(?:</think>|$)').firstMatch(content);
  if (m == null) return (answer: content, thinking: null);
  final thinking = m.group(1)!.trim();
  final answer = content.replaceRange(m.start, m.end, '').trim();
  return (answer: answer, thinking: thinking.isEmpty ? null : thinking);
}
