import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/pdm_api.dart';
import 'package:peira/screens/pdm/pdm_format.dart';

PdmStorage _s(String name, String node, bool shared, int used, int total) =>
    PdmStorage(
      remote: 'office',
      storage: name,
      node: node,
      shared: shared,
      status: 'available',
      used: used,
      total: total,
    );

void main() {
  test('local storage sums per node; shared storages are never summed', () {
    // Exact bytes PDM reported for the office cluster on 2026-10-22: three
    // NFS shares and a PBS datastore on one NAS volume (the PBS one differs
    // per node by a few KiB), and a PBS datastore on its own disk.
    const nfsUsed = 9207810097152, nfsTotal = 23894986588160;
    final rows = [
      for (final name in ['nas-backups', 'nas-media', 'nas-plex'])
        for (final node in ['n1', 'n2', 'n3', 'n4'])
          _s(name, node, true, nfsUsed, nfsTotal),
      _s('nas-dr-restore', 'n1', true, 9207810183168, 23894986375168),
      _s('nas-dr-restore', 'n2', true, 9207810179072, 23894986375168),
      _s('nas-dr-restore', 'n4', true, 9207810187264, 23894986375168),
      for (final node in ['n1', 'n2', 'n3', 'n4'])
        _s('pbs-local', node, true, 136413032448, 189103947776),
      _s('local-lvm', 'n1', false, 10, 20),
      _s('local-lvm', 'n2', false, 10, 20),
      _s('local', 'n1', false, 1, 5),
    ];

    final summary = pdmStorageSummary(rows);

    expect(summary.localUsed, 21);
    expect(summary.localTotal, 45);
    expect(summary.shared.map((g) => g.names), [
      ['nas-backups', 'nas-dr-restore', 'nas-media', 'nas-plex'],
      ['pbs-local'],
    ]);
    expect(summary.shared.first.total, nfsTotal);
  });

  test('bytes use binary units, as Proxmox shows them', () {
    expect(pdmBytes(512), '512 B');
    expect(pdmBytes(1536), '1.5 KiB');
    expect(pdmBytes(23894986588160), '21.7 TiB');
  });
}
