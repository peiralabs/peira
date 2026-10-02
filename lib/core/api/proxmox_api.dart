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
  }) =>
      _getList('/nodes/$node/rrddata?timeframe=$timeframe&cf=AVERAGE');

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

  Future<ContainerStatus> getContainerStatus(String node, int vmid) async {
    return ContainerStatus.fromJson(
      await _getMap('/nodes/$node/lxc/$vmid/status/current'),
    );
  }

  /// Raw CT config (hostname, ostype, cores, memory, net0, ...).
  Future<Map<String, dynamic>> getContainerConfig(String node, int vmid) =>
      _getMap('/nodes/$node/lxc/$vmid/config');

  /// Returns the UPID of the spawned task.
  Future<String> startContainer(String node, int vmid) =>
      _postForUpid('/nodes/$node/lxc/$vmid/status/start');

  Future<String> stopContainer(String node, int vmid) =>
      _postForUpid('/nodes/$node/lxc/$vmid/status/stop');

  Future<String> rebootContainer(String node, int vmid) =>
      _postForUpid('/nodes/$node/lxc/$vmid/status/reboot');

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
  Future<List<Map<String, dynamic>>> getBackups(
    String node,
    String storage,
  ) =>
      _getList('/nodes/$node/storage/$storage/content?content=backup');

  /// Starts an immediate vzdump backup and returns the task UPID.
  Future<String> createBackup(
    String node, {
    required int vmid,
    required String storage,
    String mode = 'snapshot',
    bool compress = true,
  }) =>
      _postForm('/nodes/$node/vzdump', {
        'vmid': vmid,
        'storage': storage,
        'mode': mode,
        'compress': compress ? 'zstd' : '0',
      });

  /// Cluster backup schedules, returned as raw Proxmox job maps.
  Future<List<Map<String, dynamic>>> getBackupJobs() =>
      _getList('/cluster/backup');

  /// Deletes [volid] from [storage] and returns the task UPID.
  Future<String> deleteBackupFile(
    String node,
    String storage,
    String volid,
  ) async {
    final encodedVolid = Uri.encodeComponent(volid);
    final response = await _dio.delete<Map<String, dynamic>>(
      '/nodes/$node/storage/$storage/content/$encodedVolid',
    );
    return response.data?['data'] as String? ?? '';
  }

  /// Available LXC templates on [node] (across all template-capable storages),
  /// as `{volid, ...}` maps. `volid` is what `ostemplate` needs.
  Future<List<Map<String, dynamic>>> getTemplates(String node) async {
    final stores = await getStorages(node, content: 'vztmpl');
    final templates = <Map<String, dynamic>>[];
    for (final s in stores) {
      final storage = s['storage'];
      try {
        templates.addAll(
          await _getList(
            '/nodes/$node/storage/$storage/content?content=vztmpl',
          ),
        );
      } catch (_) {
        // A storage may be momentarily unavailable; skip it.
      }
    }
    return templates;
  }

  /// Creates an LXC container on [node]. [params] are the raw Proxmox create
  /// fields (vmid, ostemplate, hostname, storage, rootfs, cores, memory, ...).
  /// Returns the task UPID.
  Future<String> createLxc(String node, Map<String, dynamic> params) =>
      _postForm('/nodes/$node/lxc', params);

  // --- Phase 2: lifecycle ops -------------------------------------------

  /// Destroys the container. [purge] also removes it from any backup/HA jobs;
  /// [destroyUnreferenced] wipes disks not otherwise referenced. The container
  /// must be stopped. Returns the task UPID.
  Future<String> deleteLxc(
    String node,
    int vmid, {
    bool purge = true,
    bool destroyUnreferenced = true,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/nodes/$node/lxc/$vmid',
      queryParameters: {
        if (purge) 'purge': 1,
        if (destroyUnreferenced) 'destroy-unreferenced-disks': 1,
      },
    );
    return response.data?['data'] as String? ?? '';
  }

  /// Clones [vmid] to [newid]. A [full] clone is an independent copy (works on
  /// any container); a linked clone requires the source to be a template.
  /// [storage] targets the clone's disks; [target] its destination node.
  /// Returns the task UPID.
  Future<String> cloneLxc(
    String node,
    int vmid, {
    required int newid,
    String? hostname,
    bool full = true,
    String? storage,
    String? target,
  }) {
    final params = <String, dynamic>{
      'newid': newid,
      'full': full ? 1 : 0,
      if (hostname != null && hostname.isNotEmpty) 'hostname': hostname,
      'storage': ?storage,
      'target': ?target,
    };
    return _postForm('/nodes/$node/lxc/$vmid/clone', params);
  }

  /// Snapshots for [vmid], as `{name, snaptime, description, parent, ...}` maps.
  /// Includes a synthetic `{name: 'current'}` entry (the live state) that
  /// cannot be rolled back to or deleted — callers filter it out.
  Future<List<Map<String, dynamic>>> getSnapshots(String node, int vmid) =>
      _getList('/nodes/$node/lxc/$vmid/snapshot');

  /// Takes a snapshot named [snapname] of [vmid]. Returns the task UPID.
  Future<String> createSnapshot(
    String node,
    int vmid,
    String snapname, {
    String? description,
  }) {
    final params = <String, dynamic>{
      'snapname': snapname,
      if (description != null && description.isNotEmpty)
        'description': description,
    };
    return _postForm('/nodes/$node/lxc/$vmid/snapshot', params);
  }

  /// Rolls [vmid] back to snapshot [snapname]. Returns the task UPID.
  Future<String> rollbackSnapshot(String node, int vmid, String snapname) =>
      _postForUpid('/nodes/$node/lxc/$vmid/snapshot/$snapname/rollback');

  /// Deletes snapshot [snapname] from [vmid]. Returns the task UPID.
  Future<String> deleteSnapshot(String node, int vmid, String snapname) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/nodes/$node/lxc/$vmid/snapshot/$snapname',
    );
    return response.data?['data'] as String? ?? '';
  }

  // --- Phase 3: QEMU virtual machines -----------------------------------

  Future<List<ProxmoxVm>> getVms(String node) async {
    final data = await _getList('/nodes/$node/qemu');
    final vms =
        data.map((json) => ProxmoxVm.fromJson(json).copyWith(node: node)).toList()
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

  Future<VmStatus> getVmStatus(String node, int vmid) async {
    return VmStatus.fromJson(
      await _getMap('/nodes/$node/qemu/$vmid/status/current'),
    );
  }

  /// Raw VM config (name, cores, memory, ostype, net0, scsi0, ...).
  Future<Map<String, dynamic>> getVmConfig(String node, int vmid) =>
      _getMap('/nodes/$node/qemu/$vmid/config');

  Future<String> startVm(String node, int vmid) =>
      _postForUpid('/nodes/$node/qemu/$vmid/status/start');

  /// Hard power-off (like pulling the plug). Prefer [shutdownVm] for a clean
  /// ACPI shutdown when the guest supports it.
  Future<String> stopVm(String node, int vmid) =>
      _postForUpid('/nodes/$node/qemu/$vmid/status/stop');

  /// Graceful ACPI shutdown (requires guest cooperation).
  Future<String> shutdownVm(String node, int vmid) =>
      _postForUpid('/nodes/$node/qemu/$vmid/status/shutdown');

  Future<String> rebootVm(String node, int vmid) =>
      _postForUpid('/nodes/$node/qemu/$vmid/status/reboot');

  /// Available install ISOs on [node] (across all iso-capable storages), as
  /// `{volid, ...}` maps. `volid` is what a cdrom drive (`ide2`) needs.
  Future<List<Map<String, dynamic>>> getIsos(String node) async {
    final stores = await getStorages(node, content: 'iso');
    final isos = <Map<String, dynamic>>[];
    for (final s in stores) {
      final storage = s['storage'];
      try {
        isos.addAll(
          await _getList('/nodes/$node/storage/$storage/content?content=iso'),
        );
      } catch (_) {
        // A storage may be momentarily unavailable; skip it.
      }
    }
    return isos;
  }

  /// Creates a QEMU VM on [node]. [params] are the raw Proxmox create fields
  /// (vmid, name, cores, memory, ostype, scsi0, ide2, net0, ...). Returns the
  /// task UPID.
  Future<String> createVm(String node, Map<String, dynamic> params) =>
      _postForm('/nodes/$node/qemu', params);

  /// Destroys the VM. [purge] also removes it from any backup/HA jobs;
  /// [destroyUnreferenced] wipes disks not otherwise referenced. The VM must
  /// be stopped. Returns the task UPID.
  Future<String> deleteVm(
    String node,
    int vmid, {
    bool purge = true,
    bool destroyUnreferenced = true,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/nodes/$node/qemu/$vmid',
      queryParameters: {
        if (purge) 'purge': 1,
        if (destroyUnreferenced) 'destroy-unreferenced-disks': 1,
      },
    );
    return response.data?['data'] as String? ?? '';
  }

  /// Clones [vmid] to [newid]. A [full] clone is an independent copy; a linked
  /// clone requires the source to be a template. Returns the task UPID.
  Future<String> cloneVm(
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
      if (name != null && name.isNotEmpty) 'name': name,
      'storage': ?storage,
      'target': ?target,
    };
    return _postForm('/nodes/$node/qemu/$vmid/clone', params);
  }

  /// Snapshots for [vmid], as `{name, snaptime, description, parent, ...}` maps.
  /// Includes a synthetic `{name: 'current'}` entry — callers filter it out.
  Future<List<Map<String, dynamic>>> getVmSnapshots(String node, int vmid) =>
      _getList('/nodes/$node/qemu/$vmid/snapshot');

  /// Takes a snapshot named [snapname] of [vmid]. [vmstate] also saves RAM
  /// (only meaningful for a running VM). Returns the task UPID.
  Future<String> createVmSnapshot(
    String node,
    int vmid,
    String snapname, {
    String? description,
    bool vmstate = false,
  }) {
    final params = <String, dynamic>{
      'snapname': snapname,
      if (vmstate) 'vmstate': 1,
      if (description != null && description.isNotEmpty)
        'description': description,
    };
    return _postForm('/nodes/$node/qemu/$vmid/snapshot', params);
  }

  /// Rolls [vmid] back to snapshot [snapname]. Returns the task UPID.
  Future<String> rollbackVmSnapshot(String node, int vmid, String snapname) =>
      _postForUpid('/nodes/$node/qemu/$vmid/snapshot/$snapname/rollback');

  /// Deletes snapshot [snapname] from [vmid]. Returns the task UPID.
  Future<String> deleteVmSnapshot(String node, int vmid, String snapname) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/nodes/$node/qemu/$vmid/snapshot/$snapname',
    );
    return response.data?['data'] as String? ?? '';
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

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data.cast<Map<String, dynamic>>();
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
