// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radarr_movie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RadarrMovie _$RadarrMovieFromJson(Map<String, dynamic> json) => _RadarrMovie(
  id: (json['id'] as num?)?.toInt() ?? 0,
  title: json['title'] as String? ?? '',
  year: (json['year'] as num?)?.toInt(),
  monitored: json['monitored'] as bool? ?? false,
  hasFile: json['hasFile'] as bool? ?? false,
  sizeOnDisk: (json['sizeOnDisk'] as num?)?.toInt() ?? 0,
  status: json['status'] as String?,
  tmdbId: (json['tmdbId'] as num?)?.toInt(),
  overview: json['overview'] as String?,
);

Map<String, dynamic> _$RadarrMovieToJson(_RadarrMovie instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'year': instance.year,
      'monitored': instance.monitored,
      'hasFile': instance.hasFile,
      'sizeOnDisk': instance.sizeOnDisk,
      'status': instance.status,
      'tmdbId': instance.tmdbId,
      'overview': instance.overview,
    };
