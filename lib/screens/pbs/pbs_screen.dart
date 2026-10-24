import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_tab.dart';
import '../../core/providers/navigation_providers.dart';
import '../../core/providers/pbs_jobs.dart';
import '../../core/providers/pbs_providers.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/hub_scaffold.dart';
import 'pbs_backups_view.dart';
import 'pbs_jobs_view.dart';
import 'pbs_overview_view.dart';
import 'pbs_tasks_view.dart';

class PbsScreen extends ConsumerWidget {
  const PbsScreen({super.key, required this.railIndex});
  final int railIndex;

  static const specs = [
    (icon: Ph.squaresFour, label: 'Overview'),
    (icon: Ph.database, label: 'Backups'),
    (icon: Ph.clockCounterClockwise, label: 'Jobs'),
    (icon: Ph.listChecks, label: 'Tasks'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pbsJobsProvider, (_, _) {
      final notifier = ref.read(pbsJobsProvider.notifier);
      final result = notifier.lastResult;
      if (result == null) return;
      notifier.clearLastResult();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '${result.label} completed'
                : '${result.label} failed: ${result.message ?? 'unknown error'}',
          ),
        ),
      );
    });
    final selected = ref.watch(selectedPbsSlotProvider);
    // Riverpod retries a failed provider and reports AsyncLoading meanwhile,
    // so match the error itself, not AsyncError.
    if (selected.error is PbsNotConfigured) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PBS is not configured — add a server and API token in Settings',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref
                  .read(selectedTabProvider.notifier)
                  .select(AppTab.settings.railIndex),
              icon: const Icon(Ph.gearSix),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
    return selected.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Failed to load PBS: $error')),
      data: (slot) => Column(
        children: [
          _ServerHeader(slot: slot),
          Expanded(
            child: HubScaffold(
              hub: AppTab.pbs,
              tabs: [
                HubTab(
                  icon: specs[0].icon,
                  label: specs[0].label,
                  child: PbsOverviewView(slot: slot),
                ),
                HubTab(
                  icon: specs[1].icon,
                  label: specs[1].label,
                  child: PbsBackupsView(slot: slot),
                ),
                HubTab(
                  icon: specs[2].icon,
                  label: specs[2].label,
                  child: PbsJobsView(slot: slot),
                ),
                HubTab(
                  icon: specs[3].icon,
                  label: specs[3].label,
                  child: PbsTasksView(slot: slot),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerHeader extends ConsumerWidget {
  const _ServerHeader({required this.slot});
  final PbsSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = {
      for (final candidate in PbsSlot.values)
        candidate: ref.watch(pbsConfigProvider(candidate)),
    };
    final available = [
      for (final entry in configs.entries)
        if (entry.value.value != null) entry.key,
    ];
    final elevated = ref.watch(pbsElevationProvider)[slot];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      child: Row(
        children: [
          if (available.isNotEmpty)
            SegmentedButton<PbsSlot>(
              segments: [
                for (final candidate in available)
                  ButtonSegment(
                    value: candidate,
                    label: Text(configs[candidate]!.value!.name),
                  ),
              ],
              selected: {slot},
              onSelectionChanged: (value) => ref
                  .read(selectedPbsSlotProvider.notifier)
                  .select(value.single),
            ),
          const Spacer(),
          ActionChip(
            avatar: Icon(
              elevated == null ? Ph.lockSimple : Ph.checkCircle,
              size: 16,
            ),
            label: Text(elevated == null ? 'Locked' : 'Unlocked'),
            onPressed: elevated == null
                ? null
                : () => ref.read(pbsElevationProvider.notifier).lock(slot),
          ),
        ],
      ),
    );
  }
}
