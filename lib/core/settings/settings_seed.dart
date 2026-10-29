import 'dart:convert';
import 'dart:io';

import '../models/app_settings.dart';
import 'settings_repository.dart';

/// The result of reading a setup file: the merged settings plus any keys the
/// file carried that the app does not know (typos, or a newer template).
typedef SetupImport = ({AppSettings settings, List<String> unknownKeys});

/// Setup files: a JSON object whose keys are the settings' storage keys
/// (`docs/setup-file.md`, template `setup/setup.example.json`). Used two ways:
///
/// * dropped at `$XDG_CONFIG_HOME/peira/seed.json` on desktop, it is
///   imported at launch and then deleted, so credentials never linger in a
///   plain file;
/// * pasted into Settings › Import setup file, on any platform.
///
/// External tooling cannot write flutter_secure_storage's keyring item
/// directly — the Linux plugin registers its libsecret schema name from a
/// dangling pointer (setLabel() replaces the string the schema points into),
/// so the runtime schema name is not reproducible outside the process. A
/// file the app imports itself sidesteps that entirely.
class SettingsSeed {
  /// Keys the file sets overwrite [current]; keys it leaves out keep their
  /// current value. Blank strings and nulls are treated as "leave out", so a
  /// half-filled template never wipes a configured field. Throws
  /// [FormatException] when [source] is not a JSON object.
  static SetupImport apply(AppSettings current, String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('A setup file is one JSON object.');
    }
    final known = SettingsRepository.toMap(current);
    final merged = Map<String, String>.of(known);
    final unknown = <String>[];
    decoded.forEach((key, value) {
      if (key is! String || key.startsWith('_')) return; // `_comment` etc.
      if (!known.containsKey(key)) {
        unknown.add(key);
        return;
      }
      if (value == null) return;
      final text = value is String ? value.trim() : value.toString();
      if (text.isEmpty) return;
      merged[key] = text;
    });
    return (settings: SettingsRepository.fromMap(merged), unknownKeys: unknown);
  }

  /// Reads, merges and deletes the desktop seed file. Null when there is no
  /// file or it is malformed (a malformed file is still deleted).
  static SetupImport? consume(AppSettings current, {String? configDir}) {
    if (!Platform.isLinux) return null;
    final dir =
        configDir ??
        Platform.environment['XDG_CONFIG_HOME'] ??
        '${Platform.environment['HOME']}/.config';
    final file = File('$dir/peira/seed.json');
    if (!file.existsSync()) return null;
    try {
      return apply(current, file.readAsStringSync());
    } on Object {
      return null;
    } finally {
      try {
        file.deleteSync();
      } on Object {
        // Best effort — the file may already be gone.
      }
    }
  }
}
