import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brass_panel.dart';

/// Single-series live line chart: fixed honest 0–100 scale by default, 2px
/// line in the theme's primary color, recessive grid, no legend (the title
/// names the series). Shared by the CT/VM detail screens and the node detail
/// screen. Pass [maxY] null to autoscale (byte rates) and [leftLabel] to
/// format the axis values.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.samples,
    this.maxY = 100,
    this.leftLabel,
  });

  final String title;
  final List<double> samples;

  /// Fixed top of the y-axis; null lets fl_chart autoscale to the data.
  final double? maxY;

  /// Axis-label formatter; defaults to the bare integer.
  final String Function(double value)? leftLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brass = context.brass;
    final fixedScale = maxY != null;
    return BrassPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 11.5 * 0.16,
                color: brass.smallCaps,
              )),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: samples.length < 2
                  ? Center(
                      child: Text(
                        'Collecting…',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: fixedScale ? 25 : null,
                          getDrawingHorizontalLine: (_) => FlLine(
                            // outlineVariant @0.4 vanishes on parchment —
                            // umber rule in light, dark unchanged.
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? scheme.outlineVariant
                                        .withValues(alpha: 0.4)
                                    : const Color(0x525A4A2A),
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
                              interval: fixedScale ? 25 : null,
                              reservedSize: leftLabel != null ? 44 : 32,
                              getTitlesWidget: (v, _) => Text(
                                leftLabel?.call(v) ?? '${v.toInt()}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < samples.length; i++)
                                FlSpot(i.toDouble(), samples[i]),
                            ],
                            color: scheme.primary,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
