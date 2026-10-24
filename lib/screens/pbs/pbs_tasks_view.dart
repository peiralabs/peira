import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pbs_api.dart';
import '../../core/providers/pbs_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/screen_header.dart';

class PbsTasksView extends ConsumerStatefulWidget {
  const PbsTasksView({super.key, required this.slot});
  final PbsSlot slot;
  @override
  ConsumerState<PbsTasksView> createState() => _PbsTasksViewState();
}

class _PbsTasksViewState extends ConsumerState<PbsTasksView> {
  PbsTaskFilter _filter = PbsTaskFilter.all;
  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(pbsTasksProvider(widget.slot, _filter));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
          child: ScreenHeader(
            icon: Ph.listChecks,
            title: 'Tasks',
            subtitle: 'SERVER TASK HISTORY',
            trailing: [
              SegmentedButton<PbsTaskFilter>(
                segments: const [
                  ButtonSegment(value: PbsTaskFilter.all, label: Text('All')),
                  ButtonSegment(
                    value: PbsTaskFilter.failed,
                    label: Text('Failed'),
                  ),
                  ButtonSegment(
                    value: PbsTaskFilter.running,
                    label: Text('Running'),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (value) =>
                    setState(() => _filter = value.single),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed to load tasks: $error')),
            data: (items) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) =>
                  _TaskTile(slot: widget.slot, task: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends ConsumerStatefulWidget {
  const _TaskTile({required this.slot, required this.task});
  final PbsSlot slot;
  final PbsTask task;
  @override
  ConsumerState<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<_TaskTile> {
  bool _expanded = false;
  List<String>? _log;
  Object? _error;

  Future<void> _load() async {
    if (_log != null) return;
    try {
      final api = await ref.read(pbsApiProvider(widget.slot).future);
      final log = await api.taskLogTail(widget.task.upid, limit: 50);
      if (mounted) setState(() => _log = log);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.task.raw;
    final state = '${raw['status'] ?? raw['exitstatus'] ?? 'unknown'}';
    final running = state == 'running';
    final ok = state == 'OK';
    final color = running
        ? context.brass.warn
        : ok
        ? context.brass.ok
        : context.brass.crit;
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (_expanded) _load();
            },
            leading: Chip(
              label: Text(state),
              side: BorderSide(color: color),
              labelStyle: TextStyle(color: color),
            ),
            title: Text(
              '${raw['worker_type'] ?? raw['worker-type'] ?? raw['worker'] ?? 'task'} ${raw['worker_id'] ?? raw['worker-id'] ?? ''}',
            ),
            subtitle: Text(
              '${raw['user'] ?? ''}  •  ${_taskDate(raw['starttime'])}',
            ),
            trailing: Icon(_expanded ? Ph.caretUp : Ph.caretDown),
          ),
          if (_expanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(10),
              color: context.brass.recess,
              child: _error != null
                  ? Text('Failed to load log: $_error')
                  : _log == null
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        _log!.isEmpty ? '(empty log)' : _log!.join('\n'),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

String _taskDate(dynamic value) {
  final epoch = value is int ? value : int.tryParse('$value');
  return epoch == null
      ? ''
      : DateTime.fromMillisecondsSinceEpoch(
          epoch * 1000,
        ).toLocal().toString().substring(0, 16);
}
