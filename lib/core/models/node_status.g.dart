// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NodeStatus _$NodeStatusFromJson(Map<String, dynamic> json) => _NodeStatus(
  cpu: (json['cpu'] as num?)?.toDouble(),
  uptime: (json['uptime'] as num?)?.toInt(),
  kversion: json['kversion'] as String?,
  pveversion: json['pveversion'] as String?,
  loadavg: json['loadavg'] as List<dynamic>?,
  memory: json['memory'] == null
      ? null
      : UsageInfo.fromJson(json['memory'] as Map<String, dynamic>),
  rootfs: json['rootfs'] == null
      ? null
      : UsageInfo.fromJson(json['rootfs'] as Map<String, dynamic>),
  swap: json['swap'] == null
      ? null
      : UsageInfo.fromJson(json['swap'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NodeStatusToJson(_NodeStatus instance) =>
    <String, dynamic>{
      'cpu': instance.cpu,
      'uptime': instance.uptime,
      'kversion': instance.kversion,
      'pveversion': instance.pveversion,
      'loadavg': instance.loadavg,
      'memory': instance.memory,
      'rootfs': instance.rootfs,
      'swap': instance.swap,
    };

_UsageInfo _$UsageInfoFromJson(Map<String, dynamic> json) => _UsageInfo(
  total: (json['total'] as num?)?.toInt(),
  used: (json['used'] as num?)?.toInt(),
  free: (json['free'] as num?)?.toInt(),
  avail: (json['avail'] as num?)?.toInt(),
);

Map<String, dynamic> _$UsageInfoToJson(_UsageInfo instance) =>
    <String, dynamic>{
      'total': instance.total,
      'used': instance.used,
      'free': instance.free,
      'avail': instance.avail,
    };
