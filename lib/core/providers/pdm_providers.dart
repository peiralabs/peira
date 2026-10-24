import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pdm_api.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'pdm_providers.g.dart';

/// Thrown while no PDM URL is configured — the Proxmox tab hides the panel
/// entirely rather than rendering an error.
class PdmNotConfigured implements Exception {
  const PdmNotConfigured();
}

enum PdmTaskFilter { all, failed, running }

class PdmRemoteOverview {
  const PdmRemoteOverview({
    required this.remote,
    this.clusterStatus,
    this.resources,
    this.error,
  });

  final PdmRemoteInfo remote;
  final PdmClusterStatus? clusterStatus;
  final PdmResources? resources;
  final Object? error;

  bool get failed => error != null;
}

/// Everything the Proxmox-tab PDM panel renders in one fetch: reachability,
/// then (token permitting) the remotes with their cluster state.
class PdmPanelState {
  const PdmPanelState({
    required this.reachable,
    required this.status,
    required this.tokenRejected,
  });

  final bool reachable;

  /// Null while unreachable, token-less, or rejected.
  final PdmStatus? status;

  /// The API answered 401 to the configured token.
  final bool tokenRejected;
}

@riverpod
Future<PdmApi> pdmApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (!settings.pdmConfigured || !settings.pdmTokenConfigured) {
    throw const PdmNotConfigured();
  }
  return PdmApi.fromSettings(settings);
}

@riverpod
Future<PdmPanelState> pdmPanel(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (!settings.pdmConfigured) {
    throw const PdmNotConfigured();
  }
  final api = PdmApi.fromSettings(settings);
  autoRefresh(ref);

  if (!await api.ping()) {
    return const PdmPanelState(
      reachable: false,
      status: null,
      tokenRejected: false,
    );
  }
  if (!settings.pdmTokenConfigured) {
    return const PdmPanelState(
      reachable: true,
      status: null,
      tokenRejected: false,
    );
  }
  try {
    return PdmPanelState(
      reachable: true,
      status: await api.status(),
      tokenRejected: false,
    );
  } on PdmApiException catch (e) {
    if (e.statusCode == 401) {
      return const PdmPanelState(
        reachable: true,
        status: null,
        tokenRejected: true,
      );
    }
    rethrow;
  }
}

@riverpod
Future<List<PdmRemoteOverview>> pdmOverview(Ref ref) async {
  final api = await ref.watch(pdmApiProvider.future);
  autoRefresh(ref);
  final remotes = await api.remotes();
  return Future.wait([
    for (final remote in remotes)
      () async {
        if (remote.type != 'pve') {
          return PdmRemoteOverview(remote: remote);
        }
        try {
          final results = await Future.wait<dynamic>([
            api.clusterStatus(remote.id),
            api.resources(remote.id),
          ]);
          return PdmRemoteOverview(
            remote: remote,
            clusterStatus: results[0] as PdmClusterStatus,
            resources: results[1] as PdmResources,
          );
        } catch (error) {
          return PdmRemoteOverview(remote: remote, error: error);
        }
      }(),
  ]);
}

@riverpod
Future<List<PdmTask>> pdmTasks(Ref ref, PdmTaskFilter filter) async {
  final api = await ref.watch(pdmApiProvider.future);
  autoRefresh(ref);
  final tasks = await api.tasks(
    errorsOnly: filter == PdmTaskFilter.failed,
    runningOnly: filter == PdmTaskFilter.running,
  );
  // PDM's `errors` filter also returns WARNINGS tasks, which succeeded.
  return filter == PdmTaskFilter.failed
      ? [
          for (final t in tasks)
            if (t.failed) t,
        ]
      : tasks;
}
