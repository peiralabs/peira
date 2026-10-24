import 'dart:convert';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_settings.dart';
import 'settings_repository.dart';

/// A named set of connection settings (one cluster and its services).
class ConnectionProfile {
  const ConnectionProfile({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, String> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      other is ConnectionProfile && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// The saved profiles and which one the flat settings currently hold.
class ProfileState {
  const ProfileState({required this.profiles, required this.activeId});

  /// What an install that predates profiles looks like: its existing
  /// settings are the one and only profile.
  static const legacy = ProfileState(
    profiles: [ConnectionProfile(id: ProfileStore.defaultId, name: 'Default')],
    activeId: ProfileStore.defaultId,
  );

  final List<ConnectionProfile> profiles;
  final String activeId;

  ConnectionProfile get active => profiles.firstWhere(
    (p) => p.id == activeId,
    orElse: () => profiles.first,
  );

  /// Parses the stored index; anything missing or malformed reads as [legacy]
  /// so a damaged index can never hide the operator's current settings.
  static ProfileState parse(String? index, String? activeId) {
    if (index == null || index.isEmpty) return legacy;
    try {
      final list = (jsonDecode(index) as List)
          .cast<Map<String, dynamic>>()
          .map(
            (m) => ConnectionProfile(
              id: m['id'] as String,
              name: m['name'] as String,
            ),
          )
          .toList();
      if (list.isEmpty) return legacy;
      final active = list.any((p) => p.id == activeId)
          ? activeId!
          : list.first.id;
      return ProfileState(profiles: list, activeId: active);
    } on Object {
      return legacy;
    }
  }
}

/// Named connection profiles on top of [SettingsRepository]'s flat keys.
///
/// The flat keys stay the live settings of the ACTIVE profile, so everything
/// that reads settings (and older builds of the app, and
/// `tool/reseed_keyring.py`) is unchanged. Each profile also keeps a copy of
/// its per-profile keys under `profile.<id>.<key>`; switching stashes the
/// current values into the outgoing profile and loads the incoming one's.
/// Keys in [SettingsRepository.globalKeys] are never stashed or swapped.
///
/// Nothing is written until the first mutation, so an install that never
/// touches profiles keeps exactly the keyring contents it had before.
class ProfileStore {
  ProfileStore(this._storage);

  final FlutterSecureStorage _storage;

  static const defaultId = 'default';
  static const _indexKey = 'profiles';
  static const _activeKey = 'active_profile';
  static String _stashKey(String id, String key) => 'profile.$id.$key';

  Future<Map<String, String>> _readAll() async {
    try {
      return await _storage.readAll();
    } on PlatformException catch (e) {
      SettingsRepository.translate(e);
    }
  }

  Future<void> _write(Map<String, String> values) async {
    try {
      await Future.wait([
        for (final e in values.entries)
          _storage.write(key: e.key, value: e.value),
      ]);
    } on PlatformException catch (e) {
      SettingsRepository.translate(e);
    }
  }

  Future<void> _delete(Iterable<String> keys) async {
    try {
      await Future.wait([for (final k in keys) _storage.delete(key: k)]);
    } on PlatformException catch (e) {
      SettingsRepository.translate(e);
    }
  }

  static Map<String, String> _profileKeys(AppSettings settings) => {
    for (final e in SettingsRepository.toMap(settings).entries)
      if (!SettingsRepository.globalKeys.contains(e.key)) e.key: e.value,
  };

  static Map<String, String> _indexEntries(ProfileState state) => {
    _indexKey: jsonEncode([for (final p in state.profiles) p.toJson()]),
    _activeKey: state.activeId,
  };

  Future<ProfileState> load() async {
    final values = await _readAll();
    return ProfileState.parse(values[_indexKey], values[_activeKey]);
  }

  /// Makes [targetId] the active profile: the current flat per-profile values
  /// are stashed under the outgoing profile, then replaced by the target's
  /// stash. Global keys are left alone.
  Future<ProfileState> switchTo(String targetId) async {
    final values = await _readAll();
    final state = ProfileState.parse(values[_indexKey], values[_activeKey]);
    if (!state.profiles.any((p) => p.id == targetId)) {
      throw ArgumentError.value(targetId, 'targetId', 'no such profile');
    }
    if (targetId == state.activeId) return state;

    final current = SettingsRepository.fromMap(values);
    final outgoing = _profileKeys(current);

    // Rebuild the target's settings from its stash; keys it never stored fall
    // back to the AppSettings defaults, globals come from the live values.
    final targetMap = <String, String>{
      for (final e in values.entries)
        if (SettingsRepository.globalKeys.contains(e.key)) e.key: e.value,
      for (final k in outgoing.keys) k: ?values[_stashKey(targetId, k)],
    };
    final incoming = _profileKeys(SettingsRepository.fromMap(targetMap));

    final next = ProfileState(profiles: state.profiles, activeId: targetId);
    await _write({
      for (final e in outgoing.entries)
        _stashKey(state.activeId, e.key): e.value,
      ...incoming,
      ..._indexEntries(next),
    });
    return next;
  }

  /// Adds a profile without switching to it. With [copyOf] its per-profile
  /// settings are a copy of those; otherwise it starts blank (unconfigured),
  /// so switching to it opens the setup wizard.
  Future<ProfileState> create(String name, {AppSettings? copyOf}) async {
    final values = await _readAll();
    final state = ProfileState.parse(values[_indexKey], values[_activeKey]);
    final profile = ConnectionProfile(id: _newId(state), name: name.trim());
    final next = ProfileState(
      profiles: [...state.profiles, profile],
      activeId: state.activeId,
    );
    final seeded = _profileKeys(copyOf ?? const AppSettings());
    await _write({
      for (final e in seeded.entries) _stashKey(profile.id, e.key): e.value,
      // First mutation on a legacy install: persist the active profile's
      // stash too, so the index never points at a profile with no data.
      if (values[_indexKey] == null)
        for (final e in _profileKeys(
          SettingsRepository.fromMap(values),
        ).entries)
          _stashKey(state.activeId, e.key): e.value,
      ..._indexEntries(next),
    });
    return next;
  }

  Future<ProfileState> rename(String id, String name) async {
    final state = await load();
    final next = ProfileState(
      profiles: [
        for (final p in state.profiles)
          p.id == id ? ConnectionProfile(id: id, name: name.trim()) : p,
      ],
      activeId: state.activeId,
    );
    await _write(_indexEntries(next));
    return next;
  }

  /// Removes an inactive profile and its stash. The active profile cannot be
  /// deleted (switch away first), and neither can the last one.
  Future<ProfileState> delete(String id) async {
    final values = await _readAll();
    final state = ProfileState.parse(values[_indexKey], values[_activeKey]);
    if (id == state.activeId) {
      throw StateError('cannot delete the active profile');
    }
    final next = ProfileState(
      profiles: [
        for (final p in state.profiles)
          if (p.id != id) p,
      ],
      activeId: state.activeId,
    );
    await _write(_indexEntries(next));
    await _delete([...values.keys.where((k) => k.startsWith('profile.$id.'))]);
    return next;
  }

  static String _newId(ProfileState state) {
    var n = state.profiles.length + 1;
    while (state.profiles.any((p) => p.id == 'p$n')) {
      n++;
    }
    return 'p$n';
  }
}
