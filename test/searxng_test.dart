import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/searxng_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/searxng_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/searxng/searxng_screen.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.routes);
  final Map<String, (String, String)> routes; // path -> (contentType, body)
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final r = routes[options.path];
    return ResponseBody.fromString(
      r?.$2 ?? '{}',
      r == null ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: [r?.$1 ?? Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final _search = jsonEncode({
  'query': 'proxmox',
  'results': [
    {
      'title': 'Proxmox VE',
      'url': 'https://www.proxmox.com/en/',
      'content': 'Open-source virtualization.',
      'engines': ['brave', 'bing'],
      'publishedDate': '2026-10-01T00:00:00',
    },
    {
      'url': 'https://pve.proxmox.com/wiki/Main_Page',
      'content': '',
      'engine': 'wikipedia',
    },
  ],
  'answers': [
    'plain answer',
    {'answer': 'structured answer', 'url': null},
  ],
  'corrections': [],
  'suggestions': ['proxmox backup server'],
  'infoboxes': [
    {
      'infobox': 'Proxmox VE',
      'content': 'A virtualization platform.',
      'urls': [
        {'title': 'Website', 'url': 'https://proxmox.com'},
      ],
      'attributes': [
        {'label': 'Developer', 'value': 'Proxmox Server Solutions'},
      ],
    },
  ],
  'unresponsive_engines': [
    ['duckduckgo', 'CAPTCHA'],
  ],
});

final _config = jsonEncode({
  'version': '2026.8.17',
  'autocomplete': '',
  'categories': ['general', 'images'],
  'engines': [
    {
      'name': 'brave',
      'categories': ['general'],
      'enabled': true,
    },
    {
      'name': 'bing images',
      'categories': ['images'],
      'enabled': false,
    },
  ],
  'locales': {'en': 'English', 'de': 'Deutsch'},
  'safe_search': 0,
});

void main() {
  test('search sends the filters and parses every result part', () async {
    final a = _Adapter({'/search': (Headers.jsonContentType, _search)});
    final api = SearxngApi.fromSettings(url: 'http://sx', adapter: a);
    final page = await api.search(
      'proxmox',
      page: 2,
      timeRange: 'month',
      safeSearch: 1,
      engines: ['brave', 'bing'],
    );
    final q = a.requests.single.queryParameters;
    expect(q['format'], 'json');
    expect(q['pageno'], 2);
    expect(q['time_range'], 'month');
    expect(q['safesearch'], 1);
    expect(q['engines'], 'brave,bing');
    expect(q.containsKey('language'), isFalse);
    expect(
      q.containsKey('categories'),
      isFalse,
      reason: 'categories would override the engine list',
    );

    expect(page.results.map((r) => r.title), [
      'Proxmox VE',
      'https://pve.proxmox.com/wiki/Main_Page',
    ]);
    expect(page.results.last.engines, ['wikipedia']);
    expect(page.answers, ['plain answer', 'structured answer']);
    expect(page.infoboxes.single.attributes.single.label, 'Developer');
    expect(page.unresponsive.single, ('duckduckgo', 'CAPTCHA'));
  });

  test('autocomplete reads the suggestions+json body', () async {
    final a = _Adapter({
      '/autocompleter': (
        'application/x-suggestions+json',
        '["prox", ["proxmox", "proxmox backup"], [], []]',
      ),
    });
    final api = SearxngApi.fromSettings(url: 'http://sx', adapter: a);
    expect(await api.autocomplete('prox'), ['proxmox', 'proxmox backup']);
  });

  testWidgets('searching shows answers, infobox and results', (tester) async {
    tester.view.physicalSize = const Size(1300, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _Adapter({
      '/search': (Headers.jsonContentType, _search),
      '/config': (Headers.jsonContentType, _config),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(const AppSettings(searxngUrl: 'http://sx')),
          ),
          searxngApiProvider.overrideWith(
            (ref) async =>
                SearxngApi.fromSettings(url: 'http://sx', adapter: a),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SearxngScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SearXNG 2026.8.17 · 1 engines enabled'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'proxmox');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('structured answer'), findsOneWidget);
    expect(find.text('A virtualization platform.'), findsOneWidget);
    expect(find.text('Open-source virtualization.'), findsOneWidget);
    expect(find.textContaining('duckduckgo (CAPTCHA)'), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);
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
