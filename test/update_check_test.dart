import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/update/update_check.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

Dio _dio(int status, String body) =>
    Dio()..httpClientAdapter = _FakeAdapter(status, body);

void main() {
  test('kAppVersion matches pubspec.yaml', () {
    // The release workflow separately refuses a tag that mismatches pubspec,
    // so version, tag, and this constant can only move together.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final v = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)',
      multiLine: true,
    ).firstMatch(pubspec)?.group(1);
    expect(v, kAppVersion);
  });

  test('isNewerVersion compares numerically, tolerates v-prefix', () {
    expect(isNewerVersion('v1.0.1', '1.0.0'), isTrue);
    expect(isNewerVersion('1.1.0', '1.0.9'), isTrue);
    expect(isNewerVersion('v10.0.0', '9.9.9'), isTrue); // numeric, not lexical
    expect(isNewerVersion('v1.0.0', '1.0.0'), isFalse);
    expect(isNewerVersion('v0.9.9', '1.0.0'), isFalse);
    expect(isNewerVersion('v1.0.1-rc1', '1.0.0'), isTrue); // suffix ignored
  });

  test('newer release reports UpdateAvailable with the tag', () async {
    final result =
        await checkForUpdate(dio: _dio(200, '{"tag_name": "v99.0.0"}'));
    expect(result, isA<UpdateAvailable>());
    expect((result as UpdateAvailable).latestTag, 'v99.0.0');
  });

  test('current release reports UpToDate', () async {
    final result =
        await checkForUpdate(dio: _dio(200, '{"tag_name": "v$kAppVersion"}'));
    expect(result, isA<UpToDate>());
  });

  test('API errors surface as a failed check, not a throw', () async {
    final result = await checkForUpdate(dio: _dio(500, '{}'));
    expect(result, isA<UpdateCheckFailed>());
  });
}
