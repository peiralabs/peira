import 'package:flutter/material.dart';

import '../../core/navigation/app_tab.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/hub_scaffold.dart';
import '../webview/webview_screen.dart';
import 'logs_screen.dart';
import 'metrics_screen.dart';

/// The Metrics hub (2026-08-18): the native telemetry screen, the native
/// Loki logs tail, and the changedetection.io release watcher — the lab's
/// whole observability surface behind one rail slot, same promoted-hub
/// pattern as AI/Media/Vault.
class MetricsHubScreen extends StatelessWidget {
  const MetricsHubScreen({super.key, required this.railIndex});

  /// This hub's index in the shell's rail — the Watches web view uses it to
  /// activate lazily only once the hub is opened.
  final int railIndex;

  /// Strip entries, index-aligned with [build]'s children; the shell's
  /// command palette lists them as jump targets. The telemetry sub-view is
  /// deliberately NOT labelled "Metrics" — the rail destination already is,
  /// and duplicate labels would be ambiguous for users and finders alike.
  static const specs = [
    (icon: Ph.chartLineUp, label: 'Telemetry'),
    (icon: Ph.scroll, label: 'Logs'),
    (icon: Ph.eye, label: 'Watches'),
  ];

  @override
  Widget build(BuildContext context) => HubScaffold(
        hub: AppTab.metrics,
        tabs: [
          HubTab(
            icon: specs[0].icon,
            label: specs[0].label,
            child: const MetricsScreen(),
          ),
          HubTab(
            icon: specs[1].icon,
            label: specs[1].label,
            child: const LogsScreen(),
          ),
          HubTab(
            icon: specs[2].icon,
            label: specs[2].label,
            child: WebViewScreen(
              service: 'changedetection.io',
              tabIndex: railIndex,
            ),
          ),
        ],
      );
}
