import '../../core/api/pdm_api.dart';

/// Byte counts as Proxmox shows them: powers of 1024 with binary unit names,
/// matching the Proxmox tab's backups screen.
String pdmBytes(int bytes) {
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 100 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

/// One line of shared (network) storage: storages whose figures agree to
/// within 0.1% are listed together, since they are almost certainly folders
/// on one volume. Display only; nothing here is ever added up.
class PdmSharedStorage {
  const PdmSharedStorage(this.names, this.used, this.total);
  final List<String> names;
  final int used;
  final int total;
}

/// A cluster's storage, split so no total is ever wrong:
/// - local: per-node, non-shared storages, summed (the cluster's own disks);
/// - shared: network storages, each once, grouped by near-equal figures.
/// Shared storages are never summed: several can be one NAS volume, and a PBS
/// datastore on that volume reports bytes that differ per node by a few KiB,
/// so an exact-match dedupe still counts the volume several times
/// (2026-10-22: 110.6 TiB "total" for an office with a 21.7 TiB NAS).
({int localUsed, int localTotal, List<PdmSharedStorage> shared})
pdmStorageSummary(Iterable<PdmStorage> storages) {
  var localUsed = 0;
  var localTotal = 0;
  final byName = <String, PdmStorage>{};
  for (final s in storages) {
    if (!s.shared) {
      localUsed += s.used;
      localTotal += s.total;
    } else {
      byName.putIfAbsent(s.storage, () => s);
    }
  }
  bool near(int a, int b) => (a - b).abs() <= (a > b ? a : b) * 0.001;
  final groups = <PdmSharedStorage>[];
  for (final name in byName.keys.toList()..sort()) {
    final s = byName[name]!;
    final i = groups.indexWhere(
      (g) => near(g.total, s.total) && near(g.used, s.used),
    );
    if (i < 0) {
      groups.add(PdmSharedStorage([name], s.used, s.total));
    } else {
      final g = groups[i];
      groups[i] = PdmSharedStorage([...g.names, name], g.used, g.total);
    }
  }
  return (localUsed: localUsed, localTotal: localTotal, shared: groups);
}
