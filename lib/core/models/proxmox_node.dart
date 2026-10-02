import 'package:freezed_annotation/freezed_annotation.dart';

part 'proxmox_node.freezed.dart';
part 'proxmox_node.g.dart';

/// One entry from GET /api2/json/nodes.
@freezed
abstract class ProxmoxNode with _$ProxmoxNode {
  const factory ProxmoxNode({
    required String node,
    required String status,
    double? cpu,
    int? maxcpu,
    int? mem,
    int? maxmem,
    int? disk,
    int? maxdisk,
    int? uptime,
  }) = _ProxmoxNode;

  factory ProxmoxNode.fromJson(Map<String, dynamic> json) =>
      _$ProxmoxNodeFromJson(json);
}
