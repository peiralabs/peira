import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../models/app_settings.dart';

class PbsServerConfig {
  const PbsServerConfig({
    required this.name,
    required this.url,
    required this.tokenId,
    required this.tokenSecret,
    required this.fingerprint,
    required this.user,
    required this.pveStorage,
  });

  final String name;
  final String url;
  final String tokenId;
  final String tokenSecret;
  final String fingerprint;
  final String user;
  final String pveStorage;

  static PbsServerConfig slot1(AppSettings s) => PbsServerConfig(
    name: s.pbs1Name,
    url: s.pbs1Url,
    tokenId: s.pbs1TokenId,
    tokenSecret: s.pbs1TokenSecret,
    fingerprint: s.pbs1Fingerprint,
    user: s.pbs1User,
    pveStorage: s.pbs1PveStorage,
  );

  static PbsServerConfig slot2(AppSettings s) => PbsServerConfig(
    name: s.pbs2Name,
    url: s.pbs2Url,
    tokenId: s.pbs2TokenId,
    tokenSecret: s.pbs2TokenSecret,
    fingerprint: s.pbs2Fingerprint,
    user: s.pbs2User,
    pveStorage: s.pbs2PveStorage,
  );
}

class PbsTicket {
  const PbsTicket({
    required this.ticket,
    required this.csrf,
    required this.username,
    required this.issued,
  });

  final String ticket;
  final String csrf;
  final String username;
  final DateTime issued;

  bool get expired =>
      DateTime.now().difference(issued) >= const Duration(minutes: 30);
}

class PbsTfaRequired implements Exception {
  const PbsTfaRequired();

  @override
  String toString() => 'TFA accounts are not supported yet';
}

class PbsApiException implements Exception {
  const PbsApiException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  @override
  String toString() => 'PbsApiException($statusCode): $message';
}

class PbsDatastoreUsage {
  const PbsDatastoreUsage({
    required this.store,
    required this.total,
    required this.used,
    required this.avail,
    required this.history,
    required this.gcStatus,
    required this.estimatedFullDate,
  });

  final String store;
  final int total;
  final int used;
  final int avail;
  final List<Map<String, dynamic>> history;
  final Map<String, dynamic>? gcStatus;
  final int? estimatedFullDate;
}

class PbsGroup {
  const PbsGroup({
    required this.type,
    required this.id,
    required this.lastBackup,
    required this.backupCount,
    required this.owner,
    required this.comment,
    required this.files,
    this.namespace,
  });

  final String type;
  final String id;
  final int lastBackup;
  final int backupCount;
  final String owner;
  final String comment;
  final int files;
  final String? namespace;
}

class PbsSnapshotFile {
  const PbsSnapshotFile({
    required this.filename,
    required this.size,
    required this.cryptMode,
  });

  final String filename;
  final int size;
  final String cryptMode;
}

class PbsVerification {
  const PbsVerification({required this.state, required this.upid});

  final String state;
  final String? upid;
}

class PbsSnapshot {
  const PbsSnapshot({
    required this.type,
    required this.id,
    required this.time,
    required this.size,
    required this.protected,
    required this.comment,
    required this.owner,
    required this.verification,
    required this.files,
    required this.fingerprint,
    required this.namespace,
  });

  final String type;
  final String id;
  final int time;
  final int size;
  final bool protected;
  final String comment;
  final String owner;
  final PbsVerification? verification;
  final List<PbsSnapshotFile> files;
  final String fingerprint;
  final String? namespace;

  bool get encrypted => files.any((file) => file.cryptMode == 'encrypt');
}

class PbsKeep {
  const PbsKeep({
    this.last,
    this.hourly,
    this.daily,
    this.weekly,
    this.monthly,
    this.yearly,
  });

  final int? last;
  final int? hourly;
  final int? daily;
  final int? weekly;
  final int? monthly;
  final int? yearly;

  Map<String, dynamic> toMap() => {
    'keep-last': ?last,
    'keep-hourly': ?hourly,
    'keep-daily': ?daily,
    'keep-weekly': ?weekly,
    'keep-monthly': ?monthly,
    'keep-yearly': ?yearly,
  };
}

class PbsPruneEntry {
  const PbsPruneEntry({
    required this.time,
    required this.keep,
    required this.protected,
  });

  final int time;
  final bool keep;
  final bool protected;
}

class PbsJob {
  const PbsJob({
    required this.kind,
    required this.id,
    required this.store,
    required this.schedule,
    required this.raw,
  });

  final String kind;
  final String id;
  final String store;
  final String schedule;
  final Map<String, dynamic> raw;
}

class PbsJobStatus {
  const PbsJobStatus({
    required this.lastRunState,
    required this.nextRun,
    required this.lastRunUpid,
  });

  final String? lastRunState;
  final int? nextRun;
  final String? lastRunUpid;
}

class PbsTask {
  const PbsTask({required this.raw});

  final Map<String, dynamic> raw;
  String get upid => '${raw['upid'] ?? ''}';
}

class PbsTaskStatus {
  const PbsTaskStatus({required this.raw});

  final Map<String, dynamic> raw;
  bool get running => raw['status'] == 'running';
  String? get exitStatus => raw['exitstatus'] as String?;
}

class PbsCatalogEntry {
  const PbsCatalogEntry({
    required this.filename,
    required this.text,
    required this.type,
    required this.leaf,
    required this.size,
    required this.mtime,
    required this.filepath,
  });

  final String? filename;
  final String text;
  final String type;
  final bool leaf;
  final int size;
  final int mtime;
  final String filepath;
}

/// Client for the Proxmox Backup Server JSON API.
class PbsApi {
  PbsApi(this._dio, [this._user = '']);

  factory PbsApi.fromSlot(PbsServerConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: '${config.url}/api2/json',
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 12),
        headers: {
          if (config.tokenId.isNotEmpty)
            'Authorization':
                'PBSAPIToken=${config.tokenId}:${config.tokenSecret}',
        },
      ),
    );
    final pin = _normalizeFingerprint(config.fingerprint);
    final host = Uri.tryParse(config.url)?.host;
    if (pin.isNotEmpty && host != null && host.isNotEmpty) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => HttpClient()
          ..badCertificateCallback = (cert, h, port) =>
              h == host &&
              _normalizeFingerprint(sha256.convert(cert.der).toString()) == pin,
      );
    }
    return PbsApi(dio, config.user);
  }

  final Dio _dio;
  final String _user;

  static String _normalizeFingerprint(String s) =>
      s.replaceAll(':', '').replaceAll(' ', '').toLowerCase();

  Future<bool> ping() async {
    try {
      await _dio.get<void>(
        '/version',
        options: Options(validateStatus: (_) => true),
      );
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>> version() async =>
      _map(await _getData('/version'));

  Future<PbsTicket> login(String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/access/ticket',
        data: {'username': _user, 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': null},
        ),
      );
      final data = _map(response.data?['data']);
      final ticket = '${data['ticket'] ?? ''}';
      if (ticket.startsWith('PBS:!tfa!')) throw const PbsTfaRequired();
      return PbsTicket(
        ticket: ticket,
        csrf: '${data['CSRFPreventionToken'] ?? ''}',
        username: '${data['username'] ?? _user}',
        issued: DateTime.now(),
      );
    } on PbsTfaRequired {
      rethrow;
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  PbsApi withTicket(PbsTicket ticket) {
    final options = _dio.options.copyWith(
      headers: {
        ..._dio.options.headers,
        'Authorization': null,
        'Cookie': 'PBSAuthCookie=${Uri.encodeComponent(ticket.ticket)}',
        'CSRFPreventionToken': ticket.csrf,
      },
    );
    final dio = Dio(options)..httpClientAdapter = _dio.httpClientAdapter;
    return PbsApi(dio, ticket.username);
  }

  Future<List<String>> datastores() async => [
    for (final row in _list(await _getData('/admin/datastore')))
      '${row['store'] ?? ''}',
  ];

  Future<PbsDatastoreUsage> datastoreStatus(String store) async {
    // The endpoint takes no `store` filter (PBS 400s on unknown params);
    // it lists every datastore the token can audit.
    final rows = _list(await _getData('/status/datastore-usage'));
    final row = rows.firstWhere(
      (row) => row['store'] == store,
      orElse: () => <String, dynamic>{},
    );
    return PbsDatastoreUsage(
      store: '${row['store'] ?? store}',
      total: _int(row['total']),
      used: _int(row['used']),
      avail: _int(row['avail']),
      history: _mapList(row['history']),
      gcStatus: row['gc-status'] is Map ? _map(row['gc-status']) : null,
      estimatedFullDate: row['estimated-full-date'] == null
          ? null
          : _int(row['estimated-full-date']),
    );
  }

  Future<Map<String, dynamic>> gcStatus(String store) async =>
      _map(await _getData('/admin/datastore/$store/gc'));

  Future<List<String>> namespaces(String store) async => [
    for (final row in _list(
      await _getData('/admin/datastore/$store/namespace'),
    ))
      '${row['ns'] ?? ''}',
  ];

  Future<List<PbsGroup>> groups(String store, {String? ns}) async => [
    for (final row in _list(
      await _getData(
        '/admin/datastore/$store/groups',
        queryParameters: {'ns': ?ns},
      ),
    ))
      PbsGroup(
        type: '${row['backup-type'] ?? ''}',
        id: '${row['backup-id'] ?? ''}',
        lastBackup: _int(row['last-backup']),
        backupCount: _int(row['backup-count']),
        owner: '${row['owner'] ?? ''}',
        comment: '${row['comment'] ?? ''}',
        files: _int(row['files']),
        namespace: ns,
      ),
  ];

  Future<List<PbsSnapshot>> snapshots(
    String store, {
    String? ns,
    String? type,
    String? id,
  }) async => [
    for (final row in _list(
      await _getData(
        '/admin/datastore/$store/snapshots',
        queryParameters: {'ns': ?ns, 'backup-type': ?type, 'backup-id': ?id},
      ),
    ))
      _snapshot(row, ns),
  ];

  Future<void> deleteSnapshot(String store, PbsSnapshot snap) async =>
      _deleteData('/admin/datastore/$store/snapshots', _snapshotParams(snap));

  Future<void> deleteGroup(String store, PbsGroup group) async => _deleteData(
    '/admin/datastore/$store/groups',
    _groupParams(group)..['error-on-protected'] = true,
  );

  Future<void> setProtected(String store, PbsSnapshot snap, bool value) async =>
      _putData('/admin/datastore/$store/protected', {
        ..._snapshotParams(snap),
        'protected': value,
      });

  Future<void> setNotes(String store, PbsSnapshot snap, String text) async =>
      _putData('/admin/datastore/$store/notes', {
        ..._snapshotParams(snap),
        'notes': text,
      });

  Future<void> setGroupNotes(String store, PbsGroup group, String text) async =>
      _putData('/admin/datastore/$store/group-notes', {
        ..._groupParams(group),
        'notes': text,
      });

  Future<void> changeOwner(
    String store,
    PbsGroup group,
    String newOwner,
  ) async => _postData('/admin/datastore/$store/change-owner', {
    ..._groupParams(group),
    'new-owner': newOwner,
  });

  Future<List<PbsPruneEntry>> prunePreview(
    String store,
    PbsGroup group,
    PbsKeep keep,
  ) async => _prune(store, group, keep, true);

  Future<List<PbsPruneEntry>> pruneGroup(
    String store,
    PbsGroup group,
    PbsKeep keep,
  ) async => _prune(store, group, keep, false);

  Future<String> pruneDatastore(
    String store,
    PbsKeep keep, {
    String? ns,
  }) async =>
      '${await _postData('/admin/datastore/$store/prune-datastore', {...keep.toMap(), 'ns': ?ns})}';

  Future<dynamic> pruneDatastorePreview(
    String store,
    PbsKeep keep, {
    String? ns,
  }) => _postData('/admin/datastore/$store/prune-datastore', {
    ...keep.toMap(),
    'ns': ?ns,
    'dry-run': true,
  });

  Future<String> startGc(String store) async =>
      '${await _postData('/admin/datastore/$store/gc', const {})}';

  Future<String> verify(
    String store, {
    String? ns,
    String? type,
    String? id,
    int? time,
    bool? ignoreVerified,
    int? outdatedAfter,
  }) async =>
      '${await _postData('/admin/datastore/$store/verify', {'ns': ?ns, 'backup-type': ?type, 'backup-id': ?id, 'backup-time': ?time, 'ignore-verified': ?ignoreVerified, 'outdated-after': ?outdatedAfter})}';

  Future<List<PbsJob>> pruneJobs() => _jobs('prune');
  Future<List<PbsJob>> verifyJobs() => _jobs('verify');
  Future<List<PbsJob>> syncJobs() => _jobs('sync');

  Future<PbsJobStatus> jobStatus(String kind, String id) async {
    _checkJobKind(kind);
    // `/admin/{kind}/{id}` is only a directory index (its child is `run`);
    // the job list at `/admin/{kind}` is what carries the run state.
    final row = _list(await _getData('/admin/$kind')).firstWhere(
      (row) => row['id'] == id,
      orElse: () => const <String, dynamic>{},
    );
    return PbsJobStatus(
      lastRunState: row['last-run-state'] as String?,
      nextRun: row['next-run'] == null ? null : _int(row['next-run']),
      lastRunUpid: row['last-run-upid'] as String?,
    );
  }

  Future<String> runJob(String kind, String id) async {
    _checkJobKind(kind);
    return '${await _postData('/admin/$kind/$id/run', const {})}';
  }

  Future<void> updateJob(
    String kind,
    String id,
    Map<String, dynamic> changes, {
    List<String> delete = const [],
    String? digest,
  }) async {
    _checkJobKind(kind);
    await _putData('/config/$kind/$id', {
      ...changes,
      if (delete.isNotEmpty) 'delete': delete,
      'digest': ?digest,
    });
  }

  Future<List<PbsTask>> tasks({
    int limit = 50,
    bool errorsOnly = false,
    bool running = false,
  }) async => [
    for (final row in _list(
      await _getData(
        '/nodes/localhost/tasks',
        queryParameters: {
          'limit': limit,
          if (errorsOnly) 'errors': true,
          if (running) 'running': true,
        },
      ),
    ))
      PbsTask(raw: row),
  ];

  Future<PbsTaskStatus> taskStatus(String upid) async => PbsTaskStatus(
    raw: _map(
      await _getData(
        '/nodes/localhost/tasks/${Uri.encodeComponent(upid)}/status',
      ),
    ),
  );

  Future<List<String>> taskLogTail(String upid, {int limit = 200}) async {
    final path = '/nodes/localhost/tasks/${Uri.encodeComponent(upid)}/log';
    try {
      final countResponse = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: const {'limit': 0},
      );
      final total = _int(countResponse.data?['total']);
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'start': total > limit ? total - limit : 0,
          'limit': limit,
        },
      );
      return [
        for (final row in _list(response.data?['data'])) '${row['t'] ?? ''}',
      ];
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<List<PbsCatalogEntry>> catalog(
    String store,
    PbsSnapshot snap,
    String filepath,
  ) async => [
    for (final row in _list(
      await _getData(
        '/admin/datastore/$store/catalog',
        queryParameters: {
          ..._snapshotParams(snap),
          'filepath': base64.encode(utf8.encode(filepath)),
        },
      ),
    ))
      PbsCatalogEntry(
        filename: row['filename'] as String?,
        text: '${row['text'] ?? row['filename'] ?? ''}',
        type: '${row['type'] ?? ''}',
        leaf: _bool(row['leaf']),
        size: _int(row['size']),
        mtime: _int(row['mtime']),
        filepath: _decodePath('${row['filepath'] ?? ''}'),
      ),
  ];

  Future<void> downloadFile(
    String store,
    PbsSnapshot snap,
    String filepath,
    String savePath,
  ) async {
    try {
      await _dio.download(
        '/admin/datastore/$store/pxar-file-download',
        savePath,
        queryParameters: {
          ..._snapshotParams(snap),
          'filepath': base64.encode(utf8.encode(filepath)),
        },
      );
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<List<PbsPruneEntry>> _prune(
    String store,
    PbsGroup group,
    PbsKeep keep,
    bool dryRun,
  ) async => [
    for (final row in _list(
      await _postData('/admin/datastore/$store/prune', {
        ..._groupParams(group),
        ...keep.toMap(),
        'dry-run': dryRun,
      }),
    ))
      PbsPruneEntry(
        time: _int(row['backup-time']),
        keep: _bool(row['keep']),
        protected: _bool(row['protected']),
      ),
  ];

  Future<List<PbsJob>> _jobs(String kind) async => [
    for (final row in _list(await _getData('/config/$kind')))
      PbsJob(
        kind: kind,
        id: '${row['id'] ?? ''}',
        store: '${row['store'] ?? ''}',
        schedule: '${row['schedule'] ?? ''}',
        raw: row,
      ),
  ];

  Future<dynamic> _getData(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data?['data'];
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<dynamic> _postData(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      return response.data?['data'];
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<dynamic> _putData(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      return response.data?['data'];
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<void> _deleteData(String path, Map<String, dynamic> query) async {
    try {
      await _dio.delete<Map<String, dynamic>>(path, queryParameters: query);
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  static PbsSnapshot _snapshot(Map<String, dynamic> row, String? ns) {
    final verification = row['verification'];
    return PbsSnapshot(
      type: '${row['backup-type'] ?? ''}',
      id: '${row['backup-id'] ?? ''}',
      time: _int(row['backup-time']),
      size: _int(row['size']),
      protected: _bool(row['protected']),
      comment: '${row['comment'] ?? ''}',
      owner: '${row['owner'] ?? ''}',
      verification: verification is Map
          ? PbsVerification(
              state: '${verification['state'] ?? ''}',
              upid: verification['upid'] as String?,
            )
          : null,
      files: [
        for (final file in _mapList(row['files']))
          PbsSnapshotFile(
            filename: '${file['filename'] ?? ''}',
            size: _int(file['size']),
            cryptMode: '${file['crypt-mode'] ?? ''}',
          ),
      ],
      fingerprint: '${row['fingerprint'] ?? ''}',
      namespace: ns,
    );
  }

  static Map<String, dynamic> _snapshotParams(PbsSnapshot snap) => {
    'backup-type': snap.type,
    'backup-id': snap.id,
    'backup-time': snap.time,
    'ns': ?snap.namespace,
  };

  static Map<String, dynamic> _groupParams(PbsGroup group) => {
    'backup-type': group.type,
    'backup-id': group.id,
    'ns': ?group.namespace,
  };

  static void _checkJobKind(String kind) {
    if (!const {'prune', 'verify', 'sync'}.contains(kind)) {
      throw ArgumentError.value(kind, 'kind', 'Unsupported PBS job kind');
    }
  }

  static PbsApiException _apiException(DioException error) {
    final response = error.response;
    final body = response?.data;
    final message = body is String
        ? body
        : body == null
        // No response at all: say why (timeout, TLS, decoding) instead of a
        // bare "failed" — the status code is null in every one of these.
        ? '${error.type.name}: ${error.error ?? error.message ?? 'PBS request failed'}'
        : jsonEncode(body);
    return PbsApiException(response?.statusCode, message);
  }

  /// PBS returns catalog paths base64-encoded; callers work with plain
  /// paths and [catalog]/[downloadFile] encode them again on the way out.
  static String _decodePath(String value) {
    try {
      return utf8.decode(base64.decode(value));
    } on FormatException {
      return value;
    }
  }

  static bool _bool(dynamic value) =>
      value == true || value == 1 || value == '1';
  static int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  static List<Map<String, dynamic>> _list(dynamic value) =>
      value is List ? value.whereType<Map>().map(_map).toList() : const [];
  static List<Map<String, dynamic>> _mapList(dynamic value) => _list(value);
}
