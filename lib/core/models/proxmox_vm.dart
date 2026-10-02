import 'package:freezed_annotation/freezed_annotation.dart';

part 'proxmox_vm.freezed.dart';
part 'proxmox_vm.g.dart';

/// One entry from GET /api2/json/nodes/{node}/qemu.
///
/// [node] is not part of the API payload — the client injects it so a VM
/// knows which host it lives on. [template] is 1 for VM templates.
@freezed
abstract class ProxmoxVm with _$ProxmoxVm {
  const factory ProxmoxVm({
    required int vmid,
    required String status,
    String? name,
    String? node,
    int? template,
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
  }) = _ProxmoxVm;

  factory ProxmoxVm.fromJson(Map<String, dynamic> json) =>
      _$ProxmoxVmFromJson(json);
}
