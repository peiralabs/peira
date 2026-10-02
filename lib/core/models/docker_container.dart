import 'package:freezed_annotation/freezed_annotation.dart';

part 'docker_container.freezed.dart';
part 'docker_container.g.dart';

String _dockerContainerName(Object? value) {
  if (value is! List || value.isEmpty) return '';
  final name = value.first;
  if (name is! String) return '';
  return name.startsWith('/') ? name.substring(1) : name;
}

/// One entry from `GET /containers/json?all=1`.
@freezed
abstract class DockerContainer with _$DockerContainer {
  const factory DockerContainer({
    @JsonKey(name: 'Id') @Default('') String id,
    @JsonKey(name: 'Names', fromJson: _dockerContainerName)
    @Default('')
    String name,
    @JsonKey(name: 'Image') @Default('') String image,
    @JsonKey(name: 'State') @Default('') String state,
    @JsonKey(name: 'Status') @Default('') String status,
    @JsonKey(name: 'Ports') @Default([]) List<Map<String, dynamic>> ports,
  }) = _DockerContainer;

  factory DockerContainer.fromJson(Map<String, dynamic> json) =>
      _$DockerContainerFromJson(json);
}
