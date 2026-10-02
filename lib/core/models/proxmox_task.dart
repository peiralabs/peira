import 'package:freezed_annotation/freezed_annotation.dart';

part 'proxmox_task.freezed.dart';
part 'proxmox_task.g.dart';

/// One entry from GET /api2/json/cluster/tasks.
///
/// Running tasks have no [endtime] and no [status]; finished tasks report
/// status "OK" or an error string.
@freezed
abstract class ProxmoxTask with _$ProxmoxTask {
  const ProxmoxTask._();

  const factory ProxmoxTask({
    required String upid,
    required String node,
    required String type,
    required int starttime,
    int? endtime,
    String? status,
    String? user,
    String? id,
  }) = _ProxmoxTask;

  factory ProxmoxTask.fromJson(Map<String, dynamic> json) =>
      _$ProxmoxTaskFromJson(json);

  bool get isRunning => endtime == null;
  bool get isOk => status == 'OK';

  /// PVE reports a finished task's outcome as `OK`, `WARNINGS: N`, or an error
  /// string. A warning is not a failure — `vzstart` emits
  /// "WARN: Systemd 252 detected. You may need to enable nesting." on a
  /// perfectly successful container start.
  bool get hasWarnings => status?.startsWith('WARNINGS') ?? false;

  /// Finished, and neither successful nor merely warning. This is the single
  /// definition of "failed" — use it instead of re-deriving `!isOk`, which
  /// counts warning-only tasks as failures.
  bool get isFailed => !isRunning && !isOk && !hasWarnings;
}
