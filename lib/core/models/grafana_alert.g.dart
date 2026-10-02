// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grafana_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GrafanaAlert _$GrafanaAlertFromJson(Map<String, dynamic> json) =>
    _GrafanaAlert(
      labels:
          (json['labels'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      annotations:
          (json['annotations'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      startsAt: DateTime.parse(json['startsAt'] as String),
      fingerprint: json['fingerprint'] as String?,
      status: json['status'] as Map<String, dynamic>?,
      generatorUrl: json['generatorURL'] as String? ?? '',
    );

Map<String, dynamic> _$GrafanaAlertToJson(_GrafanaAlert instance) =>
    <String, dynamic>{
      'labels': instance.labels,
      'annotations': instance.annotations,
      'startsAt': instance.startsAt.toIso8601String(),
      'fingerprint': instance.fingerprint,
      'status': instance.status,
      'generatorURL': instance.generatorUrl,
    };
