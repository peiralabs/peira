import 'package:freezed_annotation/freezed_annotation.dart';

part 'prowlarr_release.freezed.dart';
part 'prowlarr_release.g.dart';

/// One search result from Prowlarr GET /api/v1/search (a torrent/usenet
/// release found across the configured indexers).
@freezed
abstract class ProwlarrRelease with _$ProwlarrRelease {
  const factory ProwlarrRelease({
    @Default('') String title,
    String? indexer,
    @Default(0) num size,
    @Default(0) int seeders,
    @Default(0) int leechers,
    String? protocol,
    String? guid,
  }) = _ProwlarrRelease;

  factory ProwlarrRelease.fromJson(Map<String, dynamic> json) =>
      _$ProwlarrReleaseFromJson(json);
}
