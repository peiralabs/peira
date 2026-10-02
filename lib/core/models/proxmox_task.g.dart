// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxmox_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProxmoxTask _$ProxmoxTaskFromJson(Map<String, dynamic> json) => _ProxmoxTask(
  upid: json['upid'] as String,
  node: json['node'] as String,
  type: json['type'] as String,
  starttime: (json['starttime'] as num).toInt(),
  endtime: (json['endtime'] as num?)?.toInt(),
  status: json['status'] as String?,
  user: json['user'] as String?,
  id: json['id'] as String?,
);

Map<String, dynamic> _$ProxmoxTaskToJson(_ProxmoxTask instance) =>
    <String, dynamic>{
      'upid': instance.upid,
      'node': instance.node,
      'type': instance.type,
      'starttime': instance.starttime,
      'endtime': instance.endtime,
      'status': instance.status,
      'user': instance.user,
      'id': instance.id,
    };
