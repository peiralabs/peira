import 'dart:convert';
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
  final String type;
  final int? nodesOnline;
  final int? nodesTotal;
  final bool? quorate;
}

class PdmStatus {
  const PdmStatus({required this.remotes});

  final List<PdmRemote> remotes;
}

class PdmRemoteInfo {
  const PdmRemoteInfo({
    required this.id,
    required this.type,
    required this.endpoints,
  });

  final String id;
  final String type;
  final List<String> endpoints;
}

class PdmNode {
  const PdmNode({
    required this.remote,
    required this.name,
    required this.status,
    required this.cpu,
    required this.maxcpu,
    required this.mem,
    required this.maxmem,
    required this.uptime,
  });

  final String remote;
  final String name;
  final String status;
  final double cpu;
  final double maxcpu;
  final int mem;
  final int maxmem;
  final int uptime;
}

class PdmGuest {
  const PdmGuest({
    required this.remote,
    required this.kind,
    required this.vmid,
    required this.name,
    required this.node,
    required this.status,
    required this.template,
    required this.cpu,
    required this.maxcpu,
    required this.mem,
    required this.maxmem,
    required this.disk,
    required this.maxdisk,
    required this.uptime,
    required this.tags,
  });

  final String remote;
  final String kind;
  final int vmid;
  final String name;
  final String node;
  final String status;
  final bool template;
  final double cpu;
  final double maxcpu;
  final int mem;
  final int maxmem;
  final int disk;
  final int maxdisk;
  final int uptime;
  final List<String> tags;
}

class PdmStorage {
  const PdmStorage({
    required this.remote,
    required this.storage,
    required this.node,
    required this.shared,
    required this.status,
    required this.used,
    required this.total,
  });

  final String remote;
  final String storage;
  final String node;
  final bool shared;
  final String status;
  final int used;
  final int total;
}

class PdmClusterStatus {
  const PdmClusterStatus({
    required this.name,
    required this.quorate,
    required this.nodesOnline,
    required this.nodesTotal,
  });

  final String name;
  final bool quorate;
  final int nodesOnline;
  final int nodesTotal;
}

class PdmResources {
  const PdmResources({
    required this.nodes,
    required this.guests,
    required this.storages,
  });

  final List<PdmNode> nodes;
  final List<PdmGuest> guests;
  final List<PdmStorage> storages;
}

class PdmGuestConfig {
  const PdmGuestConfig({
    required this.unprivileged,
    required this.hasRawLxcKeys,
    required this.storages,
    required this.bridges,
  });

  final bool unprivileged;
  final bool hasRawLxcKeys;
  final Set<String> storages;
  final Set<String> bridges;
}

class PdmTask {
  const PdmTask({
    required this.remote,
    required this.upid,
    required this.node,
    required this.workerType,
    required this.workerId,
    required this.user,
    required this.start,
    required this.end,
    required this.status,
  });

  final String remote;
  final String upid;
  final String node;
  final String workerType;
  final String? workerId;
  final String user;
  final DateTime start;
  final DateTime? end;
  final String? status;

  bool get running => end == null;
  bool get failed =>
      !running &&
      status != null &&
      status != 'OK' &&
      !status!.startsWith('WARNINGS');
}

class PdmTaskStatus {
  const PdmTaskStatus({required this.running, required this.exitStatus});

  final bool running;
  final String? exitStatus;

  bool get succeeded =>
      !running &&
      (exitStatus == 'OK' || (exitStatus?.startsWith('WARNINGS') ?? false));
}

class PdmApiException implements Exception {
  const PdmApiException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  @override
  String toString() => 'PdmApiException($statusCode): $message';
}

/// Client for Proxmox Datacenter Manager's JSON API.
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
              _normalizeFingerprint(sha256.convert(cert.der).toString()) == pin,
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

  Future<dynamic> _getData(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data?['data'];
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<dynamic> _postData(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      return response.data?['data'];
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  static PdmApiException _apiException(DioException error) {
    final response = error.response;
    final body = response?.data;
    final message = body is String
        ? body
        : body == null
        ? error.message ?? 'PDM request failed'
        : jsonEncode(body);
    return PdmApiException(response?.statusCode, message);
  }

  static bool _bool(dynamic value) =>
      value == true || value == 1 || value == '1';
  static int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static double _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  Future<List<PdmRemoteInfo>> remotes() async {
    final rows = _getList(await _getData('/remotes/remote'));
    return [
      for (final row in rows)
        PdmRemoteInfo(
          id: '${row['id']}',
          type: '${row['type']}',
          endpoints: [
            for (final node in (row['nodes'] as List?) ?? const [])
              '$node'.split(',').first,
          ],
        ),
    ];
  }

  Future<PdmClusterStatus> clusterStatus(String remote) async {
    final rows = _getList(
      await _getData('/pve/remotes/$remote/cluster-status'),
    );
    Map<String, dynamic>? cluster;
    var online = 0;
    var nodeRows = 0;
    for (final row in rows) {
      if (row['type'] == 'cluster') {
        cluster = row;
      } else if (row['type'] == 'node') {
        nodeRows++;
        if (_bool(row['online'])) online++;
      }
    }
    return PdmClusterStatus(
      name: '${cluster?['name'] ?? remote}',
      quorate: _bool(cluster?['quorate']),
      nodesOnline: online,
      nodesTotal: cluster?['nodes'] == null
          ? nodeRows
          : _int(cluster?['nodes']),
    );
  }

  Future<PdmResources> resources(String remote) async {
    final rows = _getList(await _getData('/pve/remotes/$remote/resources'));
    final nodes = <PdmNode>[];
    final guests = <PdmGuest>[];
    final storages = <PdmStorage>[];
    for (final row in rows) {
      switch (row['type']) {
        case 'node':
          nodes.add(
            PdmNode(
              remote: remote,
              name: '${row['node'] ?? row['name'] ?? ''}',
              status: '${row['status'] ?? ''}',
              cpu: _double(row['cpu']),
              maxcpu: _double(row['maxcpu']),
              mem: _int(row['mem']),
              maxmem: _int(row['maxmem']),
              uptime: _int(row['uptime']),
            ),
          );
        case 'lxc' || 'qemu':
          guests.add(
            PdmGuest(
              remote: remote,
              kind: '${row['type']}',
              vmid: _int(row['vmid']),
              name: '${row['name'] ?? ''}',
              node: '${row['node'] ?? ''}',
              status: '${row['status'] ?? ''}',
              template: _bool(row['template']),
              cpu: _double(row['cpu']),
              maxcpu: _double(row['maxcpu']),
              mem: _int(row['mem']),
              maxmem: _int(row['maxmem']),
              disk: _int(row['disk']),
              maxdisk: _int(row['maxdisk']),
              uptime: _int(row['uptime']),
              tags: '${row['tags'] ?? ''}'
                  .split(RegExp(r'[;,]'))
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList(growable: false),
            ),
          );
        case 'storage':
          storages.add(
            PdmStorage(
              remote: remote,
              storage: '${row['storage'] ?? ''}',
              node: '${row['node'] ?? ''}',
              shared: _bool(row['shared']),
              status: '${row['status'] ?? ''}',
              used: _int(row['disk']),
              total: _int(row['maxdisk']),
            ),
          );
      }
    }
    return PdmResources(nodes: nodes, guests: guests, storages: storages);
  }

  Future<PdmGuestConfig> guestConfig(
    String remote,
    String kind,
    int vmid,
  ) async {
    _checkKind(kind);
    final config = Map<String, dynamic>.from(
      (await _getData(
            '/pve/remotes/$remote/$kind/$vmid/config',
            queryParameters: const {'state': 'active'},
          ))
          as Map,
    );
    final storages = <String>{};
    final bridges = <String>{};
    final storageKey = kind == 'lxc'
        ? RegExp(r'^(rootfs|mp\d+)$')
        : RegExp(r'^(scsi\d+|virtio\d+|sata\d+|ide\d+|efidisk0|tpmstate0)$');
    final netKey = RegExp(r'^net\d+$');
    for (final entry in config.entries) {
      final value = '${entry.value}';
      if (storageKey.hasMatch(entry.key) &&
          value != 'none' &&
          !value.contains('media=cdrom')) {
        final separator = value.indexOf(':');
        if (separator > 0) storages.add(value.substring(0, separator));
      }
      if (netKey.hasMatch(entry.key)) {
        for (final part in value.split(',')) {
          if (part.startsWith('bridge=') && part.length > 7) {
            bridges.add(part.substring(7));
          }
        }
      }
    }
    return PdmGuestConfig(
      unprivileged: _bool(config['unprivileged']),
      hasRawLxcKeys: config.containsKey('lxc'),
      storages: storages,
      bridges: bridges,
    );
  }

  Future<String> guestAction(
    String remote,
    String kind,
    int vmid,
    String action,
  ) async {
    _checkKind(kind);
    final allowed = {'start', 'shutdown', 'stop', if (kind == 'qemu') 'resume'};
    assert(allowed.contains(action), 'Unsupported $kind action: $action');
    if (!allowed.contains(action)) {
      throw ArgumentError.value(action, 'action', 'Unsupported $kind action');
    }
    return '${await _postData('/pve/remotes/$remote/$kind/$vmid/$action', {})}';
  }

  Future<PdmTaskStatus> taskStatus(String remote, String upid) async {
    final data = Map<String, dynamic>.from(
      (await _getData(
            '/pve/remotes/$remote/tasks/${Uri.encodeComponent(upid)}/status',
          ))
          as Map,
    );
    return PdmTaskStatus(
      running: data['status'] == 'running',
      exitStatus: data['exitstatus'] as String?,
    );
  }

  Future<List<String>> taskLog(
    String remote,
    String upid, {
    int limit = 200,
  }) async {
    final rows = _getList(
      await _getData(
        '/pve/remotes/$remote/tasks/${Uri.encodeComponent(upid)}/log',
        queryParameters: {'limit': limit},
      ),
    );
    return [for (final row in rows) '${row['t'] ?? ''}'];
  }

  Future<List<PdmTask>> tasks({
    int limit = 200,
    bool errorsOnly = false,
    bool runningOnly = false,
  }) async {
    final rows = _getList(
      await _getData(
        '/remotes/tasks/list',
        queryParameters: {
          'limit': limit,
          if (errorsOnly) 'errors': 1,
          if (runningOnly) 'running': 1,
        },
      ),
    );
    return [
      for (final row in rows)
        PdmTask(
          remote: _remoteFromUpid('${row['upid']}'),
          upid: '${row['upid']}',
          node: '${row['node'] ?? ''}',
          workerType: '${row['worker_type'] ?? ''}',
          workerId:
              row['worker_id']?.toString() ?? _upidWorkerId('${row['upid']}'),
          user: '${row['user'] ?? ''}',
          start: DateTime.fromMillisecondsSinceEpoch(
            _int(row['starttime']) * 1000,
            isUtc: true,
          ),
          end: row['endtime'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  _int(row['endtime']) * 1000,
                  isUtc: true,
                ),
          status: row['status'] as String?,
        ),
    ];
  }

  Future<int> nextId(String remote) async =>
      _int(await _getData('/pve/remotes/$remote/cluster-nextid'));

  Future<List<String>> bridges(String remote, String node) async {
    final rows = _getList(
      await _getData('/pve/remotes/$remote/nodes/$node/network'),
    );
    return [
      for (final row in rows)
        if (row['type'] == 'bridge') '${row['iface']}',
    ];
  }

  Future<String> remoteMigrate(
    String remote,
    String kind,
    int vmid, {
    required String target,
    required Map<String, String> storageMap,
    required Map<String, String> bridgeMap,
    int? targetVmid,
    bool delete = true,
    bool? online,
    bool? restart,
    int? timeout,
    int? bwlimitKiB,
    String? targetEndpoint,
  }) async {
    _checkKind(kind);
    final body = <String, dynamic>{
      'target': target,
      'target-storage': [
        for (final entry in storageMap.entries) '${entry.key}:${entry.value}',
      ],
      'target-bridge': [
        for (final entry in bridgeMap.entries) '${entry.key}:${entry.value}',
      ],
      'target-vmid': ?targetVmid,
      'delete': delete,
      'online': ?online,
      'restart': ?restart,
      'timeout': ?timeout,
      'bwlimit': ?bwlimitKiB,
      'target-endpoint': ?targetEndpoint,
    };
    return '${await _postData('/pve/remotes/$remote/$kind/$vmid/remote-migrate', body)}';
  }

  /// Retains the compact shape consumed by the existing Proxmox-tab panel.
  Future<PdmStatus> status() async {
    final remoteList = await remotes();
    final clusterStatuses = await Future.wait([
      for (final remote in remoteList)
        if (remote.type == 'pve') _tryClusterStatus(remote.id),
    ]);
    var pveIndex = 0;
    return PdmStatus(
      remotes: [
        for (final remote in remoteList)
          if (remote.type == 'pve')
            _panelRemote(remote, clusterStatuses[pveIndex++])
          else
            PdmRemote(name: remote.id, type: remote.type),
      ],
    );
  }

  Future<PdmClusterStatus?> _tryClusterStatus(String remote) async {
    try {
      return await clusterStatus(remote);
    } on PdmApiException {
      return null;
    }
  }

  static PdmRemote _panelRemote(
    PdmRemoteInfo remote,
    PdmClusterStatus? cluster,
  ) => PdmRemote(
    name: remote.id,
    type: remote.type,
    nodesOnline: cluster?.nodesOnline,
    nodesTotal: cluster?.nodesTotal,
    quorate: cluster?.quorate,
  );

  static List<Map<String, dynamic>> _getList(dynamic data) =>
      ((data as List?) ?? const [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);

  /// PDM's task list leaves `worker_id` null; the UPID carries it
  /// (`UPID:node:pid:pstart:starttime:type:id:user:`), e.g. `120@pbs-local`.
  static String? _upidWorkerId(String upid) {
    final bang = upid.indexOf('!');
    final fields = upid.substring(bang + 1).split(':');
    if (fields.length < 8 || fields[0] != 'UPID') return null;
    final id = fields[6];
    return id.isEmpty ? null : id;
  }

  static String _remoteFromUpid(String upid) {
    final colon = upid.indexOf(':');
    final bang = upid.indexOf('!', colon + 1);
    return colon >= 0 && bang > colon ? upid.substring(colon + 1, bang) : '';
  }

  static void _checkKind(String kind) {
    assert(kind == 'lxc' || kind == 'qemu', 'Unsupported guest kind: $kind');
    if (kind != 'lxc' && kind != 'qemu') {
      throw ArgumentError.value(kind, 'kind', 'Must be lxc or qemu');
    }
  }
}
