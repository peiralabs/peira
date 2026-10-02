import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/prometheus_api.dart';
import '../../core/api/twin_api.dart';
import '../../core/build_config.dart';
import '../../core/providers/metrics_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mol_motion.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/recessed_bar.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/status_light.dart';
import '../media/media_common.dart' show formatBytes;

/// Native cluster metrics in the Brass Edition language (design §3): brass
/// screen header + gilt divider, telemetry cards with series-tinted top rules
/// and big Playfair readouts, straight from Prometheus. Six panels (CPU,
/// memory, root disk, network in, temperature, top guests), one line per
/// node, with a trailing-window selector — plus an AI-telemetry section
/// (spend/quota strip + token and latency charts) fed by the ai_* exporters.
class MetricsScreen extends ConsumerWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(clusterMetricsProvider);
    final insights = ref.watch(metricsInsightsProvider);
    final range = ref.watch(selectedMetricsRangeProvider);
    final power = ref.watch(powerMetricsProvider);
    final pal = _MetricsPalette.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clusterMetricsProvider);
        ref.invalidate(metricsInsightsProvider);
        ref.invalidate(powerMetricsProvider);
        ref.invalidate(smartHealthProvider);
        if (!kPublicBuild) {
          ref.invalidate(aiMetricsProvider);
          ref.invalidate(twinDataProvider);
          ref.invalidate(wanMetricsProvider);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
        children: [
          ScreenHeader(
            icon: Ph.chartLineUp,
            title: 'Metrics',
            subtitle: 'CLUSTER TELEMETRY · LAST ${range.label.toUpperCase()}',
            trailing: [
              const SizedBox(width: 12),
              for (final r in MetricsRange.values)
                Padding(
                  padding: const EdgeInsets.only(left: MolSpace.sm),
                  child: _RangeChip(
                    label: r.label,
                    selected: r == range,
                    onTap: () => ref
                        .read(selectedMetricsRangeProvider.notifier)
                        .select(r),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionDivider(),
          const SizedBox(height: MolSpace.lg),
          if (insights.value case final ins?) ...[
            _HealthStrip(insights: ins),
            const SizedBox(height: MolSpace.md),
          ],
          metrics.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorState(
              error: e,
              onRetry: () => ref.invalidate(clusterMetricsProvider),
            ),
            data: (m) => LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth >= 760;
                final panels = [
                  _MetricPanel(
                    title: 'CPU',
                    accent: pal.accentCpu,
                    series: m.cpu,
                    maxY: 100,
                    format: _pct,
                  ),
                  _MetricPanel(
                    title: 'Memory',
                    accent: pal.accentMemory,
                    series: m.memory,
                    maxY: 100,
                    format: _pct,
                  ),
                  _MetricPanel(
                    title: 'Root disk',
                    accent: pal.accentDisk,
                    series: m.disk,
                    maxY: 100,
                    format: _pct,
                  ),
                  _MetricPanel(
                    title: 'Network in',
                    accent: pal.accentNetwork,
                    series: m.network,
                    format: (v) => '${formatBytes(v)}/s',
                  ),
                  _MetricPanel(
                    title: 'Temperature',
                    accent: pal.accentTemp,
                    series: m.temps,
                    format: (v) => '${v.toStringAsFixed(0)}°C',
                    warnAt: 80,
                  ),
                  if (insights.value case final ins?)
                    _TopGuestsPanel(guests: ins.topGuests)
                  else
                    const SizedBox.shrink(),
                ];
                if (!twoCol) {
                  return Column(
                    children: [
                      for (final p in panels)
                        Padding(
                          padding: const EdgeInsets.only(bottom: MolSpace.md),
                          child: p,
                        ),
                    ],
                  );
                }
                Widget row(Widget a, Widget b) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: a),
                    const SizedBox(width: MolSpace.md),
                    Expanded(child: b),
                  ],
                );
                return Column(
                  children: [
                    row(panels[0], panels[1]),
                    const SizedBox(height: MolSpace.md),
                    row(panels[2], panels[3]),
                    const SizedBox(height: MolSpace.md),
                    row(panels[4], panels[5]),
                  ],
                );
              },
            ),
          ),
          // Personal build only: AI telemetry is fed by the `ai_*` exporters,
          // which no external user has.
          if (!kPublicBuild) ...[
            const SizedBox(height: MolSpace.xl),
            const BrassSectionHeader(title: 'AI telemetry'),
            const SizedBox(height: MolSpace.md),
            ref.watch(aiMetricsProvider).when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  // The not-configured case is already explained by the
                  // cluster block's full error state above — don't repeat it.
                  error: (e, _) => e is PrometheusNotConfigured
                      ? const SizedBox.shrink()
                      : _AiUnavailable(
                          onRetry: () => ref.invalidate(aiMetricsProvider),
                        ),
                  // Empty results with a healthy Prometheus mean the ai_*
                  // exporters themselves are gone — say so instead of a
                  // reassuring $0.00 strip.
                  data: (a) => a.isEmpty
                      ? _AiUnavailable(
                          onRetry: () => ref.invalidate(aiMetricsProvider),
                        )
                      : _AiSection(ai: a, rangeLabel: range.label),
                ),
          ],
          const SizedBox(height: MolSpace.xl),
          const BrassSectionHeader(title: 'Power & cost'),
          const SizedBox(height: MolSpace.md),
          power.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            // Not-configured is already explained by the cluster block above.
            error: (e, _) => e is PrometheusNotConfigured
                ? const SizedBox.shrink()
                : _PowerUnavailable(
                    onRetry: () => ref.invalidate(powerMetricsProvider),
                  ),
            // Empty results with a healthy Prometheus mean the NUT exporter
            // itself is gone — say so instead of a misleading 0 W / $0.00.
            data: (p) => p.isEmpty
                ? _PowerUnavailable(
                    onRetry: () => ref.invalidate(powerMetricsProvider),
                  )
                : _PowerSection(power: p),
          ),
          // Both builds: smartctl_exporter is standard homelab kit; the
          // queries are job-agnostic over the smartctl_device_* family.
          const SizedBox(height: MolSpace.xl),
          const BrassSectionHeader(title: 'Disk health'),
          const SizedBox(height: MolSpace.md),
          ref.watch(smartHealthProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                // Not-configured is already explained by the cluster block.
                error: (e, _) => e is PrometheusNotConfigured
                    ? const SizedBox.shrink()
                    : _SmartUnavailable(
                        onRetry: () => ref.invalidate(smartHealthProvider),
                      ),
                // Empty results with a healthy Prometheus mean no smartctl
                // exporter is scraped or pushed — say so.
                data: (s) => s.isEmpty
                    ? _SmartUnavailable(
                        onRetry: () => ref.invalidate(smartHealthProvider),
                      )
                    : _SmartSection(smart: s),
              ),
          // Personal build only: the WAN/offsite pipeline is fed by
          // self-authored pushers (speedtest, NAS net-stats, offsite write
          // probe, tailscale-path exporter) no external user runs.
          if (!kPublicBuild) ...[
            const SizedBox(height: MolSpace.xl),
            const BrassSectionHeader(title: 'WAN & offsite path'),
            const SizedBox(height: MolSpace.md),
            ref.watch(wanMetricsProvider).when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  // Not-configured is explained by the cluster block.
                  error: (e, _) => e is PrometheusNotConfigured
                      ? const SizedBox.shrink()
                      : _WanUnavailable(
                          onRetry: () => ref.invalidate(wanMetricsProvider),
                        ),
                  data: (wanData) => wanData.isEmpty
                      ? _WanUnavailable(
                          onRetry: () => ref.invalidate(wanMetricsProvider),
                        )
                      : _WanSection(wan: wanData, rangeLabel: range.label),
                ),
          ],
          // Personal build only: the What-if planner is served by the
          // homelab-twin simulator, which no external user runs.
          if (!kPublicBuild) ...[
            const SizedBox(height: MolSpace.xl),
            const BrassSectionHeader(title: 'What-if planner'),
            const SizedBox(height: MolSpace.md),
            ref.watch(twinDataProvider).when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  // Not-configured is already explained by the cluster block.
                  error: (e, _) => e is PrometheusNotConfigured
                      ? const SizedBox.shrink()
                      : _TwinUnavailable(
                          onRetry: () => ref.invalidate(twinDataProvider),
                        ),
                  data: (t) => _TwinSection(twin: t),
                ),
          ],
        ],
      ),
    );
  }

  static String _pct(double v) => '${v.toStringAsFixed(0)}%';
}

/// Range selector pill: gilt when selected, hairline otherwise.
class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? pal.chipSelectedBg : Colors.transparent,
            border: Border.all(
              color: selected ? pal.chipSelectedBorder : brass.hairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? pal.chipSelectedText : pal.chipIdleText,
            ),
          ),
        ),
      ),
    );
  }
}

/// One telemetry card: series-tinted top rule, Playfair title, big latest
/// readout, and the per-node multi-line history chart.
class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.title,
    required this.accent,
    required this.series,
    required this.format,
    this.maxY,
    this.warnAt,
    this.sumLatest = false,
  });

  final String title;
  final Color accent;
  final List<MetricSeries> series;
  final String Function(double) format;
  final double? maxY;

  /// Draws a dashed warn line at this y-value (e.g. 80°C).
  final double? warnAt;

  /// Big readout = sum of the series' last points instead of their max —
  /// for panels whose headline reads as a total (AI tokens), not as the
  /// hottest node.
  final bool sumLatest;

  /// Per-node line shades of this panel's series colour.
  Color _colorFor(Brass brass, int i) => brass.shade(accent, i);

  /// Splits "42%" / "6.1 MB/s" / "75°C" into value + unit.
  static (String, String) _split(String s) {
    var i = 0;
    while (i < s.length &&
        (s.codeUnitAt(i) >= 0x30 && s.codeUnitAt(i) <= 0x39 ||
            s[i] == '.' ||
            s[i] == '-')) {
      i++;
    }
    return (s.substring(0, i), s.substring(i).trimLeft());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    // Latest values for the readout; auto y-max for unbounded panels.
    var top = 0.0;
    for (final s in series) {
      for (final p in s.points) {
        if (p.$2 > top) top = p.$2;
      }
    }
    var yMax = maxY ?? (top <= 0 ? 1.0 : top * 1.2);
    if (warnAt != null && yMax < warnAt! * 1.1) yMax = warnAt! * 1.1;

    final latest = series.isEmpty
        ? null
        : series
              .map((s) => s.points.isEmpty ? 0.0 : s.points.last.$2)
              .reduce((a, b) => sumLatest ? a + b : (a > b ? a : b));

    return BrassPanel(
      topRule: true,
      topRuleColor: accent,
      padding: const EdgeInsets.fromLTRB(
        MolSpace.lg,
        MolSpace.md + 4,
        MolSpace.lg,
        MolSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: brass.sand,
            ),
          ),
          if (latest != null) ...[
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final (value, unit) = _split(format(latest));
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                          height: 1,
                          color: brass.textHeading,
                        ),
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(fontSize: 16, color: pal.unitText),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: MolSpace.md),
          SizedBox(
            height: 150,
            child: series.isEmpty
                ? Center(
                    child: Text(
                      'No data',
                      style: TextStyle(color: brass.textMuted),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: yMax,
                      // Hover crosshair + tooltip: node name and value, in the
                      // brass language.
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => pal.tooltipBg,
                          tooltipBorder: BorderSide(
                            color: accent.withValues(alpha: 0.5),
                            width: 0.7,
                          ),
                          getTooltipItems: (spots) => [
                            for (final t in spots)
                              LineTooltipItem(
                                '${series[t.barIndex].label}  '
                                '${format(t.y)}',
                                TextStyle(
                                  color: pal.tooltipText,
                                  fontSize: 11,
                                  fontWeight:
                                      t.barIndex ==
                                          (spots.isEmpty
                                              ? 0
                                              : spots.first.barIndex)
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                      ),
                      extraLinesData: warnAt == null
                          ? const ExtraLinesData()
                          : ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: warnAt!,
                                  color: brass.ochre.withValues(alpha: 0.55),
                                  strokeWidth: 1,
                                  dashArray: const [6, 4],
                                ),
                              ],
                            ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: yMax / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        bottomTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 46,
                            interval: yMax / 2,
                            getTitlesWidget: (v, _) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                format(v),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  // Muted ink washed out at this size on
                                  // parchment; body ink in light, dark
                                  // unchanged.
                                  color: brass.isDark
                                      ? brass.textMuted
                                      : brass.textBody,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        for (final e in series.asMap().entries)
                          LineChartBarData(
                            spots: [
                              for (final p in e.value.points)
                                FlSpot(p.$1, p.$2),
                            ],
                            barWidth: 1.6,
                            dotData: const FlDotData(show: false),
                            color: _colorFor(brass, e.key),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _colorFor(
                                    brass,
                                    e.key,
                                  ).withValues(alpha: 0.16),
                                  _colorFor(brass, e.key).withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    duration: Duration.zero,
                  ),
          ),
          const SizedBox(height: MolSpace.sm),
          Wrap(
            spacing: MolSpace.md,
            runSpacing: 4,
            children: [
              for (final e in series.asMap().entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _colorFor(brass, e.key),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      e.value.label,
                      style: TextStyle(fontSize: 11, color: brass.textMuted),
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

/// Exporter health + disk runway in one slim glance row.
class _HealthStrip extends StatelessWidget {
  const _HealthStrip({required this.insights});

  final MetricsInsights insights;

  @override
  Widget build(BuildContext context) {
    final pal = _MetricsPalette.of(context);
    final allUp = insights.targetsUp == insights.targetsTotal;

    // Worst disk runway across nodes; > 1 year reads as "no risk".
    String runwayText;
    Health runwayHealth;
    if (insights.diskRunwayDays.isEmpty) {
      runwayText = 'disk trend unavailable';
      runwayHealth = Health.offline;
    } else {
      final worst = insights.diskRunwayDays.entries.reduce(
        (a, b) => a.value < b.value ? a : b,
      );
      if (worst.value > 365) {
        runwayText = 'no disk-full risk in the next year';
        runwayHealth = Health.ok;
      } else {
        runwayText =
            'root disk full in ~${worst.value.round()}d (${worst.key})';
        runwayHealth = worst.value < 14
            ? Health.crit
            : (worst.value < 45 ? Health.warn : Health.ok);
      }
    }

    Widget item(Health h, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusLight(health: h, size: 8),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: pal.healthStrip)),
      ],
    );

    return BrassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.lg,
        vertical: MolSpace.md,
      ),
      child: Wrap(
        spacing: MolSpace.xl,
        runSpacing: MolSpace.sm,
        children: [
          item(
            allUp ? Health.ok : Health.crit,
            '${insights.targetsUp}/${insights.targetsTotal} '
            'exporters reporting',
          ),
          item(runwayHealth, runwayText),
        ],
      ),
    );
  }
}

/// The guests actually consuming the cluster right now: top 5 by CPU with
/// CPU/RAM bars — the "what is eating the lab" panel.
class _TopGuestsPanel extends StatelessWidget {
  const _TopGuestsPanel({required this.guests});

  final List<GuestLoad> guests;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return BrassPanel(
      topRule: true,
      padding: const EdgeInsets.fromLTRB(
        MolSpace.lg,
        MolSpace.md + 4,
        MolSpace.lg,
        MolSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top guests',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: brass.sand,
            ),
          ),
          const SizedBox(height: MolSpace.md),
          if (guests.isEmpty)
            Text(
              'No guest metrics. This panel needs prometheus-pve-exporter — '
              'an optional install, separate from node_exporter. The rest of '
              'the Metrics tab works without it.',
              style: TextStyle(color: brass.textMuted),
            )
          else
            for (final g in guests)
              Padding(
                padding: const EdgeInsets.only(bottom: MolSpace.sm + 2),
                child: _GuestRow(guest: g),
              ),
        ],
      ),
    );
  }
}

class _GuestRow extends StatelessWidget {
  const _GuestRow({required this.guest});

  final GuestLoad guest;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    Widget bar(String label, double pct, List<Color> gradient) => Expanded(
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 10 * 0.14,
                color: brass.smallCaps,
              ),
            ),
          ),
          Expanded(
            child: RecessedBar(
              height: 7,
              fraction: (pct / 100).clamp(0.0, 1.0),
              gradient: gradient,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            child: Text(
              '${pct.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 12.5,
                color: pal.guestPct,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                guest.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: pal.guestName,
                ),
              ),
            ),
            Text(
              '${guest.id}  ·  ${guest.node}',
              style: TextStyle(fontSize: 11, color: brass.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            bar('CPU', guest.cpuPct, [brass.sparkGreenDeep, brass.sparkGreen]),
            const SizedBox(width: MolSpace.md),
            bar('RAM', guest.memPct, [
              pal.guestRamBarStart,
              pal.guestRamBarEnd,
            ]),
          ],
        ),
      ],
    );
  }
}

/// AI backend telemetry: spend/quota strip plus token and latency charts —
/// which model the lab is leaning on, what it costs, and whether the
/// fallback chain is firing.
class _AiSection extends StatelessWidget {
  const _AiSection({required this.ai, required this.rangeLabel});

  final AiMetrics ai;
  final String rangeLabel;

  static String _usd(double v) =>
      v >= 100 ? '\$${v.toStringAsFixed(0)}' : '\$${v.toStringAsFixed(2)}';

  /// Compact token counts: 1.2M / 34k / 850.
  static String _count(double v) => v >= 1e6
      ? '${(v / 1e6).toStringAsFixed(1)}M'
      : v >= 1e3
      ? '${(v / 1e3).toStringAsFixed(0)}k'
      : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final pal = _MetricsPalette.of(context);
    Widget item(Health h, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusLight(health: h, size: 8),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: pal.healthStrip)),
      ],
    );

    final quota = ai.codexQuotaPct;
    final cache = ai.cacheHitPct;
    return Column(
      children: [
        BrassPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: MolSpace.lg,
            vertical: MolSpace.md,
          ),
          child: Wrap(
            spacing: MolSpace.xl,
            runSpacing: MolSpace.sm,
            children: [
              item(
                Health.ok,
                'Hermes API ${_usd(ai.hermesCostUsd)} · last $rangeLabel',
              ),
              item(
                Health.ok,
                'Claude Code ${_usd(ai.claudeCodeCostUsd)} quota-equivalent',
              ),
              if (quota != null)
                item(
                  quota < 70
                      ? Health.ok
                      : (quota < 90 ? Health.warn : Health.crit),
                  'Codex ${quota.toStringAsFixed(0)}% of 7d quota',
                ),
              if (cache != null)
                item(Health.ok, 'cache hit ${cache.toStringAsFixed(0)}%'),
              item(
                ai.fallbacks > 0 ? Health.warn : Health.ok,
                '${ai.fallbacks.toStringAsFixed(0)} model fallbacks',
              ),
            ],
          ),
        ),
        const SizedBox(height: MolSpace.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final tokens = _MetricPanel(
              title: 'AI tokens',
              accent: pal.accentAiTokens,
              series: ai.tokens,
              format: _count,
              sumLatest: true,
            );
            final latency = _MetricPanel(
              title: 'AI latency',
              accent: pal.accentAiLatency,
              series: ai.latency,
              format: (v) => '${v.toStringAsFixed(1)}s',
            );
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  tokens,
                  const SizedBox(height: MolSpace.md),
                  latency,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tokens),
                const SizedBox(width: MolSpace.md),
                Expanded(child: latency),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Compact fallback when the AI providers error while the cluster block is
/// healthy (exporters down, Prometheus fine).
class _AiUnavailable extends StatelessWidget {
  const _AiUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return BrassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.lg,
        vertical: MolSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'AI telemetry unavailable (ai_* exporters offline?)',
              style: TextStyle(fontSize: 13, color: brass.textMuted),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// UPS power + energy-cost telemetry (NUT exporter on node4): a status
/// strip, the live power-draw chart, and a modelled electricity cost. The UPS
/// meters the whole lab, so these read as aggregate figures — the caption
/// says so, and the tariff comes from Settings › Power.
class _PowerSection extends StatelessWidget {
  const _PowerSection({required this.power});

  final PowerMetrics power;

  static String _usd(double v) =>
      v >= 100 ? '\$${v.toStringAsFixed(0)}' : '\$${v.toStringAsFixed(2)}';

  static String _runtime(double s) {
    final m = s / 60;
    if (m < 90) return '${m.round()} min';
    return '${(s / 3600).toStringAsFixed(1)} h';
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    final p = power;

    final Health statusHealth;
    final String statusText;
    if (p.lowBattery) {
      statusHealth = Health.crit;
      statusText = 'On battery — LOW';
    } else if (p.onBattery) {
      statusHealth = Health.warn;
      statusText = 'On battery';
    } else if (p.online == true) {
      statusHealth = Health.ok;
      statusText = 'On line';
    } else {
      statusHealth = Health.offline;
      statusText = 'status unknown';
    }

    Widget item(Health h, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusLight(health: h, size: 8),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: pal.healthStrip)),
      ],
    );

    final strip = BrassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.lg,
        vertical: MolSpace.md,
      ),
      child: Wrap(
        spacing: MolSpace.xl,
        runSpacing: MolSpace.sm,
        children: [
          item(statusHealth, statusText),
          if (p.batteryPct != null)
            item(Health.ok, 'Battery ${p.batteryPct!.toStringAsFixed(0)}%'),
          if (p.runtimeSeconds != null)
            item(Health.ok, 'Runtime ${_runtime(p.runtimeSeconds!)}'),
          if (p.loadPct != null)
            item(Health.ok, 'Load ${p.loadPct!.toStringAsFixed(0)}%'),
          if (p.inputVolts != null)
            item(Health.ok, 'Line ${p.inputVolts!.toStringAsFixed(0)} V'),
        ],
      ),
    );

    // Current watts is the power chart's own big readout, so it isn't repeated
    // as a card here — these are the derived energy + cost figures.
    final cards = <Widget>[
      if (p.kWhPerDay != null)
        _PowerStat(
          title: 'Energy',
          value: p.kWhPerDay!.toStringAsFixed(2),
          unit: 'kWh',
          accent: pal.accentPower,
          sub: 'per day · 24 h avg',
        ),
      if (p.costPerMonth != null)
        _PowerStat(
          title: 'Est. cost',
          value: _usd(p.costPerMonth!),
          unit: '/mo',
          accent: pal.accentCost,
          sub: 'at \$${p.rateUsdPerKwh.toStringAsFixed(2)}/kWh',
        ),
      if (p.costPerYear != null)
        _PowerStat(
          title: 'Est. cost',
          value: _usd(p.costPerYear!),
          unit: '/yr',
          accent: pal.accentCost,
          sub: 'projected',
        ),
    ];

    final chart = _MetricPanel(
      title: 'Power draw',
      accent: pal.accentPower,
      series: p.power,
      format: (v) => '${v.toStringAsFixed(0)} W',
    );

    return Column(
      children: [
        strip,
        const SizedBox(height: MolSpace.md),
        chart,
        if (cards.isNotEmpty) ...[
          const SizedBox(height: MolSpace.md),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [
                    for (final c in cards)
                      Padding(
                        padding: const EdgeInsets.only(bottom: MolSpace.md),
                        child: c,
                      ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, c) in cards.indexed) ...[
                    if (i > 0) const SizedBox(width: MolSpace.md),
                    Expanded(child: c),
                  ],
                ],
              );
            },
          ),
        ],
        const SizedBox(height: MolSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'UPS meters the whole lab — cluster nodes plus assorted '
            'plugged-in loads, not a pure per-node figure. Set your tariff in '
            'Settings › Power.',
            style: TextStyle(fontSize: 11, color: brass.textMuted),
          ),
        ),
      ],
    );
  }
}

/// One power/cost headline: series-tinted top rule, Playfair title, and a big
/// value + small unit — the readout half of a [_MetricPanel] without a chart.
class _PowerStat extends StatelessWidget {
  const _PowerStat({
    required this.title,
    required this.value,
    required this.unit,
    required this.accent,
    this.sub,
  });

  final String title;
  final String value;
  final String unit;
  final Color accent;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    return BrassPanel(
      topRule: true,
      topRuleColor: accent,
      padding: const EdgeInsets.fromLTRB(
        MolSpace.lg,
        MolSpace.md + 4,
        MolSpace.lg,
        MolSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: brass.sand,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    height: 1,
                    color: brass.textHeading,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 16, color: pal.unitText)),
              ],
            ],
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: brass.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact fallback when the NUT exporter is offline while the cluster block
/// is healthy (Prometheus fine, no nut_* series).
class _PowerUnavailable extends StatelessWidget {
  const _PowerUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return BrassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.lg,
        vertical: MolSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Power telemetry unavailable (NUT exporter on node4 :9199 '
              'offline?)',
              style: TextStyle(fontSize: 13, color: brass.textMuted),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// The digital twin's what-if planner: one card per node-loss scenario
/// (restore placement + time-to-recovery), a headroom row per node, and a
/// "can I fit a new guest?" form — all served by homelab-twin on the
/// monitoring CT. A node death here means PBS restore, not migration.
class _TwinSection extends StatelessWidget {
  const _TwinSection({required this.twin});

  final TwinData twin;

  @override
  Widget build(BuildContext context) {
    final cards = [for (final s in twin.scenarios) _ScenarioCard(scenario: s)];
    final headroom = _HeadroomPanel(nodes: twin.headroom);
    const whatIf = _WhatIfForm();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              for (final c in cards) ...[
                c,
                const SizedBox(height: MolSpace.md),
              ],
              headroom,
              const SizedBox(height: MolSpace.md),
              whatIf,
            ],
          );
        }
        Widget row(Widget a, Widget b) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: MolSpace.md),
            Expanded(child: b),
          ],
        );
        return Column(
          children: [
            for (var i = 0; i + 1 < cards.length; i += 2) ...[
              row(cards[i], cards[i + 1]),
              const SizedBox(height: MolSpace.md),
            ],
            if (cards.length.isOdd) ...[
              row(cards.last, const SizedBox.shrink()),
              const SizedBox(height: MolSpace.md),
            ],
            row(headroom, whatIf),
          ],
        );
      },
    );
  }
}

/// One "if this node dies" card: verdict light, restore placements, and the
/// recovery-time estimate (or the node4 PBS-lost callout).
class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});

  final TwinScenario scenario;

  String _recoveryText() {
    if (scenario.pbsLost) {
      return 'PBS dies too — weekly NAS tier (hours)';
    }
    final m = scenario.recoveryMinutes;
    if (m == null) return 'no PBS backup data';
    return m < 1 ? '~1 min PBS restore' : '~${m.round()} min PBS restore';
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    final s = scenario;
    final verdict = !s.fits
        ? Health.crit
        : s.pbsLost
        ? Health.warn
        : Health.ok;
    final verdictText = s.fits
        ? 'all ${s.guests} guest${s.guests == 1 ? '' : 's'} fit'
        : '${s.strandedNames.length} stranded';

    Widget light(Health h, String text) => Row(
      children: [
        StatusLight(health: h, size: 8),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: pal.healthStrip),
          ),
        ),
      ],
    );

    return BrassPanel(
      topRule: true,
      topRuleColor: pal.accentTwin,
      padding: const EdgeInsets.fromLTRB(
        MolSpace.lg,
        MolSpace.md + 4,
        MolSpace.lg,
        MolSpace.md + 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'If ${s.node} dies',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: brass.sand,
            ),
          ),
          const SizedBox(height: MolSpace.sm),
          light(verdict, verdictText),
          const SizedBox(height: 6),
          for (final p in s.placements)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Text(
                '${p.name} » ${p.target}   '
                '${p.demandGib.toStringAsFixed(1)} GiB',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: brass.textMuted),
              ),
            ),
          for (final name in s.strandedNames)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: light(Health.crit, '$name » nowhere to place'),
            ),
          const SizedBox(height: 6),
          light(scenario.pbsLost ? Health.warn : Health.ok, _recoveryText()),
        ],
      ),
    );
  }
}

/// Free capacity per node after observed p95 usage + the 1 GiB reserve —
/// where the next guest can actually go.
class _HeadroomPanel extends StatelessWidget {
  const _HeadroomPanel({required this.nodes});

  final List<TwinHeadroomNode> nodes;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    return BrassPanel(
      topRule: true,
      topRuleColor: pal.accentTwin,
      padding: const EdgeInsets.fromLTRB(
        MolSpace.lg,
        MolSpace.md + 4,
        MolSpace.lg,
        MolSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RAM headroom',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: brass.sand,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'free after 7-day p95 usage + 1 GiB reserve',
            style: TextStyle(fontSize: 11, color: brass.textMuted),
          ),
          const SizedBox(height: MolSpace.md),
          for (final n in nodes)
            Padding(
              padding: const EdgeInsets.only(bottom: MolSpace.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 74,
                        child: Text(
                          n.node,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 13.5,
                            color: pal.guestName,
                          ),
                        ),
                      ),
                      Expanded(
                        child: RecessedBar(
                          height: 7,
                          fraction: n.totalGib <= 0
                              ? 0
                              : (n.freeGib / n.totalGib).clamp(0.0, 1.0),
                          gradient: [brass.sparkGreenDeep, brass.sparkGreen],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${n.freeGib.toStringAsFixed(1)} GiB free',
                        style: TextStyle(fontSize: 12, color: pal.guestPct),
                      ),
                    ],
                  ),
                  if (n.largestFit != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 74, top: 1),
                      child: Text(
                        'fits ${n.largestFit}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: brass.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Placement verdict for a hypothetical new guest, straight from the twin's
/// /whatif endpoint.
class _WhatIfForm extends ConsumerStatefulWidget {
  const _WhatIfForm();

  @override
  ConsumerState<_WhatIfForm> createState() => _WhatIfFormState();
}

class _WhatIfFormState extends ConsumerState<_WhatIfForm> {
  final _cores = TextEditingController(text: '2');
  final _mem = TextEditingController(text: '2048');
  final _disk = TextEditingController(text: '16');
  Health? _health;
  String? _result;
  bool _busy = false;

  @override
  void dispose() {
    _cores.dispose();
    _mem.dispose();
    _disk.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final api = await ref.read(twinApiProvider.future);
      final w = await api.whatif(
        cores: int.tryParse(_cores.text) ?? 1,
        memMb: int.tryParse(_mem.text) ?? 1024,
        diskGb: int.tryParse(_disk.text) ?? 8,
      );
      setState(() {
        _health = w.fits ? Health.ok : Health.crit;
        _result = w.fits
            ? 'fits on ${w.best}${w.why == null ? '' : ' — ${w.why}'}'
            : 'does not fit${w.why == null ? ' on any node' : ' — ${w.why}'}';
      });
    } catch (_) {
      setState(() {
        _health = Health.offline;
        _result = 'twin service unreachable';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    Widget field(TextEditingController c, String label) => SizedBox(
      width: 86,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(labelText: label, isDense: true),
        // Editing any input invalidates the shown verdict — the form
        // reverts to waiting for Check, so a stale answer can never sit
        // under new numbers.
        onChanged: (_) {
          if (_result != null) {
            setState(() {
              _result = null;
              _health = null;
            });
          }
        },
        onSubmitted: (_) {
          if (!_busy) _check();
        },
      ),
    );

    return BrassPanel(
      topRule: true,
      topRuleColor: pal.accentTwin,
      padding: const EdgeInsets.fromLTRB(
        MolSpace.lg,
        MolSpace.md + 4,
        MolSpace.lg,
        MolSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Can I fit a new guest?',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: brass.sand,
            ),
          ),
          const SizedBox(height: MolSpace.md),
          Wrap(
            spacing: MolSpace.md,
            runSpacing: MolSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              field(_cores, 'Cores'),
              field(_mem, 'RAM MiB'),
              field(_disk, 'Disk GiB'),
              OutlinedButton(
                onPressed: _busy ? null : _check,
                child: Text(_busy ? 'Checking…' : 'Check'),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: MolSpace.md),
            Row(
              children: [
                if (_health != null) ...[
                  StatusLight(health: _health!, size: 8),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _result!,
                    style: TextStyle(fontSize: 13, color: pal.healthStrip),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact fallback when the twin service errors while the cluster block is
/// healthy (service down, Prometheus fine).
class _TwinUnavailable extends StatelessWidget {
  const _TwinUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return BrassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.lg,
        vertical: MolSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'What-if planner unavailable (homelab-twin on :9112 offline?)',
              style: TextStyle(fontSize: 13, color: brass.textMuted),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final notConfigured = error is PrometheusNotConfigured;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notConfigured ? Icons.settings_outlined : Icons.cloud_off,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              notConfigured
                  ? 'Prometheus is not configured.\nSet the Grafana or '
                        'Prometheus URL in Settings.'
                  : 'Failed to load metrics:\n$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (!notConfigured)
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Per-disk SMART health: summary cards, the temperature history chart, and
/// a per-disk row table — every disk carrying a backup tier, node NVMe and
/// pushed NAS bays alike.
class _SmartSection extends StatelessWidget {
  const _SmartSection({required this.smart});

  final SmartHealth smart;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    final disks = smart.disks;
    final passed = disks.where((d) => d.passed).length;
    final degraded = disks.where((d) => d.degraded).length;
    DiskHealth? hottest;
    DiskHealth? mostWorn;
    for (final d in disks) {
      if (d.tempC != null && (hottest?.tempC ?? -1) < d.tempC!) hottest = d;
      if (d.wearPct != null && (mostWorn?.wearPct ?? -1) < d.wearPct!) {
        mostWorn = d;
      }
    }

    final cards = <Widget>[
      if (disks.isNotEmpty)
        _PowerStat(
          title: 'SMART passed',
          value: '$passed/${disks.length}',
          unit: '',
          accent: passed == disks.length && degraded == 0
              ? pal.accentCost
              : pal.accentNetwork,
          sub: degraded == 0
              ? 'no reallocated, pending, or media errors'
              : '$degraded disk(s) degraded — see rows below',
        ),
      if (hottest != null)
        _PowerStat(
          title: 'Hottest disk',
          value: hottest.tempC!.toStringAsFixed(0),
          unit: '°C',
          accent: pal.accentTemp,
          sub: '${hottest.host} ${hottest.shortDevice}',
        ),
      if (mostWorn != null)
        _PowerStat(
          title: 'NVMe wear',
          value: mostWorn.wearPct!.toStringAsFixed(0),
          unit: '%',
          accent: pal.accentDisk,
          sub: '${mostWorn.host} ${mostWorn.shortDevice} · lifetime used',
        ),
    ];

    return Column(
      children: [
        _statCardRow(cards),
        const SizedBox(height: MolSpace.md),
        _MetricPanel(
          title: 'Disk temperature',
          accent: pal.accentTemp,
          series: smart.temps,
          format: (v) => '${v.toStringAsFixed(0)}°C',
        ),
        const SizedBox(height: MolSpace.md),
        BrassPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: MolSpace.lg,
            vertical: MolSpace.sm,
          ),
          child: Column(
            children: [
              for (final d in disks) _DiskRow(disk: d),
            ],
          ),
        ),
        const SizedBox(height: MolSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Temperature alert lines are per device class (HDD 60°C, NVMe '
            '70°C) — a shared line would flap on fanless NVMe that idles '
            'warm by design.',
            style: TextStyle(fontSize: 11, color: brass.textMuted),
          ),
        ),
      ],
    );
  }
}

/// One disk's table row: health light, identity, model, and the class-
/// appropriate wear counters (NVMe wear/media errors vs SATA sectors).
class _DiskRow extends StatelessWidget {
  const _DiskRow({required this.disk});

  final DiskHealth disk;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    final d = disk;
    final health = !d.passed
        ? Health.crit
        : d.degraded
            ? Health.warn
            : Health.ok;
    final temp = d.tempC == null ? '—' : '${d.tempC!.toStringAsFixed(0)}°C';
    final detail = d.wearPct != null
        ? '$temp · wear ${d.wearPct!.toStringAsFixed(0)}% · media errors '
            '${(d.mediaErrors ?? 0).toStringAsFixed(0)}'
        : '$temp · realloc ${(d.reallocated ?? 0).toStringAsFixed(0)} · '
            'pending ${(d.pending ?? 0).toStringAsFixed(0)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          StatusLight(health: health, size: 8),
          const SizedBox(width: MolSpace.md),
          SizedBox(
            width: 150,
            child: Text(
              '${d.host} ${d.shortDevice}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: brass.textHeading,
              ),
            ),
          ),
          const SizedBox(width: MolSpace.md),
          Expanded(
            child: Text(
              d.model,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: brass.textMuted),
            ),
          ),
          const SizedBox(width: MolSpace.md),
          Text(
            detail,
            style: TextStyle(fontSize: 12, color: pal.healthStrip),
          ),
        ],
      ),
    );
  }
}

/// Compact fallback when no smartctl exporter answers while the cluster
/// block is healthy (Prometheus fine, no smartctl_device_* series).
class _SmartUnavailable extends StatelessWidget {
  const _SmartUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return BrassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.lg,
        vertical: MolSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Disk SMART telemetry unavailable (no smartctl exporter '
              'scraped or pushed?)',
              style: TextStyle(fontSize: 13, color: brass.textMuted),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// WAN & offsite path: both circuits' scheduled speedtests, the tailnet
/// path state, the measured offsite write rate against the tier-3 model
/// line, and the NAS kernel-buffer clamp tripwire.
class _WanSection extends StatelessWidget {
  const _WanSection({required this.wan, required this.rangeLabel});

  final WanMetrics wan;
  final String rangeLabel;

  /// The tier-3 planning rate the offsite chart is judged against.
  static const _modelBytesPerSec = 450e3;

  /// The clamp is "lifted" once rmem_max reaches the 7.5 MB fix value.
  static const _clampFixedBytes = 7.5e6;

  static String _mbps(double bits) {
    final m = bits / 1e6;
    return m >= 100 ? m.toStringAsFixed(0) : m.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _MetricsPalette.of(context);
    final w = wan;

    Widget item(Health h, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusLight(health: h, size: 8),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontSize: 13, color: pal.healthStrip)),
          ],
        );

    final (pathHealth, pathText) = switch ((w.pathOnline, w.pathDirect)) {
      (false, _) => (Health.crit, 'Tailnet path down'),
      (true, true) => (Health.ok, 'Direct path'),
      (true, false) => (Health.warn, 'DERP relay'),
      _ => (Health.offline, 'path unknown'),
    };
    final clamped =
        w.rmemMaxBytes != null && w.rmemMaxBytes! < _clampFixedBytes;

    final strip = BrassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.lg,
        vertical: MolSpace.md,
      ),
      child: Wrap(
        spacing: MolSpace.xl,
        runSpacing: MolSpace.sm,
        children: [
          item(pathHealth, pathText),
          if (w.pathRttMs != null)
            item(Health.ok, 'RTT ${w.pathRttMs!.toStringAsFixed(0)} ms'),
          if (w.pathLossPct != null)
            item(
              w.pathLossPct! > 1 ? Health.warn : Health.ok,
              'Loss ${w.pathLossPct!.toStringAsFixed(1)}% / $rangeLabel',
            ),
          if (w.rmemMaxBytes != null)
            item(
              clamped ? Health.warn : Health.ok,
              clamped
                  ? 'NAS buffer clamp ACTIVE '
                      '(rmem ${formatBytes(w.rmemMaxBytes!)})'
                  : 'NAS buffer clamp lifted',
            ),
          if (w.rcvbufErrDelta != null)
            item(
              w.rcvbufErrDelta! > 0 ? Health.warn : Health.ok,
              'RcvbufErrors +${w.rcvbufErrDelta!.toStringAsFixed(0)} '
              '/ $rangeLabel',
            ),
        ],
      ),
    );

    final cards = <Widget>[
      for (final site in w.siteDownBps.keys.toList()..sort())
        _PowerStat(
          title: '${site[0].toUpperCase()}${site.substring(1)} circuit',
          value:
              '${_mbps(w.siteDownBps[site]!)} ↓ · '
              '${_mbps(w.siteUpBps[site] ?? 0)} ↑',
          unit: 'Mbps',
          accent: brass.verdigris,
          sub: 'latest scheduled speedtest',
        ),
      if (w.offsiteBps != null)
        _PowerStat(
          title: 'Offsite write',
          value: formatBytes(w.offsiteBps!),
          unit: '/s',
          accent: brass.copper,
          sub: 'fsync probe onto the offsite share',
        ),
    ];

    return Column(
      children: [
        strip,
        const SizedBox(height: MolSpace.md),
        _statCardRow(cards),
        const SizedBox(height: MolSpace.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final circuits = _MetricPanel(
              title: 'Circuit throughput',
              accent: brass.verdigris,
              series: w.circuits,
              format: (v) => '${_mbps(v)} Mbps',
            );
            final offsite = _MetricPanel(
              title: 'Offsite write rate',
              accent: brass.copper,
              series: w.offsite,
              format: (v) => '${formatBytes(v)}/s',
              warnAt: _modelBytesPerSec,
            );
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  circuits,
                  const SizedBox(height: MolSpace.md),
                  offsite,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: circuits),
                const SizedBox(width: MolSpace.md),
                Expanded(child: offsite),
              ],
            );
          },
        ),
        const SizedBox(height: MolSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Speedtest pushes, tailscale-path exporter, blackbox ICMP, and '
            'the 30-min offsite write probe. The dashed line is the '
            '450 kB/s tier-3 planning rate.',
            style: TextStyle(fontSize: 11, color: brass.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Compact fallback when the WAN pipeline is silent while the cluster block
/// is healthy (Prometheus fine, no speedtest/path series).
class _WanUnavailable extends StatelessWidget {
  const _WanUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return BrassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.lg,
        vertical: MolSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'WAN telemetry unavailable (speedtest / path-exporter pushes '
              'absent?)',
              style: TextStyle(fontSize: 13, color: brass.textMuted),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Stat cards side by side when wide, stacked when narrow — the shared
/// responsive row under the Power, Disk-health, and WAN sections.
Widget _statCardRow(List<Widget> cards) => cards.isEmpty
    ? const SizedBox.shrink()
    : LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return Column(
              children: [
                for (final c in cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: MolSpace.md),
                    child: c,
                  ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, c) in cards.indexed) ...[
                if (i > 0) const SizedBox(width: MolSpace.md),
                Expanded(child: c),
              ],
            ],
          );
        },
      );

/// Metrics-local colour pair: [dark] is verbatim from the dark-only era,
/// [light] is the parchment mapping (charts sit on paper here — unlike the
/// dashboard gauges' kept-dark faces — so series accents darken to inks).
class _MetricsPalette {
  const _MetricsPalette({
    required this.accentCpu,
    required this.accentMemory,
    required this.accentNetwork,
    required this.accentDisk,
    required this.accentTemp,
    required this.accentAiTokens,
    required this.accentAiLatency,
    required this.accentTwin,
    required this.accentPower,
    required this.accentCost,
    required this.chipSelectedBg,
    required this.chipSelectedBorder,
    required this.chipSelectedText,
    required this.chipIdleText,
    required this.unitText,
    required this.tooltipBg,
    required this.tooltipText,
    required this.healthStrip,
    required this.guestPct,
    required this.guestName,
    required this.guestRamBarStart,
    required this.guestRamBarEnd,
  });

  // Per-panel series colours (design §3).
  final Color accentCpu;
  final Color accentMemory;
  final Color accentNetwork;
  final Color accentDisk;
  final Color accentTemp;
  final Color accentAiTokens;
  final Color accentAiLatency;
  final Color accentTwin;
  final Color accentPower; // UPS watts + energy (amber)
  final Color accentCost; // dollars (green)

  // Range-selector pill (selected fill/border/label + idle label).
  final Color chipSelectedBg;
  final Color chipSelectedBorder;
  final Color chipSelectedText;
  final Color chipIdleText;

  // Readout unit, chart tooltip, health strip, guest rows.
  final Color unitText;
  final Color tooltipBg;
  final Color tooltipText;
  final Color healthStrip;
  final Color guestPct;
  final Color guestName;
  final Color guestRamBarStart;
  final Color guestRamBarEnd;

  static const dark = _MetricsPalette(
    accentCpu: Color(0xFF8BC06A),
    accentMemory: Color(0xFF5A86C0),
    accentNetwork: Color(0xFFC8564A),
    accentDisk: Color(0xFFE0BD63),
    accentTemp: Color(0xFFD68A6F),
    accentAiTokens: Color(0xFF63A38B),
    accentAiLatency: Color(0xFF7E9BB5),
    accentTwin: Color(0xFFA083B8),
    accentPower: Color(0xFFE8B84B),
    accentCost: Color(0xFF6FB07A),
    chipSelectedBg: Color(0x29C9AA58),
    chipSelectedBorder: Color(0x80E8CD78),
    chipSelectedText: Color(0xFFF4E8C4),
    chipIdleText: Color(0xFF9DB089),
    unitText: Color(0xFF9DB089),
    tooltipBg: Color(0xFF1E2C1F),
    tooltipText: Color(0xFFE8DFCC),
    healthStrip: Color(0xFFC2CDB4),
    guestPct: Color(0xFFD9E0CC),
    guestName: Color(0xFFEEE4C9),
    guestRamBarStart: Color(0xFF33517E),
    guestRamBarEnd: Color(0xFF7AA0D2),
  );

  static const light = _MetricsPalette(
    accentCpu: Color(0xFF45803A),
    accentMemory: Color(0xFF3A639C),
    accentNetwork: Color(0xFF9E362C),
    accentDisk: Color(0xFF8F6D1E),
    accentTemp: Color(0xFFA05038),
    accentAiTokens: Color(0xFF2E6B54),
    accentAiLatency: Color(0xFF3F5E7A),
    accentTwin: Color(0xFF5C4680),
    accentPower: Color(0xFF8A6A1E),
    accentCost: Color(0xFF2E7D4F),
    chipSelectedBg: Color(0x298A6A2A),
    chipSelectedBorder: Color(0x998A6A2A),
    chipSelectedText: Color(0xFF3A2E14),
    chipIdleText: Color(0xFF55684A),
    unitText: Color(0xFF55684A),
    tooltipBg: Color(0xFFF6F0E2),
    tooltipText: Color(0xFF3A3326),
    healthStrip: Color(0xFF4A5540),
    guestPct: Color(0xFF3E4A36),
    guestName: Color(0xFF2E3324),
    guestRamBarStart: Color(0xFF2C4A78),
    guestRamBarEnd: Color(0xFF3A639C),
  );

  /// The pair for the ambient brightness (Theme dependency, like [Brass.of]).
  static _MetricsPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
