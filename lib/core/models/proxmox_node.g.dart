// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxmox_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProxmoxNode _$ProxmoxNodeFromJson(Map<String, dynamic> json) => _ProxmoxNode(
  node: json['node'] as String,
  status: json['status'] as String,
  cpu: (json['cpu'] as num?)?.toDouble(),
  maxcpu: (json['maxcpu'] as num?)?.toInt(),
  mem: (json['mem'] as num?)?.toInt(),
  maxmem: (json['maxmem'] as num?)?.toInt(),
  disk: (json['disk'] as num?)?.toInt(),
  maxdisk: (json['maxdisk'] as num?)?.toInt(),
  uptime: (json['uptime'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProxmoxNodeToJson(_ProxmoxNode instance) =>
    <String, dynamic>{
      'node': instance.node,
      'status': instance.status,
      'cpu': instance.cpu,
      'maxcpu': instance.maxcpu,
      'mem': instance.mem,
      'maxmem': instance.maxmem,
      'disk': instance.disk,
      'maxdisk': instance.maxdisk,
      'uptime': instance.uptime,
    };
