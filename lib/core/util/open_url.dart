import 'dart:io';

/// Opens [url] in the system browser via `xdg-open` (Linux desktop). Returns
/// null on success or a human-readable error string on failure.
Future<String?> openUrl(String url) async {
  if (url.trim().isEmpty) return 'No URL to open.';
  try {
    final r = await Process.run('xdg-open', [url]);
    if (r.exitCode != 0) {
      return 'xdg-open failed: ${(r.stderr as String).trim()}';
    }
    return null;
  } on ProcessException catch (e) {
    return 'Could not open a browser: ${e.message}';
  }
}
