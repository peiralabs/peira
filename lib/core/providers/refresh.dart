import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Keeps a fetch provider alive and re-runs it every 30 seconds.
void autoRefresh(Ref ref) {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), () {
    link.close();
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);
}
