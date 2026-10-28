import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/searxng_api.dart';
import 'settings_providers.dart';

part 'searxng_providers.g.dart';

class SearxngNotConfigured implements Exception {
  const SearxngNotConfigured();
}

@riverpod
Future<SearxngApi> searxngApi(Ref ref) async {
  final s = await ref.watch(settingsControllerProvider.future);
  if (!s.searxngConfigured) throw const SearxngNotConfigured();
  return SearxngApi.fromSettings(
    url: s.searxngUrl,
    trustSelfSigned: s.trustSelfSigned,
  );
}

/// Categories, engines and locales the instance offers.
@riverpod
Future<SearxConfig> searxConfig(Ref ref) async =>
    (await ref.watch(searxngApiProvider.future)).config();
