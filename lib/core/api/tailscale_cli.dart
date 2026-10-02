import 'dart:convert';
import 'dart:io';

import '../models/tailscale_status.dart';

/// Thrown when the tailscale binary is missing or errors — the UI shows a
/// "not available" state instead of a stack trace.
class TailscaleUnavailable implements Exception {
  const TailscaleUnavailable(this.detail);

  final String detail;

  @override
  String toString() => detail;
}

/// Reads Tailscale state from the local CLI (`tailscale status --json`).
/// Desktop only — iOS runs Tailscale as a VPN profile with no CLI.
class TailscaleCli {
  const TailscaleCli();

  Future<TailscaleStatus> status() async {
    final ProcessResult result;
    try {
      result = await Process.run('tailscale', ['status', '--json']);
    } on ProcessException catch (e) {
      throw TailscaleUnavailable('tailscale CLI not found: ${e.message}');
    }
    if (result.exitCode != 0) {
      throw TailscaleUnavailable(
        'tailscale status failed: ${result.stderr ?? result.exitCode}',
      );
    }
    return TailscaleStatus.fromJson(
      jsonDecode(result.stdout as String) as Map<String, dynamic>,
    );
  }
}
