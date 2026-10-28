import 'package:dio/dio.dart';

import 'media_dio.dart';

/// One watched page from `/watch`.
class CdWatch {
  const CdWatch({
    required this.uuid,
    required this.url,
    required this.title,
    required this.tags,
    required this.viewed,
    this.lastChecked,
    this.lastChanged,
    this.lastError,
    this.paused = false,
    this.muted = false,
  });

  factory CdWatch.fromJson(String uuid, Map<String, dynamic> j) {
    DateTime? ts(Object? v) => v is num && v > 0
        ? DateTime.fromMillisecondsSinceEpoch((v * 1000).toInt())
        : null;
    final err = j['last_error'];
    return CdWatch(
      uuid: uuid,
      url: j['url'] as String? ?? '',
      title: (j['title'] as String?)?.isNotEmpty == true
          ? j['title'] as String
          : (j['page_title'] as String?) ?? (j['url'] as String? ?? ''),
      tags: [
        for (final t in (j['tags'] as List?) ?? const [])
          if (t is String) t,
      ],
      viewed: j['viewed'] != false,
      lastChecked: ts(j['last_checked']),
      lastChanged: ts(j['last_changed']),
      lastError: err is String && err.isNotEmpty ? err : null,
      paused: j['paused'] == true,
      muted: j['notification_muted'] == true,
    );
  }

  final String uuid;
  final String url;
  final String title;

  /// Tag uuids.
  final List<String> tags;

  /// False when there is a change the operator has not looked at.
  final bool viewed;
  final DateTime? lastChecked;
  final DateTime? lastChanged;
  final String? lastError;

  /// Only the detail call reports these two.
  final bool paused;
  final bool muted;
}

/// Editable settings of one watch (`GET /watch/{uuid}`).
class CdWatchDetail {
  const CdWatchDetail(this.watch, this.raw);
  final CdWatch watch;
  final Map<String, dynamic> raw;

  List<String> list(String key) => [
    for (final v in (raw[key] as List?) ?? const [])
      if (v is String) v,
  ];

  /// Minutes between checks, or null when the global default applies.
  int? get intervalMinutes {
    if (raw['time_between_check_use_default'] != false) return null;
    final t = (raw['time_between_check'] as Map?) ?? const {};
    int n(String k) => (t[k] as num?)?.toInt() ?? 0;
    final m =
        n('weeks') * 10080 +
        n('days') * 1440 +
        n('hours') * 60 +
        n('minutes') +
        n('seconds') ~/ 60;
    return m == 0 ? null : m;
  }
}

class CdTag {
  const CdTag(this.uuid, this.title, this.muted);
  final String uuid;
  final String title;
  final bool muted;
}

/// changedetection.io REST API (`/api/v1`, docs/api-spec.yaml at 0.60.9)
/// with an `x-api-key`.
class ChangedetectionApi {
  ChangedetectionApi(this._dio);

  factory ChangedetectionApi.fromSettings({
    required String url,
    required String apiKey,
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) => ChangedetectionApi(
    mediaDio(
      '$url/api/v1',
      headers: {'x-api-key': apiKey},
      trustSelfSigned: trustSelfSigned,
      adapter: adapter,
    ),
  );

  final Dio _dio;

  Future<Map<String, dynamic>> _map(String p, [Map<String, dynamic>? q]) async {
    final d = (await _dio.get<dynamic>(p, queryParameters: q)).data;
    return d is Map ? d.cast<String, dynamic>() : const {};
  }

  /// Action calls (recheck, pause, mute) answer plain "OK".
  Future<void> _action(String p, Map<String, dynamic> q) => _dio.get<dynamic>(
    p,
    queryParameters: q,
    options: Options(responseType: ResponseType.plain),
  );

  Future<List<CdWatch>> watches({String? tag}) async {
    final d = await _map('/watch', {'tag': ?tag});
    return [
      for (final e in d.entries)
        if (e.value is Map)
          CdWatch.fromJson(e.key, (e.value as Map).cast<String, dynamic>()),
    ]..sort((a, b) {
      final x = b.lastChanged ?? DateTime(0);
      final y = a.lastChanged ?? DateTime(0);
      return x.compareTo(y);
    });
  }

  Future<CdWatchDetail> watch(String uuid) async {
    final d = await _map('/watch/$uuid');
    return CdWatchDetail(CdWatch.fromJson(uuid, d), d);
  }

  Future<void> recheck(String uuid) =>
      _action('/watch/$uuid', {'recheck': '1'});
  Future<void> recheckAll() => _action('/watch', {'recheck_all': '1'});
  Future<void> setPaused(String uuid, bool paused) =>
      _action('/watch/$uuid', {'paused': paused ? 'paused' : 'unpaused'});
  Future<void> setMuted(String uuid, bool muted) =>
      _action('/watch/$uuid', {'muted': muted ? 'muted' : 'unmuted'});

  /// [tag] is a tag name (created if new).
  Future<void> addWatch(String url, {String? title, String? tag}) =>
      _dio.post<dynamic>(
        '/watch',
        data: {'url': url, 'title': ?title, 'tag': ?tag},
        options: Options(responseType: ResponseType.plain),
      );

  /// Changes only the fields given. [intervalMinutes] null keeps the
  /// schedule; 0 returns the watch to the global default.
  Future<void> updateWatch(
    String uuid, {
    String? url,
    String? title,
    int? intervalMinutes,
    List<String>? includeFilters,
    List<String>? ignoreText,
    List<String>? triggerText,
  }) => _dio.put<dynamic>(
    '/watch/$uuid',
    data: {
      'url': ?url,
      'title': ?title,
      if (intervalMinutes != null) ...{
        'time_between_check_use_default': intervalMinutes == 0,
        if (intervalMinutes > 0)
          'time_between_check': {
            'weeks': 0,
            'days': intervalMinutes ~/ 1440,
            'hours': intervalMinutes % 1440 ~/ 60,
            'minutes': intervalMinutes % 60,
            'seconds': 0,
          },
      },
      'include_filters': ?includeFilters,
      'ignore_text': ?ignoreText,
      'trigger_text': ?triggerText,
    },
    options: Options(responseType: ResponseType.plain),
  );

  Future<void> deleteWatch(String uuid) => _dio.delete<dynamic>(
    '/watch/$uuid',
    options: Options(responseType: ResponseType.plain),
  );

  /// Snapshot timestamps (seconds), oldest first.
  Future<List<int>> history(String uuid) async => [
    for (final k in (await _map('/watch/$uuid/history')).keys) ?int.tryParse(k),
  ]..sort();

  Future<String> snapshot(String uuid, int ts) async =>
      '${(await _dio.get<dynamic>('/watch/$uuid/history/$ts', options: Options(responseType: ResponseType.plain))).data ?? ''}';

  /// A text diff; lines start with `(added)`, `(removed)`, `(changed)` or
  /// `(into)` when [changesOnly].
  Future<String> difference(
    String uuid,
    int from,
    int to, {
    bool changesOnly = true,
  }) async =>
      '${(await _dio.get<dynamic>(
            '/watch/$uuid/difference/$from/$to',
            queryParameters: {'format': 'text', 'changesOnly': changesOnly ? 'true' : 'false'},
            options: Options(responseType: ResponseType.plain),
          )).data ?? ''}';

  Future<List<CdTag>> tags() async => [
    for (final e in (await _map('/tags')).entries)
      if (e.value is Map)
        CdTag(
          e.key,
          '${(e.value as Map)['title'] ?? ''}',
          (e.value as Map)['notification_muted'] == true,
        ),
  ]..sort((a, b) => a.title.compareTo(b.title));

  Future<void> addTag(String title) => _dio.post<dynamic>(
    '/tag',
    data: {'title': title},
    options: Options(responseType: ResponseType.plain),
  );

  Future<void> renameTag(String uuid, String title) => _dio.put<dynamic>(
    '/tag/$uuid',
    data: {'title': title},
    options: Options(responseType: ResponseType.plain),
  );

  Future<void> deleteTag(String uuid) => _dio.delete<dynamic>(
    '/tag/$uuid',
    options: Options(responseType: ResponseType.plain),
  );

  Future<void> recheckTag(String uuid) =>
      _action('/tag/$uuid', {'recheck': 'true'});
  Future<void> setTagMuted(String uuid, bool muted) =>
      _action('/tag/$uuid', {'muted': muted ? 'muted' : 'unmuted'});

  Future<Map<String, dynamic>> systemInfo() => _map('/systeminfo');
}
