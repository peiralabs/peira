import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pdm_api.dart';
import '../../core/providers/pdm_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/recessed_bar.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/status_light.dart';
import 'pdm_format.dart';

class PdmOverviewView extends ConsumerWidget {
  const PdmOverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(pdmOverviewProvider);
    Future<void> refresh() async {
      ref.invalidate(pdmOverviewProvider);
      await ref.read(pdmOverviewProvider.future);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
          child: ScreenHeader(
            icon: Ph.treeStructure,
            title: 'Datacenter Manager',
            subtitle: 'REMOTES · CLUSTERS · CAPACITY',
            trailing: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: refresh,
                icon: const Icon(Ph.arrowsClockwise),
              ),
            ],
          ),
        ),
        Expanded(
          child: overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _LoadError(error: error, retry: refresh),
            data: (remotes) => RefreshIndicator(
              onRefresh: refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                itemCount: remotes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, i) => _RemoteCard(overview: remotes[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RemoteCard extends StatelessWidget {
  const _RemoteCard({required this.overview});
  final PdmRemoteOverview overview;

  @override
  Widget build(BuildContext context) {
    final remote = overview.remote;
    final brass = context.brass;
    if (remote.type != 'pve') {
      return BrassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(Ph.database, color: brass.sage),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                remote.id,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text('PBS', style: TextStyle(color: brass.smallCaps)),
          ],
        ),
      );
    }
    if (overview.failed) {
      final error = overview.error;
      final message = error is PdmApiException ? error.message : '$error';
      return BrassPanel(
        borderColor: brass.crit.withValues(alpha: .55),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            const StatusLight(health: Health.crit, size: 9),
            const SizedBox(width: 12),
            Text(
              remote.id,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: brass.crit),
              ),
            ),
          ],
        ),
      );
    }

    final cluster = overview.clusterStatus!;
    final resources = overview.resources!;
    final online = resources.nodes.where((n) => n.status == 'online').toList();
    final cpuCapacity = online.fold<double>(0, (s, n) => s + n.maxcpu);
    final cpu = cpuCapacity == 0
        ? 0.0
        : online.fold<double>(0, (s, n) => s + n.cpu * n.maxcpu) / cpuCapacity;
    final mem = online.fold<int>(0, (s, n) => s + n.mem);
    final maxMem = online.fold<int>(0, (s, n) => s + n.maxmem);
    final storage = pdmStorageSummary(resources.storages);
    final guests = resources.guests.where((g) => !g.template);
    final running = guests.where((g) => g.status == 'running').length;

    return BrassPanel(
      topRule: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  remote.id,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: brass.textHeading,
                    fontFamily: context.displayFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Chip(
                label: cluster.quorate ? 'QUORATE' : 'NO QUORUM',
                color: cluster.quorate ? brass.ok : brass.crit,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 8,
            children: [
              _Stat('Nodes', '${cluster.nodesOnline}/${cluster.nodesTotal}'),
              _Stat('CPU', '${(cpu * 100).toStringAsFixed(1)}%'),
              _Stat('Memory', '${pdmBytes(mem)} / ${pdmBytes(maxMem)}'),
              if (storage.localTotal > 0)
                _Stat(
                  'Local storage',
                  '${pdmBytes(storage.localUsed)} / ${pdmBytes(storage.localTotal)}',
                ),
              _Stat(
                'Guests',
                '$running running · ${guests.length - running} stopped',
              ),
            ],
          ),
          if (storage.shared.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 22,
              runSpacing: 8,
              children: [
                for (final g in storage.shared)
                  _Stat(
                    g.names.join(' · '),
                    '${pdmBytes(g.used)} / ${pdmBytes(g.total)}',
                  ),
              ],
            ),
          ],
          if (resources.nodes.isNotEmpty) const SizedBox(height: 16),
          for (final node in resources.nodes) _NodeRow(node: node),
        ],
      ),
    );
  }
}

class _NodeRow extends StatelessWidget {
  const _NodeRow({required this.node});
  final PdmNode node;
  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final online = node.status == 'online';
    final mem = node.maxmem == 0 ? 0.0 : node.mem / node.maxmem;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          StatusLight(health: online ? Health.ok : Health.offline, size: 8),
          const SizedBox(width: 10),
          Expanded(child: Text(node.name)),
          SizedBox(
            width: 62,
            child: Text(
              online ? '${(node.cpu * 100).toStringAsFixed(1)}%' : 'offline',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: online ? brass.textBody : brass.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: RecessedBar(
              fraction: mem.clamp(0, 1),
              gradient: [brass.ram, brass.giltBright],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label  ', style: TextStyle(color: context.brass.textMuted)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      border: Border.all(color: color.withValues(alpha: .5)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11)),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Failed to load PDM: $error'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
