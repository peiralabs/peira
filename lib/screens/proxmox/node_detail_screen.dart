import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/proxmox_api.dart';
import '../../core/models/node_status.dart';
import '../../core/models/proxmox_container.dart';
import '../../core/models/proxmox_node.dart';
import '../../core/models/proxmox_task.dart';
import '../../core/models/proxmox_vm.dart';
import '../../core/providers/proxmox_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/chart_card.dart';
import '../../core/widgets/recessed_bar.dart';
import '../../core/widgets/status_light.dart';
import '../../core/widgets/task_log_tile.dart';
import 'ct_detail_screen.dart';
import 'vm_detail_screen.dart';

/// Live per-node detail: identity strip (/nodes/{n}/status), CPU/RAM/disk/net
/// charts from the native RRD store (history is there instantly — no
/// "Collecting…" wait), per-storage usage bars, the node's guests with
/// tap-through to CT/VM detail, its recent tasks including failures, and
/// gated Reboot/Shutdown power actions (type the node name to confirm).
///
/// [embedded] renders it as a pane (inline header, no Scaffold/AppBar) for
/// the wide-layout master-detail split on the Proxmox tab; [onSelectGuest]
/// routes guest taps into that split's selection instead of pushing routes.
class NodeDetailScreen extends ConsumerStatefulWidget {
  const NodeDetailScreen({
    super.key,
    required this.node,
    this.embedded = false,
    this.onSelectGuest,
  });

  final ProxmoxNode node;
  final bool embedded;
  final void Function(Object guest)? onSelectGuest;

  @override
  ConsumerState<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends ConsumerState<NodeDetailScreen> {
  // RRD hour-timeframe rows are minute resolution; 30s matches the
  // providers' autoRefresh cadence.
  static const _pollInterval = Duration(seconds: 30);

  Timer? _timer;
  NodeStatus? _status;
  List<Map<String, dynamic>>? _rrd;
  List<Map<String, dynamic>>? _storages;
  List<ProxmoxTask>? _tasks;
  Object? _error;
  bool _actionRunning = false;

  String get _node => widget.node.node;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_pollInterval, (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final status = await api.getNodeStatus(_node);
      final rrd = await api.getNodeRrd(_node);
      final storages = await api.getStorages(_node);
      final tasks = await api.getNodeTasks(_node);
      if (!mounted) return;
      setState(() {
        _error = null;
        _status = status;
        _rrd = rrd;
        _storages = storages;
        _tasks = tasks;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  List<double> _rrdSeries(double? Function(Map<String, dynamic> row) pick) {
    final rrd = _rrd;
    if (rrd == null) return const [];
    return [
      for (final row in rrd)
        if (pick(row) case final double v when v.isFinite) v,
    ];
  }

  static double? _num(Map<String, dynamic> row, String key) =>
      (row[key] as num?)?.toDouble();

  static double? _pct(Map<String, dynamic> row, String used, String total) {
    final u = _num(row, used), t = _num(row, total);
    if (u == null || t == null || t == 0) return null;
    return (u / t * 100).clamp(0.0, 100.0);
  }

  static String _uptime(int? seconds) {
    final s = seconds ?? 0;
    if (s <= 0) return '—';
    final d = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  static String _bytes(num? b) {
    if (b == null) return '—';
    // TiB matters here: the NAS mounts every node sees are >20 TB, which
    // would otherwise render as five-digit GiB strings.
    if (b >= 1 << 40) return '${(b / (1 << 40)).toStringAsFixed(1)} TiB';
    if (b >= 1 << 30) return '${(b / (1 << 30)).toStringAsFixed(1)} GiB';
    if (b >= 1 << 20) return '${(b / (1 << 20)).toStringAsFixed(1)} MiB';
    return '${(b / 1024).toStringAsFixed(0)} KiB';
  }

  /// Compact byte-rate axis label ("1.2M", "640K") that fits 44px.
  static String _shortRate(double v) {
    if (v >= 1 << 30) return '${(v / (1 << 30)).toStringAsFixed(1)}G';
    if (v >= 1 << 20) return '${(v / (1 << 20)).toStringAsFixed(1)}M';
    if (v >= 1024) return '${(v / 1024).round()}K';
    return '${v.round()}';
  }

  /// "pve-manager/8.0.0/abcde…" → "pve-manager 8.0.0".
  static String _pveShort(String? pveversion) {
    if (pveversion == null || pveversion.isEmpty) return '—';
    final parts = pveversion.split('/');
    return parts.length >= 2 ? '${parts[0]} ${parts[1]}' : pveversion;
  }

  /// "Linux 6.8.12-1-pve #1 SMP …" → "Linux 6.8.12-1-pve".
  static String _kernelShort(String? kversion) {
    if (kversion == null || kversion.isEmpty) return '—';
    return kversion.split(' #').first;
  }

  Future<void> _nodePower(
    String verb,
    String consequence,
    Future<void> Function(ProxmoxApi api) action,
  ) async {
    final confirmCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('$verb $_node?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$consequence Every guest on $_node goes down with it. '
                'Type $_node to confirm.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                autofocus: true,
                decoration: InputDecoration(hintText: _node),
                onChanged: (_) => setLocal(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: confirmCtrl.text.trim() == _node
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: Text(verb),
            ),
          ],
        ),
      ),
    );
    confirmCtrl.dispose();
    if (ok != true || !mounted) return;
    setState(() => _actionRunning = true);
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      await action(api);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$verb requested for $_node')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$verb failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _actionRunning = false);
      unawaited(_load());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _node,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _overflowMenu(context),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_node),
        actions: [_overflowMenu(context)],
      ),
      body: _body(),
    );
  }

  Widget _overflowMenu(BuildContext context) => PopupMenuButton<String>(
        enabled: !_actionRunning,
        onSelected: (v) {
          switch (v) {
            case 'reboot':
              _nodePower(
                'Reboot',
                'This reboots the whole node.',
                (api) => api.rebootNode(_node),
              );
            case 'shutdown':
              _nodePower(
                'Shutdown',
                'This powers the whole node OFF — bringing it back needs '
                    'physical or IPMI access.',
                (api) => api.shutdownNode(_node),
              );
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'reboot',
            child: ListTile(
              leading: Icon(Icons.restart_alt),
              title: Text('Reboot node…'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'shutdown',
            child: ListTile(
              leading: Icon(
                Icons.power_settings_new,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Shutdown node…'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      );

  Widget _body() {
    final status = _status;
    if (status == null) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Text('Failed to load: $_error'),
      );
    }
    final brass = context.brass;
    // widget.node is the navigation-time snapshot; the chip must track the
    // live cluster state (this screen's own Shutdown action would otherwise
    // keep asserting "online" forever).
    final match =
        ref.watch(nodesProvider).value?.where((n) => n.node == _node);
    final liveNode =
        (match == null || match.isEmpty) ? widget.node : match.first;
    final online = liveNode.status == 'online';

    return LayoutBuilder(builder: (context, constraints) {
      // Same pairing rule as the CT/VM detail panes: no IntrinsicHeight
      // (fl_chart throws); top-aligned, cards size to content.
      final twoCol = constraints.maxWidth >= 520;
      Widget pair(Widget a, Widget b) => twoCol
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: a),
                const SizedBox(width: 16),
                Expanded(child: b),
              ],
            )
          : Column(children: [a, const SizedBox(height: 16), b]);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Chip(
                avatar: Icon(
                  online ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: online ? brass.ok : brass.crit,
                ),
                label: Text(liveNode.status),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Last poll failed: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          pair(_identityCard(status, liveNode), _storageCard()),
          const SizedBox(height: 16),
          pair(
            ChartCard(
              title: 'CPU %',
              samples: _rrdSeries((r) {
                final v = _num(r, 'cpu');
                return v == null ? null : (v * 100).clamp(0.0, 100.0);
              }),
            ),
            ChartCard(
              title: 'RAM %',
              samples: _rrdSeries((r) => _pct(r, 'memused', 'memtotal')),
            ),
          ),
          const SizedBox(height: 16),
          pair(
            ChartCard(
              title: 'Root disk %',
              samples: _rrdSeries((r) => _pct(r, 'rootused', 'roottotal')),
            ),
            ChartCard(
              title: 'Net I/O',
              maxY: null,
              leftLabel: _shortRate,
              samples: _rrdSeries((r) {
                final i = _num(r, 'netin'), o = _num(r, 'netout');
                if (i == null || o == null) return null;
                return i + o;
              }),
            ),
          ),
          const SizedBox(height: 16),
          pair(_guestsCard(), _tasksCard()),
        ],
      );
    });
  }

  Widget _identityCard(NodeStatus status, ProxmoxNode liveNode) {
    final brass = context.brass;
    final mem = status.memory;
    final swap = status.swap;
    final rows = <(String, String)>[
      ('PVE', _pveShort(status.pveversion)),
      ('Kernel', _kernelShort(status.kversion)),
      ('Uptime', _uptime(status.uptime)),
      ('Load', status.loadDisplay ?? '—'),
      ('Cores', '${liveNode.maxcpu ?? '—'}'),
      ('RAM', '${_bytes(mem?.used)} / ${_bytes(mem?.total)}'),
      ('Swap', '${_bytes(swap?.used)} / ${_bytes(swap?.total)}'),
    ];
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NODE', style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 11.5 * 0.16,
                color: brass.smallCaps,
              )),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _storageCard() {
    final brass = context.brass;
    final storages = (_storages ?? const [])
        .where((s) => ((s['total'] as num?) ?? 0) > 0)
        .toList()
      ..sort((a, b) => '${a['storage']}'.compareTo('${b['storage']}'));
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STORAGE', style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 11.5 * 0.16,
                color: brass.smallCaps,
              )),
            const SizedBox(height: 10),
            if (storages.isEmpty)
              Text(
                'No storage reported.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final s in storages) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${s['storage']}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${s['type']}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: brass.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Own line, full width + ellipsis: as a trailing Row item
                // this overflowed the ~220px two-column panes (the NAS
                // mounts render long byte strings even with a TiB unit).
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_bytes(s['used'] as num?)} / '
                    '${_bytes(s['total'] as num?)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 5),
                Builder(builder: (context) {
                  final total = (s['total'] as num?) ?? 0;
                  final frac = total > 0
                      ? (((s['used'] as num?) ?? 0) / total)
                          .clamp(0.0, 1.0)
                          .toDouble()
                      : 0.0;
                  return RecessedBar(
                    fraction: frac,
                    gradient: brass.loadGradient(frac),
                  );
                }),
                const SizedBox(height: 11),
              ],
          ],
        ),
      ),
    );
  }

  Widget _guestsCard() {
    final brass = context.brass;
    final ctsAsync = ref.watch(containersProvider(_node));
    final vmsAsync = ref.watch(vmsProvider(_node));
    final cts = ctsAsync.value;
    final vms = vmsAsync.value;
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GUESTS', style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 11.5 * 0.16,
                color: brass.smallCaps,
              )),
            const SizedBox(height: 6),
            // The per-node families are cold on first open — don't claim
            // "no guests" while they're still loading.
            if (cts == null || vms == null)
              if (ctsAsync.hasError || vmsAsync.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Failed to load guests.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: brass.crit),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
            else if (cts.isEmpty && vms.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'No guests on this node.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else ...[
              for (final ct in cts)
                _GuestLine(
                  label: '${ct.vmid} — ${ct.name ?? 'unnamed'}',
                  kind: 'CT',
                  running: ct.status == 'running',
                  onTap: () => _openGuest(ct),
                ),
              for (final vm in vms)
                _GuestLine(
                  label: '${vm.vmid} — ${vm.name ?? 'unnamed'}',
                  kind: 'VM',
                  running: vm.status == 'running',
                  onTap: () => _openGuest(vm),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _openGuest(Object guest) {
    final select = widget.onSelectGuest;
    if (select != null) {
      select(guest);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (guest) {
          final ProxmoxContainer ct => CtDetailScreen(container: ct),
          final ProxmoxVm vm => VmDetailScreen(vm: vm),
          _ => throw StateError('not a guest: $guest'),
        },
      ),
    );
  }

  Widget _tasksCard() {
    final brass = context.brass;
    final tasks = _tasks;
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('RECENT TASKS', style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 11.5 * 0.16,
                color: brass.smallCaps,
              )),
            const SizedBox(height: 6),
            if (tasks == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'No recent tasks.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (final t in tasks.take(10))
                TaskLogTile(key: ValueKey(t.upid), task: t),
          ],
        ),
      ),
    );
  }
}

/// Compact guest row inside the node panel: status dot, name, CT/VM tag,
/// chevron. Deliberately lighter than the Proxmox tab's full guest rows.
class _GuestLine extends StatelessWidget {
  const _GuestLine({
    required this.label,
    required this.kind,
    required this.running,
    required this.onTap,
  });

  final String label;
  final String kind;
  final bool running;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Row(
          children: [
            StatusLight(
              health: running ? Health.ok : Health.offline,
              size: 8,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              kind,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: brass.textMuted, letterSpacing: 1),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 15, color: brass.textMuted),
          ],
        ),
      ),
    );
  }
}
