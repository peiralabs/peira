// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'container_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContainerStatus _$ContainerStatusFromJson(Map<String, dynamic> json) =>
    _ContainerStatus(
      status: json['status'] as String,
      vmid: (json['vmid'] as num?)?.toInt(),
      name: json['name'] as String?,
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

Map<String, dynamic> _$ContainerStatusToJson(_ContainerStatus instance) =>
    <String, dynamic>{
      'status': instance.status,
      'vmid': instance.vmid,
      'name': instance.name,
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
