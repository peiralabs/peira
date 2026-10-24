import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_providers.dart';
import '../../core/settings/profile_store.dart';
import '../../core/theme/brass.dart';
import '../../core/theme/phosphor.dart';
import 'profile_actions.dart';

/// Settings › Connection profiles: one row per saved cluster (switch, rename,
/// delete) plus "Duplicate current" and "New from setup". Theme, light/dark
/// mode, the collapsed rail and notifications are global and not part of a
/// profile.
class ConnectionProfilesPanel extends ConsumerWidget {
  const ConnectionProfilesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brass = context.brass;
    final state =
        ref.watch(profilesControllerProvider).value ?? ProfileState.legacy;
    final controller = ref.read(profilesControllerProvider.notifier);

    Future<void> run(Future<void> Function() action) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await action();
      } on Object catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Profile change failed: $e')),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in state.profiles)
            ListTile(
              key: ValueKey('profile-row-${p.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                p.id == state.activeId ? Ph.checkCircle : Ph.stack,
                size: 20,
                color: p.id == state.activeId ? brass.ok : brass.textMuted,
              ),
              title: Text(p.name),
              subtitle: p.id == state.activeId
                  ? const Text(
                      'Active: the settings below belong to this profile',
                    )
                  : null,
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (p.id != state.activeId)
                    TextButton(
                      key: ValueKey('profile-switch-${p.id}'),
                      onPressed: () => run(() => switchProfile(ref, p.id)),
                      child: const Text('Switch'),
                    ),
                  TextButton(
                    key: ValueKey('profile-rename-${p.id}'),
                    onPressed: () => run(() async {
                      final name = await promptProfileName(
                        context,
                        title: 'Rename profile',
                        initial: p.name,
                      );
                      if (name != null) await controller.rename(p.id, name);
                    }),
                    child: const Text('Rename'),
                  ),
                  if (p.id != state.activeId)
                    IconButton(
                      key: ValueKey('profile-delete-${p.id}'),
                      tooltip: 'Delete ${p.name}',
                      icon: Icon(Ph.trash, size: 18, color: brass.crit),
                      onPressed: () => run(() async {
                        if (await _confirmDelete(context, p.name)) {
                          await controller.delete(p.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('profile-duplicate'),
                icon: const Icon(Ph.copy, size: 16),
                label: const Text('Duplicate current'),
                onPressed: () => run(() async {
                  final name = await promptProfileName(
                    context,
                    title: 'Duplicate "${state.active.name}"',
                    initial: '${state.active.name} copy',
                    action: 'Create',
                  );
                  if (name == null) return;
                  final created = await controller.create(
                    name,
                    duplicate: true,
                  );
                  await switchProfile(ref, created.id);
                }),
              ),
              OutlinedButton.icon(
                key: const ValueKey('profile-new-setup'),
                icon: const Icon(Ph.plus, size: 16),
                label: const Text('New from setup'),
                onPressed: () => run(() async {
                  final name = await promptProfileName(
                    context,
                    title: 'New profile',
                    action: 'Continue to setup',
                  );
                  if (name != null) await newProfileFromSetup(ref, name);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<bool> _confirmDelete(BuildContext context, String name) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete "$name"?'),
          content: const Text(
            'Its saved URLs and tokens are removed from the keychain. '
            'The cluster itself is not touched.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('profile-delete-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}
