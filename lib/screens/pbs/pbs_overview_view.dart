import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pbs_api.dart';
import '../../core/providers/pbs_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/mechanical.dart';
import '../../core/widgets/recessed_bar.dart';
import '../../core/widgets/screen_header.dart';
import '../pdm/pdm_format.dart';
import 'pbs_actions.dart';

class PbsOverviewView extends ConsumerWidget {
  const PbsOverviewView({super.key, required this.slot});
  final PbsSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(pbsOverviewProvider(slot));
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 22, 24, 14),
          child: ScreenHeader(
            icon: Ph.squaresFour,
            title: 'Backup Server',
            subtitle: 'DATASTORE CAPACITY AND SCHEDULE HEALTH',
          ),
        ),
        Expanded(
          child: overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed to load PBS: $error')),
            data: (data) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pbsOverviewProvider(slot));
                await ref.read(pbsOverviewProvider(slot).future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                children: [
                  Text(
                    'PBS ${data.version['version'] ?? ''}',
                    style: TextStyle(color: context.brass.textMuted),
                  ),
                  const SizedBox(height: 10),
                  for (final store in data.datastores) ...[
                    _DatastoreCard(slot: slot, store: store),
                    const SizedBox(height: 12),
                  ],
                  if (data.jobs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Scheduled jobs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    BrassPanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final entry in data.jobs)
                            _JobSummary(entry: entry),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatastoreCard extends ConsumerWidget {
  const _DatastoreCard({required this.slot, required this.store});
  final PbsSlot slot;
  final PbsDatastoreUsage store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brass = context.brass;
    final fraction = store.total == 0 ? 0.0 : store.used / store.total;
    final gc = store.gcStatus ?? const <String, dynamic>{};
    return BrassPanel(
      key: ValueKey('pbs-datastore-${store.store}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Ph.database),
              const SizedBox(width: 10),
              Text(store.store, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${pdmBytes(store.used)} / ${pdmBytes(store.total)}'),
              PopupMenuButton<void>(
                itemBuilder: (context) =>
                    pbsDatastoreActions(context, ref, slot, store.store),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RecessedBar(
            fraction: fraction.clamp(0, 1).toDouble(),
            gradient: brass.loadGradient(fraction.clamp(0, 1).toDouble()),
            height: 12,
          ),
          const SizedBox(height: 8),
          Text(
            store.estimatedFullDate == null
                ? '${(fraction * 100).toStringAsFixed(1)}% used'
                : 'Estimated full ${_date(store.estimatedFullDate!)}',
            style: TextStyle(color: brass.textMuted),
          ),
          if (store.history.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(height: 54, child: _Sparkline(history: store.history)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              Text('GC: ${gc['status'] ?? gc['last-run-state'] ?? 'unknown'}'),
              if (gc['last-run-endtime'] != null)
                Text('Last: ${_date(_asInt(gc['last-run-endtime']))}'),
              if (gc['next-run'] != null)
                Text('Next: ${_date(_asInt(gc['next-run']))}'),
              if (gc['backup-count'] != null)
                Text('${gc['backup-count']} backups'),
              if (gc['group-count'] != null)
                Text('${gc['group-count']} groups'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.history});
  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < history.length; i++) {
      final value = history[i]['used'] ?? history[i]['value'];
      if (value is num) spots.add(FlSpot(i.toDouble(), value.toDouble()));
    }
    if (spots.length < 2) return const SizedBox.shrink();
    return ScopeFrame(child: LineChart(
      LineChartData(
        minX: spots.first.x,
        maxX: spots.last.x,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: false),
            color: context.brass.giltBright,
          ),
        ],
      ),
    ));
  }
}

class _JobSummary extends StatelessWidget {
  const _JobSummary({required this.entry});
  final PbsJobOverview entry;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text('${entry.job.kind} · ${entry.job.id}'),
    subtitle: Text('${entry.job.schedule}  •  ${entry.job.store}'),
    trailing: Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StateChip(entry.status.lastRunState ?? 'never'),
        Text(
          entry.status.nextRun == null
              ? 'not scheduled'
              : _date(entry.status.nextRun!),
        ),
      ],
    ),
  );
}

class _StateChip extends StatelessWidget {
  const _StateChip(this.state);
  final String state;
  @override
  Widget build(BuildContext context) {
    final ok = state == 'OK';
    final color = ok
        ? context.brass.ok
        : state == 'never'
        ? context.brass.textMuted
        : context.brass.crit;
    return Chip(
      label: Text(state),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color),
    );
  }
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
String _date(int epoch) => DateTime.fromMillisecondsSinceEpoch(
  epoch * 1000,
).toLocal().toString().substring(0, 16);
