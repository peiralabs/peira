import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/proxmox_api.dart';
import 'package:peira/core/models/app_settings.dart';

/// Serves the captured fixtures by URL path and records every request, so
/// the client's paths, headers, and parsing are all exercised.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, String> routes;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final body = routes[options.uri.path];
    if (body == null) {
      return ResponseBody.fromString('{"data":null}', 501);
    }
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

String _fixture(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();

void main() {
  const settings = AppSettings(
    proxmoxUrl: 'https://pve.example:8006',
    proxmoxTokenId: 'user@pve!token',
    proxmoxTokenSecret: 'secret-uuid',
  );

  late _FakeAdapter adapter;
  late ProxmoxApi api;

  setUp(() {
    adapter = _FakeAdapter({
      '/api2/json/nodes': _fixture('nodes'),
      '/api2/json/nodes/node4/status': _fixture('node_status'),
      '/api2/json/nodes/node4/lxc': _fixture('containers'),
      '/api2/json/nodes/node4/lxc/104/status/current':
          _fixture('container_status'),
      '/api2/json/cluster/tasks': _fixture('tasks'),
      '/api2/json/nodes/node4/lxc/104/status/start':
          '{"data":"UPID:node4:start"}',
      '/api2/json/nodes/node4/lxc/104/status/stop':
          '{"data":"UPID:node4:stop"}',
      '/api2/json/nodes/node4/lxc/104/status/reboot':
          '{"data":"UPID:node4:reboot"}',
      '/api2/json/nodes/node4/storage/pbs-local/content':
          '{"data":[{"volid":"pbs-local:backup/vm/104/2026-08-28T10:00:00Z","vmid":104,"ctime":1787911200,"size":4096}]}',
      '/api2/json/nodes/node4/vzdump':
          '{"data":"UPID:node4:vzdump"}',
    });
    final dio = Dio(BaseOptions(
      baseUrl: '${settings.proxmoxUrl}/api2/json',
      headers: {
        'Authorization':
            'PVEAPIToken=${settings.proxmoxTokenId}=${settings.proxmoxTokenSecret}',
      },
    ))
      ..httpClientAdapter = adapter;
    api = ProxmoxApi(dio);
  });

  test('getNodes parses and sorts, sends the PVEAPIToken header', () async {
    final nodes = await api.getNodes();
    expect(nodes.map((n) => n.node),
        ['node1', 'node2', 'node3', 'node4']);
    expect(
      adapter.requests.single.headers['Authorization'],
      'PVEAPIToken=user@pve!token=secret-uuid',
    );
  });

  test('getNodeStatus parses nested usage objects', () async {
    final status = await api.getNodeStatus('node4');
    expect(status.memory?.total, greaterThan(0));
    expect(status.pveversion, isNotNull);
  });

  test('getContainers injects the node and sorts by vmid', () async {
    final cts = await api.getContainers('node4');
    expect(cts.every((c) => c.node == 'node4'), isTrue);
    final vmids = cts.map((c) => c.vmid).toList();
    expect(vmids, orderedEquals([...vmids]..sort()));
  });

  test('getContainerStatus parses current status', () async {
    final status = await api.getContainerStatus('node4', 104);
    expect(status.status, 'running');
  });

  test('start/stop/reboot POST and return the UPID', () async {
    expect(await api.startContainer('node4', 104), 'UPID:node4:start');
    expect(await api.stopContainer('node4', 104), 'UPID:node4:stop');
    expect(
        await api.rebootContainer('node4', 104), 'UPID:node4:reboot');
    expect(adapter.requests.map((r) => r.method).toSet(), {'POST'});
  });

  test('getRecentTasks sorts newest first and applies limit', () async {
    final tasks = await api.getRecentTasks(limit: 3);
    expect(tasks, hasLength(3));
    expect(tasks.first.starttime,
        greaterThanOrEqualTo(tasks.last.starttime));
  });

  test('getBackups requests backup content and returns raw maps', () async {
    final backups = await api.getBackups('node4', 'pbs-local');

    expect(backups, hasLength(1));
    expect(backups.single['vmid'], 104);
    expect(adapter.requests.single.uri.queryParameters['content'], 'backup');
  });

  test('createBackup sends form parameters and returns the UPID', () async {
    final upid = await api.createBackup(
      'node4',
      vmid: 104,
      storage: 'pbs-local',
      mode: 'suspend',
      compress: false,
    );

    final request = adapter.requests.single;
    expect(upid, 'UPID:node4:vzdump');
    expect(request.method, 'POST');
    expect(request.contentType, Headers.formUrlEncodedContentType);
    expect(request.data, {
      'vmid': 104,
      'storage': 'pbs-local',
      'mode': 'suspend',
      'compress': '0',
    });
  });

  test('fromSettings builds a client without touching the network', () {
    expect(ProxmoxApi.fromSettings(settings), isA<ProxmoxApi>());
  });
}
