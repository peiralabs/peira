import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/proxmox_api.dart';
import '../../core/providers/proxmox_providers.dart';
import '../../core/widgets/brass_panel.dart';

/// Guided "new LXC container" form. Picks a node → loads that node's templates
/// and disk storages → collects resources → POSTs to Proxmox and (optionally)
/// starts the container.
class CreateContainerScreen extends StatelessWidget {
  const CreateContainerScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const CreateGuestScreen(kind: GuestKind.lxc);
}

class CreateGuestScreen extends ConsumerStatefulWidget {
  const CreateGuestScreen({super.key, required this.kind});

  final GuestKind kind;

  @override
  ConsumerState<CreateGuestScreen> createState() => _CreateGuestScreenState();
}

const _osTypes = <(String, String)>[
  ('l26', 'Linux 6.x / 5.x / 2.6 Kernel'),
  ('win11', 'Windows 11 / 2022 / 2025'),
  ('win10', 'Windows 10 / 2016 / 2019'),
  ('win8', 'Windows 8 / 2012'),
  ('other', 'Other'),
];

class _CreateGuestScreenState extends ConsumerState<CreateGuestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _cores = TextEditingController(text: '2');
  final _sockets = TextEditingController(text: '1');
  final _memory = TextEditingController(text: '2048');
  final _swap = TextEditingController(text: '512');
  late final _disk = TextEditingController(
    text: widget.kind == GuestKind.lxc ? '8' : '32',
  );

  String? _node;
  String? _installMedia;
  String? _storage;
  String _ostype = 'l26';
  bool _dhcp = true;
  late bool _startAfter = widget.kind == GuestKind.lxc;
  bool _unprivileged = true;

  List<Map<String, dynamic>> _installMediaOptions = const [];
  List<Map<String, dynamic>> _storages = const [];
  bool _loadingNodeData = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _name,
      _password,
      _cores,
      _sockets,
      _memory,
      _swap,
      _disk,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onNodeChanged(String? node) async {
    setState(() {
      _node = node;
      _installMedia = null;
      _storage = null;
      _installMediaOptions = const [];
      _storages = const [];
      _error = null;
    });
    if (node == null) return;
    setState(() => _loadingNodeData = true);
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final media = await api.getGuestInstallMedia(widget.kind, node);
      final storages = await api.getStorages(
        node,
        content: widget.kind.diskStorageContent,
      );
      if (!mounted) return;
      setState(() {
        _installMediaOptions = media;
        _storages = storages;
        if (widget.kind == GuestKind.lxc) {
          _installMedia = media.isNotEmpty
              ? media.first['volid'] as String?
              : null;
        }
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
    if (_node == null ||
        _storage == null ||
        (widget.kind == GuestKind.lxc && _installMedia == null)) {
      setState(
        () => _error = widget.kind == GuestKind.lxc
            ? 'Pick a node, template and storage.'
            : 'Pick a node and disk storage.',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      final vmid = await api.nextVmid();
      final params = widget.kind.createFields(
        vmid: vmid,
        name: _name.text.trim(),
        cores: int.parse(_cores.text),
        memory: int.parse(_memory.text),
        storage: _storage!,
        disk: _disk.text,
        start: _startAfter,
        installMedia: _installMedia,
        password: _password.text,
        swap: int.parse(_swap.text),
        dhcp: _dhcp,
        unprivileged: _unprivileged,
        sockets: int.parse(_sockets.text),
        osType: _ostype,
      );
      await api.createGuest(widget.kind, _node!, params);
      if (widget.kind == GuestKind.lxc) {
        ref.invalidate(allContainersProvider);
      } else {
        ref.invalidate(allVmsProvider);
      }
      ref.invalidate(recentTasksProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creating ${widget.kind.label} $vmid ($_node)…'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = 'Create failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Proxmox requires the guest name/hostname to be a single DNS label:
  // letters, digits and hyphens only (no underscores, spaces or dots), not
  // starting or ending with a hyphen, max 63 chars. Validating here turns an
  // opaque 400 from the API into an inline, fixable message.
  static final _guestNameRe =
      RegExp(r'^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$');

  String? _validateGuestName(String? v) {
    final name = (v ?? '').trim();
    if (name.isEmpty) return 'Required';
    if (name.length > 63) return 'Too long (max 63 characters)';
    if (!_guestNameRe.hasMatch(name)) {
      return 'Letters, numbers and hyphens only — no underscores or spaces';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodes = ref.watch(nodesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.kind == GuestKind.lxc ? 'New container' : 'New VM'),
        backgroundColor: Colors.transparent,
      ),
      body: nodes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load nodes: $e')),
        data: (nodeList) {
          final online = nodeList.where((n) => n.status == 'online').toList();
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
                          initialValue: _installMedia,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: widget.kind == GuestKind.lxc
                                ? 'Template'
                                : 'Install ISO (optional)',
                          ),
                          items: [
                            if (widget.kind == GuestKind.qemu)
                              const DropdownMenuItem(
                                child: Text('None (no CD-ROM)'),
                              ),
                            for (final media in _installMediaOptions)
                              DropdownMenuItem(
                                value: media['volid'] as String?,
                                child: Text(
                                  (media['volid'] as String? ?? '')
                                      .split('/')
                                      .last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _node == null
                              ? null
                              : (v) => setState(() => _installMedia = v),
                          validator: widget.kind == GuestKind.lxc
                              ? (v) => v == null ? 'Pick a template' : null
                              : null,
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
                        decoration: InputDecoration(
                          labelText: widget.kind == GuestKind.lxc
                              ? 'Hostname'
                              : 'Name',
                        ),
                        validator: _validateGuestName,
                      ),
                      const SizedBox(height: 12),
                      if (widget.kind == GuestKind.qemu) ...[
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
                      ],
                      Row(
                        children: [
                          Expanded(child: _numField(_cores, 'Cores')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: widget.kind == GuestKind.lxc
                                ? _numField(_memory, 'Memory (MB)')
                                : _numField(_sockets, 'Sockets'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: widget.kind == GuestKind.lxc
                                ? _numField(_swap, 'Swap (MB)')
                                : _numField(_memory, 'Memory (MB)'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _numField(_disk, 'Disk (GB)')),
                        ],
                      ),
                      if (widget.kind == GuestKind.lxc) ...[
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BrassPanel(
                  child: widget.kind == GuestKind.lxc
                      ? Column(
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
                              onChanged: (v) =>
                                  setState(() => _unprivileged = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Start after create'),
                              value: _startAfter,
                              onChanged: (v) => setState(() => _startAfter = v),
                            ),
                          ],
                        )
                      : SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Start after create'),
                          value: _startAfter,
                          onChanged: (v) => setState(() => _startAfter = v),
                        ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
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
                  label: Text(
                    _submitting
                        ? 'Creating…'
                        : widget.kind == GuestKind.lxc
                        ? 'Create container'
                        : 'Create VM',
                  ),
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
