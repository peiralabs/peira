import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/terminal/ssh_target.dart';

/// The terminal's SSH destinations are built from Proxmox inventory and the
/// operator's saved shortcuts. If a destination or saved target began with `-`
/// (e.g. `-oProxyCommand=…`), `ssh` would parse it as an option and run an
/// arbitrary local command. Every builder must put `--` ahead of any such
/// operand so option parsing is already terminated.
void main() {
  group('SshTarget arg builders terminate ssh option parsing', () {
    test('nodeArgs puts -- before the destination', () {
      expect(SshTarget.nodeArgs('root@10.0.0.73'), ['--', 'root@10.0.0.73']);
    });

    test('savedArgs puts -- before the target', () {
      expect(SshTarget.savedArgs('admin@nas'), ['--', 'admin@nas']);
    });

    test('containerArgs puts -- before the destination (root: no sudo)', () {
      expect(
        SshTarget.containerArgs(
          destination: 'root@10.0.0.73',
          viaSudo: false,
          vmid: 108,
        ),
        ['-t', '--', 'root@10.0.0.73', 'pct', 'enter', '108'],
      );
    });

    test('containerArgs inserts sudo for a non-root user', () {
      expect(
        SshTarget.containerArgs(
          destination: 'ops@10.0.0.73',
          viaSudo: true,
          vmid: 108,
        ),
        ['-t', '--', 'ops@10.0.0.73', 'sudo', 'pct', 'enter', '108'],
      );
    });

    // The security property: a hostile operand is never positioned where ssh
    // would read it as an option — `--` always precedes it.
    test('a dash-leading operand is guarded by a preceding --', () {
      for (final args in [
        SshTarget.nodeArgs('-oProxyCommand=touch /tmp/pwned@h'),
        SshTarget.savedArgs('-oProxyCommand=touch /tmp/pwned'),
        SshTarget.containerArgs(
          destination: '-oProxyCommand=touch /tmp/pwned@h',
          viaSudo: false,
          vmid: 108,
        ),
      ]) {
        final dashDash = args.indexOf('--');
        final hostile = args.indexWhere((a) => a.startsWith('-oProxyCommand'));
        expect(dashDash, isNonNegative, reason: 'args must contain --');
        expect(dashDash, lessThan(hostile),
            reason: '-- must come before the untrusted operand: $args');
      }
    });
  });
}
