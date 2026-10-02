// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vm_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VmStatus _$VmStatusFromJson(Map<String, dynamic> json) => _VmStatus(
  status: json['status'] as String,
  vmid: (json['vmid'] as num?)?.toInt(),
  name: json['name'] as String?,
  qmpstatus: json['qmpstatus'] as String?,
  cpu: (json['cpu'] as num?)?.toDouble(),
  cpus: (json['cpus'] as num?)?.toInt(),
  mem: (json['mem'] as num?)?.toInt(),
  maxmem: (json['maxmem'] as num?)?.toInt(),
  disk: (json['disk'] as num?)?.toInt(),
  maxdisk: (json['maxdisk'] as num?)?.toInt(),
  uptime: (json['uptime'] as num?)?.toInt(),
  netin: (json['netin'] as num?)?.toInt(),
  netout: (json['netout'] as num?)?.toInt(),
  diskread: (json['diskread'] as num?)?.toInt(),
  diskwrite: (json['diskwrite'] as num?)?.toInt(),
);

Map<String, dynamic> _$VmStatusToJson(_VmStatus instance) => <String, dynamic>{
  'status': instance.status,
  'vmid': instance.vmid,
  'name': instance.name,
  'qmpstatus': instance.qmpstatus,
  'cpu': instance.cpu,
  'cpus': instance.cpus,
  'mem': instance.mem,
  'maxmem': instance.maxmem,
  'disk': instance.disk,
  'maxdisk': instance.maxdisk,
  'uptime': instance.uptime,
  'netin': instance.netin,
  'netout': instance.netout,
  'diskread': instance.diskread,
  'diskwrite': instance.diskwrite,
};
