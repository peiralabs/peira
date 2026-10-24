import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pdm_api.dart';
import 'pdm_providers.dart';

part 'pdm_jobs.g.dart';

class PdmJob {
  const PdmJob({
    required this.label,
    required this.remote,
    required this.startedAt,
    this.upid,
    this.error,
  });

  final String label;
  final String remote;
  final String? upid;
  final DateTime startedAt;
  final String? error;

  PdmJob copyWith({String? upid, String? error}) => PdmJob(
    label: label,
    remote: remote,
    startedAt: startedAt,
    upid: upid ?? this.upid,
    error: error ?? this.error,
  );
}

class PdmJobResult {
  const PdmJobResult({
    required this.guestKey,
    required this.label,
    required this.success,
    this.exitStatus,
  });

  final String guestKey;
  final String label;
  final bool success;
  final String? exitStatus;
}

typedef _Done = void Function(PdmTaskStatus status);

/// Runs PDM actions independently of screen lifetime and owns every polling
/// timer. Jobs are keyed by `remote/vmid`, which also makes row lookup cheap.
@Riverpod(keepAlive: true)
class PdmJobs extends _$PdmJobs {
  final Map<String, Timer> _timers = {};
  PdmJobResult? _lastResult;

  PdmJobResult? get lastResult => _lastResult;

  @override
  Map<String, PdmJob> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  static String key(String remote, int vmid) => '$remote/$vmid';

  void clearLastResult() => _lastResult = null;

  Future<void> runPowerAction(
    PdmGuest guest,
    String action, {
    String? label,
  }) async {
    final guestKey = key(guest.remote, guest.vmid);
    final jobLabel = label ?? _actionLabel(action);
    _start(
      guestKey,
      PdmJob(label: jobLabel, remote: guest.remote, startedAt: DateTime.now()),
    );
    try {
      final api = await ref.read(pdmApiProvider.future);
      if (action == 'reboot') {
        final shutdown = await api.guestAction(
          guest.remote,
          guest.kind,
          guest.vmid,
          'shutdown',
        );
        _setUpid(guestKey, shutdown);
        _poll(
          api: api,
          guestKey: guestKey,
          remote: guest.remote,
          upid: shutdown,
          deadline: DateTime.now().add(const Duration(minutes: 10)),
          done: (status) async {
            if (!status.succeeded) {
              _finish(guestKey, jobLabel, status);
              return;
            }
            try {
              final start = await api.guestAction(
                guest.remote,
                guest.kind,
                guest.vmid,
                'start',
              );
              _setUpid(guestKey, start);
              _poll(
                api: api,
                guestKey: guestKey,
                remote: guest.remote,
                upid: start,
                deadline: DateTime.now().add(const Duration(minutes: 10)),
                done: (result) => _finish(guestKey, jobLabel, result),
              );
            } catch (error) {
              _fail(guestKey, jobLabel, error);
            }
          },
        );
        return;
      }

      final upid = await api.guestAction(
        guest.remote,
        guest.kind,
        guest.vmid,
        action,
      );
      _setUpid(guestKey, upid);
      _poll(
        api: api,
        guestKey: guestKey,
        remote: guest.remote,
        upid: upid,
        deadline: DateTime.now().add(const Duration(minutes: 10)),
        done: (status) => _finish(guestKey, jobLabel, status),
      );
    } catch (error) {
      _fail(guestKey, jobLabel, error);
    }
  }

  void runMigration({
    required String guestKey,
    required String sourceRemote,
    required String targetRemote,
    required String upid,
  }) {
    final label = 'Migrating to $targetRemote';
    _start(
      guestKey,
      PdmJob(
        label: label,
        remote: sourceRemote,
        upid: upid,
        startedAt: DateTime.now(),
      ),
    );
    ref
        .read(pdmApiProvider.future)
        .then(
          (api) => _poll(
            api: api,
            guestKey: guestKey,
            remote: sourceRemote,
            upid: upid,
            done: (status) => _finish(guestKey, label, status),
          ),
          onError: (Object error, StackTrace _) =>
              _fail(guestKey, label, error),
        );
  }

  void _start(String key, PdmJob job) {
    _timers.remove(key)?.cancel();
    _lastResult = null;
    state = {...state, key: job};
  }

  void _setUpid(String key, String upid) {
    final job = state[key];
    if (job != null) state = {...state, key: job.copyWith(upid: upid)};
  }

  void _poll({
    required PdmApi api,
    required String guestKey,
    required String remote,
    required String upid,
    required _Done done,
    DateTime? deadline,
  }) {
    var checking = false;
    // A migration runs for minutes; one failed status read (PDM busy, a
    // network blip) must not report a still-running task as failed.
    var consecutiveErrors = 0;
    Future<void> check() async {
      if (checking || !state.containsKey(guestKey)) return;
      if (deadline != null && !DateTime.now().isBefore(deadline)) {
        _fail(guestKey, state[guestKey]!.label, 'still running — check Tasks');
        return;
      }
      checking = true;
      try {
        final status = await api.taskStatus(remote, upid);
        consecutiveErrors = 0;
        if (!status.running) {
          _timers.remove(guestKey)?.cancel();
          done(status);
        }
      } catch (error) {
        if (++consecutiveErrors >= 5) {
          _fail(guestKey, state[guestKey]?.label ?? 'Job', error);
        }
      } finally {
        checking = false;
      }
    }

    _timers.remove(guestKey)?.cancel();
    _timers[guestKey] = Timer.periodic(
      const Duration(seconds: 3),
      (_) => check(),
    );
  }

  void _finish(String key, String label, PdmTaskStatus status) {
    _timers.remove(key)?.cancel();
    _lastResult = PdmJobResult(
      guestKey: key,
      label: label,
      success: status.succeeded,
      exitStatus: status.exitStatus,
    );
    state = {...state}..remove(key);
    _refresh();
  }

  void _fail(String key, String label, Object error) {
    _timers.remove(key)?.cancel();
    final message = error is PdmApiException ? error.message : '$error';
    _lastResult = PdmJobResult(
      guestKey: key,
      label: label,
      success: false,
      exitStatus: message,
    );
    state = {...state}..remove(key);
    _refresh();
  }

  void _refresh() {
    ref.invalidate(pdmOverviewProvider);
    for (final filter in PdmTaskFilter.values) {
      ref.invalidate(pdmTasksProvider(filter));
    }
  }

  static String _actionLabel(String action) => switch (action) {
    'start' => 'Starting',
    'shutdown' => 'Shutting down',
    'stop' => 'Stopping',
    'resume' => 'Resuming',
    'reboot' => 'Rebooting',
    _ => action,
  };
}
