import 'package:dio/dio.dart';

import 'media_dio.dart';

/// One Home Assistant entity as `/api/states` reports it.
class HaEntity {
  const HaEntity({
    required this.entityId,
    required this.state,
    required this.attributes,
    this.lastChanged,
  });

  factory HaEntity.fromJson(Map<String, dynamic> json) => HaEntity(
    entityId: json['entity_id'] as String? ?? '',
    state: json['state']?.toString() ?? '',
    attributes: (json['attributes'] as Map?)?.cast<String, dynamic>() ?? {},
    lastChanged: DateTime.tryParse(json['last_changed'] as String? ?? ''),
  );

  final String entityId;
  final String state;
  final Map<String, dynamic> attributes;
  final DateTime? lastChanged;

  String get domain => entityId.split('.').first;
  String get name => attributes['friendly_name'] as String? ?? entityId;
  bool get unavailable => state == 'unavailable' || state == 'unknown';

  /// The `supported_features` bitmask; each domain defines its own bits.
  int get features => (attributes['supported_features'] as num?)?.toInt() ?? 0;
  bool supports(int bit) => features & bit != 0;

  String? get unit => attributes['unit_of_measurement'] as String?;
  double? get numericState => double.tryParse(state);
}

/// A service HA offers, from `/api/services`.
class HaService {
  const HaService({
    required this.domain,
    required this.service,
    required this.name,
    required this.description,
    required this.fields,
  });

  final String domain;
  final String service;
  final String name;
  final String description;

  /// Field name → its description map (`description`, `example`,
  /// `required`, `selector`), as HA publishes it.
  final Map<String, Map<String, dynamic>> fields;

  String get id => '$domain.$service';
}

/// One `/api/logbook` row.
class HaLogbookEntry {
  const HaLogbookEntry({
    required this.when,
    required this.name,
    this.entityId,
    this.state,
    this.message,
  });

  factory HaLogbookEntry.fromJson(Map<String, dynamic> json) => HaLogbookEntry(
    when: DateTime.tryParse(json['when'] as String? ?? '') ?? DateTime(0),
    name: json['name'] as String? ?? json['entity_id'] as String? ?? '',
    entityId: json['entity_id'] as String?,
    state: json['state']?.toString(),
    message: json['message'] as String?,
  );

  final DateTime when;
  final String name;
  final String? entityId;
  final String? state;
  final String? message;
}

/// A point on an entity's state history.
class HaHistoryPoint {
  const HaHistoryPoint(this.when, this.state);
  final DateTime when;
  final String state;
}

/// One to-do list item (`todo.get_items`).
class HaTodoItem {
  const HaTodoItem({
    required this.uid,
    required this.summary,
    required this.done,
    this.due,
    this.description,
  });

  factory HaTodoItem.fromJson(Map<String, dynamic> json) => HaTodoItem(
    uid: json['uid'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    done: json['status'] == 'completed',
    due: json['due'] as String?,
    description: json['description'] as String?,
  );

  final String uid;
  final String summary;
  final bool done;
  final String? due;
  final String? description;
}

/// Home Assistant REST API (https://developers.home-assistant.io/docs/api/rest)
/// with a long-lived access token. Everything the tab does goes through
/// [callService], so the token's user rights are the only limit.
class HomeAssistantApi {
  HomeAssistantApi(this._dio);

  factory HomeAssistantApi.fromSettings({
    required String url,
    required String token,
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) => HomeAssistantApi(
    mediaDio(
      url,
      headers: {'Authorization': 'Bearer $token'},
      trustSelfSigned: trustSelfSigned,
      adapter: adapter,
    ),
  );

  final Dio _dio;

  Future<Map<String, dynamic>> config() async =>
      (await _dio.get<Map<String, dynamic>>('/api/config')).data ?? {};

  Future<List<HaEntity>> states() async {
    final res = await _dio.get<List<dynamic>>('/api/states');
    return [
      for (final e in res.data ?? const [])
        HaEntity.fromJson((e as Map).cast<String, dynamic>()),
    ]..sort((a, b) => a.entityId.compareTo(b.entityId));
  }

  Future<List<HaService>> services() async {
    final res = await _dio.get<List<dynamic>>('/api/services');
    final out = <HaService>[];
    for (final d in res.data ?? const []) {
      final domain = (d as Map)['domain'] as String? ?? '';
      final services = (d['services'] as Map?) ?? const {};
      services.forEach((name, spec) {
        final s = (spec as Map?) ?? const {};
        final fields = <String, Map<String, dynamic>>{};
        ((s['fields'] as Map?) ?? const {}).forEach((k, v) {
          if (v is Map) fields['$k'] = v.cast<String, dynamic>();
        });
        out.add(
          HaService(
            domain: domain,
            service: '$name',
            name: s['name'] as String? ?? '$name',
            description: s['description'] as String? ?? '',
            fields: fields,
          ),
        );
      });
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return out;
  }

  /// Calls `domain.service` with [data] (`entity_id` and service fields).
  /// With [returnResponse], HA answers with the service's response data
  /// (`service_response`), which some services (to-do items, weather
  /// forecasts) require.
  Future<Map<String, dynamic>> callService(
    String domain,
    String service, {
    Map<String, dynamic> data = const {},
    bool returnResponse = false,
  }) async {
    final res = await _dio.post<dynamic>(
      '/api/services/$domain/$service${returnResponse ? '?return_response' : ''}',
      data: data,
    );
    final body = res.data;
    if (body is Map) return body.cast<String, dynamic>();
    return {'changed_states': body};
  }

  Future<List<HaHistoryPoint>> history(
    String entityId, {
    required DateTime since,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/history/period/${since.toUtc().toIso8601String()}',
      queryParameters: {
        'filter_entity_id': entityId,
        'minimal_response': '',
        'no_attributes': '',
      },
    );
    final series = res.data ?? const [];
    if (series.isEmpty) return const [];
    return [
      for (final p in series.first as List)
        HaHistoryPoint(
          DateTime.tryParse(
                ((p as Map)['last_changed'] ?? p['last_updated'] ?? '')
                    as String,
              ) ??
              DateTime(0),
          p['state']?.toString() ?? '',
        ),
    ];
  }

  Future<List<HaLogbookEntry>> logbook({
    required DateTime since,
    String? entityId,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/logbook/${since.toUtc().toIso8601String()}',
      queryParameters: {'entity': ?entityId},
    );
    return [
      for (final e in res.data ?? const [])
        HaLogbookEntry.fromJson((e as Map).cast<String, dynamic>()),
    ]..sort((a, b) => b.when.compareTo(a.when));
  }

  Future<String> errorLog() async =>
      (await _dio.get<String>(
        '/api/error_log',
        options: Options(responseType: ResponseType.plain),
      )).data ??
      '';

  /// Validates `configuration.yaml`: `{result: valid|invalid, errors}`.
  Future<Map<String, dynamic>> checkConfig() async =>
      (await _dio.post<Map<String, dynamic>>(
        '/api/config/core/check_config',
      )).data ??
      {};

  Future<String> renderTemplate(String template) async =>
      (await _dio.post<String>(
        '/api/template',
        data: {'template': template},
        options: Options(responseType: ResponseType.plain),
      )).data ??
      '';

  Future<List<HaTodoItem>> todoItems(String entityId) async {
    final res = await callService(
      'todo',
      'get_items',
      data: {'entity_id': entityId},
      returnResponse: true,
    );
    final lists = res['service_response'] as Map? ?? const {};
    final items = (lists[entityId] as Map?)?['items'] as List? ?? const [];
    return [
      for (final i in items)
        HaTodoItem.fromJson((i as Map).cast<String, dynamic>()),
    ];
  }

  /// A camera's current still (`/api/camera_proxy`), as image bytes.
  Future<List<int>> cameraImage(String entityId) async =>
      (await _dio.get<List<int>>(
        '/api/camera_proxy/$entityId',
        options: Options(responseType: ResponseType.bytes),
      )).data ??
      const [];
}
