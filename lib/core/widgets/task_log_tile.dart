import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/proxmox_task.dart';
import '../providers/proxmox_providers.dart';
import '../theme/app_theme.dart';
import 'status_light.dart';

/// One Proxmox task as an expandable row: status light + type/guest label,
/// node and absolute start time (relative times would make goldens
/// non-deterministic and are useless for diagnosis anyway), the full status
/// text, and — expanded — the task log fetched once from
/// `/nodes/{n}/tasks/{upid}/log` so the error is readable in-app.
class TaskLogTile extends ConsumerStatefulWidget {
  const TaskLogTile({
    super.key,
    required this.task,
    this.initiallyExpanded = false,
  });

  final ProxmoxTask task;
  final bool initiallyExpanded;

  @override
  ConsumerState<TaskLogTile> createState() => _TaskLogTileState();
}

class _TaskLogTileState extends ConsumerState<TaskLogTile> {
  late bool _expanded = widget.initiallyExpanded;
  List<String>? _log;
  Object? _logError;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String absTime(int epoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${_months[dt.month - 1]} ${dt.day}, '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  static String _duration(int start, int? end) {
    if (end == null) return 'running';
    final s = end - start;
    if (s < 60) return '${s}s';
    if (s < 3600) return '${s ~/ 60}m ${s % 60}s';
    return '${s ~/ 3600}h ${(s % 3600) ~/ 60}m';
  }

  @override
  void initState() {
    super.initState();
    if (_expanded) _fetchLog();
  }

  Future<void> _fetchLog() async {
    if (_log != null || _logError != null) return;
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final lines = await api.getTaskLog(widget.task.node, widget.task.upid);
      if (!mounted) return;
      setState(() => _log = [for (final l in lines) '${l['t'] ?? ''}']);
    } catch (e) {
      if (mounted) setState(() => _logError = e);
    }
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      // Re-expanding retries a failed fetch — without this a single
      // transient blip pins the error for the tile's whole lifetime.
      if (_expanded) _logError = null;
    });
    if (_expanded) _fetchLog();
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final theme = Theme.of(context);
    final task = widget.task;
    final health = task.isRunning
        ? Health.warn
        : task.isOk
            ? Health.ok
            : task.hasWarnings
                ? Health.warn
                : Health.crit;
    final statusText = task.isRunning ? 'running' : (task.status ?? '—');
    // Same health ramp as the dashboard's task feed, so the two lists read
    // identically one tap apart.
    final statusColor = switch (health) {
      Health.ok => brass.ok,
      Health.warn => brass.warn,
      _ => brass.crit,
    };
    final label = [task.type, if (task.id != null) task.id].join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                StatusLight(health: health, size: 8),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${task.node}  ·  ${absTime(task.starttime)}'
                        '  ·  ${_duration(task.starttime, task.endtime)}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: brass.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!_expanded)
                  Tooltip(
                    message: statusText,
                    waitDuration: const Duration(milliseconds: 400),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: statusColor),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: brass.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The full status line, uncapped — for failed tasks this is
                // the error summary the dashboard's 220px feed elides.
                SelectableText(
                  statusText,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: statusColor),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: brass.recess,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: brass.hairline),
                  ),
                  child: _logError != null
                      ? Text(
                          'Failed to load log: $_logError',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: brass.crit),
                        )
                      : _log == null
                          // Fixed height: a bare Center would balloon to
                          // the recess's 240px maxHeight while loading and
                          // collapse when the log lands.
                          ? const SizedBox(
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: SelectableText(
                                _log!.isEmpty
                                    ? '(empty log)'
                                    : _log!.join('\n'),
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12,
                                  height: 1.45,
                                  color: brass.textBody,
                                ),
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
