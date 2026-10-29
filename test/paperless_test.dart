import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/paperless_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/providers/paperless_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/paperless/paperless_screen.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.routes);
  final Map<String, Object> routes;
  final calls = <RequestOptions>[];
  final bodies = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(o);
    final bytes = requestStream == null
        ? <int>[]
        : await requestStream.expand((c) => c).toList();
    bodies.add(utf8.decode(bytes, allowMalformed: true));
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

PaperlessApi _api(_Adapter a) =>
    PaperlessApi.fromSettings(url: 'http://pl:8000', token: 't', adapter: a);

final _docs = {
  'count': 1,
  'next': null,
  'results': [
    {
      'id': 7,
      'title': 'Electric bill',
      'tags': [1],
      'correspondent': 2,
      'document_type': null,
      'created_date': '2026-10-01',
      'archive_serial_number': 12,
    },
  ],
};

void main() {
  test('documents send filters, token and API version 10', () async {
    final a = _Adapter({'GET /api/documents/': _docs});
    final p = await _api(
      a,
    ).documents(tagsAll: [1, 3], correspondent: 2, inboxOnly: true);
    expect(p.documents.single.asn, 12);
    final q = a.calls.single.queryParameters;
    expect(q['tags__id__all'], '1,3');
    expect(q['correspondent__id'], 2);
    expect(q['is_in_inbox'], true);
    expect(q['ordering'], '-created');
    expect(q.containsKey('query'), isFalse);
    expect(a.calls.single.headers['Authorization'], 'Token t');
    expect(a.calls.single.headers['Accept'], 'application/json; version=10');
  });

  test(
    'a text query drops the explicit ordering (relevance ranking)',
    () async {
      final a = _Adapter({'GET /api/documents/': _docs});
      await _api(a).documents(query: 'invoice');
      expect(a.calls.single.queryParameters.containsKey('ordering'), isFalse);
    },
  );

  test('v10 tasks parse type, file, status and document', () async {
    final a = _Adapter({
      'GET /api/tasks/': {
        'count': 2,
        'results': [
          {
            'id': 5,
            'task_type': 'consume_file',
            'task_type_display': 'Consume File',
            'status': 'failure',
            'input_data': {'filename': '/tmp/x/scan.pdf'},
            'result_data': {'error': 'duplicate'},
            'related_document_ids': [9],
            'date_created': '2026-10-28T10:00:00Z',
          },
        ],
      },
    });
    final r = await _api(a).tasks();
    final t = r.tasks.single;
    expect(r.count, 2);
    expect(t.name, 'Consume File: scan.pdf');
    expect(t.status, 'failure');
    expect(t.result, 'duplicate');
    expect(t.documentId, 9);
    expect(a.calls.single.queryParameters['acknowledged'], false);
  });

  test('writes: patch, bulk edit, notes, trash', () async {
    final a = _Adapter({});
    final api = _api(a);
    await api.updateDocument(7, clearCorrespondent: true, tags: [1, 2]);
    await api.bulkEdit([7], 'rotate', {'degrees': 90});
    await api.deleteNote(7, 3);
    await api.trashAction('empty', ids: [7]);
    expect(jsonDecode(a.bodies[0]), {
      'tags': [1, 2],
      'correspondent': null,
    });
    expect(jsonDecode(a.bodies[1]), {
      'documents': [7],
      'method': 'rotate',
      'parameters': {'degrees': 90},
    });
    expect(a.calls[2].queryParameters, {'id': 3});
    expect(jsonDecode(a.bodies[3]), {
      'action': 'empty',
      'documents': [7],
    });
  });

  testWidgets('documents list renders labels by name', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _Adapter({'GET /api/documents/': _docs});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                paperlessUrl: 'http://pl:8000',
                paperlessToken: 't',
              ),
            ),
          ),
          paperlessApiProvider.overrideWith((ref) async => _api(a)),
          plLabelsProvider(
            'tags',
          ).overrideWith((ref) async => const [PlLabel(1, 'bills', 1)]),
          plLabelsProvider(
            'correspondents',
          ).overrideWith((ref) async => const [PlLabel(2, 'City Power', 1)]),
          plLabelsProvider(
            'document_types',
          ).overrideWith((ref) async => const <PlLabel>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: PaperlessScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Electric bill'), findsOneWidget);
    expect(find.textContaining('City Power'), findsWidgets);
    expect(find.textContaining('#bills'), findsOneWidget);
    expect(find.text('1 documents'), findsOneWidget);
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
