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
  /// is `[--, root@ip]`; for a container it's
  /// `[-t, --, root@nodeIp, pct, enter, vmid]` so it works even when the
  /// container runs no sshd.
  final List<String> args;

  /// `--` terminates `ssh`'s option parsing, so every token after it is treated
  /// as the destination or the remote command, never as an option. Destinations
  /// and saved targets are built from Proxmox inventory and operator config; a
  /// value beginning with `-` (e.g. `-oProxyCommand=…`) would otherwise be read
  /// as an `ssh` option and run an arbitrary local command. OpenSSH has honored
  /// `--` for option termination for a long time; these builders put it ahead of
  /// every untrusted operand so that cannot happen. The remote `vmid` is an
  /// `int` by type, so it can carry no shell metacharacters.
  static List<String> nodeArgs(String destination) => ['--', destination];

  static List<String> savedArgs(String target) => ['--', target];

  static List<String> containerArgs({
    required String destination,
    required bool viaSudo,
    required int vmid,
  }) => [
        '-t',
        '--',
        destination,
        if (viaSudo) 'sudo',
        'pct',
        'enter',
        '$vmid',
      ];
}
