import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/home_assistant_api.dart';
import '../../core/navigation/app_tab.dart';
import '../../core/providers/home_assistant_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/hub_scaffold.dart';
import '../../core/widgets/service_frame.dart';
import 'ha_entities_view.dart';

/// Native Home Assistant over its REST API and a long-lived access token:
/// every entity with its domain's controls, any service call, the logbook,
/// to-do lists, and system tools. The HA frontend stays one click away
/// ("Open in browser") for dashboards and the configuration editors, which
/// the REST API does not expose.
class HomeAssistantScreen extends ConsumerWidget {
  const HomeAssistantScreen({super.key});

  static const specs = [
    (icon: Ph.house, label: 'Entities'),
    (icon: Ph.lightning, label: 'Services'),
    (icon: Ph.scroll, label: 'Logbook'),
    (icon: Ph.listChecks, label: 'Lists'),
    (icon: Ph.gearSix, label: 'System'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider).value;
    return ServiceFrame(
      service: 'Home Assistant',
      icon: Ph.house,
      subtitle: 'DEVICES, SERVICES AND AUTOMATIONS',
      url: s?.homeAssistantUrl ?? '',
      configured: s?.homeAssistantConfigured ?? false,
      credentialName: 'long-lived access token',
      child: HubScaffold(
        hub: AppTab.homeAssistant,
        tabs: [
          HubTab(
            icon: specs[0].icon,
            label: specs[0].label,
            child: const HaEntitiesView(),
          ),
          HubTab(
            icon: specs[1].icon,
            label: specs[1].label,
            child: const _ServicesView(),
          ),
          HubTab(
            icon: specs[2].icon,
            label: specs[2].label,
            child: const _LogbookView(),
          ),
          HubTab(
            icon: specs[3].icon,
            label: specs[3].label,
            child: const _ListsView(),
          ),
          HubTab(
            icon: specs[4].icon,
            label: specs[4].label,
            child: const _SystemView(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Services

class _ServicesView extends ConsumerStatefulWidget {
  const _ServicesView();

  @override
  ConsumerState<_ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends ConsumerState<_ServicesView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(haServicesProvider);
    return services.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(haServicesProvider),
      ),
      data: (all) {
        final q = _query.toLowerCase();
        final shown = [
          for (final s in all)
            if (q.isEmpty ||
                s.id.contains(q) ||
                s.name.toLowerCase().contains(q))
              s,
        ];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search ${all.length} services',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                itemCount: shown.length,
                itemBuilder: (context, i) {
                  final s = shown[i];
                  return ListTile(
                    key: ValueKey('ha-svc-${s.id}'),
                    dense: true,
                    leading: Icon(haDomainIcon(s.domain), size: 20),
                    title: Text(s.id),
                    subtitle: Text(
                      s.description.isEmpty ? s.name : s.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => HaServiceCallDialog(service: s),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Calls one service: optional target entity, the service's fields as JSON,
/// and the response shown in place.
class HaServiceCallDialog extends ConsumerStatefulWidget {
  const HaServiceCallDialog({super.key, required this.service});
  final HaService service;

  @override
  ConsumerState<HaServiceCallDialog> createState() =>
      _HaServiceCallDialogState();
}

class _HaServiceCallDialogState extends ConsumerState<HaServiceCallDialog> {
  late final _data = TextEditingController(text: _template());
  String? _entity;
  bool _returnResponse = false;
  bool _busy = false;
  String? _result;

  /// A JSON skeleton of the service's fields with HA's example values.
  String _template() {
    final m = <String, dynamic>{};
    widget.service.fields.forEach((k, v) {
      if (v['example'] != null) m[k] = v['example'];
    });
    return m.isEmpty ? '{}' : const JsonEncoder.withIndent('  ').convert(m);
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    Map<String, dynamic> data;
    try {
      final parsed = jsonDecode(_data.text.trim().isEmpty ? '{}' : _data.text);
      if (parsed is! Map) throw const FormatException('not an object');
      data = parsed.cast<String, dynamic>();
    } on FormatException catch (e) {
      setState(() => _result = 'Data is not a JSON object: ${e.message}');
      return;
    }
    if (_entity != null) data['entity_id'] = _entity;
    setState(() => _busy = true);
    final res = await haCall(
      context,
      ref,
      widget.service.domain,
      widget.service.service,
      data: data,
      returnResponse: _returnResponse,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = res == null
          ? 'Failed (see message below).'
          : const JsonEncoder.withIndent(
              '  ',
            ).convert(_returnResponse ? res['service_response'] : res);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final entities = [
      for (final e in ref.watch(haStatesProvider).value ?? const <HaEntity>[])
        if (e.domain == s.domain || s.domain == 'homeassistant') e.entityId,
    ];
    final brass = context.brass;
    return AlertDialog(
      title: Text(s.id),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.description.isNotEmpty)
                Text(s.description, style: TextStyle(color: brass.textMuted)),
              const SizedBox(height: 12),
              if (entities.isNotEmpty)
                DropdownButtonFormField<String?>(
                  initialValue: _entity,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Target entity (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(child: Text('None')),
                    for (final id in entities)
                      DropdownMenuItem(value: id, child: Text(id)),
                  ],
                  onChanged: (v) => setState(() => _entity = v),
                ),
              const SizedBox(height: 12),
              if (s.fields.isNotEmpty) ...[
                Text('Fields', style: Theme.of(context).textTheme.labelLarge),
                for (final f in s.fields.entries)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${f.key}${f.value['required'] == true ? ' (required)' : ''}'
                      '${f.value['description'] != null ? ': ${f.value['description']}' : ''}',
                      style: TextStyle(fontSize: 12, color: brass.textMuted),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _data,
                maxLines: 8,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                ),
                decoration: const InputDecoration(
                  labelText: 'Service data (JSON)',
                  border: OutlineInputBorder(),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _returnResponse,
                onChanged: (v) => setState(() => _returnResponse = v ?? false),
                title: const Text('Return the service response'),
                subtitle: const Text(
                  'Needed by services that return data (to-do items, '
                  'forecasts). Services that return nothing reject it.',
                ),
              ),
              if (_result != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  color: brass.isDark ? Colors.black26 : Colors.black12,
                  child: SelectableText(
                    _result!,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _busy ? null : _call,
          child: Text(_busy ? 'Calling…' : 'Call service'),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- Logbook

class _LogbookView extends ConsumerStatefulWidget {
  const _LogbookView();

  @override
  ConsumerState<_LogbookView> createState() => _LogbookViewState();
}

class _LogbookViewState extends ConsumerState<_LogbookView> {
  int _hours = 24;

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(haLogbookProvider(_hours));
    final brass = context.brass;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Row(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1h')),
                  ButtonSegment(value: 6, label: Text('6h')),
                  ButtonSegment(value: 24, label: Text('24h')),
                  ButtonSegment(value: 168, label: Text('7d')),
                ],
                selected: {_hours},
                onSelectionChanged: (v) => setState(() => _hours = v.single),
              ),
            ],
          ),
        ),
        Expanded(
          child: log.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ServiceError(
              error: e,
              onRetry: () => ref.invalidate(haLogbookProvider(_hours)),
            ),
            data: (rows) => rows.isEmpty
                ? const Center(child: Text('Nothing logged in this window.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          haDomainIcon(r.entityId?.split('.').first ?? ''),
                          size: 20,
                        ),
                        title: Text(r.name),
                        subtitle: Text(
                          r.message ??
                              (r.state == null ? '' : 'changed to ${r.state}'),
                        ),
                        trailing: Text(
                          _when(r.when),
                          style: TextStyle(color: brass.textMuted),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- Lists

class _ListsView extends ConsumerWidget {
  const _ListsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref
        .watch(haStatesProvider)
        .whenData(
          (all) => [
            for (final e in all)
              if (e.domain == 'todo') e,
          ],
        );
    return lists.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(haStatesProvider),
      ),
      data: (todo) => todo.isEmpty
          ? const Center(child: Text('No to-do lists in Home Assistant.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                for (final l in todo) ...[
                  _TodoList(list: l),
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _TodoList extends ConsumerStatefulWidget {
  const _TodoList({required this.list});
  final HaEntity list;

  @override
  ConsumerState<_TodoList> createState() => _TodoListState();
}

class _TodoListState extends ConsumerState<_TodoList> {
  final _add = TextEditingController();

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  Future<void> _todo(String service, Map<String, dynamic> data) async {
    await haCall(
      context,
      ref,
      'todo',
      service,
      data: {'entity_id': widget.list.entityId, ...data},
    );
    ref.invalidate(haTodoItemsProvider(widget.list.entityId));
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(haTodoItemsProvider(widget.list.entityId));
    return BrassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.list.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          items.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(describeServiceError(e)),
            data: (list) => Column(
              children: [
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Empty.',
                      style: TextStyle(color: context.brass.textMuted),
                    ),
                  ),
                for (final item in list)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: item.done,
                    title: Text(
                      item.summary,
                      style: item.done
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                    subtitle: item.due == null ? null : Text('Due ${item.due}'),
                    secondary: IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _todo('remove_item', {'item': item.uid}),
                    ),
                    onChanged: (v) => _todo('update_item', {
                      'item': item.uid,
                      'status': v == true ? 'completed' : 'needs_action',
                    }),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _add,
                  decoration: const InputDecoration(
                    hintText: 'Add an item',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              IconButton(
                tooltip: 'Add',
                icon: const Icon(Icons.add),
                onPressed: _addItem,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    final text = _add.text.trim();
    if (text.isEmpty) return;
    _add.clear();
    await _todo('add_item', {'item': text});
  }
}

// ------------------------------------------------------------------ System

class _SystemView extends ConsumerStatefulWidget {
  const _SystemView();

  @override
  ConsumerState<_SystemView> createState() => _SystemViewState();
}

class _SystemViewState extends ConsumerState<_SystemView> {
  final _template = TextEditingController(
    text: '{{ states | count }} entities, sun is {{ states("sun.sun") }}',
  );
  String? _templateOut;
  String? _check;
  String? _log;
  bool _errorsOnly = true;

  @override
  void dispose() {
    _template.dispose();
    super.dispose();
  }

  Future<HomeAssistantApi> get _api =>
      ref.read(homeAssistantApiProvider.future);

  Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(describeServiceError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(haConfigProvider);
    final brass = context.brass;
    const mono = TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      children: [
        BrassPanel(
          child: config.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(describeServiceError(e)),
            data: (c) => Wrap(
              spacing: 28,
              runSpacing: 8,
              children: [
                _kv(context, 'Version', '${c['version'] ?? '?'}'),
                _kv(context, 'Location', '${c['location_name'] ?? ''}'),
                _kv(context, 'Time zone', '${c['time_zone'] ?? ''}'),
                _kv(
                  context,
                  'Units',
                  '${(c['unit_system'] as Map?)?['temperature'] ?? ''}',
                ),
                _kv(
                  context,
                  'Integrations',
                  '${(c['components'] as List?)?.length ?? 0}',
                ),
                _kv(context, 'State', '${c['state'] ?? ''}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.rule),
              label: const Text('Check configuration'),
              onPressed: () => _guard(() async {
                final r = await (await _api).checkConfig();
                setState(
                  () => _check = r['result'] == 'valid'
                      ? 'Configuration is valid.'
                      : 'Invalid: ${r['errors'] ?? ''}',
                );
              }),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reload YAML'),
              onPressed: () => haCall(
                context,
                ref,
                'homeassistant',
                'reload_all',
                done: 'Reloaded all YAML configuration',
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restart Home Assistant'),
              onPressed: () async {
                if (!await haConfirm(
                  context,
                  'Restart Home Assistant?',
                  'Automations and devices pause until it is back, usually '
                      'under a minute. Check the configuration first.',
                  'Restart',
                )) {
                  return;
                }
                if (context.mounted) {
                  await haCall(
                    context,
                    ref,
                    'homeassistant',
                    'restart',
                    done: 'Restart requested',
                  );
                }
              },
            ),
          ],
        ),
        if (_check != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(_check!)),
        const SizedBox(height: 20),
        Text('Template', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _template,
          maxLines: 3,
          style: mono,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => _guard(() async {
                final out = await (await _api).renderTemplate(_template.text);
                setState(() => _templateOut = out);
              }),
              child: const Text('Render'),
            ),
            const SizedBox(width: 12),
            if (_templateOut != null)
              Expanded(child: SelectableText(_templateOut!, style: mono)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Error log', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            FilterChip(
              label: const Text('Warnings and errors only'),
              selected: _errorsOnly,
              onSelected: (v) => setState(() => _errorsOnly = v),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _guard(() async {
                final text = await (await _api).errorLog();
                setState(() => _log = text);
              }),
              child: Text(_log == null ? 'Load' : 'Reload'),
            ),
          ],
        ),
        if (_log != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(maxHeight: 420),
            color: brass.isDark ? Colors.black26 : Colors.black12,
            child: SingleChildScrollView(
              reverse: true,
              child: SelectableText(_filterLog(_log!), style: mono),
            ),
          ),
      ],
    );
  }

  String _filterLog(String log) {
    final lines = log.split('\n');
    final kept = _errorsOnly
        ? lines.where((l) => RegExp(r' (WARNING|ERROR|CRITICAL) ').hasMatch(l))
        : lines;
    final tail = kept.toList();
    final start = tail.length > 400 ? tail.length - 400 : 0;
    final out = tail.sublist(start).join('\n');
    return out.isEmpty ? 'No matching lines.' : out;
  }

  Widget _kv(BuildContext context, String k, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(k, style: TextStyle(color: context.brass.textMuted, fontSize: 12)),
      Text(v, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

String _when(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.month}/${l.day} ${two(l.hour)}:${two(l.minute)}';
}
