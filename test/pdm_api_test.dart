import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/pdm_api.dart';

class _Reply {
  const _Reply(this.body, {this.statusCode = 200, this.contentType});

  final String body;
  final int statusCode;
  final String? contentType;
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, _Reply> routes;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = routes[options.uri.path];
    if (reply == null) {
      return ResponseBody.fromString('missing ${options.uri.path}', 501);
    }
    return ResponseBody.fromString(
      reply.body,
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [
          reply.contentType ?? Headers.jsonContentType,
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAdapter adapter;
  late PdmApi api;

  void configure(Map<String, _Reply> routes) {
    adapter = _FakeAdapter(routes);
    final dio = Dio(BaseOptions(baseUrl: 'https://pdm.example/api2/json'))
      ..httpClientAdapter = adapter;
    api = PdmApi(dio);
  }

  test('remotes parses endpoint hosts without exposing auth fields', () async {
    configure({
      '/api2/json/remotes/remote': const _Reply(
        '{"data":[{"id":"office","type":"pve",'
        '"authid":"private-user","token":"private-token",'
        '"nodes":["10.0.0.1,fingerprint=AA:BB",'
        '"host.example,fingerprint=CC:DD"]},'
        '{"id":"backup","type":"pbs","nodes":[]}]}',
      ),
    });

    final remotes = await api.remotes();

    expect(remotes, hasLength(2));
    expect(remotes.first.id, 'office');
    expect(remotes.first.type, 'pve');
    expect(remotes.first.endpoints, ['10.0.0.1', 'host.example']);
    expect(remotes.first.toString(), isNot(contains('private')));
  });

  test(
    'resources splits known types, tolerates numbers, and ignores unknown',
    () async {
      configure({
        '/api2/json/pve/remotes/office/resources': const _Reply(
          '{"data":['
          '{"type":"node","node":"node1","status":"online",'
          '"cpu":0.02,"maxcpu":8,"mem":100.0,"maxmem":200,"uptime":300},'
          '{"type":"lxc","vmid":101,"name":"ct","node":"node1",'
          '"status":"running","template":0,"cpu":0,"maxcpu":2.0,'
          '"mem":10,"maxmem":20.0,"disk":30,"maxdisk":40.0,'
          '"uptime":50,"tags":"one; two,three"},'
          '{"type":"qemu","vmid":102.0,"name":"vm","node":"node1",'
          '"status":"stopped","template":false,"cpu":0.0,"maxcpu":4,'
          '"mem":0,"maxmem":100,"disk":5.0,"maxdisk":200,"uptime":0},'
          '{"type":"storage","storage":"local","node":"node1",'
          '"shared":1,"status":"available","disk":123.0,"maxdisk":456},'
          '{"type":"sdn","id":"ignored"}]}',
        ),
      });

      final resources = await api.resources('office');

      expect(resources.nodes.single.maxcpu, 8.0);
      expect(resources.nodes.single.mem, 100);
      expect(resources.guests, hasLength(2));
      expect(resources.guests.first.tags, ['one', 'two', 'three']);
      expect(resources.guests.last.vmid, 102);
      expect(resources.storages.single.used, 123);
      expect(resources.storages.single.total, 456);
    },
  );

  test('clusterStatus accepts bool and numeric flags', () async {
    configure({
      '/api2/json/pve/remotes/office/cluster-status': const _Reply(
        '{"data":[{"type":"cluster","name":"pvehome","nodes":3,'
        '"quorate":1},{"type":"node","name":"one","online":true},'
        '{"type":"node","name":"two","online":1},'
        '{"type":"node","name":"three","online":0}]}',
      ),
    });

    final status = await api.clusterStatus('office');

    expect(status.name, 'pvehome');
    expect(status.quorate, isTrue);
    expect(status.nodesOnline, 2);
    expect(status.nodesTotal, 3);
  });

  test(
    'guestConfig parses LXC privilege, raw keys, storage, and bridge',
    () async {
      configure({
        '/api2/json/pve/remotes/office/lxc/111/config': const _Reply(
          '{"data":{"rootfs":"local-lvm:vm-111-disk-0,size=12G",'
          '"mp0":"bulk:vm-111-disk-1,mp=/data,size=8G",'
          '"net0":"name=eth0,bridge=vmbr0,ip=dhcp,type=veth",'
          '"lxc":[["lxc.cgroup2.devices.allow","c 195:* rwm"]]}}',
        ),
      });

      final config = await api.guestConfig('office', 'lxc', 111);

      expect(config.unprivileged, isFalse);
      expect(config.hasRawLxcKeys, isTrue);
      expect(config.storages, {'local-lvm', 'bulk'});
      expect(config.bridges, {'vmbr0'});
      expect(adapter.requests.single.queryParameters, {'state': 'active'});
    },
  );

  test('guestConfig parses QEMU disks and skips cdrom and none', () async {
    configure({
      '/api2/json/pve/remotes/office/qemu/120/config': const _Reply(
        '{"data":{"scsi0":"local-lvm:vm-120-disk-0,size=32G",'
        '"efidisk0":"efi:vm-120-disk-1,size=4M",'
        '"ide2":"local:iso/os.iso,media=cdrom",'
        '"sata0":"none","net0":"virtio=AA:BB,bridge=vmbr1"}}',
      ),
    });

    final config = await api.guestConfig('office', 'qemu', 120);

    expect(config.storages, {'local-lvm', 'efi'});
    expect(config.bridges, {'vmbr1'});
    expect(config.hasRawLxcKeys, isFalse);
  });

  test('guestAction posts JSON empty object to the exact path', () async {
    configure({
      '/api2/json/pve/remotes/office/qemu/120/resume': const _Reply(
        '{"data":"pve:office!UPID:node:resume"}',
      ),
    });

    final upid = await api.guestAction('office', 'qemu', 120, 'resume');

    expect(upid, 'pve:office!UPID:node:resume');
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.data, <String, dynamic>{});
    expect(request.contentType, Headers.jsonContentType);
    expect(request.uri.path, '/api2/json/pve/remotes/office/qemu/120/resume');
  });

  test('taskStatus applies stopped OK and WARNINGS success rules', () async {
    for (final (body, running, succeeded) in [
      ('{"data":{"status":"running"}}', true, false),
      ('{"data":{"status":"stopped","exitstatus":"OK"}}', false, true),
      ('{"data":{"status":"stopped","exitstatus":"WARNINGS: 1"}}', false, true),
      ('{"data":{"status":"stopped","exitstatus":"failed"}}', false, false),
    ]) {
      configure({
        '/api2/json/pve/remotes/office/tasks/pve%3Aoffice!UPID%3Aone/status':
            _Reply(body),
      });
      final status = await api.taskStatus('office', 'pve:office!UPID:one');
      expect(status.running, running);
      expect(status.succeeded, succeeded);
    }
  });

  test('tasks parses remote, timestamps, filters, and running state', () async {
    configure({
      '/api2/json/remotes/tasks/list': const _Reply(
        '{"data":[{"upid":"pve:office!UPID:node:one",'
        '"node":"node1","starttime":1792679229,"user":"root@pam",'
        '"worker_type":"vzdestroy","worker_id":null}]}',
      ),
    });

    final tasks = await api.tasks(limit: 25, runningOnly: true);

    expect(tasks.single.remote, 'office');
    expect(tasks.single.running, isTrue);
    expect(tasks.single.failed, isFalse);
    expect(tasks.single.end, isNull);
    expect(tasks.single.start.isUtc, isTrue);
    expect(adapter.requests.single.queryParameters, {
      'limit': 25,
      'running': 1,
    });
  });

  test('a null worker_id is read from the UPID', () async {
    configure({
      '/api2/json/remotes/tasks/list': const _Reply(
        '{"data":[{"upid":"pve:office!UPID:node1:00127C15:00BBE9C0:'
        '6AD9191C:imgdel:120@pbs-local:root@pam:","node":"node1",'
        '"starttime":1792679229,"endtime":1792679230,"user":"root@pam",'
        '"worker_type":"imgdel","worker_id":null,"status":"failed"},'
        '{"upid":"pve:office!UPID:node1:1:2:3:vzstart:9001:user@pve!token:",'
        '"node":"node1","starttime":1792679229,"endtime":1792679231,'
        '"user":"user@pve!token","worker_type":"vzstart","worker_id":null,'
        '"status":"WARNINGS: 1"}]}',
      ),
    });

    final tasks = await api.tasks();

    expect(tasks.map((t) => t.workerId), ['120@pbs-local', '9001']);
    expect(tasks.map((t) => t.failed), [true, false]);
  });

  test('taskLog and bridges parse their list responses', () async {
    configure({
      '/api2/json/pve/remotes/office/tasks/pve%3Aoffice!UPID%3Aone/log':
          const _Reply('{"data":[{"n":1,"t":"first"},{"n":2,"t":"done"}]}'),
      '/api2/json/pve/remotes/office/nodes/node1/network': const _Reply(
        '{"data":[{"iface":"vmbr0","type":"bridge","active":true},'
        '{"iface":"eno1","type":"eth"}]}',
      ),
    });

    expect(await api.taskLog('office', 'pve:office!UPID:one', limit: 2), [
      'first',
      'done',
    ]);
    expect(await api.bridges('office', 'node1'), ['vmbr0']);
  });

  test('nextId accepts integer and numeric string', () async {
    for (final value in ['100', '"101"']) {
      configure({
        '/api2/json/pve/remotes/office/cluster-nextid': _Reply(
          '{"data":$value}',
        ),
      });
      expect(await api.nextId('office'), value == '100' ? 100 : 101);
    }
  });

  test('remoteMigrate sends exactly required and supplied keys', () async {
    configure({
      '/api2/json/pve/remotes/office/lxc/111/remote-migrate': const _Reply(
        '{"data":"pve:office!UPID:node:migrate"}',
      ),
    });

    final upid = await api.remoteMigrate(
      'office',
      'lxc',
      111,
      target: 'home',
      storageMap: {'local-lvm': 'local-lvm'},
      bridgeMap: {'vmbr0': 'vmbr1'},
      targetEndpoint: '100.64.0.2',
    );

    expect(upid, 'pve:office!UPID:node:migrate');
    final request = adapter.requests.single;
    expect(request.contentType, Headers.jsonContentType);
    expect(request.data, {
      'target': 'home',
      'target-storage': ['local-lvm:local-lvm'],
      'target-bridge': ['vmbr0:vmbr1'],
      'delete': true,
      'target-endpoint': '100.64.0.2',
    });
  });

  test('status discovers names through /remotes/remote only', () async {
    configure({
      '/api2/json/remotes/remote': const _Reply(
        '{"data":[{"id":"office","type":"pve","nodes":[]},'
        '{"id":"backup","type":"pbs","nodes":[]}]}',
      ),
      '/api2/json/pve/remotes/office/cluster-status': const _Reply(
        '{"data":[{"type":"cluster","name":"office","nodes":1,'
        '"quorate":true},{"type":"node","online":true}]}',
      ),
    });

    final status = await api.status();

    expect(status.remotes.map((remote) => remote.name), ['office', 'backup']);
    expect(status.remotes.first.nodesOnline, 1);
    expect(
      adapter.requests.map((request) => request.uri.path),
      isNot(contains('/api2/json/pve/remotes')),
    );
  });

  for (final statusCode in [403, 500]) {
    test('$statusCode response becomes PdmApiException with body', () async {
      configure({
        '/api2/json/remotes/remote': _Reply(
          'permission denied by PDM',
          statusCode: statusCode,
          contentType: Headers.textPlainContentType,
        ),
      });

      await expectLater(
        api.remotes(),
        throwsA(
          isA<PdmApiException>()
              .having((error) => error.statusCode, 'statusCode', statusCode)
              .having(
                (error) => error.message,
                'message',
                'permission denied by PDM',
              ),
        ),
      );
    });
  }
}
