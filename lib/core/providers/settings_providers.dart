import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_settings.dart';
import '../settings/settings_repository.dart';
import '../settings/settings_seed.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(const FlutterSecureStorage());

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  Future<AppSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    var settings = await repo.load();
    if (!settings.isConfigured) {
      final seeded = SettingsSeed.consume();
      if (seeded != null) {
        await repo.save(seeded);
        settings = seeded;
      }
    }
    return settings;
  }

  Future<void> save(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    state = AsyncData(settings);
  }
}
