import 'dart:io' show Platform;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../navigation/app_tab.dart';

part 'navigation_providers.g.dart';

/// Currently selected AppShell tab. Null until something picks one, letting
/// the shell decide the initial tab (Dashboard normally, Settings on first
/// launch). Dashboard tiles set this to jump to other tabs.
///
/// `MOL_INITIAL_TAB` forces the starting tab — a debug aid for launching
/// straight into a webview tab (e.g. to attach CEF DevTools to Grafana).
@Riverpod(keepAlive: true)
class SelectedTab extends _$SelectedTab {
  @override
  int? build() {
    final override = int.tryParse(
      Platform.environment['MOL_INITIAL_TAB'] ?? '',
    );
    return override;
  }

  void select(int index) => state = index;
}

/// Selected sub-tab per hub destination (AI, Media, Vault). Provider-driven
/// rather than a widget-local DefaultTabController so the command palette
/// (and any deep link) can address a hub's sub-view directly; the hub's
/// strip and this state two-way sync in [HubScaffold].
@Riverpod(keepAlive: true)
class HubSubTab extends _$HubSubTab {
  @override
  int build(AppTab tab) => 0;

  void select(int index) => state = index;
}
