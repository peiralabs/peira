import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_tab.dart';
import '../../core/providers/navigation_providers.dart';
import '../../core/providers/pdm_providers.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/hub_scaffold.dart';
import 'pdm_guests_view.dart';
import 'pdm_overview_view.dart';
import 'pdm_tasks_view.dart';

/// Native Proxmox Datacenter Manager hub. [railIndex] deliberately mirrors
/// the other hub constructors; Unit 3 supplies the rail destination.
class PdmScreen extends ConsumerWidget {
  const PdmScreen({super.key, required this.railIndex});

  final int railIndex;

  static const specs = [
    (icon: Ph.squaresFour, label: 'Overview'),
    (icon: Ph.hardDrives, label: 'Guests'),
    (icon: Ph.listChecks, label: 'Tasks'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(pdmApiProvider);
    // Riverpod retries a failed provider and reports AsyncLoading meanwhile,
    // so match the error itself, not AsyncError.
    if (api.error is PdmNotConfigured) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PDM is not configured — add its URL and an API token in Settings',
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
    return HubScaffold(
      hub: AppTab.pdm,
      tabs: [
        HubTab(
          icon: specs[0].icon,
          label: specs[0].label,
          child: const PdmOverviewView(),
        ),
        HubTab(
          icon: specs[1].icon,
          label: specs[1].label,
          child: const PdmGuestsView(),
        ),
        HubTab(
          icon: specs[2].icon,
          label: specs[2].label,
          child: const PdmTasksView(),
        ),
      ],
    );
  }
}
