import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../models/app_settings.dart';
import '../models/container_status.dart';
import '../models/node_status.dart';
import '../models/proxmox_container.dart';
import '../models/proxmox_node.dart';
import '../models/proxmox_task.dart';
import '../models/proxmox_vm.dart';
import '../models/vm_status.dart';

/// One-time console credentials returned by `termproxy`/`vncproxy`: the VNC
/// ticket, the allocated port, and the authenticated user. Consumed by
/// [ProxmoxTermSocket] to open the `vncwebsocket` terminal stream.
class TermProxyTicket {
  const TermProxyTicket({
    required this.ticket,
    required this.port,
    required this.user,
  });

  final String ticket;
  final int port;
  final String user;
}

/// The two Proxmox guest APIs share the same wire shape except for this
/// segment and a small set of kind-specific fields.
enum GuestKind {
  lxc(
    pathSegment: 'lxc',
    label: 'CT',
    cloneNameField: 'hostname',
    installMediaContent: 'vztmpl',
    diskStorageContent: 'rootdir',
  ),
  qemu(
    pathSegment: 'qemu',
    label: 'VM',
    cloneNameField: 'name',
    installMediaContent: 'iso',
    diskStorageContent: 'images',
  );

  const GuestKind({
    required this.pathSegment,
    required this.label,
    required this.cloneNameField,
    required this.installMediaContent,
    required this.diskStorageContent,
  });

  final String pathSegment;
  final String label;
  final String cloneNameField;
  final String installMediaContent;
  final String diskStorageContent;

  /// Builds the exact form field order historically sent by each create
  /// screen. Keeping this here makes the kind-specific wire contract explicit.
  Map<String, dynamic> createFields({
    required int vmid,
    required String name,
    required int cores,
    required int memory,
    required String storage,
    required String disk,
    required bool start,
    String? installMedia,
    String password = '',
    int swap = 512,
    bool dhcp = true,
    bool unprivileged = true,
    int sockets = 1,
    String osType = 'l26',
  }) => switch (this) {
    GuestKind.lxc => <String, dynamic>{
      'vmid': vmid,
      'ostemplate': installMedia,
      'hostname': name,
      'cores': cores,
      'memory': memory,
      'swap': swap,
      'rootfs': '$storage:$disk',
      'net0': 'name=eth0,bridge=vmbr0,ip=${dhcp ? 'dhcp' : 'manual'}',
      'unprivileged': unprivileged ? 1 : 0,
      'start': start ? 1 : 0,
      if (password.isNotEmpty) 'password': password,
    },
    GuestKind.qemu => <String, dynamic>{
      'vmid': vmid,
      'name': name,
      'cores': cores,
      'sockets': sockets,
      'memory': memory,
      'ostype': osType,
      'scsihw': 'virtio-scsi-pci',
      'scsi0': '$storage:$disk',
      'net0': 'virtio,bridge=vmbr0',
      if (installMedia != null) 'ide2': '$installMedia,media=cdrom',
      'boot': 'order=scsi0;ide2;net0',
      'start': start ? 1 : 0,
    },
  };
}

/// Common status projection used by the shared CT/VM detail screen.
class GuestStatus {
  const GuestStatus({
    required this.status,
    this.qmpstatus,
    this.cpu,
    this.cpus,
    this.mem,
    this.maxmem,
    this.disk,
    this.maxdisk,
    this.uptime,
    this.netin,
    this.netout,
  });

  final String status;
  final String? qmpstatus;
  final double? cpu;
  final int? cpus;
  final int? mem;
  final int? maxmem;
  final int? disk;
  final int? maxdisk;
  final int? uptime;
  final int? netin;
  final int? netout;
}

GuestStatus _containerGuestStatus(ContainerStatus status) => GuestStatus(
  status: status.status,
  cpu: status.cpu,
  cpus: status.cpus,
  mem: status.mem,
  maxmem: status.maxmem,
  disk: status.disk,
  maxdisk: status.maxdisk,
  uptime: status.uptime,
  netin: status.netin,
  netout: status.netout,
);

GuestStatus _vmGuestStatus(VmStatus status) => GuestStatus(
  status: status.status,
  qmpstatus: status.qmpstatus,
  cpu: status.cpu,
  cpus: status.cpus,
  mem: status.mem,
  maxmem: status.maxmem,
  disk: status.disk,
  maxdisk: status.maxdisk,
  uptime: status.uptime,
  netin: status.netin,
  netout: status.netout,
);

/// Dio-based client for the Proxmox VE JSON API.
///
/// Auth is API-token only (no CSRF needed):
/// `Authorization: PVEAPIToken=<user@realm!tokenid>=<uuid>`.
class ProxmoxApi {
  ProxmoxApi(this._dio);

  /// Builds a client from settings, including the self-signed-certificate
  /// exception — trusted only for the configured Proxmox host, never
  /// globally.
  factory ProxmoxApi.fromSettings(AppSettings settings) {
    final dio = Dio(
      BaseOptions(
        baseUrl: '${settings.proxmoxUrl}/api2/json',
        headers: {
          'Authorization':
              'PVEAPIToken=${settings.proxmoxTokenId}=${settings.proxmoxTokenSecret}',
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    if (settings.trustSelfSigned) {
      final trustedHost = Uri.tryParse(settings.proxmoxUrl)?.host;
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () =>
            HttpClient()
              ..badCertificateCallback = (cert, host, port) =>
                  trustedHost != null && host == trustedHost,
      );
    }
    return ProxmoxApi(dio);
  }

  final Dio _dio;

  Future<List<ProxmoxNode>> getNodes() async {
    final data = await _getList('/nodes');
    final nodes = data.map(ProxmoxNode.fromJson).toList()
      ..sort((a, b) => a.node.compareTo(b.node));
    return nodes;
  }

  Future<NodeStatus> getNodeStatus(String node) async {
    return NodeStatus.fromJson(await _getMap('/nodes/$node/status'));
  }

  /// Native RRD time series for [node]: `{time, cpu, memused, memtotal,
  /// netin, netout, rootused, roottotal, ...}` rows, oldest first. The
  /// newest rows can hold nulls while the RRD consolidates — callers skip
  /// entries without the metric they chart.
  Future<List<Map<String, dynamic>>> getNodeRrd(
    String node, {
    String timeframe = 'hour',
  }) => _getList('/nodes/$node/rrddata?timeframe=$timeframe&cf=AVERAGE');

  /// Recent tasks on [node] (running and archived — `source` defaults to
  /// archive-only without the explicit `all`), newest first.
  Future<List<ProxmoxTask>> getNodeTasks(String node, {int limit = 20}) async {
    final data = await _getList('/nodes/$node/tasks?limit=$limit&source=all');
    final tasks = data.map(ProxmoxTask.fromJson).toList()
      ..sort((a, b) => b.starttime.compareTo(a.starttime));
    return tasks.take(limit).toList();
  }

  /// The LAST [limit] lines of a task's log as `{n: line#, t: text}` rows —
  /// the diagnostic `TASK ERROR` tail lives at the end, so a plain
  /// `?limit=N` fetch (which reads from the start) would drop it on long
  /// vzdump/migration logs. A 1-line probe reads the envelope's `total` to
  /// aim the real fetch at the tail. UPIDs ride in the path verbatim — their
  /// colons are legal path characters and Proxmox expects them unescaped.
  Future<List<Map<String, dynamic>>> getTaskLog(
    String node,
    String upid, {
    int limit = 200,
  }) async {
    final path = '/nodes/$node/tasks/$upid/log';
    final probe = await _dio.get<Map<String, dynamic>>('$path?limit=1');
    final total = (probe.data?['total'] as num?)?.toInt() ?? 0;
    final start = total > limit ? total - limit : 0;
    return _getList('$path?start=$start&limit=$limit');
  }

  /// Reboots the whole node. Unlike guest power calls this returns no UPID
  /// (the API answers with null data).
  Future<void> rebootNode(String node) =>
      _postForm('/nodes/$node/status', {'command': 'reboot'});

  /// Powers the whole node off (needs physical/IPMI access to undo).
  Future<void> shutdownNode(String node) =>
      _postForm('/nodes/$node/status', {'command': 'shutdown'});

  /// Node name → management IP, from `/cluster/status` (the `node` entries).
  /// Used to build SSH targets for the terminal without baking in any IPs.
  Future<Map<String, String>> nodeAddresses() async {
    final data = await _getList('/cluster/status');
    return {
      for (final e in data)
        if (e['type'] == 'node' &&
            e['name'] is String &&
            (e['ip'] as String?)?.isNotEmpty == true)
          e['name'] as String: e['ip'] as String,
    };
  }

  Future<List<ProxmoxContainer>> getContainers(String node) async {
    final data = await _getList('/nodes/$node/lxc');
    final cts =
        data
            .map((json) => ProxmoxContainer.fromJson(json).copyWith(node: node))
            .toList()
          ..sort((a, b) => a.vmid.compareTo(b.vmid));
    return cts;
  }

  /// Containers across every online node, sorted by vmid.
  Future<List<ProxmoxContainer>> getAllContainers() async {
    final nodes = await getNodes();
    final all = <ProxmoxContainer>[];
    for (final n in nodes.where((n) => n.status == 'online')) {
      all.addAll(await getContainers(n.node));
    }
    all.sort((a, b) => a.vmid.compareTo(b.vmid));
    return all;
  }

  Future<GuestStatus> getGuestStatus(
    GuestKind kind,
    String node,
    int vmid,
  ) async {
    final path = '/nodes/$node/${kind.pathSegment}/$vmid/status/current';
    final data = await _getMap(path);
    return switch (kind) {
      GuestKind.lxc => _containerGuestStatus(ContainerStatus.fromJson(data)),
      GuestKind.qemu => _vmGuestStatus(VmStatus.fromJson(data)),
    };
  }

  Future<Map<String, dynamic>> getGuestConfig(
    GuestKind kind,
    String node,
    int vmid,
  ) => _getMap('/nodes/$node/${kind.pathSegment}/$vmid/config');

  /// Returns the UPID of the spawned task.
  Future<String> changeGuestStatus(
    GuestKind kind,
    String node,
    int vmid,
    String action,
  ) => _postForUpid('/nodes/$node/${kind.pathSegment}/$vmid/status/$action');

  /// Next free VMID for a new guest.
  Future<int> nextVmid() async {
    final response = await _dio.get<Map<String, dynamic>>('/cluster/nextid');
    return int.tryParse('${response.data?['data']}') ?? 0;
  }

  /// Storages on [node], optionally filtered to those that can hold [content]
  /// (e.g. `vztmpl` for templates, `rootdir` for container disks).
  Future<List<Map<String, dynamic>>> getStorages(
    String node, {
    String? content,
  }) {
    final q = content != null ? '?content=$content' : '';
    return _getList('/nodes/$node/storage$q');
  }

  /// Backup-capable storages available on [node].
  Future<List<Map<String, dynamic>>> getBackupStorages(String node) =>
      _getList('/nodes/$node/storage?content=backup');

  /// Backup volumes on [storage], returned as raw Proxmox content maps.
  Future<List<Map<String, dynamic>>> getBackups(String node, String storage) =>
      _getList('/nodes/$node/storage/$storage/content?content=backup');

  /// Starts an immediate vzdump backup and returns the task UPID.
  Future<String> createBackup(
    String node, {
    required int vmid,
    required String storage,
    String mode = 'snapshot',
    bool compress = true,
  }) => _postForm('/nodes/$node/vzdump', {
    'vmid': vmid,
    'storage': storage,
    'mode': mode,
    'compress': compress ? 'zstd' : '0',
  });

  /// Cluster backup schedules, returned as raw Proxmox job maps.
  Future<List<Map<String, dynamic>>> getBackupJobs() =>
      _getList('/cluster/backup');

  /// Deletes [volid] from [storage] and returns the task UPID.
  Future<String> deleteBackupFile(String node, String storage, String volid) {
    final encodedVolid = Uri.encodeComponent(volid);
    return _deleteForUpid(
      '/nodes/$node/storage/$storage/content/$encodedVolid',
    );
  }

  /// Templates for LXC and install ISOs for QEMU, across all capable storage.
  Future<List<Map<String, dynamic>>> getGuestInstallMedia(
    GuestKind kind,
    String node,
  ) => _contentAcrossStorages(node, kind.installMediaContent);

  Future<String> createGuest(
    GuestKind kind,
    String node,
    Map<String, dynamic> params,
  ) => _postForm('/nodes/$node/${kind.pathSegment}', params);

  Future<String> deleteGuest(
    GuestKind kind,
    String node,
    int vmid, {
    bool purge = true,
    bool destroyUnreferenced = true,
  }) => _deleteForUpid(
    '/nodes/$node/${kind.pathSegment}/$vmid',
    queryParameters: {
      if (purge) 'purge': 1,
      if (destroyUnreferenced) 'destroy-unreferenced-disks': 1,
    },
  );

  Future<String> cloneGuest(
    GuestKind kind,
    String node,
    int vmid, {
    required int newid,
    String? name,
    bool full = true,
    String? storage,
    String? target,
  }) {
    final params = <String, dynamic>{
      'newid': newid,
      'full': full ? 1 : 0,
      if (name != null && name.isNotEmpty) kind.cloneNameField: name,
      'storage': ?storage,
      'target': ?target,
    };
    return _postForm('/nodes/$node/${kind.pathSegment}/$vmid/clone', params);
  }

  Future<List<Map<String, dynamic>>> getGuestSnapshots(
    GuestKind kind,
    String node,
    int vmid,
  ) => _getList('/nodes/$node/${kind.pathSegment}/$vmid/snapshot');

  Future<String> createGuestSnapshot(
    GuestKind kind,
    String node,
    int vmid,
    String snapname, {
    String? description,
    bool vmstate = false,
  }) {
    final params = <String, dynamic>{
      'snapname': snapname,
      if (kind == GuestKind.qemu && vmstate) 'vmstate': 1,
      if (description != null && description.isNotEmpty)
        'description': description,
    };
    return _postForm('/nodes/$node/${kind.pathSegment}/$vmid/snapshot', params);
  }

  Future<String> rollbackGuestSnapshot(
    GuestKind kind,
    String node,
    int vmid,
    String snapname,
  ) => _postForUpid(
    '/nodes/$node/${kind.pathSegment}/$vmid/snapshot/$snapname/rollback',
  );

  Future<String> deleteGuestSnapshot(
    GuestKind kind,
    String node,
    int vmid,
    String snapname,
  ) => _deleteForUpid(
    '/nodes/$node/${kind.pathSegment}/$vmid/snapshot/$snapname',
  );

  // --- Phase 3: QEMU virtual machines -----------------------------------

  Future<List<ProxmoxVm>> getVms(String node) async {
    final data = await _getList('/nodes/$node/qemu');
    final vms =
        data
            .map((json) => ProxmoxVm.fromJson(json).copyWith(node: node))
            .toList()
          ..sort((a, b) => a.vmid.compareTo(b.vmid));
    return vms;
  }

  /// VMs across every online node, sorted by vmid.
  Future<List<ProxmoxVm>> getAllVms() async {
    final nodes = await getNodes();
    final all = <ProxmoxVm>[];
    for (final n in nodes.where((n) => n.status == 'online')) {
      all.addAll(await getVms(n.node));
    }
    all.sort((a, b) => a.vmid.compareTo(b.vmid));
    return all;
  }

  // --- Phase 4: console -------------------------------------------------

  /// Opens a serial/term console proxy for LXC [vmid] and returns the one-time
  /// VNC ticket, allocated port, and authenticated user — the inputs to the
  /// `vncwebsocket` terminal stream ([ProxmoxTermSocket]). Verified to work with
  /// the API token against the live cluster (no login ticket/cookie required).
  Future<TermProxyTicket> lxcTermProxy(String node, int vmid) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nodes/$node/lxc/$vmid/termproxy',
    );
    final d = response.data?['data'] as Map<String, dynamic>? ?? const {};
    return TermProxyTicket(
      ticket: d['ticket'] as String? ?? '',
      port: int.tryParse('${d['port']}') ?? 0,
      user: d['user'] as String? ?? '',
    );
  }

  /// Cluster-wide recent tasks, newest first.
  Future<List<ProxmoxTask>> getRecentTasks({int limit = 20}) async {
    final data = await _getList('/cluster/tasks');
    final tasks = data.map(ProxmoxTask.fromJson).toList()
      ..sort((a, b) => b.starttime.compareTo(a.starttime));
    return tasks.take(limit).toList();
  }

  /// All content entries of a given [content] type across every storage on
  /// [node] that can hold it (templates, ISOs). A storage that's momentarily
  /// unavailable is skipped rather than failing the whole list.
  Future<List<Map<String, dynamic>>> _contentAcrossStorages(
    String node,
    String content,
  ) async {
    final stores = await getStorages(node, content: content);
    final out = <Map<String, dynamic>>[];
    for (final s in stores) {
      final storage = s['storage'];
      try {
        out.addAll(
          await _getList(
            '/nodes/$node/storage/$storage/content?content=$content',
          ),
        );
      } catch (_) {
        // A storage may be momentarily unavailable; skip it.
      }
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data.cast<Map<String, dynamic>>();
  }

  /// DELETE returning the spawned task's UPID (mirrors [_postForUpid]).
  Future<String> _deleteForUpid(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return response.data?['data'] as String? ?? '';
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    return response.data?['data'] as Map<String, dynamic>? ?? const {};
  }

  Future<String> _postForUpid(String path) async {
    final response = await _dio.post<Map<String, dynamic>>(path);
    return response.data?['data'] as String? ?? '';
  }

  /// POST with form-urlencoded body (Proxmox's expected content type for
  /// create/config calls); returns the task UPID.
  Future<String> _postForm(String path, Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return response.data?['data'] as String? ?? '';
  }
}
