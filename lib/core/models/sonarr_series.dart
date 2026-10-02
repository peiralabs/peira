import 'package:freezed_annotation/freezed_annotation.dart';

part 'sonarr_series.freezed.dart';
part 'sonarr_series.g.dart';

/// Aggregate episode counts Sonarr reports per series.
@freezed
abstract class SonarrSeriesStatistics with _$SonarrSeriesStatistics {
  const factory SonarrSeriesStatistics({
    @Default(0) int episodeCount,
    @Default(0) int episodeFileCount,
    @Default(0) int totalEpisodeCount,
    @Default(0) int sizeOnDisk,
  }) = _SonarrSeriesStatistics;

  factory SonarrSeriesStatistics.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeriesStatisticsFromJson(json);
}

/// One series from Sonarr GET /api/v3/series (or a lookup result from
/// /api/v3/series/lookup, where [id] is 0 until the series is added).
@freezed
abstract class SonarrSeries with _$SonarrSeries {
  const factory SonarrSeries({
    @Default(0) int id,
    @Default('') String title,
    int? year,
    @Default(false) bool monitored,
    String? status,
    String? network,
    String? seriesType,
    int? tvdbId,
    String? overview,
    SonarrSeriesStatistics? statistics,
  }) = _SonarrSeries;

  factory SonarrSeries.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeriesFromJson(json);
}
