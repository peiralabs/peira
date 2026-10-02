import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/proxmox_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/status_light.dart';
import '../../core/widgets/task_log_tile.dart';

/// The destination behind the dashboard's "N tasks failed" attention chip:
/// every failed task in the recent cluster window with its full status text
/// and an in-app log view, so a failure is diagnosable without opening the
/// Proxmox web UI. Tiles start expanded — arriving here means something
/// already went wrong.
class FailedTasksScreen extends ConsumerWidget {
  const FailedTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brass = context.brass;
    final tasks = ref.watch(recentTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Failed tasks')),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load tasks:\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(recentTasksProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (list) {
          final failed = list.where((t) => t.isFailed).toList();
          if (failed.isEmpty) {
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StatusLight(health: Health.ok),
                  const SizedBox(width: 10),
                  Text(
                    'No failed tasks in the recent window',
                    style: TextStyle(color: brass.textMuted),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(recentTasksProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              children: [
                Text(
                  'RECENT WINDOW · ${failed.length} OF ${list.length} '
                  'CLUSTER TASKS FAILED',
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 11.5 * 0.16,
                    color: brass.smallCaps,
                  ),
                ),
                const SizedBox(height: 12),
                BrassPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    children: [
                      for (final t in failed)
                        TaskLogTile(
                          key: ValueKey(t.upid),
                          task: t,
                          initiallyExpanded: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
