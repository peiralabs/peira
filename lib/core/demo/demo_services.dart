import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/changedetection_api.dart';
import '../api/home_assistant_api.dart';
import '../api/immich_api.dart';
import '../api/karakeep_api.dart';
import '../api/open_webui_api.dart';
import '../api/paperless_api.dart';
import '../api/searxng_api.dart';
import '../api/seerr_api.dart';
import '../api/wikijs_api.dart';
import '../providers/changedetection_providers.dart';
import '../providers/home_assistant_providers.dart';
import '../providers/immich_providers.dart';
import '../providers/karakeep_providers.dart';
import '../providers/open_webui_providers.dart';
import '../providers/paperless_providers.dart';
import '../providers/searxng_providers.dart';
import '../providers/seerr_providers.dart';
import '../providers/wikijs_providers.dart';

/// Canned answers for the native service tabs in demo mode: every read
/// returns plausible fake data, every write answers OK and changes nothing,
/// and no request leaves the app.
class _Canned implements HttpClientAdapter {
  _Canned(this.answer);

  /// Returns the JSON-encodable body (or a String for text routes) for a
  /// request, or null for an empty `{}`.
  final Object? Function(String method, String path, Object? body) answer;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (requestStream != null) {
      final bytes = await requestStream.expand((c) => c).toList();
      try {
        body = jsonDecode(utf8.decode(bytes));
      } on Object {
        body = null;
      }
    }
    final r = answer(o.method, o.path, body);
    final text = r is String;
    return ResponseBody.fromString(
      text ? r : jsonEncode(r ?? (o.method == 'GET' ? const {} : 'OK')),
      200,
      headers: {
        Headers.contentTypeHeader: [
          text ? 'text/plain' : Headers.jsonContentType,
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String _ago(Duration d) =>
    DateTime.now().toUtc().subtract(d).toIso8601String();
int _epoch(Duration d) =>
    DateTime.now().subtract(d).millisecondsSinceEpoch ~/ 1000;

// ------------------------------------------------------------ Home Assistant

Map<String, dynamic> _ha(String id, String state, Map<String, dynamic> a) => {
  'entity_id': id,
  'state': state,
  'attributes': a,
  'last_changed': _ago(const Duration(minutes: 12)),
};

final _haStates = [
  _ha('light.kitchen', 'on', {
    'friendly_name': 'Kitchen',
    'brightness': 190,
    'supported_color_modes': ['brightness'],
  }),
  _ha('light.porch', 'off', {
    'friendly_name': 'Porch',
    'supported_color_modes': ['onoff'],
  }),
  _ha('light.office', 'on', {
    'friendly_name': 'Office desk',
    'brightness': 120,
    'supported_color_modes': ['color_temp'],
    'min_color_temp_kelvin': 2700,
    'max_color_temp_kelvin': 6500,
    'color_temp_kelvin': 4000,
  }),
  _ha('switch.rack_fan', 'on', {'friendly_name': 'Rack fan'}),
  _ha('switch.nas_power', 'on', {'friendly_name': 'NAS outlet'}),
  _ha('climate.hallway', 'heat', {
    'friendly_name': 'Hallway thermostat',
    'current_temperature': 68.5,
    'temperature': 70,
    'min_temp': 50,
    'max_temp': 85,
    'target_temp_step': 0.5,
    'hvac_modes': ['off', 'heat', 'cool', 'auto'],
  }),
  _ha('cover.garage_door', 'closed', {
    'friendly_name': 'Garage door',
    'supported_features': 11,
  }),
  _ha('lock.front_door', 'locked', {'friendly_name': 'Front door'}),
  _ha('media_player.living_room', 'playing', {
    'friendly_name': 'Living room',
    'supported_features': 152461,
    'volume_level': 0.32,
    'media_title': 'Weekend playlist',
  }),
  _ha('scene.movie_night', 'unknown', {'friendly_name': 'Movie night'}),
  _ha('script.backup_reminder', 'off', {'friendly_name': 'Backup reminder'}),
  _ha('automation.porch_at_sunset', 'on', {
    'friendly_name': 'Porch light at sunset',
  }),
  _ha('sensor.rack_temperature', '31.4', {
    'friendly_name': 'Rack temperature',
    'unit_of_measurement': '°C',
  }),
  _ha('sensor.ups_load', '18', {
    'friendly_name': 'UPS load',
    'unit_of_measurement': '%',
  }),
  _ha('binary_sensor.garage_motion', 'off', {'friendly_name': 'Garage motion'}),
  _ha('weather.home', 'sunny', {
    'friendly_name': 'Home',
    'temperature': 72,
    'temperature_unit': '°F',
  }),
  _ha('todo.shopping_list', '2', {'friendly_name': 'Shopping list'}),
];

Object? _homeAssistant(String m, String p, Object? body) => switch (p) {
  '/api/states' => _haStates,
  '/api/config' => {
    'version': '2026.8.1',
    'location_name': 'Home',
    'time_zone': 'America/Chicago',
    'unit_system': {'temperature': '°F'},
    'components': List.filled(48, 'x'),
    'state': 'RUNNING',
  },
  '/api/services' => [
    {
      'domain': 'light',
      'services': {
        'turn_on': {'name': 'Turn on', 'description': 'Turns on lights.'},
        'turn_off': {'name': 'Turn off', 'description': 'Turns off lights.'},
      },
    },
    {
      'domain': 'homeassistant',
      'services': {
        'restart': {'name': 'Restart', 'description': 'Restarts Home Assistant.'},
      },
    },
  ],
  '/api/services/todo/get_items?return_response' => {
    'service_response': {
      'todo.shopping_list': {
        'items': [
          {'uid': '1', 'summary': 'Spare SSD', 'status': 'needs_action'},
          {'uid': '2', 'summary': 'Cable ties', 'status': 'needs_action'},
          {'uid': '3', 'summary': 'UPS battery', 'status': 'completed'},
        ],
      },
    },
  },
  _ when p.startsWith('/api/logbook') => [
    {
      'name': 'Porch',
      'entity_id': 'light.porch',
      'state': 'off',
      'when': _ago(const Duration(minutes: 40)),
    },
    {
      'name': 'Garage door',
      'entity_id': 'cover.garage_door',
      'state': 'closed',
      'when': _ago(const Duration(hours: 2)),
    },
  ],
  _ when p.startsWith('/api/history') => [
    [
      for (var i = 0; i < 24; i++)
        {
          'state': '${30 + (i % 6) * 0.4}',
          'last_changed': _ago(Duration(hours: 24 - i)),
        },
    ],
  ],
  '/api/error_log' => '',
  '/api/template' => 'demo',
  _ => m == 'POST' ? const [] : null,
};

// ------------------------------------------------------------------ Wiki.js

final _wikiPages = [
  for (final (i, path, title, tags) in [
    (1, 'home', 'Home lab handbook', ['home']),
    (2, 'runbooks/backups', 'Backups and restores', ['backups', 'pbs']),
    (3, 'runbooks/proxmox-upgrade', 'Upgrading Proxmox VE', ['proxmox']),
    (4, 'services/media', 'Media stack', ['media']),
    (5, 'network/tailscale', 'Remote access with Tailscale', ['network']),
    (6, 'hardware/nodes', 'Nodes and hardware', ['hardware']),
  ])
    {
      'id': i,
      'path': path,
      'locale': 'en',
      'title': title,
      'description': '',
      'updatedAt': _ago(Duration(days: i * 3)),
      'tags': tags,
    },
];

Object? _wiki(String m, String p, Object? body) {
  final q = '${(body as Map?)?['query'] ?? ''}';
  if (q.contains('list(')) return {'data': {'pages': {'list': _wikiPages}}};
  if (q.contains('single(') || q.contains('singleByPath(')) {
    return {
      'data': {
        'pages': {
          (q.contains('single(') ? 'single' : 'singleByPath'): {
            ..._wikiPages.first,
            'editor': 'markdown',
            'contentType': 'markdown',
            'isPublished': true,
            'isPrivate': false,
            'tags': [
              {'tag': 'home'},
            ],
            'content':
                '# Home lab handbook\n\nEverything about this lab, in one '
                'place.\n\n- [Backups and restores](runbooks/backups)\n- '
                '[Upgrading Proxmox VE](runbooks/proxmox-upgrade)\n- '
                '[Media stack](services/media)\n',
          },
        },
      },
    };
  }
  if (q.contains('tags {')) {
    return {
      'data': {
        'pages': {
          'tags': [
            for (final (i, t) in [
              'backups',
              'hardware',
              'home',
              'media',
              'network',
              'pbs',
              'proxmox',
            ].indexed)
              {'id': i, 'tag': t, 'title': t},
          ],
        },
      },
    };
  }
  if (q.contains('system {')) {
    return {
      'data': {
        'system': {
          'info': {
            'currentVersion': '2.5.317',
            'latestVersion': '2.5.317',
            'pagesTotal': 42,
            'tagsTotal': 7,
            'usersTotal': 2,
            'groupsTotal': 2,
            'dbType': 'SQLite',
            'nodeVersion': '20',
            'hostname': 'wiki',
          },
        },
      },
    };
  }
  return {'data': {}};
}

// --------------------------------------------------------- changedetection

Object? _changedetection(String m, String p, Object? body) => switch (p) {
  '/watch' when m == 'GET' => {
    for (final (i, title, url, unseen) in [
      ('a', 'Proxmox VE releases', 'https://www.proxmox.com/en/news', true),
      ('b', 'Jellyfin releases', 'https://github.com/jellyfin/jellyfin/releases', false),
      ('c', 'Home Assistant blog', 'https://www.home-assistant.io/blog/', true),
      ('d', 'Tailscale changelog', 'https://tailscale.com/changelog', false),
    ])
      i: {
        'title': title,
        'url': url,
        'last_checked': _epoch(const Duration(minutes: 9)),
        'last_changed': _epoch(Duration(hours: unseen ? 3 : 50)),
        'last_error': false,
        'viewed': !unseen,
        'tags': ['t1'],
      },
  },
  '/tags' => {
    't1': {'title': 'releases', 'notification_muted': false},
  },
  '/systeminfo' => {
    'version': '0.60.9',
    'watch_count': 4,
    'queue_size': 0,
    'overdue_watches': [],
    'uptime': 864000,
  },
  _ => null,
};

// ---------------------------------------------------------------- Paperless

Object? _paperless(String m, String p, Object? body) => switch (p) {
  '/api/documents/' => {
    'count': 4,
    'next': null,
    'results': [
      for (final (i, title, tag, corr) in [
        (1, 'UPS warranty', 1, 1),
        (2, 'Electricity bill — September', 2, 2),
        (3, 'NAS invoice', 1, 1),
        (4, 'Internet contract', 2, 3),
      ])
        {
          'id': i,
          'title': title,
          'tags': [tag],
          'correspondent': corr,
          'document_type': null,
          'created_date': '2026-0${i + 4}-1$i',
          'page_count': i,
        },
    ],
  },
  '/api/tags/' => {
    'next': null,
    'results': [
      {'id': 1, 'name': 'hardware', 'document_count': 2},
      {'id': 2, 'name': 'bills', 'document_count': 2},
    ],
  },
  '/api/correspondents/' => {
    'next': null,
    'results': [
      {'id': 1, 'name': 'Hardware shop', 'document_count': 2},
      {'id': 2, 'name': 'Power company', 'document_count': 1},
      {'id': 3, 'name': 'ISP', 'document_count': 1},
    ],
  },
  '/api/statistics/' => {
    'documents_total': 4,
    'documents_inbox': 1,
    'tag_count': 2,
    'correspondent_count': 3,
    'document_type_count': 0,
    'character_count': 18400,
  },
  _ when p.endsWith('/') && p.startsWith('/api/') =>
    {'count': 0, 'next': null, 'results': []},
  _ => null,
};

// ---------------------------------------------------------------- Karakeep

Object? _karakeep(String m, String p, Object? body) => switch (p) {
  '/bookmarks' => {
    'nextCursor': null,
    'bookmarks': [
      for (final (i, title, url, tags) in [
        ('k1', 'ZFS on Proxmox: a practical guide', 'https://example.org/zfs', ['storage']),
        ('k2', 'Tailscale subnet routers explained', 'https://example.org/tailscale', ['network']),
        ('k3', 'Restic vs Borg for homelab backups', 'https://example.org/backups', ['backups']),
      ])
        {
          'id': i,
          'createdAt': _ago(const Duration(days: 2)),
          'title': title,
          'archived': false,
          'favourited': i == 'k1',
          'taggingStatus': 'success',
          'tags': [
            for (final t in tags) {'id': t, 'name': t, 'attachedBy': 'ai'},
          ],
          'content': {'type': 'link', 'url': url},
        },
    ],
  },
  _ => null,
};

// ------------------------------------------------------------------- Seerr

Object? _seerr(String m, String p, Object? body) => switch (p) {
  '/request' => {
    'pageInfo': {'results': 3},
    'results': [
      for (final (i, st, type) in [(1, 1, 'movie'), (2, 2, 'tv'), (3, 5, 'movie')])
        {
          'id': i,
          'status': st,
          'type': type,
          'media': {'tmdbId': 100 + i, 'status': st == 5 ? 5 : 3},
          'requestedBy': {'displayName': 'demo'},
          'createdAt': _ago(Duration(days: i)),
        },
    ],
  },
  '/request/count' => {'total': 3, 'pending': 1, 'processing': 1, 'completed': 1},
  '/movie/101' => {'id': 101, 'title': 'The Long Weekend', 'releaseDate': '2025-06-01'},
  '/tv/102' => {'id': 102, 'name': 'Server Room', 'firstAirDate': '2024-01-10'},
  '/movie/103' => {'id': 103, 'title': 'Cold Storage', 'releaseDate': '2023-11-20'},
  _ when p.startsWith('/discover') || p == '/search' => {
    'totalPages': 1,
    'results': [
      for (final (i, t) in ['The Long Weekend', 'Cold Storage', 'Uptime'].indexed)
        {
          'id': 101 + i,
          'mediaType': 'movie',
          'title': t,
          'releaseDate': '2025-0${i + 1}-01',
          'overview': 'A demo title.',
        },
    ],
  },
  '/status' => {'version': '3.5.1', 'updateAvailable': false},
  '/settings/jobs' => const [],
  _ => null,
};

// -------------------------------------------------------------- Open WebUI

Object? _openWebUi(String m, String p, Object? body) => switch (p) {
  '/api/models' => {
    'data': [
      for (final (id, size) in [('qwen2.5:14b', '14.8B'), ('llama3.2:3b', '3.2B')])
        {
          'id': id,
          'name': id,
          'owned_by': 'ollama',
          'ollama': {
            'details': {'family': id.split(':').first, 'parameter_size': size},
          },
        },
    ],
  },
  '/api/v1/knowledge/' => {'items': [], 'total': 0},
  '/api/v1/chats/' || '/api/v1/chats/pinned' || '/api/v1/chats/search' =>
    const [],
  '/api/v1/prompts/' || '/api/v1/tools/' || '/api/v1/functions/' => const [],
  '/api/v1/users/' => {'total': 1, 'users': []},
  '/api/version' => {'version': '0.12.4'},
  '/api/chat/completions' => {
    'choices': [
      {
        'message': {
          'content':
              'This is demo mode, so no model ran. Connected to a real Open '
              'WebUI, the answer from the model you picked appears here.',
        },
      },
    ],
  },
  _ => null,
};

// ------------------------------------------------------------------ SearXNG

Object? _searxng(String m, String p, Object? body) => switch (p) {
  '/config' => {
    'version': '2026.8.17',
    'autocomplete': '',
    'categories': ['general', 'images', 'news', 'it'],
    'engines': [
      {'name': 'demo', 'categories': ['general'], 'enabled': true},
    ],
    'locales': {'en': 'English'},
    'safe_search': 0,
  },
  '/search' => {
    'results': [
      {
        'title': 'Proxmox VE documentation',
        'url': 'https://pve.proxmox.com/pve-docs/',
        'content': 'Demo result.',
        'engines': ['demo'],
      },
    ],
  },
  _ => null,
};

Object? _immich(String m, String p, Object? body) => switch (p) {
  '/api/queues' || '/api/albums' || '/api/memories' || '/api/duplicates' =>
    const [],
  '/api/people' => {'people': [], 'total': 0},
  '/api/server/about' => {'version': 'v3.3.5'},
  '/api/server/statistics' => {'photos': 2400, 'videos': 180, 'usage': 0},
  '/api/server/storage' => {
    'diskSize': '1.8 TiB',
    'diskUse': '690 GiB',
    'diskUsagePercentage': 37.4,
  },
  _ => null,
};

/// The demo settings' service URLs (documentation address space).
const demoServiceUrls = (
  homeAssistant: 'http://10.0.0.20:8123',
  wiki: 'http://10.0.0.21:3000',
  changedetection: 'http://10.0.0.22:5000',
  paperless: 'http://10.0.0.23:8000',
  karakeep: 'http://10.0.0.24:3000',
  seerr: 'http://10.0.0.25:5055',
  searxng: 'http://10.0.0.26:8888',
  immich: 'http://10.0.0.27:2283',
);

Dio _dio(String base, Object? Function(String, String, Object?) answer) =>
    Dio(BaseOptions(baseUrl: base))..httpClientAdapter = _Canned(answer);

/// Provider overrides that put every native service tab on canned data.
final demoServiceOverrides = [
  homeAssistantApiProvider.overrideWith(
    (ref) async => HomeAssistantApi(
      _dio(demoServiceUrls.homeAssistant, _homeAssistant),
    ),
  ),
  wikiJsApiProvider.overrideWith(
    (ref) async =>
        WikiJsApi(_dio(demoServiceUrls.wiki, _wiki), demoServiceUrls.wiki),
  ),
  changedetectionApiProvider.overrideWith(
    (ref) async => ChangedetectionApi(
      _dio('${demoServiceUrls.changedetection}/api/v1', _changedetection),
    ),
  ),
  paperlessApiProvider.overrideWith(
    (ref) async => PaperlessApi(
      _dio(demoServiceUrls.paperless, _paperless),
      demoServiceUrls.paperless,
      'demo',
    ),
  ),
  karakeepApiProvider.overrideWith(
    (ref) async => KarakeepApi(
      _dio('${demoServiceUrls.karakeep}/api/v1', _karakeep),
      demoServiceUrls.karakeep,
    ),
  ),
  seerrApiProvider.overrideWith(
    (ref) async => SeerrApi(
      _dio('${demoServiceUrls.seerr}/api/v1', _seerr),
      demoServiceUrls.seerr,
    ),
  ),
  openWebUiApiProvider.overrideWith(
    (ref) async =>
        OpenWebUiApi(_dio('http://10.0.0.7:8080', _openWebUi), 'http://10.0.0.7:8080'),
  ),
  searxngApiProvider.overrideWith(
    (ref) async => SearxngApi(_dio(demoServiceUrls.searxng, _searxng)),
  ),
  immichApiProvider.overrideWith(
    (ref) async => ImmichApi(
      _dio(demoServiceUrls.immich, _immich),
      demoServiceUrls.immich,
      'demo',
    ),
  ),
];
