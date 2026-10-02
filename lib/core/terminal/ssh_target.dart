/// One connectable SSH destination shown in the terminal's "+" menu. Built from
/// live Proxmox inventory (nodes + running containers) and the operator's saved
/// shortcuts — see `sshTargetsProvider`. No addresses are baked into source.
class SshTarget {
  const SshTarget({
    required this.label,
    required this.group,
    required this.subtitle,
    required this.args,
  });

  /// Display name, e.g. `node4` or `CT 108 · minecraft`.
  final String label;

  /// Menu grouping: `Nodes`, `Containers`, or `Saved`.
  final String group;

  /// Secondary line, e.g. `root@10.0.0.73` or `via node4 · pct enter`.
  final String subtitle;

  /// Arguments passed to `ssh` (the process the session runs). For a node this
  /// is `[root@ip]`; for a container it's `[-t, root@nodeIp, pct, enter, vmid]`
  /// so it works even when the container runs no sshd.
  final List<String> args;
}
