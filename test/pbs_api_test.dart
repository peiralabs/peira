import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/pbs_api.dart';

class _Reply {
  const _Reply(this.body);

  final String body;
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(Map<String, List<_Reply>> routes)
    : routes = routes.map((key, value) => MapEntry(key, [...value]));

  final Map<String, List<_Reply>> routes;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final replies = routes[options.uri.path];
    if (replies == null || replies.isEmpty) {
      return ResponseBody.fromString('missing ${options.uri.path}', 501);
    }
    final reply = replies.removeAt(0);
    return ResponseBody.fromString(
      reply.body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAdapter adapter;
  late PbsApi api;

  void configure(Map<String, List<_Reply>> routes, {String user = 'user@pbs'}) {
    adapter = _FakeAdapter(routes);
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://pbs.example/api2/json',
        headers: const {
          'Authorization': 'PBSAPIToken=reader@pbs!app:token-secret',
        },
      ),
    )..httpClientAdapter = adapter;
    api = PbsApi(dio, user);
  }

  test('token header is sent on ordinary requests', () async {
    configure({
      '/api2/json/version': [const _Reply('{"data":{"version":"4.2"}}')],
    });

    expect((await api.version())['version'], '4.2');
    expect(
      adapter.requests.single.headers['Authorization'],
      'PBSAPIToken=reader@pbs!app:token-secret',
    );
  });

  test('login is form encoded without token auth and parses ticket', () async {
    configure({
      '/api2/json/access/ticket': [
        const _Reply(
          '{"data":{"ticket":"PBS:ticket/value",'
          '"CSRFPreventionToken":"csrf","username":"user@pbs"}}',
        ),
      ],
    });

    final ticket = await api.login('password');

    expect(ticket.ticket, 'PBS:ticket/value');
    expect(ticket.csrf, 'csrf');
    expect(ticket.username, 'user@pbs');
    expect(ticket.expired, isFalse);
    final request = adapter.requests.single;
    expect(request.contentType, Headers.formUrlEncodedContentType);
    expect(request.headers['Authorization'], isNull);
    expect(request.data, {'username': 'user@pbs', 'password': 'password'});
  });

  test('login rejects a TFA challenge ticket', () async {
    configure({
      '/api2/json/access/ticket': [
        const _Reply(
          '{"data":{"ticket":"PBS:!tfa!:challenge",'
          '"CSRFPreventionToken":"csrf","username":"user@pbs"}}',
        ),
      ],
    });

    await expectLater(api.login('password'), throwsA(isA<PbsTfaRequired>()));
  });

  test('withTicket sends cookie and CSRF but no Authorization', () async {
    configure({
      '/api2/json/admin/datastore/store/gc': [
        const _Reply('{"data":"UPID:gc"}'),
      ],
    });
    final elevated = api.withTicket(
      PbsTicket(
        ticket: 'PBS:ticket/value',
        csrf: 'csrf-value',
        username: 'user@pbs',
        issued: DateTime.now(),
      ),
    );

    expect(await elevated.startGc('store'), 'UPID:gc');

    final request = adapter.requests.single;
    expect(request.headers['Authorization'], isNull);
    expect(request.headers['Cookie'], 'PBSAuthCookie=PBS%3Aticket%2Fvalue');
    expect(request.headers['CSRFPreventionToken'], 'csrf-value');
  });

  test('snapshots parses verification and detects encrypted files', () async {
    configure({
      '/api2/json/admin/datastore/store/snapshots': [
        const _Reply(
          '{"data":[{"backup-type":"vm","backup-id":"101",'
          '"backup-time":1792679229,"size":456,"protected":1,'
          '"comment":"nightly","owner":"reader@pbs",'
          '"verification":{"state":"ok","upid":"UPID:verify"},'
          '"files":[{"filename":"index.json.blob","size":12,'
          '"crypt-mode":"none"},{"filename":"drive-scsi0.img.fidx",'
          '"size":444,"crypt-mode":"encrypt"}],'
          '"fingerprint":"AA:BB"}]}',
        ),
      ],
    });

    final snapshot = (await api.snapshots(
      'store',
      ns: 'office',
      type: 'vm',
      id: '101',
    )).single;

    expect(snapshot.type, 'vm');
    expect(snapshot.id, '101');
    expect(snapshot.namespace, 'office');
    expect(snapshot.protected, isTrue);
    expect(snapshot.verification?.state, 'ok');
    expect(snapshot.verification?.upid, 'UPID:verify');
    expect(snapshot.encrypted, isTrue);
    expect(snapshot.files.last.size, 444);
  });

  test('prunePreview includes identity, retention, and dry-run', () async {
    configure({
      '/api2/json/admin/datastore/store/prune': [
        const _Reply(
          '{"data":[{"backup-time":100,"keep":true,"protected":0}]}',
        ),
      ],
    });
    const group = PbsGroup(
      type: 'host',
      id: 'node1',
      lastBackup: 100,
      backupCount: 2,
      owner: 'reader@pbs',
      comment: '',
      files: 3,
      namespace: 'office',
    );

    final result = await api.prunePreview(
      'store',
      group,
      const PbsKeep(last: 3, daily: 7),
    );

    expect(result.single.keep, isTrue);
    expect(adapter.requests.single.data, {
      'backup-type': 'host',
      'backup-id': 'node1',
      'ns': 'office',
      'keep-last': 3,
      'keep-daily': 7,
      'dry-run': true,
    });
  });

  test('deleteSnapshot puts complete identity in query parameters', () async {
    configure({
      '/api2/json/admin/datastore/store/snapshots': [
        const _Reply('{"data":null}'),
      ],
    });
    const snapshot = PbsSnapshot(
      type: 'ct',
      id: '200',
      time: 1234,
      size: 0,
      protected: false,
      comment: '',
      owner: '',
      verification: null,
      files: [],
      fingerprint: '',
      namespace: 'lab',
    );

    await api.deleteSnapshot('store', snapshot);

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.queryParameters, {
      'backup-type': 'ct',
      'backup-id': '200',
      'backup-time': 1234,
      'ns': 'lab',
    });
  });

  test('taskLogTail reads total then requests only the tail', () async {
    configure({
      '/api2/json/nodes/localhost/tasks/UPID%3Anode%3Aone/log': [
        const _Reply('{"data":[],"total":250}'),
        const _Reply(
          '{"data":[{"n":151,"t":"tail one"},'
          '{"n":152,"t":"tail two"}],"total":250}',
        ),
      ],
    });

    expect(await api.taskLogTail('UPID:node:one', limit: 100), [
      'tail one',
      'tail two',
    ]);
    expect(adapter.requests.first.queryParameters, {'limit': 0});
    expect(adapter.requests.last.queryParameters, {'start': 150, 'limit': 100});
  });

  test('runJob uses the admin kind/id run path', () async {
    configure({
      '/api2/json/admin/verify/nightly/run': [
        const _Reply('{"data":"UPID:verify"}'),
      ],
    });

    expect(await api.runJob('verify', 'nightly'), 'UPID:verify');
    expect(
      adapter.requests.single.uri.path,
      '/api2/json/admin/verify/nightly/run',
    );
    expect(adapter.requests.single.method, 'POST');
  });

  test(
    'datastore usage is filtered client-side, with no store param',
    () async {
      configure({
        '/api2/json/status/datastore-usage': [
          const _Reply(
            '{"data":[{"store":"other","total":1,"used":1},'
            '{"store":"pbs-local","total":100,"used":40,"avail":60}]}',
          ),
        ],
      });

      final usage = await api.datastoreStatus('pbs-local');

      expect(usage.used, 40);
      expect(adapter.requests.single.uri.queryParameters, isEmpty);
    },
  );

  test('catalog paths come back decoded from PBS base64', () async {
    configure({
      '/api2/json/admin/datastore/s/catalog': [
        const _Reply(
          '{"data":[{"text":"etc","type":"d","leaf":false,'
          '"filepath":"cm9vdC5weGFyLmRpZHgvZXRj"}]}',
        ),
      ],
    });
    const snap = PbsSnapshot(
      type: 'ct',
      id: '1',
      time: 1,
      size: 0,
      protected: false,
      comment: '',
      owner: '',
      verification: null,
      files: [],
      fingerprint: '',
      namespace: null,
    );

    final rows = await api.catalog('s', snap, '/');

    expect(rows.single.filepath, 'root.pxar.didx/etc');
  });
}
