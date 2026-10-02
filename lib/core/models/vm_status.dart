import 'package:freezed_annotation/freezed_annotation.dart';

part 'vm_status.freezed.dart';
part 'vm_status.g.dart';

/// GET /api2/json/nodes/{node}/qemu/{vmid}/status/current.
@freezed
abstract class VmStatus with _$VmStatus {
  const factory VmStatus({
    required String status,
    int? vmid,
    String? name,
    String? qmpstatus,
    double? cpu,
    int? cpus,
    int? mem,
    int? maxmem,
    int? disk,
    int? maxdisk,
    int? uptime,
    int? netin,
    int? netout,
    int? diskread,
    int? diskwrite,
  }) = _VmStatus;

  factory VmStatus.fromJson(Map<String, dynamic> json) =>
      _$VmStatusFromJson(json);
}
