import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/pbs_providers.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/screen_header.dart';
import 'pbs_actions.dart';

class PbsJobsView extends ConsumerWidget {
  const PbsJobsView({super.key, required this.slot});
  final PbsSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(pbsOverviewProvider(slot));
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 22, 24, 14),
          child: ScreenHeader(
            icon: Ph.clockCounterClockwise,
            title: 'Jobs',
            subtitle: 'PRUNE, VERIFY, AND SYNC SCHEDULES',
          ),
        ),
        Expanded(
          child: overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed to load jobs: $error')),
            data: (data) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              itemCount: data.jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final entry = data.jobs[index];
                final options = entry.job.raw.entries
                    .where(
                      (e) =>
                          e.key.startsWith('keep-') ||
                          const [
                            'remote',
                            'remote-store',
                            'ns',
                          ].contains(e.key),
                    )
                    .map((e) => '${e.key}=${e.value}')
                    .join(', ');
                return BrassPanel(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Ph.clockCounterClockwise),
                    title: Text('${entry.job.kind} · ${entry.job.id}'),
                    subtitle: Text(
                      '${entry.job.store}  •  ${entry.job.schedule}${options.isEmpty ? '' : '\n$options'}',
                    ),
                    isThreeLine: options.isNotEmpty,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${entry.status.lastRunState ?? 'never'}  •  ${entry.status.nextRun == null ? 'no next run' : _date(entry.status.nextRun!)}',
                        ),
                        PopupMenuButton<void>(
                          itemBuilder: (context) =>
                              pbsJobActions(context, ref, slot, entry.job),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

String _date(int epoch) => DateTime.fromMillisecondsSinceEpoch(
  epoch * 1000,
).toLocal().toString().substring(0, 16);
