import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/docker_api.dart';
import '../models/docker_container.dart';
import '../models/docker_image.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'docker_providers.g.dart';

/// Thrown while no Docker Engine URL has been entered yet.
class DockerNotConfigured implements Exception {
  const DockerNotConfigured();
}

@riverpod
Future<DockerApi> dockerApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (settings.dockerUrl.isEmpty) throw const DockerNotConfigured();
  return DockerApi.fromSettings(settings);
}

@riverpod
Future<List<DockerContainer>> dockerContainers(Ref ref) async {
  final api = await ref.watch(dockerApiProvider.future);
  autoRefresh(ref);
  return api.getContainers();
}

@riverpod
Future<List<DockerImage>> dockerImages(Ref ref) async {
  final api = await ref.watch(dockerApiProvider.future);
  return api.getImages();
}
