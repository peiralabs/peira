import 'package:freezed_annotation/freezed_annotation.dart';

part 'qbittorrent_torrent.freezed.dart';
part 'qbittorrent_torrent.g.dart';

/// One torrent from qBittorrent GET /api/v2/torrents/info.
///
/// The WebUI API uses snake_case keys and reports [progress] as a 0..1
/// fraction; speeds are bytes/sec, [size] is bytes, [eta] is seconds
/// (8640000 = qBittorrent's "infinity" sentinel).
@freezed
abstract class QbittorrentTorrent with _$QbittorrentTorrent {
  const factory QbittorrentTorrent({
    @Default('') String hash,
    @Default('') String name,
    @Default('') String state,
    @Default(0) double progress,
    @Default(0) int dlspeed,
    @Default(0) int upspeed,
    @Default(0) int size,
    @Default(0) int eta,
    @Default('') String category,
    @JsonKey(name: 'num_seeds') @Default(0) int numSeeds,
    @JsonKey(name: 'num_leechs') @Default(0) int numLeechs,
    @Default(0) double ratio,
  }) = _QbittorrentTorrent;

  factory QbittorrentTorrent.fromJson(Map<String, dynamic> json) =>
      _$QbittorrentTorrentFromJson(json);
}
