import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/proxmox_providers.dart';
import '../../core/widgets/brass_panel.dart';

/// Guided "new QEMU VM" form. Picks a node → loads that node's install ISOs
/// and image storages → collects resources → POSTs to Proxmox and (optionally)
/// starts the VM.
class CreateVmScreen extends ConsumerStatefulWidget {
  const CreateVmScreen({super.key});

  @override
  ConsumerState<CreateVmScreen> createState() => _CreateVmScreenState();
}

/// Proxmox OS-type codes → human labels (drives guest optimisations).
const _osTypes = <(String, String)>[
  ('l26', 'Linux 6.x / 5.x / 2.6 Kernel'),
  ('win11', 'Windows 11 / 2022 / 2025'),
  ('win10', 'Windows 10 / 2016 / 2019'),
  ('win8', 'Windows 8 / 2012'),
  ('other', 'Other'),
];

class _CreateVmScreenState extends ConsumerState<CreateVmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cores = TextEditingController(text: '2');
  final _sockets = TextEditingController(text: '1');
  final _memory = TextEditingController(text: '2048');
  final _disk = TextEditingController(text: '32');

  String? _node;
  String? _iso; // volid, optional
  String? _storage;
  String _ostype = 'l26';
  final String _bridge = 'vmbr0';
  bool _startAfter = false;

  List<Map<String, dynamic>> _isos = const [];
  List<Map<String, dynamic>> _storages = const [];
  bool _loadingNodeData = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _cores, _sockets, _memory, _disk]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onNodeChanged(String? node) async {
    setState(() {
      _node = node;
      _iso = null;
      _storage = null;
      _isos = const [];
      _storages = const [];
      _error = null;
    });
    if (node == null) return;
    setState(() => _loadingNodeData = true);
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final isos = await api.getIsos(node);
      final storages = await api.getStorages(node, content: 'images');
      if (!mounted) return;
      setState(() {
        _isos = isos;
        _storages = storages;
        _storage = storages.isNotEmpty
            ? storages.first['storage'] as String?
            : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load node data: $e');
    } finally {
      if (mounted) setState(() => _loadingNodeData = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_node == null || _storage == null) {
      setState(() => _error = 'Pick a node and disk storage.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final vmid = await api.nextVmid();
      final params = <String, dynamic>{
        'vmid': vmid,
        'name': _name.text.trim(),
        'cores': int.parse(_cores.text),
        'sockets': int.parse(_sockets.text),
        'memory': int.parse(_memory.text),
        'ostype': _ostype,
        'scsihw': 'virtio-scsi-pci',
        'scsi0': '$_storage:${_disk.text}',
        'net0': 'virtio,bridge=$_bridge',
        if (_iso != null) 'ide2': '$_iso,media=cdrom',
        'boot': 'order=scsi0;ide2;net0',
        'start': _startAfter ? 1 : 0,
      };
      await api.createVm(_node!, params);
      ref.invalidate(allVmsProvider);
      ref.invalidate(recentTasksProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Creating VM $vmid ($_node)…')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = 'Create failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodes = ref.watch(nodesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('New VM'),
        backgroundColor: Colors.transparent,
      ),
      body: nodes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load nodes: $e')),
        data: (nodeList) {
          final online = nodeList
              .where((n) => n.status == 'online')
              .toList();
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                BrassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _node,
                        decoration: const InputDecoration(labelText: 'Node'),
                        items: [
                          for (final n in online)
                            DropdownMenuItem(
                              value: n.node,
                              child: Text(n.node),
                            ),
                        ],
                        onChanged: _onNodeChanged,
                        validator: (v) => v == null ? 'Pick a node' : null,
                      ),
                      const SizedBox(height: 12),
                      if (_loadingNodeData)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        )
                      else ...[
                        DropdownButtonFormField<String>(
                          initialValue: _iso,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Install ISO (optional)',
                          ),
                          items: [
                            const DropdownMenuItem(
                              child: Text('None (no CD-ROM)'),
                            ),
                            for (final iso in _isos)
                              DropdownMenuItem(
                                value: iso['volid'] as String?,
                                child: Text(
                                  (iso['volid'] as String? ?? '')
                                      .split('/')
                                      .last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _node == null
                              ? null
                              : (v) => setState(() => _iso = v),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _storage,
                          decoration: const InputDecoration(
                            labelText: 'Disk storage',
                          ),
                          items: [
                            for (final s in _storages)
                              DropdownMenuItem(
                                value: s['storage'] as String?,
                                child: Text(s['storage'] as String? ?? ''),
                              ),
                          ],
                          onChanged: _node == null
                              ? null
                              : (v) => setState(() => _storage = v),
                          validator: (v) => v == null ? 'Pick storage' : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BrassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _ostype,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'OS type',
                        ),
                        items: [
                          for (final (code, label) in _osTypes)
                            DropdownMenuItem(value: code, child: Text(label)),
                        ],
                        onChanged: (v) =>
                            setState(() => _ostype = v ?? 'l26'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _numField(_cores, 'Cores')),
                          const SizedBox(width: 12),
                          Expanded(child: _numField(_sockets, 'Sockets')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _numField(_memory, 'Memory (MB)')),
                          const SizedBox(width: 12),
                          Expanded(child: _numField(_disk, 'Disk (GB)')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BrassPanel(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start after create'),
                    value: _startAfter,
                    onChanged: (v) => setState(() => _startAfter = v),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_submitting ? 'Creating…' : 'Create VM'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) => TextFormField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    validator: (v) =>
        (v == null || int.tryParse(v) == null || int.parse(v) <= 0)
        ? 'Required'
        : null,
  );
}
