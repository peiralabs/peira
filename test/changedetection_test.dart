import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/changedetection_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/changedetection_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/changedetection/changedetection_screen.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.routes);
  final Map<String, Object> routes;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? <int>[]
        : await requestStream.expand((c) => c).toList();
    calls.add(
      '${o.method} ${o.path}'
      '${o.queryParameters.isEmpty ? '' : ' ${jsonEncode(o.queryParameters)}'}'
      '${bytes.isEmpty ? '' : ' ${utf8.decode(bytes)}'}',
    );
    final body = routes['${o.method} ${o.path}'];
    final isJson = body is Map || body is List;
    return ResponseBody.fromString(
      body == null ? 'OK' : (isJson ? jsonEncode(body) : '$body'),
      200,
      headers: {
        Headers.contentTypeHeader: [
          isJson ? Headers.jsonContentType : 'text/plain',
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ChangedetectionApi _api(_Adapter a) => ChangedetectionApi.fromSettings(
  url: 'http://cd:5000',
  apiKey: 'k',
  adapter: a,
);

final _watches = {
  'u1': {
    'title': 'Plex releases',
    'url': 'https://plex.tv/api/downloads/5.json',
    'last_checked': 1793160000,
    'last_changed': 1793100000,
    'last_error': false,
    'viewed': false,
    'tags': ['t1'],
  },
  'u2': {
    'title': '',
    'page_title': 'Tailscale releases',
    'url': 'https://api.github.com/repos/tailscale/tailscale/releases/latest',
    'last_checked': 1793160000,
    'last_changed': 0,
    'last_error': 'Timeout',
    'viewed': true,
    'tags': [],
  },
};

void main() {
  test('watches parse, newest change first; actions send v1 params', () async {
    final a = _Adapter({'GET /watch': _watches});
    final api = _api(a);
    final w = await api.watches();
    expect(w.map((x) => x.title), ['Plex releases', 'Tailscale releases']);
    expect(w.first.viewed, isFalse);
    expect(w.last.lastError, 'Timeout');
    expect(w.last.lastChanged, isNull);

    await api.setPaused('u1', true);
    await api.recheck('u1');
    await api.updateWatch('u1', intervalMinutes: 90);
    await api.updateWatch('u1', intervalMinutes: 0);
    expect(a.calls.skip(1), [
      'GET /watch/u1 {"paused":"paused"}',
      'GET /watch/u1 {"recheck":"1"}',
      'PUT /watch/u1 {"time_between_check_use_default":false,'
          '"time_between_check":{"weeks":0,"days":0,"hours":1,"minutes":30,"seconds":0}}',
      'PUT /watch/u1 {"time_between_check_use_default":true}',
    ]);
  });

  test('interval reads back from the time_between_check fields', () {
    const d = CdWatchDetail(
      CdWatch(uuid: 'u', url: '', title: '', tags: [], viewed: true),
      {
        'time_between_check_use_default': false,
        'time_between_check': {'days': 1, 'hours': 2, 'minutes': 5},
      },
    );
    expect(d.intervalMinutes, 1565);
  });

  testWidgets('watch list shows unseen changes and errors', (tester) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _Adapter({
      'GET /watch': _watches,
      'GET /tags': {
        't1': {'title': 'releases', 'notification_muted': false},
      },
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                changedetectionUrl: 'http://cd:5000',
                changedetectionApiKey: 'k',
              ),
            ),
          ),
          changedetectionApiProvider.overrideWith((ref) async => _api(a)),
          cdWatchesProvider.overrideWith(
            (ref) async =>
                (await ref.watch(changedetectionApiProvider.future)).watches(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: ChangedetectionScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plex releases'), findsOneWidget);
    expect(find.text('2 watches · 1 unseen changes'), findsOneWidget);
    expect(find.textContaining('#releases'), findsOneWidget);
    expect(find.textContaining('Timeout'), findsOneWidget);
  });
}

class _Settings implements SettingsRepository {
  _Settings(this.settings);
  AppSettings settings;
  @override
  Future<AppSettings> load() async => settings;
  @override
  Future<void> save(AppSettings value) async => settings = value;
}
