import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/proxmox_container.dart';
import '../../core/models/proxmox_vm.dart';
import '../../core/providers/proxmox_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import 'proxmox_common.dart';

class _SelectedBackupStorage extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? storage) => state = storage;
}

final _selectedBackupStorageProvider =
    NotifierProvider<_SelectedBackupStorage, String?>(
      _SelectedBackupStorage.new,
    );

class _GuestChoice {
  const _GuestChoice({
    required this.vmid,
    required this.node,
    required this.label,
  });

  final int vmid;
  final String node;
  final String label;
}

/// Proxmox vzdump/PBS backup browser, ad-hoc runner, and schedule overview.
class BackupsScreen extends ConsumerWidget {
  const BackupsScreen({super.key});

  static int _asInt(Object? value) => switch (value) {
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? 0,
    _ => 0,
  };

  static int _vmid(Map<String, dynamic> backup) {
    final direct = _asInt(backup['vmid']);
    if (direct > 0) return direct;
    final volid = '${backup['volid'] ?? ''}';
    final match = RegExp(
      r'(?:vzdump-(?:lxc|qemu)-|backup/(?:ct|vm)/)(\d+)',
    ).firstMatch(volid);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static String _humanSize(Object? value) {
    var size = _asInt(value).toDouble();
    const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final digits = unit == 0 || size >= 10 ? 0 : 1;
    return '${size.toStringAsFixed(digits)} ${units[unit]}';
  }

  static String _when(Object? value) {
    final epoch = _asInt(value);
    if (epoch <= 0) return 'Date unavailable';
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch * 1000).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  static String _format(Map<String, dynamic> backup) {
    final explicit = '${backup['format'] ?? ''}'.trim();
    if (explicit.isNotEmpty) return explicit;
    final volid = '${backup['volid'] ?? ''}';
    if (volid.contains(':backup/')) return 'PBS';
    final parts = volid.split('.');
    return parts.length > 1 ? parts.skip(1).join('.') : 'backup';
  }

  static bool _enabled(Object? value) => switch (value) {
    null => true,
    final bool enabled => enabled,
    final num enabled => enabled != 0,
    final String enabled => enabled != '0' && enabled != 'false',
    _ => false,
  };

  static List<_GuestChoice> _guests(
    List<ProxmoxContainer> containers,
    List<ProxmoxVm> vms,
  ) {
    final guests = [
      for (final ct in containers)
        _GuestChoice(
          vmid: ct.vmid,
          node: ct.node ?? '',
          label: 'CT ${ct.vmid} — ${ct.name ?? 'Unnamed'}',
        ),
      for (final vm in vms)
        _GuestChoice(
          vmid: vm.vmid,
          node: vm.node ?? '',
          label: 'VM ${vm.vmid} — ${vm.name ?? 'Unnamed'}',
        ),
    ]..sort((a, b) => a.vmid.compareTo(b.vmid));
    return guests;
  }

  Future<void> _backupNow(
    BuildContext context,
    WidgetRef ref, {
    required List<_GuestChoice> guests,
    required List<String> storages,
    required String initialStorage,
    required String refreshNode,
  }) async {
    var guest = guests.first;
    var storage = initialStorage;
    var mode = 'snapshot';
    final confirmCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Run backup now?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: guest.vmid,
                  decoration: const InputDecoration(labelText: 'Guest'),
                  items: [
                    for (final item in guests)
                      DropdownMenuItem(
                        value: item.vmid,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (vmid) => setLocal(() {
                    guest = guests.firstWhere((item) => item.vmid == vmid);
                    confirmCtrl.clear();
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: storage,
                  decoration: const InputDecoration(labelText: 'Storage'),
                  items: [
                    for (final item in storages)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) =>
                      setLocal(() => storage = value ?? storage),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  decoration: const InputDecoration(labelText: 'Mode'),
                  items: const [
                    DropdownMenuItem(
                      value: 'snapshot',
                      child: Text('Snapshot'),
                    ),
                    DropdownMenuItem(value: 'suspend', child: Text('Suspend')),
                    DropdownMenuItem(value: 'stop', child: Text('Stop')),
                  ],
                  onChanged: (value) => setLocal(() => mode = value ?? mode),
                ),
                const SizedBox(height: 16),
                Text('Type ${guest.vmid} to confirm this backup job.'),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: '${guest.vmid}'),
                  onChanged: (_) => setLocal(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: confirmCtrl.text.trim() == '${guest.vmid}'
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Run backup'),
            ),
          ],
        ),
      ),
    );
    confirmCtrl.dispose();
    if (confirmed != true || !context.mounted) return;

    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final upid = await api.createBackup(
        guest.node,
        vmid: guest.vmid,
        storage: storage,
        mode: mode,
      );
      ref.invalidate(backupsProvider(refreshNode, storage));
      if (guest.node != refreshNode) {
        ref.invalidate(backupsProvider(guest.node, storage));
      }
      ref.invalidate(recentTasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup requested for ${guest.vmid} ($upid)')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $error')));
      }
    }
  }

  Future<void> _deleteBackup(
    BuildContext context,
    WidgetRef ref, {
    required String node,
    required String storage,
    required String volid,
  }) async {
    final confirmCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Delete backup?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This permanently deletes the backup. Type $volid to confirm.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                autofocus: true,
                decoration: InputDecoration(hintText: volid),
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
              onPressed: confirmCtrl.text.trim() == volid
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    confirmCtrl.dispose();
    if (confirmed != true || !context.mounted) return;

    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final upid = await api.deleteBackupFile(node, storage, volid);
      ref.invalidate(backupsProvider(node, storage));
      ref.invalidate(recentTasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleting backup… ($upid)')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(nodesProvider);
    final containers = ref.watch(allContainersProvider).value ?? const [];
    final vms = ref.watch(allVmsProvider).value ?? const [];
    final guests = _guests(containers, vms);

    return Scaffold(
      appBar: AppBar(title: const Text('Backups')),
      body: nodes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load nodes: $error')),
        data: (nodeList) {
          if (nodeList.isEmpty) {
            return const Center(child: Text('No Proxmox nodes available.'));
          }
          final node = nodeList.first.node;
          final storages = ref.watch(backupStoragesProvider(node));
          final jobs = ref.watch(backupJobsProvider);
          return storages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed to load backup storages: $error')),
            data: (storageMaps) {
              final storageNames =
                  storageMaps
                      .map((item) => '${item['storage'] ?? ''}')
                      .where((name) => name.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
              if (storageNames.isEmpty) {
                return const Center(
                  child: Text('No backup-capable storage is available.'),
                );
              }
              final selected = ref.watch(_selectedBackupStorageProvider);
              final storage = storageNames.contains(selected)
                  ? selected!
                  : storageNames.first;
              final backups = ref.watch(backupsProvider(node, storage));
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  BrassPanel(
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: storage,
                            decoration: const InputDecoration(
                              labelText: 'Backup storage',
                            ),
                            items: [
                              for (final item in storageNames)
                                DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                            ],
                            onChanged: (value) => ref
                                .read(_selectedBackupStorageProvider.notifier)
                                .select(value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: guests.isEmpty
                              ? null
                              : () => _backupNow(
                                  context,
                                  ref,
                                  guests: guests,
                                  storages: storageNames,
                                  initialStorage: storage,
                                  refreshNode: node,
                                ),
                          icon: const Icon(Icons.backup_outlined),
                          label: const Text('Backup now'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BackupsPanel(
                    backups: backups,
                    onDelete: (volid) => _deleteBackup(
                      context,
                      ref,
                      node: node,
                      storage: storage,
                      volid: volid,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _JobsPanel(jobs: jobs),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BackupsPanel extends StatelessWidget {
  const _BackupsPanel({required this.backups, required this.onDelete});

  final AsyncValue<List<Map<String, dynamic>>> backups;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProxmoxSectionHeader('BACKUP FILES'),
            const SizedBox(height: 8),
            backups.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Failed to load backups: $error'),
              data: (items) {
                final sorted = [...items]
                  ..sort(
                    (a, b) => BackupsScreen._asInt(
                      b['ctime'],
                    ).compareTo(BackupsScreen._asInt(a['ctime'])),
                  );
                if (sorted.isEmpty) {
                  return Text(
                    'No backup files on this storage.',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return Column(
                  children: [
                    for (final backup in sorted)
                      _BackupRow(backup: backup, onDelete: onDelete),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupRow extends StatelessWidget {
  const _BackupRow({required this.backup, required this.onDelete});

  final Map<String, dynamic> backup;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final volid = '${backup['volid'] ?? ''}';
    final vmid = BackupsScreen._vmid(backup);
    final notes = '${backup['notes'] ?? ''}'.trim();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.inventory_2_outlined, color: brass.ok),
      title: Text(
        'Guest ${vmid > 0 ? vmid : 'unknown'}  ·  '
        '${BackupsScreen._humanSize(backup['size'])}  ·  '
        '${BackupsScreen._when(backup['ctime'])}',
      ),
      subtitle: Text(
        [
          BackupsScreen._format(backup),
          if (notes.isNotEmpty) notes,
          volid,
        ].join('  ·  '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Delete backup',
        icon: Icon(Icons.delete_outline, color: brass.crit),
        onPressed: volid.isEmpty ? null : () => onDelete(volid),
      ),
    );
  }
}

class _JobsPanel extends StatelessWidget {
  const _JobsPanel({required this.jobs});

  final AsyncValue<List<Map<String, dynamic>>> jobs;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProxmoxSectionHeader('SCHEDULED JOBS'),
            const SizedBox(height: 8),
            jobs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Failed to load backup jobs: $error'),
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    'No scheduled backup jobs.',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return Column(
                  children: [
                    for (final job in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.schedule,
                          color: BackupsScreen._enabled(job['enabled'])
                              ? brass.ok
                              : brass.crit,
                        ),
                        title: Text('${job['schedule'] ?? 'No schedule'}'),
                        subtitle: Text(
                          'Storage: ${job['storage'] ?? 'default'}  ·  '
                          '${BackupsScreen._enabled(job['enabled']) ? 'Enabled' : 'Disabled'}',
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
