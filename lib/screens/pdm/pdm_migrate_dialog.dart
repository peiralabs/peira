import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pdm_api.dart';
import '../../core/providers/pdm_jobs.dart';
import '../../core/providers/pdm_providers.dart';
import '../../core/theme/app_theme.dart';
import 'pdm_format.dart';

class PdmMigrateDialog extends ConsumerStatefulWidget {
  const PdmMigrateDialog({
    super.key,
    required this.guest,
    required this.target,
    required this.config,
    required this.overview,
  });

  final PdmGuest guest;
  final PdmRemoteInfo target;
  final PdmGuestConfig config;
  final List<PdmRemoteOverview> overview;

  @override
  ConsumerState<PdmMigrateDialog> createState() => _PdmMigrateDialogState();
}

class _PdmMigrateDialogState extends ConsumerState<PdmMigrateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _vmid;
  final _bandwidth = TextEditingController();
  Map<String, String> _storageMap = {};
  Map<String, String> _bridgeMap = {};
  List<String> _bridges = const [];
  String? _endpoint;
  bool _delete = true;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  PdmRemoteOverview get _targetOverview =>
      widget.overview.firstWhere((o) => o.remote.id == widget.target.id);

  @override
  void initState() {
    super.initState();
    _vmid = TextEditingController();
    _endpoint = _preferredEndpoint();
    _load();
  }

  @override
  void dispose() {
    _vmid.dispose();
    _bandwidth.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = await ref.read(pdmApiProvider.future);
      final onlineNodes =
          _targetOverview.resources?.nodes.where((n) => n.status == 'online') ??
          const Iterable<PdmNode>.empty();
      final results = await Future.wait<dynamic>([
        api.nextId(widget.target.id),
        if (onlineNodes.isNotEmpty)
          api.bridges(widget.target.id, onlineNodes.first.name)
        else
          Future<List<String>>.value(const []),
      ]);
      final storages =
          (_targetOverview.resources?.storages ?? const [])
              .where((s) => s.status == 'available')
              .map((s) => s.storage)
              .toSet()
              .toList()
            ..sort();
      _bridges = (results[1] as List<String>).toSet().toList()..sort();
      _storageMap = {
        for (final source in widget.config.storages)
          if (storages.isNotEmpty)
            source: storages.contains(source) ? source : storages.first,
      };
      _bridgeMap = {
        for (final source in widget.config.bridges)
          if (_bridges.isNotEmpty)
            source: _bridges.contains(source) ? source : _bridges.first,
      };
      if (!mounted) return;
      setState(() {
        _vmid.text = '${results[0]}';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _message(error);
      });
    }
  }

  String? _preferredEndpoint() {
    if (widget.target.endpoints.isEmpty) return null;
    final source = widget.overview
        .where((o) => o.remote.id == widget.guest.remote)
        .map((o) => o.remote)
        .firstOrNull;
    final sourceEndpoints = source?.endpoints ?? const <String>[];
    final sourceHasTail = sourceEndpoints.any(_isTailscale);
    final sourceAllTail =
        sourceEndpoints.isNotEmpty && sourceEndpoints.every(_isTailscale);
    final targetHasTail = widget.target.endpoints.any(_isTailscale);
    final targetHasOther = widget.target.endpoints.any((e) => !_isTailscale(e));
    if ((sourceAllTail || (sourceHasTail && targetHasTail && targetHasOther)) &&
        targetHasTail) {
      return widget.target.endpoints.firstWhere(_isTailscale);
    }
    return widget.target.endpoints.first;
  }

  static bool _isTailscale(String endpoint) {
    final host = Uri.tryParse(
      endpoint.contains('://') ? endpoint : 'https://$endpoint',
    )?.host;
    final parts = host?.split('.').map(int.tryParse).toList();
    return parts != null &&
        parts.length == 4 &&
        parts.every((p) => p != null) &&
        parts[0] == 100 &&
        parts[1]! >= 64 &&
        parts[1]! <= 127;
  }

  List<String> get _storageOptions =>
      (_targetOverview.resources?.storages ?? const [])
          .where((s) => s.status == 'available')
          .map((s) => s.storage)
          .toSet()
          .toList()
        ..sort();

  String? _validateVmid(String? value) {
    final id = int.tryParse(value ?? '');
    if (id == null || id < 100) return 'Enter a VMID of 100 or greater';
    final used =
        _targetOverview.resources?.guests.any((g) => g.vmid == id) ?? false;
    return used ? 'VMID $id is already used on ${widget.target.id}' : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = await ref.read(pdmApiProvider.future);
      final running = widget.guest.status == 'running';
      final bandwidthMiB = int.tryParse(_bandwidth.text.trim());
      final upid = await api.remoteMigrate(
        widget.guest.remote,
        widget.guest.kind,
        widget.guest.vmid,
        target: widget.target.id,
        storageMap: _storageMap,
        bridgeMap: _bridgeMap,
        targetVmid: int.parse(_vmid.text),
        delete: _delete,
        online: running && widget.guest.kind == 'qemu' ? true : null,
        restart: running && widget.guest.kind == 'lxc' ? true : null,
        timeout: running && widget.guest.kind == 'lxc' ? 180 : null,
        bwlimitKiB: bandwidthMiB == null ? null : bandwidthMiB * 1024,
        targetEndpoint: _endpoint,
      );
      ref
          .read(pdmJobsProvider.notifier)
          .runMigration(
            guestKey: PdmJobs.key(widget.guest.remote, widget.guest.vmid),
            sourceRemote: widget.guest.remote,
            targetRemote: widget.target.id,
            upid: upid,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = _message(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final runningCt =
        widget.guest.kind == 'lxc' && widget.guest.status == 'running';
    final privileged =
        widget.guest.kind == 'lxc' && !widget.config.unprivileged;
    final minutesFast = widget.guest.maxdisk / (10 * 1024 * 1024) / 60;
    final minutesSlow = widget.guest.maxdisk / (5 * 1024 * 1024) / 60;
    return AlertDialog(
      title: Text('Migrate ${widget.guest.name} to ${widget.target.id}'),
      content: SizedBox(
        width: 540,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Disk: ${pdmBytes(widget.guest.maxdisk)} · '
                        '≈ ${math.max(1, minutesFast.ceil())}–'
                        '${math.max(1, minutesSlow.ceil())} min at 5–10 MB/s',
                      ),
                      if (runningCt)
                        const _Warning(
                          'The container is shut down for the whole copy and started on the target',
                        ),
                      if (privileged)
                        const _Warning(
                          'This is a privileged container. Review its host access on the target.',
                        ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey('pdm-target-vmid'),
                        controller: _vmid,
                        decoration: const InputDecoration(
                          labelText: 'Target VMID',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _validateVmid,
                      ),
                      for (final source in widget.config.storages)
                        DropdownButtonFormField<String>(
                          key: ValueKey('pdm-storage-$source'),
                          initialValue: _storageMap[source],
                          decoration: InputDecoration(
                            labelText: 'Storage: $source',
                          ),
                          items: [
                            for (final option in _storageOptions)
                              DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _storageMap[source] = value!),
                        ),
                      for (final source in widget.config.bridges)
                        DropdownButtonFormField<String>(
                          key: ValueKey('pdm-bridge-$source'),
                          initialValue: _bridgeMap[source],
                          decoration: InputDecoration(
                            labelText: 'Bridge: $source',
                          ),
                          items: [
                            for (final option in _bridges)
                              DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _bridgeMap[source] = value!),
                        ),
                      if (widget.target.endpoints.isNotEmpty)
                        DropdownButtonFormField<String>(
                          key: const ValueKey('pdm-target-endpoint'),
                          initialValue: _endpoint,
                          decoration: const InputDecoration(
                            labelText: 'Target endpoint',
                            helperText:
                                "Must be reachable from the source cluster's nodes",
                          ),
                          items: [
                            for (final endpoint in widget.target.endpoints)
                              DropdownMenuItem(
                                value: endpoint,
                                child: Text(endpoint),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _endpoint = value),
                        ),
                      TextFormField(
                        controller: _bandwidth,
                        decoration: const InputDecoration(
                          labelText: 'Bandwidth limit MiB/s (optional)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Delete the original after a successful migration',
                        ),
                        value: _delete,
                        onChanged: (value) => setState(() => _delete = value),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _error!,
                            style: TextStyle(color: brass.crit),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('pdm-migrate-submit'),
          onPressed: _loading || _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Migrate'),
        ),
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, size: 18, color: context.brass.warn),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: context.brass.warn)),
        ),
      ],
    ),
  );
}

String _message(Object error) =>
    error is PdmApiException ? error.message : '$error';
