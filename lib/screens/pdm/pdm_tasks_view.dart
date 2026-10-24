import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pdm_api.dart';
import '../../core/providers/pdm_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/screen_header.dart';

class PdmTasksView extends ConsumerStatefulWidget {
  const PdmTasksView({super.key});
  @override
  ConsumerState<PdmTasksView> createState() => _PdmTasksViewState();
}

class _PdmTasksViewState extends ConsumerState<PdmTasksView> {
  PdmTaskFilter _filter = PdmTaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(pdmTasksProvider(_filter));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
          child: ScreenHeader(
            icon: Ph.listChecks,
            title: 'Tasks',
            subtitle: 'CROSS-REMOTE TASK HISTORY',
            trailing: [
              SegmentedButton<PdmTaskFilter>(
                segments: const [
                  ButtonSegment(value: PdmTaskFilter.all, label: Text('All')),
                  ButtonSegment(
                    value: PdmTaskFilter.failed,
                    label: Text('Failed'),
                  ),
                  ButtonSegment(
                    value: PdmTaskFilter.running,
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
            data: (items) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pdmTasksProvider(_filter));
                await ref.read(pdmTasksProvider(_filter).future);
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) => _PdmTaskTile(task: items[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PdmTaskTile extends ConsumerStatefulWidget {
  const _PdmTaskTile({required this.task});
  final PdmTask task;
  @override
  ConsumerState<_PdmTaskTile> createState() => _PdmTaskTileState();
}

class _PdmTaskTileState extends ConsumerState<_PdmTaskTile> {
  late bool _expanded = widget.task.failed;
  List<String>? _log;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (_expanded) _load();
  }

  Future<void> _load() async {
    if (_log != null) return;
    try {
      final api = await ref.read(pdmApiProvider.future);
      final log = await api.taskLog(
        widget.task.remote,
        widget.task.upid,
        limit: 50,
      );
      if (mounted) setState(() => _log = log);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) _load();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final brass = context.brass;
    final color = task.running
        ? brass.warn
        : task.status == 'OK'
        ? brass.ok
        : task.status?.startsWith('WARNINGS') == true
        ? brass.warn
        : brass.crit;
    // The chip stays one short word; a failure's text goes on its own line
    // below, where a long PBS/PVE error cannot push the row off-screen.
    final status = task.running
        ? 'running'
        : task.status == 'OK'
        ? 'OK'
        : task.status?.startsWith('WARNINGS') == true
        ? 'warnings'
        : 'failed';
    return BrassPanel(
      borderColor: task.failed ? brass.crit.withValues(alpha: .65) : null,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      border: Border.all(color: color.withValues(alpha: .5)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: Text(task.remote, overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      task.node,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: brass.textMuted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      [
                        task.workerType,
                        if (task.workerId != null) task.workerId,
                      ].join(' '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      task.user,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: brass.textMuted),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      _relative(task.start),
                      textAlign: TextAlign.end,
                      style: TextStyle(color: brass.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 72,
                    child: Text(
                      _duration(task.start, task.end),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: brass.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (task.failed)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                task.status!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: brass.crit, fontSize: 12),
              ),
            ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 240),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: brass.recess,
                  border: Border.all(color: brass.hairline),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: _error != null
                    ? Text(
                        'Failed to load log: $_error',
                        style: TextStyle(color: brass.crit),
                      )
                    : _log == null
                    ? const SizedBox(
                        height: 38,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : SingleChildScrollView(
                        child: SelectableText(
                          _log!.isEmpty ? '(empty log)' : _log!.join('\n'),
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            height: 1.45,
                            color: brass.textBody,
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

String _relative(DateTime date) {
  final elapsed = DateTime.now().difference(date.toLocal());
  if (elapsed.inSeconds < 60) return '${elapsed.inSeconds.clamp(0, 59)}s ago';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  return '${elapsed.inDays}d ago';
}

String _duration(DateTime start, DateTime? end) {
  if (end == null) {
    return 'running';
  }
  final elapsed = end.difference(start);
  if (elapsed.inSeconds < 60) {
    return '${elapsed.inSeconds}s';
  }
  if (elapsed.inMinutes < 60) {
    return '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s';
  }
  return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';
}
