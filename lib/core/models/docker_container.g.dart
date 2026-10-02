// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'docker_container.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DockerContainer _$DockerContainerFromJson(Map<String, dynamic> json) =>
    _DockerContainer(
      id: json['Id'] as String? ?? '',
      name: json['Names'] == null ? '' : _dockerContainerName(json['Names']),
      image: json['Image'] as String? ?? '',
      state: json['State'] as String? ?? '',
      status: json['Status'] as String? ?? '',
      ports:
          (json['Ports'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DockerContainerToJson(_DockerContainer instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Names': instance.name,
      'Image': instance.image,
      'State': instance.state,
      'Status': instance.status,
      'Ports': instance.ports,
    };
