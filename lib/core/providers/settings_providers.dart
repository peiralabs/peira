import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_settings.dart';
import '../settings/profile_store.dart';
import '../settings/settings_repository.dart';
import '../settings/settings_seed.dart';
import 'cluster_history_providers.dart';

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
    // A setup file dropped next to the app configures it at launch, first
    // run or not; its keys overwrite, everything else is kept.
    final seeded = SettingsSeed.consume(settings);
    if (seeded != null) {
      await repo.save(seeded.settings);
      settings = seeded.settings;
    }
    return settings;
  }

  Future<void> save(AppSettings settings) async {
    // Mid-switch, callers that copyWith() from `.value` hold the outgoing
    // profile's settings; writing them would land in the incoming profile's
    // live keys and be stashed over it on the next switch.
    if (state.isLoading) return;
    await ref.read(settingsRepositoryProvider).save(settings);
    state = AsyncData(settings);
  }
}

@Riverpod(keepAlive: true)
ProfileStore profileStore(Ref ref) =>
    ProfileStore(const FlutterSecureStorage());

/// Saved connection profiles and the active one. Switching rewrites the live
/// settings, so every settings-derived provider (API clients, data) rebuilds
/// against the new cluster; per-cluster history caches are reset here.
@Riverpod(keepAlive: true)
class ProfilesController extends _$ProfilesController {
  @override
  Future<ProfileState> build() => ref.watch(profileStoreProvider).load();

  ProfileStore get _store => ref.read(profileStoreProvider);

  Future<void> switchTo(String id) async {
    final next = await _store.switchTo(id);
    ref.invalidate(clusterCpuHistoryProvider);
    ref.invalidate(nodeCpuHistoryProvider);
    ref.invalidate(settingsControllerProvider);
    state = AsyncData(next);
  }

  /// Adds a profile (a copy of the active one when [duplicate]) and returns it.
  Future<ConnectionProfile> create(
    String name, {
    required bool duplicate,
  }) async {
    final copy = duplicate
        ? await ref.read(settingsControllerProvider.future)
        : null;
    final next = await _store.create(name, copyOf: copy);
    state = AsyncData(next);
    return next.profiles.last;
  }

  Future<void> rename(String id, String name) async {
    state = AsyncData(await _store.rename(id, name));
  }

  Future<void> delete(String id) async {
    state = AsyncData(await _store.delete(id));
  }
}
