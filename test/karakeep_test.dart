import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/karakeep_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/karakeep_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/karakeep/karakeep_screen.dart';

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
    final key = '${o.method} ${o.path}';
    calls.add(
      '$key${bytes.isEmpty ? '' : ' ${utf8.decode(bytes)}'}'
      '${o.queryParameters.isEmpty ? '' : ' ${jsonEncode(o.queryParameters)}'}',
    );
    final body = routes[key];
    return ResponseBody.fromString(
      body == null ? '{}' : jsonEncode(body),
      body == null && o.method == 'GET' ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final _bookmark = {
  'id': 'b1',
  'createdAt': '2026-10-28T10:00:00.000Z',
  'modifiedAt': '2026-10-28T10:00:00.000Z',
  'title': null,
  'archived': false,
  'favourited': true,
  'taggingStatus': 'success',
  'tags': [
    {'id': 't1', 'name': 'homelab', 'attachedBy': 'ai'},
  ],
  'content': {
    'type': 'link',
    'url': 'https://example.com/post',
    'title': 'A post',
    'description': 'About things.',
  },
  'assets': [],
};

KarakeepApi _api(_Adapter a) =>
    KarakeepApi.fromSettings(url: 'http://kk:3000', apiKey: 'k', adapter: a);

void main() {
  test('bookmarks parse link content and page by cursor', () async {
    final a = _Adapter({
      'GET /bookmarks': {
        'bookmarks': [_bookmark],
        'nextCursor': 'c2',
      },
    });
    final page = await _api(a).bookmarks(favourited: true, cursor: 'c1');
    final b = page.bookmarks.single;
    expect(b.title, 'A post', reason: 'falls back to the crawled title');
    expect(b.url, 'https://example.com/post');
    expect(b.tags.single.attachedBy, 'ai');
    expect(page.nextCursor, 'c2');
    expect(a.calls.single, contains('"favourited":true'));
    expect(a.calls.single, contains('"cursor":"c1"'));
  });

  test('writes match the v0.33 API', () async {
    final a = _Adapter({});
    final api = _api(a);
    await api.addLink('https://x.test');
    await api.attachTags('b1', ['a', 'b']);
    await api.detachTag('b1', 't1');
    await api.createList('Reading', query: '#homelab');
    await api.addToList('l1', 'b1');
    expect(a.calls, [
      'POST /bookmarks {"type":"link","url":"https://x.test"}',
      'POST /bookmarks/b1/tags {"tags":[{"tagName":"a"},{"tagName":"b"}]}',
      'DELETE /bookmarks/b1/tags {"tags":[{"tagId":"t1"}]}',
      'POST /lists {"name":"Reading","icon":"📚","type":"smart","query":"#homelab"}',
      'PUT /lists/l1/bookmarks/b1',
    ]);
    expect(api.webUrl('b1'), 'http://kk:3000/dashboard/preview/b1');
  });

  testWidgets('bookmarks render and the star toggles favourite', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _Adapter({
      'GET /bookmarks': {
        'bookmarks': [_bookmark],
        'nextCursor': null,
      },
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                karakeepUrl: 'http://kk:3000',
                karakeepApiKey: 'k',
              ),
            ),
          ),
          karakeepApiProvider.overrideWith((ref) async => _api(a)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: KarakeepScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A post'), findsOneWidget);
    expect(find.textContaining('#homelab'), findsOneWidget);
    await tester.tap(find.byTooltip('Unfavourite'));
    await tester.pumpAndSettle();
    expect(a.calls, contains('PATCH /bookmarks/b1 {"favourited":false}'));
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
