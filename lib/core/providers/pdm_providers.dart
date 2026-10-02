import 'package:dio/dio.dart';
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
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      return const PdmPanelState(
        reachable: true,
        status: null,
        tokenRejected: true,
      );
    }
    rethrow;
  }
}
