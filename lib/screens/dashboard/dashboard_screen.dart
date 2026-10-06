import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_config.dart';
import '../../core/models/grafana_alert.dart';
import '../../core/models/proxmox_node.dart';
import '../../core/models/proxmox_task.dart';
import '../../core/navigation/app_tab.dart';
import '../../core/providers/cluster_history_providers.dart';
import '../../core/providers/grafana_providers.dart';
import '../../core/providers/navigation_providers.dart';
import '../../core/providers/proxmox_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mol_motion.dart';
import '../../core/theme/phosphor.dart';
import '../../core/util/open_url.dart';
import '../../core/widgets/astrolabe.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/instrument_gauge.dart';
import '../../core/widgets/micro_spark.dart';
import '../../core/widgets/recessed_bar.dart';
import '../../core/widgets/status_light.dart';
import '../proxmox/node_detail_screen.dart';
import 'attention_strip.dart';

/// Home overview in the Brass Edition language (design §Dashboard): the
/// needs-attention banner, the grand banner with the hero astrolabe and
/// gilded stat medallions, node cards with CPU sparklines (never a ring —
/// rings read empty at idle loads), the Cluster Instruments gauge panel, and
/// the CPU trend + alert feed. Data refreshes every 30s via the providers'
/// autoRefresh.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static Health nodeHealth(ProxmoxNode n) {
    if (n.status != 'online') return Health.offline;
    final cpu = n.cpu ?? 0;
    final ram = (n.maxmem ?? 0) > 0 ? (n.mem ?? 0) / n.maxmem! : 0.0;
    return Health.fromLoad(math.max(cpu, ram).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Feed the sparkline: each time nodes refresh, record the cluster-average
    // CPU%. Runs after build, so mutating the history provider here is safe.
    ref.listen<AsyncValue<List<ProxmoxNode>>>(nodesProvider, (_, next) {
      final list = next.value;
      if (list == null || list.isEmpty) return;
      final avg =
          list.map((n) => n.cpu ?? 0).reduce((a, b) => a + b) /
          list.length *
          100;
      ref.read(clusterCpuHistoryProvider.notifier).add(avg);
      final nodeHist = ref.read(nodeCpuHistoryProvider.notifier);
      for (final n in list) {
        nodeHist.add(n.node, (n.cpu ?? 0) * 100);
      }
    });

    final nodes = ref.watch(nodesProvider);
    final containers = ref.watch(allContainersProvider);
    final alerts = ref.watch(activeAlertsProvider);
    final history = ref.watch(clusterCpuHistoryProvider);
    final nodeHistory = ref.watch(nodeCpuHistoryProvider);
    final tasks = ref.watch(recentTasksProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(nodesProvider);
        ref.invalidate(allContainersProvider);
        ref.invalidate(activeAlertsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 44),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AttentionStrip(),
                  const SizedBox(height: 22),
                  _GrandBanner(
                    nodes: nodes,
                    runningGuests: (containers.value ?? const [])
                        .where((c) => c.status == 'running')
                        .length,
                    totalGuests: (containers.value ?? const []).length,
                  ),
                  const SizedBox(height: 22),
                  const BrassSectionHeader(title: 'Nodes'),
                  const SizedBox(height: 16),
                  nodes.when(
                    loading: () => const _LoadingBlock(),
                    error: (e, _) => _NotConfiguredOrError(
                      error: e,
                      notConfiguredMessage: e is ProxmoxNotConfigured
                          ? 'Proxmox is not configured yet.\nEnter the URL and API token in Settings.'
                          : null,
                      onRetry: () => ref.invalidate(nodesProvider),
                    ),
                    data: (nodeList) => _NodeGrid(
                      nodes: nodeList,
                      histories: nodeHistory,
                      onRefresh: () => ref.invalidate(nodesProvider),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const BrassSectionHeader(title: 'Cluster Instruments'),
                  const SizedBox(height: 16),
                  nodes.maybeWhen(
                    data: (nodeList) => _InstrumentsPanel(
                      nodes: nodeList,
                      running: (containers.value ?? const [])
                          .where((c) => c.status == 'running')
                          .length,
                      total: (containers.value ?? const []).length,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final trend = _ClusterTrendCard(history: history);
                      final alertCard = _AlertsCard(
                        alerts: alerts,
                        onOpen: () => ref
                            .read(selectedTabProvider.notifier)
                            .select(AppTab.metrics.railIndex),
                        onRetry: () => ref.invalidate(activeAlertsProvider),
                      );
                      if (constraints.maxWidth >= 640) {
                        // No IntrinsicHeight — fl_chart doesn't support
                        // intrinsic sizing and would throw. Align to top.
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: trend),
                            const SizedBox(width: 16),
                            Expanded(child: alertCard),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          trend,
                          const SizedBox(height: 16),
                          alertCard,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const BrassSectionHeader(title: 'Activity'),
                  const SizedBox(height: 16),
                  _RecentTasksCard(tasks: tasks),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The grand banner: corner brackets, the hero astrolabe, cluster title +
/// enamel status plaque, and the gilded stat medallions.
class _GrandBanner extends StatelessWidget {
  const _GrandBanner({
    required this.nodes,
    required this.runningGuests,
    required this.totalGuests,
  });

  final AsyncValue<List<ProxmoxNode>> nodes;
  final int runningGuests;
  final int totalGuests;

  static const _rank = {
    Health.ok: 0,
    Health.warn: 1,
    Health.offline: 2,
    Health.crit: 3,
  };

  @override
  Widget build(BuildContext context) {
    final list = nodes.value ?? const [];
    final online = list.where((n) => n.status == 'online').length;
    final total = list.length;
    final offline = total - online;

    final worst = list
        .map(DashboardScreen.nodeHealth)
        .fold(Health.ok, (a, b) => _rank[b]! > _rank[a]! ? b : a);
    final (summary, jewel) = total == 0
        ? ('Contacting cluster…', Brass.topaz)
        : switch (worst) {
            Health.crit => ('Critical load on a node', Brass.ruby),
            Health.offline => (
              '$offline node${offline == 1 ? '' : 's'} offline',
              Brass.ruby,
            ),
            Health.warn => ('Elevated load', Brass.topaz),
            Health.ok => ('All systems nominal', Brass.emerald),
          };

    final brass = context.brass;
    final palette = _Palette.of(brass);

    return BrassPanel(
      banner: true,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
      child: Stack(
        children: [
          const CornerBrackets(),
          // Astrolabe + title on the left; the medallions pushed flush to the
          // right edge (design §Dashboard grand banner). Below ~560px of
          // content the medallions wrap under the title instead of overflowing.
          LayoutBuilder(
            builder: (context, constraints) {
              final titleBlock = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$kAppName Cluster',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: context.displayFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      height: 1.06,
                      color: brass.textHeading,
                      shadows: [
                        Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                            color: palette.bannerTitleShadow),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _EnamelPlaque(text: summary, jewel: jewel),
                ],
              );
              final medallions = total == 0
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Medallion(value: '$online/$total', label: 'Nodes'),
                        const SizedBox(width: 20),
                        _Medallion(
                            value: '$runningGuests/$totalGuests',
                            label: 'Guests'),
                      ],
                    );
              if (constraints.maxWidth >= 560) {
                return Row(
                  children: [
                    const Astrolabe(size: 120),
                    const SizedBox(width: 24),
                    Expanded(child: titleBlock),
                    if (medallions != null) ...[
                      const SizedBox(width: 24),
                      medallions,
                    ],
                  ],
                );
              }
              // Narrow: astrolabe + title on one row, medallions below.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Astrolabe(size: 120),
                      const SizedBox(width: 24),
                      Expanded(child: titleBlock),
                    ],
                  ),
                  if (medallions != null) ...[
                    const SizedBox(height: 16),
                    medallions,
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The enamel status plaque: a recessed green (or amber/ruby) enamel pill
/// with a jewel cabochon dot.
class _EnamelPlaque extends StatelessWidget {
  const _EnamelPlaque({required this.text, required this.jewel});

  final String text;
  final Jewel jewel;

  @override
  Widget build(BuildContext context) {
    final tint = jewel.mid;
    // The plaque is a dark enamel object in both modes (mapping
    // dashboard.plaque): its gradient, border, inner shadow, and text lerp
    // are shared; only the cabochon halo resolves per brightness.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF1A2A1C), tint, 0.22)!
                .withValues(alpha: 0.8),
            Color.lerp(const Color(0xFF14231A), tint, 0.12)!
                .withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000),
              offset: Offset(0, -2),
              blurRadius: 4,
              spreadRadius: -3),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: jewel.cabochon,
              boxShadow: context.brass.jewelHalo(jewel),
            ),
          ),
          const SizedBox(width: 9),
          // Flexible + ellipsis so a long status can't overflow the plaque
          // when the banner is narrow.
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14, color: Color.lerp(tint, Colors.white, 0.45)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A gilded stat medallion: 92px brass ring, dark recessed center, Playfair
/// value + small-caps label.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final palette = _Palette.of(brass);
    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: brass.brassV,
        boxShadow: [
          BoxShadow(
              color: palette.medallionShadow,
              offset: const Offset(0, 3),
              blurRadius: 7),
        ],
      ),
      // The recessed well stays dark inside the brass ring in both modes
      // (mapping dashboard.medallionCenter), so its inks are pinned, not
      // tokens — like the gauge readouts on their kept-dark faces.
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.2, -0.36),
            colors: [Color(0xFF26402A), Color(0xFF0E1A10)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: context.displayFont,
                fontWeight: FontWeight.w800,
                fontSize: 23,
                height: 1,
                color: const Color(0xFFF4EEDA), // dark textHeading, pinned
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 10 * 0.18,
                color: Color(0xFFA3B892),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive node-card grid (design: `minmax(214px, 1fr)`).
class _NodeGrid extends StatelessWidget {
  const _NodeGrid({
    required this.nodes,
    required this.histories,
    required this.onRefresh,
  });

  final List<ProxmoxNode> nodes;
  final Map<String, List<double>> histories;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols =
            (constraints.maxWidth / 230).floor().clamp(1, nodes.length.clamp(1, 4));
        final w = (constraints.maxWidth - (cols - 1) * 16) / cols;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final n in nodes)
              SizedBox(
                width: w,
                child: _NodeCard(
                  node: n,
                  cpuHistory: histories[n.node] ?? const [],
                  onRefresh: onRefresh,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A node instrument card: gilt top rule, health cabochon + Playfair name +
/// refresh, CPU LOAD readout over a sparkline, and the recessed RAM bar.
/// Design rule: sparkline, never a ring — a ring reads empty at 0–5% CPU.
class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.cpuHistory,
    required this.onRefresh,
  });

  final ProxmoxNode node;
  final List<double> cpuHistory;
  final VoidCallback onRefresh;

  static String _gb(int? bytes) =>
      ((bytes ?? 0) / (1 << 30)).round().toString();

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final palette = _Palette.of(brass);
    final health = DashboardScreen.nodeHealth(node);
    final online = node.status == 'online';
    final cpu = (node.cpu ?? 0).clamp(0.0, 1.0);
    final maxmem = node.maxmem ?? 0;
    final ramFrac =
        maxmem > 0 ? ((node.mem ?? 0) / maxmem).clamp(0.0, 1.0) : 0.0;

    return BrassPanel(
      topRule: true,
      hoverLift: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => NodeDetailScreen(node: node)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusLight(health: health, size: 9),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  node.node,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: palette.nodeName,
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onRefresh,
                  child: Icon(Ph.arrowsClockwise,
                      size: 15, color: palette.refreshIcon),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (online) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'CPU LOAD',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 12 * 0.16,
                      color: brass.smallCaps,
                    ),
                  ),
                ),
                Text(
                  '${(cpu * 100).round()}%',
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    height: 1,
                    color: brass.textHeading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: cpuHistory.length < 2
                  ? const SizedBox.expand()
                  : CustomPaint(
                      painter: MicroSpark(cpuHistory, brass.sparkGreen),
                      child: const SizedBox.expand(),
                    ),
            ),
          ] else
            SizedBox(
              height: 78,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel, color: brass.crit, size: 26),
                    const SizedBox(height: 4),
                    Text('offline', style: TextStyle(color: brass.clay)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'RAM',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 12 * 0.16,
                    color: brass.smallCaps,
                  ),
                ),
              ),
              Text(
                '${_gb(node.mem)} / ${_gb(node.maxmem)} GB',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: context.displayFont,
                  fontSize: 14,
                  color: palette.ramReadout,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RecessedBar(
            fraction: online ? ramFrac.toDouble() : 0,
            // Fixed healthy ramp; light flips it so the fill's leading edge
            // keeps contrast on the pale track (mirrors Brass.loadGradient).
            gradient: brass.isDark
                ? [brass.sparkGreenDeep, brass.sparkGreen]
                : [brass.sparkGreen, brass.sparkGreenDeep],
          ),
        ],
      ),
    );
  }
}

/// The Cluster Instruments panel: corner brackets, the italic "Cluster Load"
/// plate, and the four brass gauges with fixed per-metric colours.
class _InstrumentsPanel extends StatelessWidget {
  const _InstrumentsPanel({
    required this.nodes,
    required this.running,
    required this.total,
  });

  final List<ProxmoxNode> nodes;
  final int running;
  final int total;

  @override
  Widget build(BuildContext context) {
    final online = nodes.where((n) => n.status == 'online').toList();
    final cpu = online.isEmpty
        ? 0.0
        : (online.map((n) => n.cpu ?? 0).reduce((a, b) => a + b) /
                  online.length)
              .clamp(0.0, 1.0);
    var mem = 0, maxmem = 0, disk = 0, maxdisk = 0;
    for (final n in online) {
      mem += n.mem ?? 0;
      maxmem += n.maxmem ?? 0;
      disk += n.disk ?? 0;
      maxdisk += n.maxdisk ?? 0;
    }
    final ram = maxmem > 0 ? (mem / maxmem).clamp(0.0, 1.0) : 0.0;
    final storage = maxdisk > 0 ? (disk / maxdisk).clamp(0.0, 1.0) : 0.0;
    final ctFrac = total > 0 ? (running / total).clamp(0.0, 1.0) : 0.0;

    final brass = context.brass;
    return BrassPanel(
      banner: true,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      child: Stack(
        children: [
          const CornerBrackets(inset: 0),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GiltRule(width: 40, reverse: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Cluster Load',
                      style: TextStyle(
                        fontFamily: context.displayFont,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                        color: brass.sand,
                      ),
                    ),
                  ),
                  const GiltRule(width: 40),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                runSpacing: 16,
                children: [
                  _Instrument(
                    label: 'CPU',
                    fraction: cpu.toDouble(),
                    color: brass.gaugeCpu,
                    display: '${(cpu * 100).round()}%',
                  ),
                  _Instrument(
                    label: 'Memory',
                    fraction: ram.toDouble(),
                    color: brass.gaugeMemory,
                    display: '${(ram * 100).round()}%',
                  ),
                  _Instrument(
                    label: 'Storage',
                    fraction: storage.toDouble(),
                    color: brass.gaugeStorage,
                    display: '${(storage * 100).round()}%',
                  ),
                  _Instrument(
                    label: 'Containers',
                    fraction: ctFrac.toDouble(),
                    color: brass.gaugeContainers,
                    display: '$running/$total',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Instrument extends StatelessWidget {
  const _Instrument({
    required this.label,
    required this.fraction,
    required this.color,
    required this.display,
  });

  final String label;
  final double fraction;
  final Color color;
  final String display;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context.brass);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InstrumentGauge(
            fraction: fraction,
            color: color,
            display: display,
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              letterSpacing: 12.5 * 0.18,
              color: palette.gaugeLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClusterTrendCard extends StatelessWidget {
  const _ClusterTrendCard({required this.history});

  final List<double> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brass = context.brass;
    return BrassPanel(
      topRule: true,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cluster CPU',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: brass.sand,
                  ),
                ),
              ),
              if (history.isNotEmpty)
                Text(
                  '${history.last.round()}%',
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: brass.giltBright,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: 96, child: _spark(theme, _Palette.of(brass))),
        ],
      ),
    );
  }

  Widget _spark(ThemeData theme, _Palette palette) {
    if (history.length < 2) {
      return Center(
        child: Text(
          'Collecting trend…',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final maxY = math.max(10.0, history.reduce(math.max) * 1.25);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < history.length; i++)
                FlSpot(i.toDouble(), history[i]),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: palette.trendLine,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.trendLine.withValues(alpha: 0.4),
                  palette.trendLine.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.alerts,
    required this.onOpen,
    required this.onRetry,
  });

  final AsyncValue<List<GrafanaAlert>> alerts;
  final VoidCallback onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final palette = _Palette.of(brass);
    return BrassPanel(
      topRule: true,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: alerts.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => _NotConfiguredOrError(
          error: e,
          notConfiguredMessage: e is GrafanaNotConfigured
              ? 'Grafana is not configured yet.\nEnter the URL and API key in Settings.'
              : null,
          onRetry: onRetry,
        ),
        data: (alertList) {
          final active = alertList.where((a) => !a.isSuppressed).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Active Alerts',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: context.displayFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: brass.sand,
                      ),
                    ),
                  ),
                  _CountBadge(count: active.length),
                ],
              ),
              const SizedBox(height: 14),
              if (active.isEmpty)
                _DashedWell(
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.28, -0.4),
                            colors: [
                              brass.moss.withValues(alpha: 0.35),
                              palette.allClearEdge,
                            ],
                          ),
                          border: Border.all(color: palette.allClearBorder),
                        ),
                        child: Icon(Ph.check,
                            size: 15, color: palette.allClearIcon),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No active alerts — all quiet in the archive.',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15, color: palette.allClearText),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final a in active)
                  _AlertRow(
                    alert: a,
                    onTap: () => _triageAlert(context, a, onOpen),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Alert triage: open the alert's runbook/generator URL in the browser so the
/// operator lands on the firing query or the runbook. Falls back to the Metrics
/// tab ([onOpen]) when the alert carries no link.
Future<void> _triageAlert(
  BuildContext context,
  GrafanaAlert alert,
  VoidCallback onOpen,
) async {
  if (alert.triageUrl.isEmpty) {
    onOpen();
    return;
  }
  final err = await openUrl(alert.triageUrl);
  if (err != null) {
    onOpen();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

/// The dashed-border recessed well behind the alerts empty state.
class _DashedWell extends StatelessWidget {
  const _DashedWell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context.brass);
    return CustomPaint(
      painter: _DashedRRectPainter(palette),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: palette.dashedWellFill,
        ),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter(this.palette);

  final _Palette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(11));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = palette.dashedBorder;
    const dash = 4.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      !identical(old.palette, palette);
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final palette = _Palette.of(brass);
    final ok = count == 0;
    final tint = ok ? brass.moss : brass.madder;
    return Container(
      width: 27,
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.24, -0.4),
          colors: [
            tint.withValues(alpha: 0.3),
            // Tinted well in the dark; an 18% green wash on paper (mapping
            // dashboard.badgeOuter).
            brass.isDark
                ? const Color(0xFF2E4A30).withValues(alpha: 0.5)
                : const Color(0x2E38702E),
          ],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: context.displayFont,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: ok ? palette.badgeNumOk : palette.badgeNumAlert,
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.onTap});

  final GrafanaAlert alert;
  final VoidCallback onTap;

  static const _icons = {
    'critical': Icons.dangerous_outlined,
    'warning': Icons.warning_amber_rounded,
    'info': Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Severity → status ramp, resolved per brightness (was a static const
    // map of dark tokens).
    final brass = context.brass;
    final colors = {
      'critical': brass.crit,
      'warning': brass.warn,
      'info': brass.ram,
    };
    final color = colors[alert.severity] ?? brass.ram;
    final summary = alert.annotations['summary'];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MolRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: MolSpace.sm, horizontal: MolSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _icons[alert.severity] ?? Icons.info_outline,
              color: color,
              size: 18,
            ),
            const SizedBox(width: MolSpace.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (summary != null)
                    Text(
                      summary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _NotConfiguredOrError extends StatelessWidget {
  const _NotConfiguredOrError({
    required this.error,
    required this.notConfiguredMessage,
    required this.onRetry,
  });

  final Object error;
  final String? notConfiguredMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (notConfiguredMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: MolSpace.sm),
        child: Text(notConfiguredMessage!),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MolSpace.sm),
      child: Row(
        children: [
          Expanded(child: Text('Failed to load: $error')),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Most recent cluster tasks (start/stop/migrate/backup ...), newest first.
class _RecentTasksCard extends StatelessWidget {
  const _RecentTasksCard({required this.tasks});

  final AsyncValue<List<ProxmoxTask>> tasks;

  static String _rel(int startEpoch) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final d = now - startEpoch;
    if (d < 60) return '${d}s ago';
    if (d < 3600) return '${d ~/ 60}m ago';
    if (d < 86400) return '${d ~/ 3600}h ago';
    return '${d ~/ 86400}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrassPanel(
      topRule: true,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Tasks',
            style: TextStyle(
              fontFamily: context.displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: context.brass.sand,
            ),
          ),
          const SizedBox(height: MolSpace.sm),
          tasks.when(
            loading: () => const _LoadingBlock(),
            error: (e, _) => e is ProxmoxNotConfigured
                ? const SizedBox.shrink()
                : Text(
                    'Failed to load tasks: $e',
                    style: theme.textTheme.bodySmall,
                  ),
            data: (list) {
              if (list.isEmpty) {
                return Text(
                  'No recent tasks',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return Column(
                children: [
                  for (final t in list.take(6)) _TaskRow(task: t),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final ProxmoxTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final health = task.isRunning
        ? Health.warn
        : task.isOk
            ? Health.ok
            : task.hasWarnings
                ? Health.warn
                : Health.crit;
    // Health.color is the static dark ramp; resolve through brass so the
    // status text follows brightness.
    final brass = context.brass;
    final color = switch (health) {
      Health.ok => brass.ok,
      Health.warn => brass.warn,
      Health.crit => brass.crit,
      Health.offline => const Color(0xFF6B6B7A), // shared offline grey
    };
    final label = [task.type, if (task.id != null) task.id].join(' ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MolSpace.sm - 2),
      child: Row(
        children: [
          StatusLight(health: health, size: 8),
          const SizedBox(width: MolSpace.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${task.node}  ·  ${_RecentTasksCard._rel(task.starttime)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Failed tasks carry their whole command line in `status`; cap it so
          // one long error can't take over the row (full text via tooltip).
          Tooltip(
            message: task.isRunning ? 'running' : (task.status ?? '—'),
            waitDuration: const Duration(milliseconds: 400),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                task.isRunning ? 'running' : (task.status ?? '—'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashboard-local colours that differ by brightness (the `dashboard.*`
/// family in the light mapping). Dark values are verbatim from the dark-only
/// era; the instances are canonical consts, so the dashed-well painter can use
/// `identical(old.palette, palette)` as an exact repaint check.
class _Palette {
  const _Palette({
    required this.bannerTitleShadow,
    required this.medallionShadow,
    required this.nodeName,
    required this.refreshIcon,
    required this.ramReadout,
    required this.gaugeLabel,
    required this.trendLine,
    required this.allClearEdge,
    required this.allClearBorder,
    required this.allClearIcon,
    required this.allClearText,
    required this.dashedWellFill,
    required this.dashedBorder,
    required this.badgeNumOk,
    required this.badgeNumAlert,
  });

  static const dark = _Palette(
    bannerTitleShadow: Color(0x80000000),
    medallionShadow: Color(0x80000000),
    nodeName: Color(0xFFF2ECD6),
    refreshIcon: Color(0xFF8BA079),
    ramReadout: Color(0xFFD9E0CC),
    gaugeLabel: Color(0xFFAEBD9C),
    trendLine: Color(0xFF9FC873),
    allClearEdge: Color(0x991C3220),
    allClearBorder: Color(0x807BB26A),
    allClearIcon: Color(0xFFA9E099),
    allClearText: Color(0xFFBCCAA9),
    dashedWellFill: Color(0x73091009),
    dashedBorder: Color(0x47C9AA58),
    badgeNumOk: Color(0xFFCFE0BF),
    badgeNumAlert: Color(0xFFF2CABF),
  );

  /// Black shadows become umber ink / warm-white letterpress, pale sage inks
  /// darken to their light-ramp equivalents, and the recessed wells become
  /// tinted paper washes.
  static const light = _Palette(
    bannerTitleShadow: Color(0x66FFFBEE),
    medallionShadow: Color(0x33352511),
    nodeName: Color(0xFF2E3324),
    refreshIcon: Color(0xFF5F6E50),
    ramReadout: Color(0xFF3E4A36),
    gaugeLabel: Color(0xFF4A5C3E),
    trendLine: Color(0xFF4F8A45),
    allClearEdge: Color(0x3338702E),
    allClearBorder: Color(0x8C38702E),
    allClearIcon: Color(0xFF2C5222),
    allClearText: Color(0xFF4F5C44),
    dashedWellFill: Color(0x2946381F),
    dashedBorder: Color(0x596E5220),
    badgeNumOk: Color(0xFF2C5222),
    badgeNumAlert: Color(0xFF7A241A),
  );

  static _Palette of(Brass brass) => brass.isDark ? dark : light;

  final Color bannerTitleShadow;
  final Color medallionShadow;
  final Color nodeName;
  final Color refreshIcon;
  final Color ramReadout;
  final Color gaugeLabel;
  final Color trendLine;
  final Color allClearEdge;
  final Color allClearBorder;
  final Color allClearIcon;
  final Color allClearText;
  final Color dashedWellFill;
  final Color dashedBorder;
  final Color badgeNumOk;
  final Color badgeNumAlert;
}
