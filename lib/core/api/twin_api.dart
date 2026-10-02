import 'package:dio/dio.dart';

/// One guest's restore target in a node-loss scenario.
class TwinPlacement {
  const TwinPlacement({
    required this.vmid,
    required this.name,
    required this.target,
    required this.demandGib,
  });

  factory TwinPlacement.fromJson(Map<String, dynamic> j) => TwinPlacement(
    vmid: (j['vmid'] as num).toInt(),
    name: '${j['name']}',
    target: '${j['target']}',
    demandGib: (j['demand_gib'] as num?)?.toDouble() ?? 0,
  );

  final int vmid;
  final String name;
  final String target;
  final double demandGib;
}

/// "If this node dies right now" — restore placement of its running guests
/// onto the survivors, plus the PBS restore-time estimate.
class TwinScenario {
  const TwinScenario({
    required this.node,
    required this.fits,
    required this.guests,
    required this.placements,
    required this.strandedNames,
    required this.recoveryMinutes,
    required this.pbsLost,
  });

  factory TwinScenario.fromJson(Map<String, dynamic> j) => TwinScenario(
    node: '${j['node']}',
    fits: j['fits'] == true,
    guests: (j['guests'] as num?)?.toInt() ?? 0,
    placements: [
      for (final p in (j['placements'] as List? ?? const []))
        TwinPlacement.fromJson(p as Map<String, dynamic>),
    ],
    strandedNames: [
      for (final s in (j['stranded'] as List? ?? const [])) '${s['name']}',
    ],
    recoveryMinutes: (j['recovery_minutes'] as num?)?.toDouble(),
    pbsLost: j['pbs_lost'] == true,
  );

  final String node;
  final bool fits;
  final int guests;
  final List<TwinPlacement> placements;
  final List<String> strandedNames;

  /// Serial PBS restore estimate; null when no backup data — or when the
  /// dead node hosts PBS itself ([pbsLost]).
  final double? recoveryMinutes;
  final bool pbsLost;
}

/// Per-node placement capacity after observed p95 usage + 1 GiB reserve.
class TwinHeadroomNode {
  const TwinHeadroomNode({
    required this.node,
    required this.totalGib,
    required this.freeGib,
    required this.vcpuRatio,
    required this.localLvmFreeGib,
    required this.largestFit,
  });

  factory TwinHeadroomNode.fromJson(Map<String, dynamic> j) => TwinHeadroomNode(
    node: '${j['node']}',
    totalGib: (j['total_gib'] as num?)?.toDouble() ?? 0,
    freeGib: (j['free_gib'] as num?)?.toDouble() ?? 0,
    vcpuRatio: (j['vcpu_ratio'] as num?)?.toDouble(),
    localLvmFreeGib: (j['local_lvm_free_gib'] as num?)?.toDouble() ?? 0,
    largestFit: switch (j['largest_guest_that_fits']) {
      {'name': final name, 'demand_gib': final num d} =>
        '$name (${d.toStringAsFixed(1)} GiB)',
      _ => null,
    },
  );

  final String node;
  final double totalGib;
  final double freeGib;
  final double? vcpuRatio;
  final double localLvmFreeGib;

  /// "name (x.y GiB)" of the largest running guest that still fits here.
  final String? largestFit;
}

/// Verdict for a hypothetical new guest.
class TwinWhatIf {
  const TwinWhatIf({required this.fits, required this.best, required this.why});

  factory TwinWhatIf.fromJson(Map<String, dynamic> j) {
    final options = j['options'] as List? ?? const [];
    final notes = j['notes'] as List? ?? const [];
    return TwinWhatIf(
      fits: j['fits'] == true,
      best: j['best'] as String?,
      // Fitting: the winning node's capacity line. Not fitting: the twin's
      // per-node blocker reasons (e.g. "only 8 threads (need 24)").
      why: options.isNotEmpty
          ? '${options.first['why']}'
          : notes.isEmpty
          ? null
          : notes.take(2).map((n) => '$n').join(' · '),
    );
  }

  final bool fits;
  final String? best;
  final String? why;
}

/// Everything the What-if section renders in one fetch.
class TwinData {
  const TwinData({required this.scenarios, required this.headroom});

  final List<TwinScenario> scenarios;
  final List<TwinHeadroomNode> headroom;
}

/// Read-only client for the homelab-twin service (CT 105 :9112) — the
/// capacity & failure simulator over Proxmox topology + Prometheus history.
class TwinApi {
  TwinApi(this._dio);

  factory TwinApi.fromBase(String baseUrl) => TwinApi(
    Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        // First hit after the 60s cache expires collects PVE+prom+PBS.
        receiveTimeout: const Duration(seconds: 30),
      ),
    ),
  );

  final Dio _dio;

  Future<List<TwinScenario>> scenarios() async {
    final res = await _dio.get<Map<String, dynamic>>('/scenarios');
    return [
      for (final s in (res.data?['scenarios'] as List? ?? const []))
        TwinScenario.fromJson(s as Map<String, dynamic>),
    ];
  }

  Future<List<TwinHeadroomNode>> headroom() async {
    final res = await _dio.get<Map<String, dynamic>>('/headroom');
    return [
      for (final n in (res.data?['nodes'] as List? ?? const []))
        TwinHeadroomNode.fromJson(n as Map<String, dynamic>),
    ];
  }

  Future<TwinWhatIf> whatif({
    required int cores,
    required int memMb,
    required int diskGb,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/whatif',
      queryParameters: {'cores': cores, 'mem_mb': memMb, 'disk_gb': diskGb},
    );
    return TwinWhatIf.fromJson(res.data ?? const {});
  }
}
