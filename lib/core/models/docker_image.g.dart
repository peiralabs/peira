// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'docker_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DockerImage _$DockerImageFromJson(Map<String, dynamic> json) => _DockerImage(
  id: json['Id'] as String? ?? '',
  repoTags:
      (json['RepoTags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  size: (json['Size'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DockerImageToJson(_DockerImage instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'RepoTags': instance.repoTags,
      'Size': instance.size,
    };
