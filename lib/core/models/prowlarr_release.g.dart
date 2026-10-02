// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prowlarr_release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProwlarrRelease _$ProwlarrReleaseFromJson(Map<String, dynamic> json) =>
    _ProwlarrRelease(
      title: json['title'] as String? ?? '',
      indexer: json['indexer'] as String?,
      size: json['size'] as num? ?? 0,
      seeders: (json['seeders'] as num?)?.toInt() ?? 0,
      leechers: (json['leechers'] as num?)?.toInt() ?? 0,
      protocol: json['protocol'] as String?,
      guid: json['guid'] as String?,
    );

Map<String, dynamic> _$ProwlarrReleaseToJson(_ProwlarrRelease instance) =>
    <String, dynamic>{
      'title': instance.title,
      'indexer': instance.indexer,
      'size': instance.size,
      'seeders': instance.seeders,
      'leechers': instance.leechers,
      'protocol': instance.protocol,
      'guid': instance.guid,
    };
