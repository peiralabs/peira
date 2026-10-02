// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prowlarr_indexer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProwlarrIndexer _$ProwlarrIndexerFromJson(Map<String, dynamic> json) =>
    _ProwlarrIndexer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      enable: json['enable'] as bool? ?? false,
      protocol: json['protocol'] as String?,
      priority: (json['priority'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProwlarrIndexerToJson(_ProwlarrIndexer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'enable': instance.enable,
      'protocol': instance.protocol,
      'priority': instance.priority,
    };
