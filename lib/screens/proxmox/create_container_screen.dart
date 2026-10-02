import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/proxmox_providers.dart';
import '../../core/widgets/brass_panel.dart';

/// Guided "new LXC container" form. Picks a node → loads that node's templates
/// and disk storages → collects resources → POSTs to Proxmox and (optionally)
/// starts the container.
class CreateContainerScreen extends ConsumerStatefulWidget {
  const CreateContainerScreen({super.key});

  @override
  ConsumerState<CreateContainerScreen> createState() =>
      _CreateContainerScreenState();
}

class _CreateContainerScreenState extends ConsumerState<CreateContainerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostname = TextEditingController();
  final _password = TextEditingController();
  final _cores = TextEditingController(text: '2');
  final _memory = TextEditingController(text: '2048');
  final _swap = TextEditingController(text: '512');
  final _disk = TextEditingController(text: '8');

  String? _node;
  String? _template; // volid
  String? _storage;
  final String _bridge = 'vmbr0';
  bool _dhcp = true;
  bool _startAfter = true;
  bool _unprivileged = true;

  List<Map<String, dynamic>> _templates = const [];
  List<Map<String, dynamic>> _storages = const [];
  bool _loadingNodeData = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_hostname, _password, _cores, _memory, _swap, _disk]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onNodeChanged(String? node) async {
    setState(() {
      _node = node;
      _template = null;
      _storage = null;
      _templates = const [];
      _storages = const [];
      _error = null;
    });
    if (node == null) return;
    setState(() => _loadingNodeData = true);
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final templates = await api.getTemplates(node);
      final storages = await api.getStorages(node, content: 'rootdir');
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _storages = storages;
        _template = templates.isNotEmpty
            ? templates.first['volid'] as String?
            : null;
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
    if (_node == null || _template == null || _storage == null) {
      setState(() => _error = 'Pick a node, template and storage.');
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
        'ostemplate': _template,
        'hostname': _hostname.text.trim(),
        'cores': int.parse(_cores.text),
        'memory': int.parse(_memory.text),
        'swap': int.parse(_swap.text),
        'rootfs': '$_storage:${_disk.text}',
        'net0': 'name=eth0,bridge=$_bridge,ip=${_dhcp ? 'dhcp' : 'manual'}',
        'unprivileged': _unprivileged ? 1 : 0,
        'start': _startAfter ? 1 : 0,
        if (_password.text.isNotEmpty) 'password': _password.text,
      };
      await api.createLxc(_node!, params);
      ref.invalidate(allContainersProvider);
      ref.invalidate(recentTasksProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Creating CT $vmid ($_node)…')),
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
        title: const Text('New container'),
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
                          initialValue: _template,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Template',
                          ),
                          items: [
                            for (final t in _templates)
                              DropdownMenuItem(
                                value: t['volid'] as String?,
                                child: Text(
                                  (t['volid'] as String? ?? '').split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _node == null
                              ? null
                              : (v) => setState(() => _template = v),
                          validator: (v) =>
                              v == null ? 'Pick a template' : null,
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
                        controller: _hostname,
                        decoration: const InputDecoration(
                          labelText: 'Hostname',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _numField(_cores, 'Cores'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _numField(_memory, 'Memory (MB)')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _numField(_swap, 'Swap (MB)')),
                          const SizedBox(width: 12),
                          Expanded(child: _numField(_disk, 'Disk (GB)')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Root password',
                          helperText: 'Required unless the template has keys',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BrassPanel(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Network: DHCP on vmbr0'),
                        value: _dhcp,
                        onChanged: (v) => setState(() => _dhcp = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Unprivileged'),
                        value: _unprivileged,
                        onChanged: (v) => setState(() => _unprivileged = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start after create'),
                        value: _startAfter,
                        onChanged: (v) => setState(() => _startAfter = v),
                      ),
                    ],
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
                  label: Text(_submitting ? 'Creating…' : 'Create container'),
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
