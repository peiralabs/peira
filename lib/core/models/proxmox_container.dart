import 'package:freezed_annotation/freezed_annotation.dart';

part 'proxmox_container.freezed.dart';
part 'proxmox_container.g.dart';

/// One entry from GET /api2/json/nodes/{node}/lxc.
///
/// [node] is not part of the API payload — the client injects it so a
/// container knows which host it lives on.
@freezed
abstract class ProxmoxContainer with _$ProxmoxContainer {
  const factory ProxmoxContainer({
    required int vmid,
    required String status,
    String? name,
    String? node,
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
  }) = _ProxmoxContainer;

  factory ProxmoxContainer.fromJson(Map<String, dynamic> json) =>
      _$ProxmoxContainerFromJson(json);
}
