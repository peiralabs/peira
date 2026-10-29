import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brass_panel.dart';
import 'mechanical.dart';

/// Single-series live chart as an instrument: the trace behind glass in a
/// [TraceWindow] (phosphor scope in dark themes, chart paper in light), with
/// its scale engraved beside the window. Fixed honest 0–100 scale by
/// default, no legend (the title names the series). Shared by the CT/VM detail screens and the node detail
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

  /// Fixed top of the y-axis; null scales to a little above the peak.
  final double? maxY;

  /// Axis-label formatter; defaults to the bare integer.
  final String Function(double value)? leftLabel;

  static double _autoTop(List<double> s) =>
      math.max(1.0, s.reduce(math.max) * 1.2);

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
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
                  : _Trace(
                      samples: samples,
                      top: maxY ?? _autoTop(samples),
                      label: leftLabel,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The window plus its engraved scale: labels at the quarter rulings of the
/// window's graticule (the window insets its plot 5px top and bottom).
class _Trace extends StatelessWidget {
  const _Trace({required this.samples, required this.top, this.label});

  final List<double> samples;
  final double top;
  final String Function(double value)? label;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final style = TextStyle(
      fontSize: 11,
      color: brass.smallCaps,
      shadows: engraved(brass),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: label != null ? 44 : 30,
          child: LayoutBuilder(
            builder: (context, box) {
              final plot = box.maxHeight - 10;
              return Stack(
                children: [
                  for (var k = 0; k <= 4; k++)
                    Positioned(
                      right: 6,
                      top: 5 + plot * (1 - k / 4) - 7,
                      child: Text(
                        label?.call(top * k / 4) ??
                            '${(top * k / 4).round()}',
                        style: style,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: TraceWindow(
            data: samples,
            color: brass.sparkGreen,
            style: brass.isDark ? TraceStyle.scope : TraceStyle.paper,
            maxValue: top,
          ),
        ),
      ],
    );
  }
}
