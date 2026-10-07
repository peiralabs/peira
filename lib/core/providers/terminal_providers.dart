import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../terminal/ssh_target.dart';
import 'proxmox_providers.dart';
import 'settings_providers.dart';

/// The SSH destinations offered in the terminal's "+" menu: the operator's
/// saved shortcuts, plus live Proxmox inventory (online nodes and running
/// containers) with their real addresses pulled from `/cluster/status`.
///
/// Best-effort on the cluster part — if Proxmox isn't configured or is
/// unreachable, the saved shortcuts still show.
final sshTargetsProvider =
    FutureProvider.autoDispose<List<SshTarget>>((ref) async {
  final targets = <SshTarget>[];

  final settings = await ref.watch(settingsControllerProvider.future);
  // Configurable because Proxmox's own hardening guidance is to disable root
  // SSH — operators following it connect as an admin user instead.
  final user = settings.sshUser;
  for (final s in settings.sshShortcuts) {
    targets.add(SshTarget(
      label: s.label,
      group: 'Saved',
      subtitle: s.target,
      args: SshTarget.savedArgs(s.target),
    ));
  }

  try {
    final api = await ref.watch(proxmoxApiProvider.future);
    final nodes = await ref.watch(nodesProvider.future);

    // `/cluster/status` node entries only carry an `ip` when the server can
    // resolve the nodename; a standalone (non-clustered) node has no corosync
    // config to fall back on, so the field can be absent there. A single-node
    // install has a perfectly good address anyway — the host the operator
    // configured — so the terminal never shows an unexplained empty Nodes
    // section on the most common Proxmox shape.
    Map<String, String> ips = const {};
    try {
      ips = await api.nodeAddresses();
    } catch (_) {
      // Endpoint unavailable — the single-node fallback below still works.
    }
    final urlHost = Uri.tryParse(settings.proxmoxUrl)?.host;
    final soleHost =
        nodes.length == 1 && (urlHost?.isNotEmpty ?? false) ? urlHost : null;

    for (final n in nodes.where((n) => n.status == 'online')) {
      final ip = ips[n.node] ?? soleHost;
      if (ip == null) continue;
      targets.add(SshTarget(
        label: n.node,
        group: 'Nodes',
        subtitle: '$user@$ip',
        args: SshTarget.nodeArgs('$user@$ip'),
      ));
    }

    final cts = await ref.watch(allContainersProvider.future);
    for (final c in cts.where((c) => c.status == 'running')) {
      final ip = ips[c.node] ?? soleHost;
      if (ip == null) continue;
      final name = (c.name ?? '').trim();
      targets.add(SshTarget(
        label: name.isEmpty ? 'CT ${c.vmid}' : 'CT ${c.vmid} · $name',
        group: 'Containers',
        subtitle: 'via ${c.node} · pct enter',
        // pct enter reaches the container from its node — no in-container sshd
        // required. -t forces a TTY for the interactive shell. pct itself
        // needs root on the node, so a non-root SSH user goes through sudo
        // (absent sudo rights fail loudly in the terminal, not silently).
        args: SshTarget.containerArgs(
          destination: '$user@$ip',
          viaSudo: user != 'root',
          vmid: c.vmid,
        ),
      ));
    }
  } catch (_) {
    // Proxmox unconfigured/unreachable — saved shortcuts only.
  }

  return targets;
});
