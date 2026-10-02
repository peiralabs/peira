// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxmox_vm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProxmoxVm _$ProxmoxVmFromJson(Map<String, dynamic> json) => _ProxmoxVm(
  vmid: (json['vmid'] as num).toInt(),
  status: json['status'] as String,
  name: json['name'] as String?,
  node: json['node'] as String?,
  template: (json['template'] as num?)?.toInt(),
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

Map<String, dynamic> _$ProxmoxVmToJson(_ProxmoxVm instance) =>
    <String, dynamic>{
      'vmid': instance.vmid,
      'status': instance.status,
      'name': instance.name,
      'node': instance.node,
      'template': instance.template,
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
