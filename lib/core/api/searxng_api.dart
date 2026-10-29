import 'dart:convert';

import 'package:dio/dio.dart';

import 'media_dio.dart';

/// One search hit from SearXNG's JSON output.
class SearxResult {
  const SearxResult({
    required this.title,
    required this.url,
    required this.content,
    required this.engines,
    this.category,
    this.imgSrc,
    this.thumbnail,
    this.published,
  });

  factory SearxResult.fromJson(Map<String, dynamic> json) {
    final engines = (json['engines'] as List?)?.whereType<String>().toList();
    String? str(String k) {
      final v = json[k];
      return v is String && v.isNotEmpty ? v : null;
    }

    return SearxResult(
      title: str('title') ?? str('url') ?? '',
      url: str('url') ?? '',
      content: str('content') ?? '',
      engines: engines ?? [if (str('engine') != null) str('engine')!],
      category: str('category'),
      imgSrc: str('img_src'),
      thumbnail: str('thumbnail_src') ?? str('thumbnail'),
      published: DateTime.tryParse(str('publishedDate') ?? ''),
    );
  }

  final String title;
  final String url;
  final String content;
  final List<String> engines;
  final String? category;
  final String? imgSrc;
  final String? thumbnail;
  final DateTime? published;
}

class SearxInfobox {
  const SearxInfobox({
    required this.title,
    required this.content,
    required this.links,
    required this.attributes,
    this.image,
  });
  final String title;
  final String content;
  final List<({String title, String url})> links;
  final List<({String label, String value})> attributes;
  final String? image;
}

class SearxPage {
  const SearxPage({
    required this.results,
    required this.answers,
    required this.suggestions,
    required this.corrections,
    required this.infoboxes,
    required this.unresponsive,
  });
  final List<SearxResult> results;
  final List<String> answers;
  final List<String> suggestions;
  final List<String> corrections;
  final List<SearxInfobox> infoboxes;

  /// Engine name → why it did not answer (rate limit, CAPTCHA, timeout).
  final List<(String, String)> unresponsive;
}

/// An engine from `/config`, for the engine picker.
class SearxEngine {
  const SearxEngine(this.name, this.categories, this.enabled);
  final String name;
  final List<String> categories;
  final bool enabled;
}

class SearxConfig {
  const SearxConfig({
    required this.version,
    required this.categories,
    required this.engines,
    required this.locales,
    required this.safeSearch,
    required this.autocomplete,
  });
  final String version;
  final List<String> categories;
  final List<SearxEngine> engines;

  /// Locale code → display name.
  final Map<String, String> locales;
  final int safeSearch;

  /// The configured autocomplete backend, empty when off.
  final String autocomplete;
}

/// SearXNG's search API (`/search?format=json`). No credential: the
/// instance must list `json` in `search.formats`.
class SearxngApi {
  SearxngApi(this._dio);

  factory SearxngApi.fromSettings({
    required String url,
    bool trustSelfSigned = false,
    HttpClientAdapter? adapter,
  }) => SearxngApi(
    mediaDio(
      url,
      headers: const {'Accept': 'application/json'},
      trustSelfSigned: trustSelfSigned,
      adapter: adapter,
    ),
  );

  final Dio _dio;

  Future<SearxConfig> config() async {
    final d =
        (await _dio.get<Map<String, dynamic>>('/config')).data ??
        const <String, dynamic>{};
    final locales = <String, String>{};
    ((d['locales'] as Map?) ?? const {}).forEach((k, v) {
      locales['$k'] = '$v';
    });
    return SearxConfig(
      version: '${d['version'] ?? ''}',
      categories: ((d['categories'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      engines: [
        for (final e in (d['engines'] as List?) ?? const [])
          if (e is Map)
            SearxEngine(
              '${e['name']}',
              ((e['categories'] as List?) ?? const [])
                  .whereType<String>()
                  .toList(),
              e['enabled'] == true,
            ),
      ]..sort((a, b) => a.name.compareTo(b.name)),
      locales: locales,
      safeSearch: (d['safe_search'] as num?)?.toInt() ?? 0,
      autocomplete: '${d['autocomplete'] ?? ''}',
    );
  }

  /// [timeRange] is `day`, `week`, `month` or `year`; [safeSearch] 0–2;
  /// [engines] restricts the search to those engine names.
  Future<SearxPage> search(
    String query, {
    String category = 'general',
    int page = 1,
    String? timeRange,
    int? safeSearch,
    String? language,
    List<String> engines = const [],
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {
        'q': query,
        'format': 'json',
        // SearXNG lets `categories` override an explicit engine list
        // (checked against 2026.8.17), so send one or the other.
        if (engines.isEmpty) 'categories': category,
        'pageno': page,
        'time_range': ?timeRange,
        'safesearch': ?safeSearch,
        'language': ?language,
        if (engines.isNotEmpty) 'engines': engines.join(','),
      },
    );
    final d = res.data ?? const <String, dynamic>{};
    List<String> strings(String k) => [
      for (final v in (d[k] as List?) ?? const [])
        if (v is String)
          v
        else if (v is Map && v['answer'] is String)
          v['answer'] as String,
    ];
    return SearxPage(
      results: [
        for (final r in (d['results'] as List?) ?? const [])
          if (r is Map) SearxResult.fromJson(r.cast<String, dynamic>()),
      ],
      answers: strings('answers'),
      suggestions: strings('suggestions'),
      corrections: strings('corrections'),
      infoboxes: [
        for (final b in (d['infoboxes'] as List?) ?? const [])
          if (b is Map)
            SearxInfobox(
              title: '${b['infobox'] ?? ''}',
              content: '${b['content'] ?? ''}',
              image: b['img_src'] as String?,
              attributes: [
                for (final a in (b['attributes'] as List?) ?? const [])
                  if (a is Map && a['label'] != null && a['value'] != null)
                    (label: '${a['label']}', value: '${a['value']}'),
              ],
              links: [
                for (final u in (b['urls'] as List?) ?? const [])
                  if (u is Map && u['url'] is String)
                    (
                      title: '${u['title'] ?? u['url']}',
                      url: u['url'] as String,
                    ),
              ],
            ),
      ],
      unresponsive: [
        for (final u in (d['unresponsive_engines'] as List?) ?? const [])
          if (u is List && u.length >= 2) ('${u[0]}', '${u[1]}'),
      ],
    );
  }

  /// Query completions from the instance's autocomplete backend
  /// (`/autocompleter`, OpenSearch suggestions: `[query, [completions]]`).
  Future<List<String>> autocomplete(String query) async {
    final res = await _dio.get<dynamic>(
      '/autocompleter',
      queryParameters: {'q': query},
    );
    // Served as application/x-suggestions+json, which Dio leaves as text.
    final raw = res.data;
    final d = raw is String ? jsonDecode(raw) : raw;
    if (d is List && d.length >= 2 && d[1] is List) {
      return (d[1] as List).whereType<String>().toList();
    }
    if (d is List) return d.whereType<String>().toList();
    return const [];
  }
}
