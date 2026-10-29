import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/wikijs_api.dart';
import 'package:peira/core/build_config.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/providers/wikijs_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/wikijs/wikijs_screen.dart';

/// Answers each GraphQL request with the first canned body whose key occurs
/// in the query text.
class _Gql implements HttpClientAdapter {
  _Gql(this.answers);
  final Map<String, Object> answers;
  final requests = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = await requestStream!.expand((c) => c).toList();
    final req = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    requests.add(req);
    final q = req['query'] as String;
    final hit = answers.entries.where((e) => q.contains(e.key)).firstOrNull;
    return ResponseBody.fromString(
      jsonEncode(hit?.value ?? {'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

WikiJsApi _api(_Gql a) =>
    WikiJsApi.fromSettings(url: 'http://wiki:3000', apiKey: 'k', adapter: a);

void main() {
  test('wiki links resolve relative, absolute, locale and .md forms', () {
    expect(resolveWikiLink('services/pdm', '../topics/nas.md'), (
      path: 'topics/nas',
      locale: null,
    ));
    expect(resolveWikiLink('home', 'projects.md#top'), (
      path: 'projects',
      locale: null,
    ));
    expect(resolveWikiLink('a/b', '/en/infrastructure/access'), (
      path: 'infrastructure/access',
      locale: 'en',
    ));
    expect(resolveWikiLink('a/b', '/runbooks'), (
      path: 'runbooks',
      locale: null,
    ));
    expect(resolveWikiLink('a/b', '#section'), isNull);
  });

  test('search ids arrive as strings and still parse', () async {
    final a = _Gql({
      'search(': {
        'data': {
          'pages': {
            'search': {
              'results': [
                {
                  'id': '387',
                  'title': 'NAS restic',
                  'description': '',
                  'path': 'journal/x',
                  'locale': 'en',
                },
              ],
              'suggestions': [],
              'totalHits': 1,
            },
          },
        },
      },
    });
    final r = await _api(a).search('restic');
    expect(r.results.single.id, 387);
    expect(r.total, 1);
  });

  test('titles sort ascending, dates descending', () async {
    final a = _Gql({
      'list(': {
        'data': {
          'pages': {'list': []},
        },
      },
    });
    await _api(a).pages(orderBy: 'TITLE');
    await _api(a).pages();
    expect(a.requests[0]['variables']['dir'], 'ASC');
    expect(a.requests[1]['variables']['dir'], 'DESC');
  });

  test('GraphQL errors and failed results throw', () async {
    final a = _Gql({
      'single(': {
        'errors': [
          {'message': 'Forbidden'},
        ],
      },
      'delete(': {
        'data': {
          'pages': {
            'delete': {
              'responseResult': {'succeeded': false, 'message': 'Not allowed'},
            },
          },
        },
      },
    });
    expect(
      () => _api(a).page(1),
      throwsA(
        isA<WikiJsException>().having((e) => e.message, 'message', 'Forbidden'),
      ),
    );
    expect(
      () => _api(a).deletePage(1),
      throwsA(
        isA<WikiJsException>().having(
          (e) => e.message,
          'message',
          'Not allowed',
        ),
      ),
    );
  });

  testWidgets('pages list; edit controls only in the public build', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _Gql({
      'list(': {
        'data': {
          'pages': {
            'list': [
              {
                'id': 58,
                'path': 'home',
                'locale': 'en',
                'title': 'Second Brain',
                'description': 'Start here',
                'updatedAt': '2026-10-27T15:03:46.915Z',
                'tags': ['home'],
              },
            ],
          },
        },
      },
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(wikiUrl: 'http://wiki:3000', wikiApiKey: 'k'),
            ),
          ),
          wikiJsApiProvider.overrideWith((ref) async => _api(a)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: WikiJsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Second Brain'), findsOneWidget);
    expect(
      find.text('1 of 1 pages · Enter searches page text'),
      findsOneWidget,
    );
    expect(find.text('New page'), kPublicBuild ? findsOneWidget : findsNothing);
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
