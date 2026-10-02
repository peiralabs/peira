import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Outcome of poking a Proxmox API with candidate credentials.
sealed class ProbeResult {
  const ProbeResult();
}

class ProbeSuccess extends ProbeResult {
  const ProbeSuccess({required this.version, required this.nodes});

  /// pve-manager version, e.g. "8.2.4".
  final String version;
  final List<String> nodes;
}

class ProbeFailure extends ProbeResult {
  const ProbeFailure(this.message);
  final String message;
}

typedef SetupProbe = Future<ProbeResult> Function({
  required String url,
  required String tokenId,
  required String tokenSecret,
  required bool trustSelfSigned,
});

/// Seam for tests: the wizard reads its probe from here so widget tests can
/// answer without a network.
final setupProbeProvider = Provider<SetupProbe>((ref) => probeProxmox);

/// GET `/version` (authenticates the token) then `/nodes` (proves Sys.Audit
/// and feeds the "found N nodes" confirmation). Mirrors
/// `ProxmoxApi.fromSettings`'s transport, including the host-scoped
/// self-signed exception, but with tight fail-fast timeouts — this runs
/// while someone watches a button spinner.
Future<ProbeResult> probeProxmox({
  required String url,
  required String tokenId,
  required String tokenSecret,
  required bool trustSelfSigned,
  HttpClientAdapter? adapter, // tests only
}) async {
  final host = Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) {
    return const ProbeFailure(
        'Enter the full URL, e.g. https://10.0.0.5:8006');
  }
  final dio = Dio(BaseOptions(
    baseUrl: '$url/api2/json',
    headers: {'Authorization': 'PVEAPIToken=$tokenId=$tokenSecret'},
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));
  if (adapter != null) {
    dio.httpClientAdapter = adapter;
  } else if (trustSelfSigned) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback = (cert, h, port) => h == host,
    );
  }
  try {
    final version = await dio.get<Map<String, dynamic>>('/version');
    final v =
        (version.data?['data'] as Map<String, dynamic>?)?['version'] ?? '?';
    final nodesRes = await dio.get<Map<String, dynamic>>('/nodes');
    final nodes = [
      for (final n in (nodesRes.data?['data'] as List? ?? const []))
        if (n is Map && n['node'] is String) n['node'] as String,
    ]..sort();
    return ProbeSuccess(version: '$v', nodes: nodes);
  } on DioException catch (e) {
    return ProbeFailure(_explain(e, host));
  } finally {
    dio.close();
  }
}

String _explain(DioException e, String host) {
  final code = e.response?.statusCode;
  if (code == 401) {
    return 'Proxmox rejected the token. Check the token ID '
        '(user@realm!name) and the secret — and that the token has not '
        'expired.';
  }
  if (code == 403) {
    return 'The token authenticated but lacks privileges. Grant at least '
        'PVEAuditor on / — the command below does exactly that.';
  }
  return switch (e.type) {
    DioExceptionType.badCertificate =>
      'The TLS certificate was rejected. Proxmox ships self-signed — '
          'enable "Trust this host\'s certificate" below, or install a '
          'real certificate on the node.',
    DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
      'Timed out reaching $host. Host down, wrong address, or a firewall '
          'in the way.',
    DioExceptionType.connectionError =>
      'Nothing answered at $host. Check the address and port — the '
          'Proxmox web UI and API listen on 8006 by default.',
    _ => 'Connection failed: ${e.message}',
  };
}
