import 'package:freezed_annotation/freezed_annotation.dart';

part 'container_status.freezed.dart';
part 'container_status.g.dart';

/// GET /api2/json/nodes/{node}/lxc/{vmid}/status/current.
@freezed
abstract class ContainerStatus with _$ContainerStatus {
  const factory ContainerStatus({
    required String status,
    int? vmid,
    String? name,
    double? cpu,
    int? cpus,
    int? mem,
    int? maxmem,
    int? swap,
    int? maxswap,
    int? disk,
    int? maxdisk,
    int? uptime,
    int? netin,
    int? netout,
    int? diskread,
    int? diskwrite,
  }) = _ContainerStatus;

  factory ContainerStatus.fromJson(Map<String, dynamic> json) =>
      _$ContainerStatusFromJson(json);
}
