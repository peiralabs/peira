// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxmox_container.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProxmoxContainer _$ProxmoxContainerFromJson(Map<String, dynamic> json) =>
    _ProxmoxContainer(
      vmid: (json['vmid'] as num).toInt(),
      status: json['status'] as String,
      name: json['name'] as String?,
      node: json['node'] as String?,
      cpu: (json['cpu'] as num?)?.toDouble(),
      cpus: (json['cpus'] as num?)?.toInt(),
      mem: (json['mem'] as num?)?.toInt(),
      maxmem: (json['maxmem'] as num?)?.toInt(),
      swap: (json['swap'] as num?)?.toInt(),
      maxswap: (json['maxswap'] as num?)?.toInt(),
      disk: (json['disk'] as num?)?.toInt(),
      maxdisk: (json['maxdisk'] as num?)?.toInt(),
      uptime: (json['uptime'] as num?)?.toInt(),
      netin: (json['netin'] as num?)?.toInt(),
      netout: (json['netout'] as num?)?.toInt(),
      diskread: (json['diskread'] as num?)?.toInt(),
      diskwrite: (json['diskwrite'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProxmoxContainerToJson(_ProxmoxContainer instance) =>
    <String, dynamic>{
      'vmid': instance.vmid,
      'status': instance.status,
      'name': instance.name,
      'node': instance.node,
      'cpu': instance.cpu,
      'cpus': instance.cpus,
      'mem': instance.mem,
      'maxmem': instance.maxmem,
      'swap': instance.swap,
      'maxswap': instance.maxswap,
      'disk': instance.disk,
      'maxdisk': instance.maxdisk,
      'uptime': instance.uptime,
      'netin': instance.netin,
      'netout': instance.netout,
      'diskread': instance.diskread,
      'diskwrite': instance.diskwrite,
    };
