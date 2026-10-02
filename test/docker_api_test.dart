import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/docker_api.dart';
import 'package:peira/core/models/app_settings.dart';

class _FakeAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.uri.path == '/containers/json') {
      return ResponseBody.fromString(
        '[{"Id":"bbb","Names":["/stopped"],"Image":"alpine",'
        '"State":"exited","Status":"Exited (0)","Ports":[]},'
        '{"Id":"aaa","Names":["/running"],"Image":"nginx",'
        '"State":"running","Status":"Up 2 hours","Ports":[]}]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.uri.path == '/containers/aaa/start') {
      return ResponseBody.fromString('', 204);
    }
    return ResponseBody.fromString('{}', 501);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const settings = AppSettings(dockerUrl: 'http://docker.example:2375');

  late _FakeAdapter adapter;
  late DockerApi api;

  setUp(() {
    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: settings.dockerUrl))
      ..httpClientAdapter = adapter;
    api = DockerApi(dio);
  });

  test('getContainers parses the bare Docker list and all=1 query', () async {
    final containers = await api.getContainers();

    expect(containers, hasLength(2));
    expect(containers.first.name, 'stopped');
    expect(containers.last.state, 'running');
    expect(adapter.requests.single.uri.queryParameters['all'], '1');
    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
  });

  test('startContainer posts to the container action endpoint', () async {
    await api.startContainer('aaa');

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.uri.path, '/containers/aaa/start');
  });

  test('fromSettings builds a client without touching the network', () {
    expect(DockerApi.fromSettings(settings), isA<DockerApi>());
  });
}
