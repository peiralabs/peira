import 'dart:io';

/// Opens [url] in the system browser via `xdg-open` (Linux desktop). Returns
/// null on success or a human-readable error string on failure.
///
/// Only `http`/`https` URLs are handed to `xdg-open`. Some callers pass data
/// that originates off-device — e.g. an alert's triage URL comes from Grafana
/// / Prometheus annotations (`runbook_url` / `generatorUrl`) — so a value with
/// a `file:`, custom-app, or option-like (`-…`) form must never reach the
/// desktop's URL handler, where it could launch an unintended local handler.
/// Every legitimate caller opens a web page, so this is behaviour-preserving.
Future<String?> openUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return 'No URL to open.';
  final uri = Uri.tryParse(trimmed);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return 'Refusing to open a non-web URL.';
  }
  try {
    final r = await Process.run('xdg-open', [trimmed]);
    if (r.exitCode != 0) {
      return 'xdg-open failed: ${(r.stderr as String).trim()}';
    }
    return null;
  } on ProcessException catch (e) {
    return 'Could not open a browser: ${e.message}';
  }
}
