import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/models/container_status.dart';
import 'package:peira/core/models/node_status.dart';
import 'package:peira/core/models/proxmox_container.dart';
import 'package:peira/core/models/proxmox_node.dart';
import 'package:peira/core/models/proxmox_task.dart';
import 'package:peira/core/models/tailscale_status.dart';

/// Fixtures are real payloads captured from the cluster on 2026-07-03 —
/// parsing them guards against the API's int/float quirks (cpu is float on
/// nodes but int 0 on idle containers, running tasks omit endtime/status).
dynamic fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())['data'];

void main() {
  test('ProxmoxNode parses /nodes', () {
    final nodes = (fixture('nodes') as List)
        .map((e) => ProxmoxNode.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(nodes, hasLength(4));
    expect(nodes.every((n) => n.status == 'online'), isTrue);
    expect(nodes.first.cpu, isA<double>());
  });

  test('NodeStatus parses /nodes/{node}/status', () {
    final status =
        NodeStatus.fromJson(fixture('node_status') as Map<String, dynamic>);
    expect(status.kversion, contains('pve'));
    expect(status.memory?.total, greaterThan(0));
    expect(status.memory?.usedFraction, inExclusiveRange(0, 1));
  });

  test('ProxmoxContainer parses /nodes/{node}/lxc (int cpu tolerated)', () {
    final cts = (fixture('containers') as List)
        .map((e) => ProxmoxContainer.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(cts, isNotEmpty);
    expect(cts.first.vmid, isA<int>());
    expect(cts.every((c) => c.status.isNotEmpty), isTrue);
  });

  test('ContainerStatus parses /status/current', () {
    final status = ContainerStatus.fromJson(
        fixture('container_status') as Map<String, dynamic>);
    expect(status.status, 'running');
    expect(status.maxmem, greaterThan(0));
  });

  test('ProxmoxTask parses /cluster/tasks', () {
    final tasks = (fixture('tasks') as List)
        .map((e) => ProxmoxTask.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(tasks, hasLength(5));
    expect(tasks.first.upid, startsWith('UPID:'));
  });

  test('ProxmoxTask handles a running task (no endtime/status)', () {
    final task = ProxmoxTask.fromJson(const {
      'upid': 'UPID:node4:0000:0000:0000:vzdump:104:root@pam:',
      'node': 'node4',
      'type': 'vzdump',
      'starttime': 1751500000,
    });
    expect(task.isRunning, isTrue);
    expect(task.isOk, isFalse);
    // A running task is not a failure just because it has no status yet.
    expect(task.isFailed, isFalse);
  });

  test('ProxmoxTask treats a WARNINGS status as not-failed', () {
    ProxmoxTask withStatus(String status) => ProxmoxTask.fromJson({
          'upid': 'UPID:node4:0000:0000:0000:vzstart:9106:root@pam:',
          'node': 'node4',
          'type': 'vzstart',
          'starttime': 1751500000,
          'endtime': 1751500001,
          'status': status,
        });

    // The real case: `pct start` on a restored container emits
    // "WARN: Systemd 252 detected..." and PVE records "WARNINGS: 1".
    // That is a successful start, not a failed task.
    final warned = withStatus('WARNINGS: 1');
    expect(warned.isOk, isFalse);
    expect(warned.hasWarnings, isTrue);
    expect(warned.isFailed, isFalse);

    final ok = withStatus('OK');
    expect(ok.isFailed, isFalse);
    expect(ok.hasWarnings, isFalse);

    // A genuine failure still reports as failed.
    final failed =
        withStatus("command 'apt-get update' failed: exit code 100");
    expect(failed.isFailed, isTrue);
    expect(failed.hasWarnings, isFalse);
  });
  test('AppSettings.sshShortcuts parses label=target and bare lines', () {
    const s = AppSettings(
      sshTargets: 'node1=root@192.168.1.10\n\n  admin@nas  \nweird=a=b',
    );
    final sc = s.sshShortcuts;
    expect(sc, hasLength(3));
    expect(sc[0], (label: 'node1', target: 'root@192.168.1.10'));
    // A bare line labels itself; blank lines are skipped.
    expect(sc[1], (label: 'admin@nas', target: 'admin@nas'));
    // Only the first '=' splits, so targets may contain '='.
    expect(sc[2], (label: 'weird', target: 'a=b'));
  });

  test('TailscaleStatus parses tailscale status --json', () {
    final raw = jsonDecode(
            File('test/fixtures/tailscale_status.json').readAsStringSync())
        as Map<String, dynamic>;
    final status = TailscaleStatus.fromJson(raw);
    expect(status.running, isTrue);
    expect(status.self.hostName, 'laptop');
    expect(status.self.ip, '100.64.0.10');
    expect(status.peers, hasLength(2));
    // Online peers sort first.
    expect(status.peers.first.hostName, 'node4');
    expect(status.peers.first.exitNodeOption, isTrue);
    expect(status.peers.last.online, isFalse);
  });

}
