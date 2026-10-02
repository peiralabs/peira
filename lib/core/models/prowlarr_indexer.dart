import 'package:freezed_annotation/freezed_annotation.dart';

part 'prowlarr_indexer.freezed.dart';
part 'prowlarr_indexer.g.dart';

/// One configured indexer from Prowlarr GET /api/v1/indexer.
@freezed
abstract class ProwlarrIndexer with _$ProwlarrIndexer {
  const factory ProwlarrIndexer({
    @Default(0) int id,
    @Default('') String name,
    @Default(false) bool enable,
    String? protocol,
    int? priority,
  }) = _ProwlarrIndexer;

  factory ProwlarrIndexer.fromJson(Map<String, dynamic> json) =>
      _$ProwlarrIndexerFromJson(json);
}
