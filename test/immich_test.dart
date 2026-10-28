import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/immich_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/immich_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/immich/immich_screen.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.routes);
  final Map<String, Object> routes; // "METHOD path" -> JSON value
  final calls = <(String, Map<String, dynamic>, Object?)>[];

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
    calls.add((
      key,
      o.queryParameters,
      bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes)),
    ));
    final body = routes[key];
    return ResponseBody.fromString(
      body == null ? '{}' : jsonEncode(body),
      body == null ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ImmichApi _api(_Adapter a) =>
    ImmichApi.fromSettings(url: 'http://immich:2283', apiKey: 'k', adapter: a);

void main() {
  test('library search sends filters and pages', () async {
    final a = _Adapter({
      'POST /api/search/metadata': {
        'albums': {},
        'assets': {
          'items': [
            {
              'id': 'a1',
              'type': 'VIDEO',
              'originalFileName': 'clip.mov',
              'isFavorite': true,
              'visibility': 'timeline',
            },
          ],
          'nextPage': '2',
        },
      },
    });
    final page = await _api(a).assets(favorites: true, type: 'VIDEO');
    expect(page.nextPage, 2);
    expect(page.assets.single.isVideo, isTrue);
    expect(a.calls.single.$3, {
      'page': 1,
      'size': 60,
      'order': 'desc',
      'visibility': 'timeline',
      'isFavorite': true,
      'type': 'VIDEO',
    });

    await _api(a).assets(trashed: true);
    final trash = a.calls.last.$3! as Map;
    expect(trash.containsKey('visibility'), isFalse);
    expect(trash['withDeleted'], isTrue);
  });

  test('album assets are read from the columnar timeline', () async {
    final a = _Adapter({
      'GET /api/timeline/buckets': [
        {'timeBucket': '2026-10-01', 'count': 2},
      ],
      'GET /api/timeline/bucket': {
        'id': ['x', 'y'],
        'isImage': [true, false],
        'isFavorite': [false, true],
        'visibility': ['timeline', 'timeline'],
        'fileCreatedAt': ['2026-10-02T10:00:00Z', '2026-10-03T10:00:00Z'],
      },
    });
    final assets = await _api(a).albumAssets('alb');
    expect(assets.map((x) => (x.id, x.isVideo, x.isFavorite)), [
      ('x', false, false),
      ('y', true, true),
    ]);
    expect(a.calls.last.$2, {'albumId': 'alb', 'timeBucket': '2026-10-01'});
  });

  test('writes use the v3 endpoints and bodies', () async {
    final a = _Adapter({
      'PUT /api/assets': {},
      'DELETE /api/assets': {},
      'PUT /api/jobs/thumbnailGeneration': {},
      'POST /api/trash/empty': {'count': 3},
    });
    final api = _api(a);
    await api.updateAssets(['a'], isFavorite: true);
    await api.deleteAssets(['a']);
    await api.queueCommand('thumbnailGeneration', 'start', force: true);
    expect(await api.emptyTrash(), 3);
    expect(a.calls.map((c) => '${c.$1} ${jsonEncode(c.$3)}'), [
      'PUT /api/assets {"ids":["a"],"isFavorite":true}',
      'DELETE /api/assets {"ids":["a"],"force":false}',
      'PUT /api/jobs/thumbnailGeneration {"command":"start","force":true}',
      'POST /api/trash/empty null',
    ]);
    expect(
      api.thumbnailUrl('a', size: 'preview'),
      'http://immich:2283/api/assets/a/thumbnail?size=preview',
    );
    expect(api.imageHeaders, {'x-api-key': 'k'});
  });

  testWidgets('without a key it asks for one', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(const AppSettings(immichUrl: 'http://immich:2283')),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: ImmichScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Immich needs its API key.'), findsOneWidget);
    expect(find.text('Open in browser'), findsOneWidget);
  });

  testWidgets('server view shows storage and queue controls', (tester) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _Adapter({
      'GET /api/server/about': {'version': 'v3.3.5'},
      'GET /api/server/statistics': {
        'photos': 2238,
        'videos': 179,
        'usage': 53687091200,
      },
      'GET /api/server/storage': {
        'diskSize': '1.8 TiB',
        'diskUse': '700 GiB',
        'diskUsagePercentage': 38.4,
      },
      'GET /api/server/features': {'smartSearch': true},
      'GET /api/queues': [
        {
          'name': 'thumbnailGeneration',
          'isPaused': false,
          'statistics': {'active': 1, 'waiting': 4, 'failed': 0, 'delayed': 0},
        },
      ],
      'PUT /api/jobs/thumbnailGeneration': {},
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                immichUrl: 'http://immich:2283',
                immichApiKey: 'k',
              ),
            ),
          ),
          immichApiProvider.overrideWith((ref) async => _api(a)),
          // The auto-refreshing providers would leave 30 s timers pending.
          immichServerProvider.overrideWith(
            (ref) async => (await ref.watch(immichApiProvider.future)).server(),
          ),
          immichQueuesProvider.overrideWith(
            (ref) async => (await ref.watch(immichApiProvider.future)).queues(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: ImmichScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Server'));
    await tester.pumpAndSettle();
    expect(find.text('Immich v3.3.5'), findsOneWidget);
    expect(find.textContaining('2238 photos · 179 videos'), findsOneWidget);
    expect(find.textContaining('waiting 4'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run missing'));
    await tester.pumpAndSettle();
    expect(
      a.calls
          .where((c) => c.$1 == 'PUT /api/jobs/thumbnailGeneration')
          .single
          .$3,
      {'command': 'start', 'force': false},
    );
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
