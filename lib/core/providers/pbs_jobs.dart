import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pbs_api.dart';
import 'pbs_providers.dart';

part 'pbs_jobs.g.dart';

class PbsRunningJob {
  const PbsRunningJob(this.label, this.upid, this.startedAt);
  final String label;
  final String upid;
  final DateTime startedAt;
}

class PbsJobResult {
  const PbsJobResult(this.label, this.success, this.message);
  final String label;
  final bool success;
  final String? message;
}

@Riverpod(keepAlive: true)
class PbsJobs extends _$PbsJobs {
  final _timers = <String, Timer>{};
  PbsJobResult? _lastResult;
  PbsJobResult? get lastResult => _lastResult;

  @override
  Map<String, PbsRunningJob> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
    });
    return const {};
  }

  void clearLastResult() => _lastResult = null;

  void track(PbsSlot slot, String label, String upid) {
    final key = '${slot.name}/$upid';
    state = {...state, key: PbsRunningJob(label, upid, DateTime.now())};
    var checking = false;
    Future<void> check() async {
      if (checking || !state.containsKey(key)) return;
      checking = true;
      try {
        final api = await ref.read(pbsApiProvider(slot).future);
        final status = await api.taskStatus(upid);
        if (!status.running) {
          _finish(
            slot,
            key,
            label,
            status.exitStatus == 'OK',
            status.exitStatus,
          );
        }
      } catch (error) {
        if (error case PbsApiException(statusCode: 401)) {
          ref.read(pbsElevationProvider.notifier).lock(slot);
        }
        _finish(slot, key, label, false, '$error');
      } finally {
        checking = false;
      }
    }

    _timers[key]?.cancel();
    _timers[key] = Timer.periodic(const Duration(seconds: 3), (_) => check());
  }

  void _finish(
    PbsSlot slot,
    String key,
    String label,
    bool success,
    String? message,
  ) {
    _timers.remove(key)?.cancel();
    state = {...state}..remove(key);
    _lastResult = PbsJobResult(label, success, message);
    ref.invalidate(pbsOverviewProvider(slot));
    for (final filter in PbsTaskFilter.values) {
      ref.invalidate(pbsTasksProvider(slot, filter));
    }
    ref.invalidate(pbsGroupsProvider);
    ref.invalidate(pbsSnapshotsProvider);
  }
}
