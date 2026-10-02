import 'package:freezed_annotation/freezed_annotation.dart';

part 'servarr_queue_item.freezed.dart';
part 'servarr_queue_item.g.dart';

/// One active/queued grab from Radarr or Sonarr GET /api/v3/queue.
///
/// Radarr and Sonarr share the same queue payload shape, so a single model
/// serves both. Sizes are bytes; [timeleft] is a "HH:MM:SS" string when the
/// download client reports an ETA.
@freezed
abstract class ServarrQueueItem with _$ServarrQueueItem {
  const factory ServarrQueueItem({
    @Default(0) int id,
    @Default('') String title,
    String? status,
    String? trackedDownloadState,
    String? trackedDownloadStatus,
    @Default(0) num size,
    @Default(0) num sizeleft,
    String? timeleft,
    String? indexer,
  }) = _ServarrQueueItem;

  const ServarrQueueItem._();

  factory ServarrQueueItem.fromJson(Map<String, dynamic> json) =>
      _$ServarrQueueItemFromJson(json);

  /// 0..1 completed fraction, guarding against a zero total.
  double get progress =>
      size <= 0 ? 0 : ((size - sizeleft) / size).clamp(0, 1).toDouble();
}
