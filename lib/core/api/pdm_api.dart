import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../models/app_settings.dart';

/// One PDM remote and what its cluster looks like from PDM's view.
class PdmRemote {
  const PdmRemote({
    required this.name,
    required this.type,
    this.nodesOnline,
    this.nodesTotal,
    this.quorate,
  });

  final String name;
  final String type; // 'pve' | 'pbs'
  final int? nodesOnline;
  final int? nodesTotal;
  final bool? quorate;
}

class PdmStatus {
  const PdmStatus({required this.remotes});

  final List<PdmRemote> remotes;
}

/// Minimal read-only client for Proxmox Datacenter Manager's JSON API
/// (standard Proxmox API shapes on :8443; endpoints verified against the
/// deployed 1.1.7 api-viewer schema).
///
/// Auth uses the PBS-family API-token header (`PDMAPIToken=<id>:<secret>`,
/// colon separator) — PDM shares the PBS rest-server lineage. The
/// self-signed cert is pinned by SHA-256 fingerprint from settings, scoped
/// to the PDM host (PDM's own remotes.cfg pins upstream certs the same
/// way); with no fingerprint the system trust store applies (ACME setups).
class PdmApi {
  PdmApi(this._dio);

  factory PdmApi.fromSettings(AppSettings settings) {
    final dio = Dio(
      BaseOptions(
        baseUrl: '${settings.pdmUrl}/api2/json',
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 12),
        headers: {
          if (settings.pdmTokenId.isNotEmpty)
            'Authorization':
                'PDMAPIToken=${settings.pdmTokenId}:${settings.pdmTokenSecret}',
        },
      ),
    );
    final pin = _normalizeFingerprint(settings.pdmFingerprint);
    final host = Uri.tryParse(settings.pdmUrl)?.host;
    if (pin.isNotEmpty && host != null && host.isNotEmpty) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => HttpClient()
          ..badCertificateCallback = (cert, h, port) =>
              h == host &&
              _normalizeFingerprint(sha256.convert(cert.der).toString()) ==
                  pin,
      );
    }
    return PdmApi(dio);
  }

  final Dio _dio;

  /// Case/colon/space-insensitive fingerprint comparison form.
  static String _normalizeFingerprint(String s) =>
      s.replaceAll(':', '').replaceAll(' ', '').toLowerCase();

  /// Any HTTP answer (401 included) proves the service is up; only
  /// connection/TLS failures read as unreachable.
  Future<bool> ping() async {
    try {
      await _dio.get<void>(
        '/version',
        options: Options(validateStatus: (_) => true),
      );
      return true;
    } on DioException {
      return false;
    }
  }

  Future<List<String>> _remoteNames(String path) async {
    final res = await _dio.get<Map<String, dynamic>>(path);
    final data = (res.data?['data'] as List?) ?? const [];
    return [
      for (final r in data.cast<Map<String, dynamic>>()) '${r['remote']}',
    ];
  }

  /// PVE cluster-status rows mirror PVE's /cluster/status: the `cluster`
  /// row carries nodes/quorate, `node` rows carry online flags.
  Future<(int, int, bool?)?> _tryClusterStatus(String remote) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/pve/remotes/$remote/cluster-status',
      );
      final rows =
          ((res.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
      var online = 0;
      var total = 0;
      bool? quorate;
      for (final r in rows) {
        if (r['type'] == 'node') {
          total++;
          if (r['online'] == true || r['online'] == 1) online++;
        } else if (r['type'] == 'cluster') {
          quorate = r['quorate'] == true || r['quorate'] == 1;
        }
      }
      return (online, total, quorate);
    } on DioException {
      // One unreachable remote must not blank the panel — PDM itself keeps
      // listing it.
      return null;
    }
  }

  Future<PdmStatus> status() async {
    final names = await Future.wait([
      _remoteNames('/pve/remotes'),
      _remoteNames('/pbs/remotes'),
    ]);
    final pve = names[0];
    final pbs = names[1];
    final statuses = await Future.wait([
      for (final r in pve) _tryClusterStatus(r),
    ]);
    return PdmStatus(
      remotes: [
        for (final (i, r) in pve.indexed)
          PdmRemote(
            name: r,
            type: 'pve',
            nodesOnline: statuses[i]?.$1,
            nodesTotal: statuses[i]?.$2,
            quorate: statuses[i]?.$3,
          ),
        for (final r in pbs) PdmRemote(name: r, type: 'pbs'),
      ],
    );
  }
}
