import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/home_assistant_api.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/navigation/app_tab.dart';
import 'package:peira/core/providers/home_assistant_providers.dart';
import 'package:peira/core/providers/navigation_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/widgets/mechanical.dart';
import 'package:peira/screens/home_assistant/home_assistant_screen.dart';

class _SettingsRepository implements SettingsRepository {
  _SettingsRepository(this.settings);
  AppSettings settings;
  @override
  Future<AppSettings> load() async => settings;
  @override
  Future<void> save(AppSettings value) async => settings = value;
}

/// Records service calls; answers every POST with an empty change list.
class _Recorder implements HttpClientAdapter {
  final calls = <(String, Object?)>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? <int>[]
        : await requestStream.expand((c) => c).toList();
    calls.add((
      '${options.method} ${options.path}',
      bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes)),
    ));
    return ResponseBody.fromString(
      '[]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _configured = AppSettings(
  homeAssistantUrl: 'http://ha.example:8123',
  homeAssistantToken: 'tok',
);

const _states = [
  HaEntity(
    entityId: 'switch.desk_lamp',
    state: 'off',
    attributes: {'friendly_name': 'Desk lamp'},
  ),
  HaEntity(
    entityId: 'sensor.office_temp',
    state: '21.5',
    attributes: {'friendly_name': 'Office', 'unit_of_measurement': '°C'},
  ),
  HaEntity(
    entityId: 'scene.movie',
    state: 'unknown',
    attributes: {'friendly_name': 'Movie night'},
  ),
];

Future<(ProviderContainer, _Recorder)> _pump(
  WidgetTester tester,
  AppSettings settings,
) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final recorder = _Recorder();
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(
        _SettingsRepository(settings),
      ),
      homeAssistantApiProvider.overrideWith(
        (ref) async => HomeAssistantApi.fromSettings(
          url: 'http://ha.example:8123',
          token: 'tok',
          adapter: recorder,
        ),
      ),
      haStatesProvider.overrideWith((ref) async => _states),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: HomeAssistantScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, recorder);
}

void main() {
  testWidgets('without a token it asks for one and keeps the browser link', (
    tester,
  ) async {
    final (container, _) = await _pump(
      tester,
      const AppSettings(homeAssistantUrl: 'http://ha.example:8123'),
    );
    expect(
      find.text('Home Assistant needs its long-lived access token.'),
      findsOneWidget,
    );
    expect(find.text('Open in browser'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    expect(container.read(selectedTabProvider), AppTab.settings.railIndex);
  });

  testWidgets('entities render grouped, controllable first', (tester) async {
    await _pump(tester, _configured);
    expect(find.text('Desk lamp'), findsOneWidget);
    expect(find.text('21.5 °C'), findsOneWidget);
    expect(find.text('Movie night'), findsOneWidget);
    final switchY = tester.getTopLeft(find.text('SWITCH')).dy;
    final sensorY = tester.getTopLeft(find.text('SENSOR')).dy;
    expect(switchY, lessThan(sensorY));
  });

  testWidgets('the switch and the scene call their services', (tester) async {
    final (_, recorder) = await _pump(tester, _configured);
    await tester.tap(find.byType(BrassToggle));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Run'));
    await tester.pumpAndSettle();
    expect(recorder.calls.map((c) => c.$1), [
      'POST /api/services/switch/turn_on',
      'POST /api/services/scene/turn_on',
    ]);
    expect(recorder.calls.map((c) => c.$2), [
      {'entity_id': 'switch.desk_lamp'},
      {'entity_id': 'scene.movie'},
    ]);
  });

  testWidgets('search filters the list', (tester) async {
    await _pump(tester, _configured);
    await tester.enterText(find.byType(TextField).first, 'office');
    await tester.pumpAndSettle();
    expect(find.text('Office'), findsOneWidget);
    expect(find.text('Desk lamp'), findsNothing);
  });
}
