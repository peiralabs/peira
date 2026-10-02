// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servarr_queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServarrQueueItem _$ServarrQueueItemFromJson(Map<String, dynamic> json) =>
    _ServarrQueueItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      status: json['status'] as String?,
      trackedDownloadState: json['trackedDownloadState'] as String?,
      trackedDownloadStatus: json['trackedDownloadStatus'] as String?,
      size: json['size'] as num? ?? 0,
      sizeleft: json['sizeleft'] as num? ?? 0,
      timeleft: json['timeleft'] as String?,
      indexer: json['indexer'] as String?,
    );

Map<String, dynamic> _$ServarrQueueItemToJson(_ServarrQueueItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': instance.status,
      'trackedDownloadState': instance.trackedDownloadState,
      'trackedDownloadStatus': instance.trackedDownloadStatus,
      'size': instance.size,
      'sizeleft': instance.sizeleft,
      'timeleft': instance.timeleft,
      'indexer': instance.indexer,
    };
