// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qbittorrent_torrent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QbittorrentTorrent _$QbittorrentTorrentFromJson(Map<String, dynamic> json) =>
    _QbittorrentTorrent(
      hash: json['hash'] as String? ?? '',
      name: json['name'] as String? ?? '',
      state: json['state'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      dlspeed: (json['dlspeed'] as num?)?.toInt() ?? 0,
      upspeed: (json['upspeed'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      eta: (json['eta'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      numSeeds: (json['num_seeds'] as num?)?.toInt() ?? 0,
      numLeechs: (json['num_leechs'] as num?)?.toInt() ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$QbittorrentTorrentToJson(_QbittorrentTorrent instance) =>
    <String, dynamic>{
      'hash': instance.hash,
      'name': instance.name,
      'state': instance.state,
      'progress': instance.progress,
      'dlspeed': instance.dlspeed,
      'upspeed': instance.upspeed,
      'size': instance.size,
      'eta': instance.eta,
      'category': instance.category,
      'num_seeds': instance.numSeeds,
      'num_leechs': instance.numLeechs,
      'ratio': instance.ratio,
    };
