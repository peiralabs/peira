import 'package:freezed_annotation/freezed_annotation.dart';

part 'docker_image.freezed.dart';
part 'docker_image.g.dart';

/// One entry from `GET /images/json`.
@freezed
abstract class DockerImage with _$DockerImage {
  const factory DockerImage({
    @JsonKey(name: 'Id') @Default('') String id,
    @JsonKey(name: 'RepoTags') @Default([]) List<String> repoTags,
    @JsonKey(name: 'Size') @Default(0) int size,
  }) = _DockerImage;

  factory DockerImage.fromJson(Map<String, dynamic> json) =>
      _$DockerImageFromJson(json);
}
