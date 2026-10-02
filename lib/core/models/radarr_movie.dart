import 'package:freezed_annotation/freezed_annotation.dart';

part 'radarr_movie.freezed.dart';
part 'radarr_movie.g.dart';

/// One movie from Radarr GET /api/v3/movie (or a lookup result from
/// /api/v3/movie/lookup, where [id] is 0 until the movie is added).
@freezed
abstract class RadarrMovie with _$RadarrMovie {
  const factory RadarrMovie({
    @Default(0) int id,
    @Default('') String title,
    int? year,
    @Default(false) bool monitored,
    @Default(false) bool hasFile,
    @Default(0) int sizeOnDisk,
    String? status,
    int? tmdbId,
    String? overview,
  }) = _RadarrMovie;

  factory RadarrMovie.fromJson(Map<String, dynamic> json) =>
      _$RadarrMovieFromJson(json);
}
