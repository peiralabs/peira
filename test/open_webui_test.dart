import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/open_webui_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/open_webui_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/open_webui/open_webui_screen.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.routes);
  final Map<String, Object> routes;
  final bodies = <String, Object?>{};

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
    bodies[key] = bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
    return ResponseBody.fromString(
      jsonEncode(routes[key] ?? {}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

OpenWebUiApi _api(_Adapter a) =>
    OpenWebUiApi.fromSettings(url: 'http://ow:8080', apiKey: 'k', adapter: a);

final _models = {
  'data': [
    {
      'id': 'qwen2.5:3b',
      'name': 'qwen2.5:3b',
      'owned_by': 'ollama',
      'ollama': {
        'details': {'family': 'qwen2', 'parameter_size': '3.1B'},
      },
    },
    {
      'id': 'nomic-embed-text:latest',
      'name': 'nomic-embed-text:latest',
      'owned_by': 'ollama',
      'ollama': {
        'details': {'family': 'nomic-bert'},
      },
    },
  ],
};

void main() {
  test('embedding models are kept out of the chat picker', () async {
    final m = await _api(_Adapter({'GET /api/models': _models})).models();
    expect(m.where((x) => x.canChat).map((x) => x.id), ['qwen2.5:3b']);
  });

  test('completion sends features and collections; sources parse', () async {
    final a = _Adapter({
      'POST /api/chat/completions': {
        'choices': [
          {
            'message': {'content': 'PVE 9.1'},
          },
        ],
        'sources': [
          {
            'source': {'name': 'web'},
            'metadata': [
              {
                'title': 'Proxmox news',
                'source': 'https://www.proxmox.com/news',
              },
            ],
          },
        ],
      },
    });
    final r = await _api(a).complete(
      'qwen2.5:3b',
      const [OwMessage('user', 'latest pve?')],
      webSearch: true,
      knowledgeIds: ['kb1'],
    );
    expect(r.content, 'PVE 9.1');
    expect(r.sources.single.url, 'https://www.proxmox.com/news');
    expect(a.bodies['POST /api/chat/completions'], {
      'model': 'qwen2.5:3b',
      'stream': false,
      'messages': [
        {'role': 'user', 'content': 'latest pve?'},
      ],
      'features': {'web_search': true},
      'files': [
        {'type': 'collection', 'id': 'kb1'},
      ],
    });
  });

  test('chat history walks the current branch of the tree', () async {
    final a = _Adapter({
      'GET /api/v1/chats/c1': {
        'title': 'T',
        'pinned': true,
        'chat': {
          'messages': [],
          'history': {
            'currentId': 'b',
            'messages': {
              'u': {'role': 'user', 'content': 'q', 'parentId': null},
              'a': {'role': 'assistant', 'content': 'old', 'parentId': 'u'},
              'b': {'role': 'assistant', 'content': 'new', 'parentId': 'u'},
            },
          },
        },
      },
    });
    final c = await _api(a).chat('c1');
    expect(c.pinned, isTrue);
    expect(c.messages.map((m) => m.content), ['q', 'new']);
  });

  testWidgets('chat sends to the picked model and shows the reply', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _Adapter({
      'GET /api/models': _models,
      'GET /api/v1/knowledge/': {'items': [], 'total': 0},
      'POST /api/chat/completions': {
        'choices': [
          {
            'message': {'content': 'Hello from qwen'},
          },
        ],
      },
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                ollamaUrl: 'http://ow:8080',
                openWebuiApiKey: 'k',
              ),
            ),
          ),
          openWebUiApiProvider.overrideWith((ref) async => _api(a)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: OpenWebUiScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'hi');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Hello from qwen'), findsOneWidget);
    expect(
      (a.bodies['POST /api/chat/completions']! as Map)['model'],
      'qwen2.5:3b',
    );
  });

  test('reasoning blocks split from the answer', () {
    expect(stripThinking('<think>hmm</think>\nok'), (
      answer: 'ok',
      thinking: 'hmm',
    ));
    expect(stripThinking('plain'), (answer: 'plain', thinking: null));
    expect(stripThinking('<think>cut off'), (answer: '', thinking: 'cut off'));
  });

  testWidgets('Enter sends, Shift+Enter does not; failures show inline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _Adapter({
      'GET /api/models': _models,
      'GET /api/v1/knowledge/': {'items': [], 'total': 0},
    });
    // No route for completions: the adapter answers 200 with {}, so make it
    // fail by pointing the reply at a 500 instead.
    final failing = _FailingCompletions(a);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                ollamaUrl: 'http://ow:8080',
                openWebuiApiKey: 'k',
              ),
            ),
          ),
          openWebUiApiProvider.overrideWith(
            (ref) async => OpenWebUiApi.fromSettings(
              url: 'http://ow:8080',
              apiKey: 'k',
              adapter: failing,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: OpenWebUiScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'hello');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(failing.completions, 0, reason: 'Shift+Enter must not send');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(failing.completions, 1);
    expect(
      find.textContaining('No answer: Server Connection Error'),
      findsOneWidget,
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

/// Delegates to [_Adapter] but fails every completion with Open WebUI's
/// own error body.
class _FailingCompletions implements HttpClientAdapter {
  _FailingCompletions(this.inner);
  final _Adapter inner;
  int completions = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (o.path == '/api/chat/completions') {
      completions++;
      return ResponseBody.fromString(
        '{"detail":"Server Connection Error"}',
        502,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return inner.fetch(o, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
