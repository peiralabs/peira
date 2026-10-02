import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's bundled fonts (plus Roboto/MaterialIcons from the engine)
/// so headless renders — golden screenshots and the app-icon renderer — draw
/// with real type instead of the test fallback. Shared by every render test.
Future<void> loadRealFonts() async {
  // Derive the bundled-font dir from the running engine so goldens render with
  // real fonts regardless of where Flutter is installed (~/flutter locally,
  // /opt/flutter on node4). resolvedExecutable lives under <sdk>/bin/cache/
  // (…/artifacts/engine/… for flutter_tester, …/dart-sdk/… for dart), so we
  // anchor on the /bin/cache/ marker rather than counting path segments.
  const fallback = '/opt/flutter/bin/cache/artifacts/material_fonts';
  final exe = Platform.resolvedExecutable;
  const marker = '/bin/cache/';
  final idx = exe.indexOf(marker);
  var dir = idx == -1
      ? fallback
      : '${exe.substring(0, idx + marker.length)}artifacts/material_fonts';
  if (!Directory(dir).existsSync()) dir = fallback;
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('$dir/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);

  // The app's fonts. Variable weights render via the wght axis; the italic
  // file joins its family so ital styles resolve.
  for (final (family, files) in [
    ('Playfair Display', ['PlayfairDisplay.ttf', 'PlayfairDisplay-Italic.ttf']),
    ('EB Garamond', ['EBGaramond.ttf', 'EBGaramond-Italic.ttf']),
    ('JetBrains Mono', ['JetBrainsMono.ttf', 'JetBrainsMono-Italic.ttf']),
    ('Phosphor', ['Phosphor.ttf']),
    ('Phosphor-Bold', ['Phosphor-Bold.ttf']),
  ]) {
    final loader = FontLoader(family);
    var any = false;
    for (final file in files) {
      final f = File('assets/fonts/$file');
      if (f.existsSync()) {
        any = true;
        loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
      }
    }
    if (any) await loader.load();
  }
}
