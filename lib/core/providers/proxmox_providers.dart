import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/proxmox_api.dart';
import '../models/proxmox_container.dart';
import '../models/proxmox_node.dart';
import '../models/proxmox_task.dart';
import '../models/proxmox_vm.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'proxmox_providers.g.dart';

/// Thrown while Proxmox credentials have not been entered yet; the UI shows
/// a "configure in settings" state instead of an error.
class ProxmoxNotConfigured implements Exception {
  const ProxmoxNotConfigured();
}

@riverpod
Future<ProxmoxApi> proxmoxApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (!settings.isConfigured) throw const ProxmoxNotConfigured();
  return ProxmoxApi.fromSettings(settings);
}

@riverpod
Future<List<ProxmoxNode>> nodes(Ref ref) async {
  final api = await ref.watch(proxmoxApiProvider.future);
  autoRefresh(ref);
  return api.getNodes();
}

@riverpod
Future<List<ProxmoxContainer>> containers(Ref ref, String node) async {
  final api = await ref.watch(proxmoxApiProvider.future);
  autoRefresh(ref);
  return api.getContainers(node);
}

@riverpod
Future<List<ProxmoxContainer>> allContainers(Ref ref) async {
  final api = await ref.watch(proxmoxApiProvider.future);
  autoRefresh(ref);
  return api.getAllContainers();
}

@riverpod
Future<List<ProxmoxVm>> vms(Ref ref, String node) async {
  final api = await ref.watch(proxmoxApiProvider.future);
  autoRefresh(ref);
  return api.getVms(node);
}

@riverpod
Future<List<ProxmoxVm>> allVms(Ref ref) async {
  final api = await ref.watch(proxmoxApiProvider.future);
  autoRefresh(ref);
  return api.getAllVms();
}

@riverpod
Future<List<Map<String, dynamic>>> backupStorages(Ref ref, String node) async {
  final api = await ref.watch(proxmoxApiProvider.future);
  autoRefresh(ref);
  return api.getBackupStorages(node);
}

@riverpod
Future<List<Map<String, dynamic>>> backups(
  Ref ref,
  String node,
  String storage,
) async {
  final api = await ref.watch(proxmoxApiProvider.future);
  autoRefresh(ref);
  return api.getBackups(node, storage);
}

@riverpod
Future<List<Map<String, dynamic>>> backupJobs(Ref ref) async {
  final api = await ref.watch(proxmoxApiProvider.future);
  autoRefresh(ref);
  return api.getBackupJobs();
}

@riverpod
Future<List<ProxmoxTask>> recentTasks(Ref ref) async {
  final api = await ref.watch(proxmoxApiProvider.future);
  autoRefresh(ref);
  return api.getRecentTasks();
}
