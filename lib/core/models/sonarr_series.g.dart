// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarr_series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SonarrSeriesStatistics _$SonarrSeriesStatisticsFromJson(
  Map<String, dynamic> json,
) => _SonarrSeriesStatistics(
  episodeCount: (json['episodeCount'] as num?)?.toInt() ?? 0,
  episodeFileCount: (json['episodeFileCount'] as num?)?.toInt() ?? 0,
  totalEpisodeCount: (json['totalEpisodeCount'] as num?)?.toInt() ?? 0,
  sizeOnDisk: (json['sizeOnDisk'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SonarrSeriesStatisticsToJson(
  _SonarrSeriesStatistics instance,
) => <String, dynamic>{
  'episodeCount': instance.episodeCount,
  'episodeFileCount': instance.episodeFileCount,
  'totalEpisodeCount': instance.totalEpisodeCount,
  'sizeOnDisk': instance.sizeOnDisk,
};

_SonarrSeries _$SonarrSeriesFromJson(Map<String, dynamic> json) =>
    _SonarrSeries(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      year: (json['year'] as num?)?.toInt(),
      monitored: json['monitored'] as bool? ?? false,
      status: json['status'] as String?,
      network: json['network'] as String?,
      seriesType: json['seriesType'] as String?,
      tvdbId: (json['tvdbId'] as num?)?.toInt(),
      overview: json['overview'] as String?,
      statistics: json['statistics'] == null
          ? null
          : SonarrSeriesStatistics.fromJson(
              json['statistics'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$SonarrSeriesToJson(_SonarrSeries instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'year': instance.year,
      'monitored': instance.monitored,
      'status': instance.status,
      'network': instance.network,
      'seriesType': instance.seriesType,
      'tvdbId': instance.tvdbId,
      'overview': instance.overview,
      'statistics': instance.statistics,
    };
