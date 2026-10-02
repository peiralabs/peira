import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/proxmox_api.dart';
import '../../core/models/proxmox_vm.dart';
import '../../core/models/vm_status.dart';
import '../../core/providers/proxmox_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/proxmox_console.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/chart_card.dart';
import 'proxmox_screen.dart' show selectedGuestProvider;

/// Live VM detail: CPU/RAM charts (5s polling), info, snapshots, and power
/// actions (start / shutdown / stop / reboot).
///
/// [embedded] renders it as a pane (inline header, no Scaffold/AppBar) for
/// the wide-layout master-detail split on the Proxmox tab.
class VmDetailScreen extends ConsumerStatefulWidget {
  const VmDetailScreen({super.key, required this.vm, this.embedded = false});

  final ProxmoxVm vm;
  final bool embedded;

  @override
  ConsumerState<VmDetailScreen> createState() => _VmDetailScreenState();
}

class _Sample {
  const _Sample(this.cpuPct, this.ramPct);

  final double cpuPct;
  final double ramPct;
}

class _VmDetailScreenState extends ConsumerState<VmDetailScreen> {
  static const _pollInterval = Duration(seconds: 5);
  static const _maxSamples = 60; // 5 minutes of history

  Timer? _timer;
  VmStatus? _status;
  Map<String, dynamic>? _config;
  Object? _error;
  final _samples = <_Sample>[];
  int? _lastNetin, _lastNetout;
  double _netinRate = 0, _netoutRate = 0;
  bool _actionRunning = false;
  List<Map<String, dynamic>>? _snapshots;

  String get _node => widget.vm.node ?? '';
  int get _vmid => widget.vm.vmid;

  @override
  void initState() {
    super.initState();
    _poll();
    _loadSnapshots();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final status = await api.getVmStatus(_node, _vmid);
      _config ??= await api.getVmConfig(_node, _vmid);
      if (!mounted) return;
      setState(() {
        _error = null;
        _status = status;
        final maxmem = status.maxmem ?? 0;
        _samples.add(
          _Sample(
            (status.cpu ?? 0) * 100,
            maxmem > 0 ? (status.mem ?? 0) / maxmem * 100 : 0,
          ),
        );
        if (_samples.length > _maxSamples) _samples.removeAt(0);
        // netin/netout are lifetime counters; diff to a bytes/s rate.
        final netin = status.netin, netout = status.netout;
        if (netin != null && _lastNetin != null) {
          _netinRate = (netin - _lastNetin!) / _pollInterval.inSeconds;
          _netoutRate = (netout! - _lastNetout!) / _pollInterval.inSeconds;
        }
        _lastNetin = netin;
        _lastNetout = netout;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _confirmAndRun(
    String verb,
    Future<String> Function(ProxmoxApi api) action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$verb VM $_vmid?'),
        content: Text('$verb ${widget.vm.name ?? 'VM'} on $_node.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(verb),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionRunning = true);
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final upid = await action(api);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$verb requested ($upid)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$verb failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _actionRunning = false);
      unawaited(_poll());
    }
  }

  Future<void> _openConsole() async {
    final proxmoxUrl =
        ref.read(settingsControllerProvider).value?.proxmoxUrl ?? '';
    final err = await openProxmoxConsole(
      proxmoxUrl: proxmoxUrl,
      node: _node,
      vmid: _vmid,
      kind: 'kvm',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Opening VM $_vmid console in your browser…'),
      ),
    );
  }

  Future<void> _loadSnapshots() async {
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final snaps = await api.getVmSnapshots(_node, _vmid);
      if (!mounted) return;
      // Drop the synthetic 'current' entry; show newest first.
      setState(() {
        _snapshots =
            snaps.where((s) => s['name'] != 'current').toList()..sort(
              (a, b) => ((b['snaptime'] as num?) ?? 0).compareTo(
                (a['snaptime'] as num?) ?? 0,
              ),
            );
      });
    } catch (_) {
      // Non-fatal — the card just shows nothing.
    }
  }

  /// Snackbar + refresh wrapper for a snapshot-mutating action.
  Future<void> _runSnapshotAction(
    String label,
    Future<String> Function(ProxmoxApi api) action,
  ) async {
    setState(() => _actionRunning = true);
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final upid = await action(api);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label ($upid)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _actionRunning = false);
      unawaited(_poll());
      unawaited(_loadSnapshots());
    }
  }

  Future<void> _takeSnapshot() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var withRam = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Snapshot VM $_vmid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. before-upgrade',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include RAM'),
                subtitle: const Text('Save running memory state'),
                value: withRam,
                onChanged: (v) => setLocal(() => withRam = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Snapshot'),
            ),
          ],
        ),
      ),
    );
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    final desc = descCtrl.text.trim();
    descCtrl.dispose();
    if (ok != true || name.isEmpty || !mounted) return;
    await _runSnapshotAction(
      'Snapshot $name requested',
      (api) => api.createVmSnapshot(
        _node,
        _vmid,
        name,
        description: desc.isEmpty ? null : desc,
        vmstate: withRam,
      ),
    );
  }

  Future<void> _rollback(String snapname) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Roll back to "$snapname"?'),
        content: Text(
          'VM $_vmid will be reverted to this snapshot. Any changes made since '
          'then are lost.',
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
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Roll back'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _runSnapshotAction(
      'Rollback to $snapname requested',
      (api) => api.rollbackVmSnapshot(_node, _vmid, snapname),
    );
  }

  Future<void> _deleteSnapshot(String snapname) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete snapshot "$snapname"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _runSnapshotAction(
      'Delete $snapname requested',
      (api) => api.deleteVmSnapshot(_node, _vmid, snapname),
    );
  }

  Future<void> _clone() async {
    int? newid;
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      newid = await api.nextVmid();
    } catch (_) {}
    if (!mounted) return;
    final idCtrl = TextEditingController(text: newid?.toString() ?? '');
    final nameCtrl = TextEditingController();
    var full = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Clone VM $_vmid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'New VMID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Full clone'),
                subtitle: const Text('Independent copy of all disks'),
                value: full,
                onChanged: (v) => setLocal(() => full = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clone'),
            ),
          ],
        ),
      ),
    );
    final targetId = int.tryParse(idCtrl.text);
    final name = nameCtrl.text.trim();
    idCtrl.dispose();
    nameCtrl.dispose();
    if (ok != true || targetId == null || !mounted) return;
    setState(() => _actionRunning = true);
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final upid = await api.cloneVm(
        _node,
        _vmid,
        newid: targetId,
        name: name.isEmpty ? null : name,
        full: full,
      );
      ref.invalidate(allVmsProvider);
      ref.invalidate(recentTasksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cloning to VM $targetId… ($upid)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Clone failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _actionRunning = false);
    }
  }

  Future<void> _delete() async {
    final running = _status?.status == 'running';
    if (running) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stop the VM before deleting.')),
      );
      return;
    }
    final confirmCtrl = TextEditingController();
    var purge = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Delete VM $_vmid?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This permanently destroys ${widget.vm.name ?? 'the VM'} and '
                'its disks. Type $_vmid to confirm.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(hintText: '$_vmid'),
                onChanged: (_) => setLocal(() {}),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Purge from backup/HA jobs'),
                value: purge,
                onChanged: (v) => setLocal(() => purge = v),
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
              onPressed: confirmCtrl.text.trim() == '$_vmid'
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Delete'),
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
      final upid = await api.deleteVm(_node, _vmid, purge: purge);
      ref.invalidate(allVmsProvider);
      ref.invalidate(recentTasksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleting VM $_vmid… ($upid)')),
        );
        if (widget.embedded) {
          // No pushed route in the wide-split pane — popping here would
          // take the shell's home route with it. Clear the selection so
          // the pane returns to its placeholder.
          ref.read(selectedGuestProvider.notifier).select(null);
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionRunning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final running = status?.status == 'running';

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
                    'VM $_vmid — ${widget.vm.name ?? ''}',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _overflowMenu(context),
              ],
            ),
          ),
          Expanded(child: _body(status, running)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('VM $_vmid — ${widget.vm.name ?? ''}'),
        actions: [_overflowMenu(context)],
      ),
      body: _body(status, running),
    );
  }

  Widget _overflowMenu(BuildContext context) => PopupMenuButton<String>(
            enabled: !_actionRunning,
            onSelected: (v) {
              switch (v) {
                case 'clone':
                  _clone();
                case 'snapshot':
                  _takeSnapshot();
                case 'delete':
                  _delete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clone',
                child: ListTile(
                  leading: Icon(Icons.copy_all),
                  title: Text('Clone…'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'snapshot',
                child: ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Take snapshot…'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Delete…'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          );

  Widget _body(VmStatus? status, bool running) => status == null
      ? Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Text('Failed to load: $_error'),
        )
      : LayoutBuilder(builder: (context, constraints) {
          final brass = context.brass;
          // Wide panes pair the cards up two-across (see ct_detail_screen).
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(
                        running ? Icons.play_arrow : Icons.stop,
                        size: 16,
                        color: running ? brass.ok : brass.crit,
                      ),
                      label: Text(status.status),
                    ),
                    OutlinedButton(
                      onPressed: !_actionRunning && !running
                          ? () => _confirmAndRun(
                              'Start',
                              (api) => api.startVm(_node, _vmid),
                            )
                          : null,
                      child: const Text('Start'),
                    ),
                    OutlinedButton(
                      onPressed: !_actionRunning && running
                          ? () => _confirmAndRun(
                              'Shutdown',
                              (api) => api.shutdownVm(_node, _vmid),
                            )
                          : null,
                      child: const Text('Shutdown'),
                    ),
                    OutlinedButton(
                      onPressed: !_actionRunning && running
                          ? () => _confirmAndRun(
                              'Stop',
                              (api) => api.stopVm(_node, _vmid),
                            )
                          : null,
                      child: const Text('Stop'),
                    ),
                    OutlinedButton(
                      onPressed: !_actionRunning && running
                          ? () => _confirmAndRun(
                              'Reboot',
                              (api) => api.rebootVm(_node, _vmid),
                            )
                          : null,
                      child: const Text('Reboot'),
                    ),
                    OutlinedButton.icon(
                      onPressed: running ? _openConsole : null,
                      icon: const Icon(Icons.desktop_windows_outlined, size: 16),
                      label: const Text('Console'),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Last poll failed: $_error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                pair(
                  ChartCard(
                    title: 'CPU %',
                    samples: [for (final s in _samples) s.cpuPct],
                  ),
                  ChartCard(
                    title: 'RAM %',
                    samples: [for (final s in _samples) s.ramPct],
                  ),
                ),
                const SizedBox(height: 16),
                pair(
                  _InfoCard(
                    status: status,
                    config: _config,
                    netinRate: _netinRate,
                    netoutRate: _netoutRate,
                  ),
                  _SnapshotCard(
                    snapshots: _snapshots,
                    busy: _actionRunning,
                    onTake: _takeSnapshot,
                    onRollback: _rollback,
                    onDelete: _deleteSnapshot,
                  ),
                ),
              ],
            );
        });
}

/// Snapshot list + management for the current VM.
class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.snapshots,
    required this.busy,
    required this.onTake,
    required this.onRollback,
    required this.onDelete,
  });

  final List<Map<String, dynamic>>? snapshots;
  final bool busy;
  final VoidCallback onTake;
  final void Function(String snapname) onRollback;
  final void Function(String snapname) onDelete;

  static String _when(num? epoch) {
    if (epoch == null || epoch == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      epoch.toInt() * 1000,
    ).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final snaps = snapshots;
    final brass = context.brass;
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'SNAPSHOTS',
                  style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 11.5 * 0.16,
                color: brass.smallCaps,
              ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: busy ? null : onTake,
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
            if (snaps == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snaps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No snapshots.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (final s in snaps)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.camera_alt_outlined, size: 20),
                  title: Text('${s['name']}'),
                  subtitle: Text(
                    [
                      _when(s['snaptime'] as num?),
                      if ((s['description'] as String?)?.trim().isNotEmpty ??
                          false)
                        (s['description'] as String).trim(),
                    ].where((e) => e.isNotEmpty).join('  ·  '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Roll back',
                        icon: const Icon(Icons.restore),
                        onPressed: busy
                            ? null
                            : () => onRollback('${s['name']}'),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: busy
                            ? null
                            : () => onDelete('${s['name']}'),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.status,
    required this.config,
    required this.netinRate,
    required this.netoutRate,
  });

  final VmStatus status;
  final Map<String, dynamic>? config;
  final double netinRate;
  final double netoutRate;

  static String _uptime(int? seconds) {
    if (seconds == null || seconds == 0) return '—';
    final d = Duration(seconds: seconds);
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  static String _bytes(int? b) {
    if (b == null) return '—';
    if (b >= 1 << 30) return '${(b / (1 << 30)).toStringAsFixed(1)} GiB';
    if (b >= 1 << 20) return '${(b / (1 << 20)).toStringAsFixed(1)} MiB';
    return '${(b / 1024).toStringAsFixed(0)} KiB';
  }

  static String _rate(double bps) => '${_bytes(bps.round())}/s';

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final cfg = config ?? const <String, dynamic>{};
    final cores = cfg['cores'];
    final sockets = cfg['sockets'];
    final vcpus = (cores is num && sockets is num)
        ? '${(cores * sockets).toInt()}'
        : '${cores ?? status.cpus ?? '—'}';
    final rows = <(String, String)>[
      ('Uptime', _uptime(status.uptime)),
      ('OS type', '${cfg['ostype'] ?? '—'}'),
      ('QMP status', status.qmpstatus ?? '—'),
      ('vCPUs', vcpus),
      ('RAM', '${_bytes(status.mem)} / ${_bytes(status.maxmem)}'),
      ('Disk', '${_bytes(status.disk)} / ${_bytes(status.maxdisk)}'),
      ('Boot disk', '${cfg['scsi0'] ?? cfg['virtio0'] ?? cfg['sata0'] ?? '—'}'),
      ('Net in', _rate(netinRate)),
      ('Net out', _rate(netoutRate)),
    ];
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INFO', style: TextStyle(
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
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
