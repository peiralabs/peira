import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pdm_api.dart';
import '../../core/providers/pdm_jobs.dart';
import '../../core/providers/pdm_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/status_light.dart';
import 'pdm_format.dart';
import 'pdm_migrate_dialog.dart';

class PdmGuestsView extends ConsumerStatefulWidget {
  const PdmGuestsView({super.key});
  @override
  ConsumerState<PdmGuestsView> createState() => _PdmGuestsViewState();
}

class _PdmGuestsViewState extends ConsumerState<PdmGuestsView> {
  String _query = '';
  final Set<String> _remotes = {};
  bool _running = false;
  bool _stopped = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(pdmJobsProvider, (_, _) {
      final notifier = ref.read(pdmJobsProvider.notifier);
      final result = notifier.lastResult;
      if (result == null) return;
      notifier.clearLastResult();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '${result.label} completed'
                : '${result.label} failed: ${result.exitStatus ?? 'unknown error'}',
          ),
        ),
      );
    });
    final overview = ref.watch(pdmOverviewProvider);
    final jobs = ref.watch(pdmJobsProvider);
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 22, 24, 12),
          child: ScreenHeader(
            icon: Ph.hardDrives,
            title: 'Guests',
            subtitle: 'ALL PVE REMOTES',
          ),
        ),
        Expanded(
          child: overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed to load guests: $error')),
            data: (data) {
              final pve = data.where((o) => o.remote.type == 'pve').toList();
              final guests =
                  [
                    for (final remote in pve)
                      for (final guest
                          in remote.resources?.guests ?? const <PdmGuest>[])
                        if (!guest.template) guest,
                  ]..sort((a, b) {
                    final remote = a.remote.compareTo(b.remote);
                    return remote != 0 ? remote : a.vmid.compareTo(b.vmid);
                  });
              final filtered = guests.where((g) {
                final haystack =
                    '${g.name} ${g.vmid} ${g.node} ${g.tags.join(' ')}'
                        .toLowerCase();
                if (_query.isNotEmpty &&
                    !haystack.contains(_query.toLowerCase())) {
                  return false;
                }
                if (_remotes.isNotEmpty && !_remotes.contains(g.remote)) {
                  return false;
                }
                if (_running && g.status != 'running') {
                  return false;
                }
                if (_stopped && g.status == 'running') {
                  return false;
                }
                return true;
              }).toList();
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(pdmOverviewProvider);
                  await ref.read(pdmOverviewProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  children: [
                    TextField(
                      key: const ValueKey('pdm-guest-search'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Ph.magnifyingGlass),
                        hintText: 'Search name, VMID, node, or tags',
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final remote in pve)
                          FilterChip(
                            label: Text(remote.remote.id),
                            selected: _remotes.contains(remote.remote.id),
                            onSelected: (selected) => setState(
                              () => selected
                                  ? _remotes.add(remote.remote.id)
                                  : _remotes.remove(remote.remote.id),
                            ),
                          ),
                        FilterChip(
                          label: const Text('Running'),
                          selected: _running,
                          onSelected: (value) =>
                              setState(() => _running = value),
                        ),
                        FilterChip(
                          label: const Text('Stopped'),
                          selected: _stopped,
                          onSelected: (value) =>
                              setState(() => _stopped = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            'No guests match the filters.',
                            style: TextStyle(color: context.brass.textMuted),
                          ),
                        ),
                      ),
                    for (final guest in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _GuestRow(
                          guest: guest,
                          remotes: pve,
                          job: jobs[PdmJobs.key(guest.remote, guest.vmid)],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GuestRow extends ConsumerStatefulWidget {
  const _GuestRow({required this.guest, required this.remotes, this.job});
  final PdmGuest guest;
  final List<PdmRemoteOverview> remotes;
  final PdmJob? job;
  @override
  ConsumerState<_GuestRow> createState() => _GuestRowState();
}

class _GuestRowState extends ConsumerState<_GuestRow> {
  PdmGuestConfig? _config;
  Object? _configError;
  bool _configLoading = false;

  Future<void> _loadConfig() async {
    if (_config != null ||
        _configLoading ||
        widget.guest.tags.contains('iac')) {
      return;
    }
    setState(() => _configLoading = true);
    try {
      final api = await ref.read(pdmApiProvider.future);
      final value = await api.guestConfig(
        widget.guest.remote,
        widget.guest.kind,
        widget.guest.vmid,
      );
      if (mounted) setState(() => _config = value);
    } catch (error) {
      if (mounted) setState(() => _configError = error);
    } finally {
      if (mounted) setState(() => _configLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guest = widget.guest;
    final brass = context.brass;
    final running = guest.status == 'running';
    return BrassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          StatusLight(
            health: running
                ? Health.ok
                : guest.status == 'paused'
                ? Health.warn
                : Health.offline,
            size: 9,
          ),
          const SizedBox(width: 10),
          _Badge(guest.kind == 'lxc' ? 'CT' : 'VM'),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${guest.vmid}',
              style: TextStyle(color: brass.giltBright),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              guest.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              '${guest.remote} · ${guest.node}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: brass.textMuted),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              running ? '${(guest.cpu * 100).toStringAsFixed(1)}%' : '—',
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(
              '${pdmBytes(guest.mem)} / ${pdmBytes(guest.maxmem)}',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: brass.textMuted),
            ),
          ),
          if (guest.tags.isNotEmpty) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                guest.tags.join(' · '),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: brass.smallCaps, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(width: 8),
          if (widget.job != null) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 7),
            Text(widget.job!.label, style: TextStyle(color: brass.warn)),
          ] else
            PopupMenuButton<String>(
              key: ValueKey('pdm-menu-${guest.remote}-${guest.vmid}'),
              tooltip: 'Guest actions',
              onOpened: _loadConfig,
              onSelected: _selected,
              itemBuilder: (_) => _menuItems(context),
            ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuItems(BuildContext context) {
    final guest = widget.guest;
    final running = guest.status == 'running';
    final items = <PopupMenuEntry<String>>[
      if (!running) const PopupMenuItem(value: 'start', child: Text('Start')),
      if (running) ...const [
        PopupMenuItem(value: 'shutdown', child: Text('Shutdown')),
        PopupMenuItem(value: 'stop', child: Text('Stop (hard)')),
        PopupMenuItem(value: 'reboot', child: Text('Reboot')),
      ],
      if (guest.kind == 'qemu' && guest.status == 'paused')
        const PopupMenuItem(value: 'resume', child: Text('Resume')),
    ];
    final targets = widget.remotes.where((o) => o.remote.id != guest.remote);
    for (final target in targets) {
      final reason = guest.tags.contains('iac')
          ? 'Managed by OpenTofu — migrating it would drift the IaC state'
          : _config?.hasRawLxcKeys == true
          ? "Has raw lxc.* keys (device passthrough) bound to this cluster's hardware"
          : _configError != null
          ? 'Could not check migration: $_configError'
          : null;
      final ready = _config != null && reason == null;
      items.add(
        PopupMenuItem(
          value: ready ? 'migrate:${target.remote.id}' : null,
          enabled: ready,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Migrate to ${target.remote.id}…'),
              if (reason != null)
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.brass.textMuted,
                  ),
                )
              else if (!ready)
                const Text(
                  'Checking guest configuration…',
                  style: TextStyle(fontSize: 11),
                ),
            ],
          ),
        ),
      );
    }
    return items;
  }

  Future<void> _selected(String value) async {
    if (value.startsWith('migrate:')) {
      final targetId = value.substring('migrate:'.length);
      final target = widget.remotes.firstWhere((o) => o.remote.id == targetId);
      final confirmed = await _confirm(
        'Migrate ${widget.guest.name}?',
        'Migrate ${widget.guest.name} from ${widget.guest.remote} to $targetId?',
      );
      if (!confirmed || !mounted) return;
      await showDialog<bool>(
        context: context,
        builder: (_) => PdmMigrateDialog(
          guest: widget.guest,
          target: target.remote,
          config: _config!,
          overview: widget.remotes,
        ),
      );
      return;
    }
    if (const {'shutdown', 'stop', 'reboot'}.contains(value)) {
      final warning = value == 'stop'
          ? 'Hard stop ${widget.guest.name} on ${widget.guest.remote}? '
                'This is like pulling the plug.'
          : '${_title(value)} ${widget.guest.name} on ${widget.guest.remote}?';
      if (!await _confirm('${_title(value)} ${widget.guest.name}?', warning)) {
        return;
      }
    }
    ref.read(pdmJobsProvider.notifier).runPowerAction(widget.guest, value);
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      border: Border.all(color: context.brass.hairline),
      borderRadius: BorderRadius.circular(5),
      color: context.brass.recess,
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: context.brass.smallCaps,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _title(String action) => switch (action) {
  'shutdown' => 'Shutdown',
  'stop' => 'Stop',
  'reboot' => 'Reboot',
  _ => action,
};
