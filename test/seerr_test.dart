import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/seerr_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/seerr_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/seerr/seerr_screen.dart';

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
      '${o.method} ${o.path}${bytes.isEmpty ? '' : ' ${utf8.decode(bytes)}'}',
    );
    final body = routes['${o.method} ${o.path}'];
    return ResponseBody.fromString(
      jsonEncode(body ?? {}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

SeerrApi _api(_Adapter a) =>
    SeerrApi.fromSettings(url: 'http://seerr:5055', apiKey: 'k', adapter: a);

void main() {
  test('status names follow the v3.5.1 code enums, not the spec', () {
    expect(seerrMediaStatus(5), 'Available');
    expect(seerrMediaStatus(6), 'Blocklisted');
    expect(seerrMediaStatus(7), 'Deleted');
    expect(seerrMediaStatus(null), 'Not requested');
    expect(seerrRequestStatus(4), 'Failed');
    expect(seerrRequestStatus(5), 'Completed');
  });

  test('requests: movie plain, TV with seasons or all', () async {
    final a = _Adapter({});
    final api = _api(a);
    await api.request('movie', 550);
    await api.request('tv', 1399, seasons: [1, 2]);
    await api.request('tv', 1399);
    await api.setRequest(9, 'approve');
    await api.setIssue(3, 'resolved');
    expect(a.calls, [
      'POST /request {"mediaType":"movie","mediaId":550,"is4k":false}',
      'POST /request {"mediaType":"tv","mediaId":1399,"seasons":[1,2],"is4k":false}',
      'POST /request {"mediaType":"tv","mediaId":1399,"seasons":"all","is4k":false}',
      'POST /request/9/approve',
      'POST /issue/3/resolved',
    ]);
  });

  test('search drops people; titles carry status and poster', () async {
    final a = _Adapter({
      'GET /search': {
        'totalPages': 1,
        'results': [
          {
            'id': 438631,
            'mediaType': 'movie',
            'title': 'Dune',
            'releaseDate': '2021-09-15',
            'posterPath': '/dune.jpg',
            'mediaInfo': {'id': 12, 'status': 5},
          },
          {'id': 1, 'mediaType': 'person', 'name': 'Someone'},
        ],
      },
    });
    final r = await _api(a).search('dune');
    final t = r.results.single;
    expect((t.title, t.year, t.status, t.mediaId), ('Dune', '2021', 5, 12));
    expect(
      t.posterUrl,
      'https://image.tmdb.org/t/p/w300/dune.jpg',
    );
  });

  testWidgets('pending requests show approve and decline', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _Adapter({
      'GET /discover/trending': {'totalPages': 1, 'results': []},
      'GET /request': {
        'pageInfo': {'results': 1},
        'results': [
          {
            'id': 9,
            'status': 1,
            'type': 'movie',
            'media': {'tmdbId': 550, 'status': 2},
            'requestedBy': {'displayName': 'Sam'},
            'createdAt': '2026-10-28T10:00:00.000Z',
          },
        ],
      },
      'GET /movie/550': {
        'id': 550,
        'title': 'Fight Club',
        'releaseDate': '1999-10-15',
      },
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                jellyseerrUrl: 'http://seerr:5055',
                jellyseerrApiKey: 'k',
              ),
            ),
          ),
          seerrApiProvider.overrideWith((ref) async => _api(a)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SeerrScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Fight Club (1999)'), findsOneWidget);
    expect(find.textContaining('Pending approval'), findsOneWidget);
    expect(find.textContaining('by Sam'), findsOneWidget);
    await tester.tap(find.byTooltip('Approve'));
    await tester.pumpAndSettle();
    expect(a.calls, contains('POST /request/9/approve'));
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
