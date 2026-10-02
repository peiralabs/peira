import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_tab.dart';
import '../../core/providers/grafana_providers.dart';
import '../../core/providers/navigation_providers.dart';
import '../../core/providers/proxmox_providers.dart';
import '../../core/providers/tailscale_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mol_motion.dart';
import '../../core/widgets/status_light.dart';
import '../proxmox/failed_tasks_screen.dart';

/// The first thing on the dashboard: what needs a human, not what the CPU is.
/// Each chip is one class of problem (critical alerts, offline nodes, stopped
/// guests, failed tasks, offline peers) and jumps to the tab that fixes it.
/// When nothing needs attention it collapses to a single calm "all clear" row.
class AttentionStrip extends ConsumerWidget {
  const AttentionStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(nodesProvider).value ?? const [];
    final cts = ref.watch(allContainersProvider).value ?? const [];
    final vms = ref.watch(allVmsProvider).value ?? const [];
    final alerts = ref.watch(activeAlertsProvider).value ?? const [];
    final tasks = ref.watch(recentTasksProvider).value ?? const [];
    final tailscale = ref.watch(tailscaleStatusProvider).value;

    void goTo(int tab) => ref.read(selectedTabProvider.notifier).select(tab);

    final critAlerts = alerts
        .where((a) => a.labels['severity'] == 'critical')
        .length;
    final warnAlerts = alerts.length - critAlerts;
    final offlineNodes = nodes.where((n) => n.status != 'online').length;
    final stoppedGuests =
        cts.where((c) => c.status != 'running').length +
        vms.where((v) => v.status != 'running').length;
    final failedTasks = tasks.where((t) => t.isFailed).length;
    final offlinePeers =
        tailscale?.peers.where((p) => !p.online).length ?? 0;

    final items = <_AttentionItem>[
      if (offlineNodes > 0)
        _AttentionItem(Health.crit, Icons.dns_outlined, 'node offline',
            'nodes offline', offlineNodes, () => goTo(AppTab.proxmox.railIndex)),
      if (critAlerts > 0)
        _AttentionItem(Health.crit, Icons.notification_important_outlined,
            'critical alert', 'critical alerts', critAlerts,
            () => goTo(AppTab.metrics.railIndex)),
      if (warnAlerts > 0)
        _AttentionItem(Health.warn, Icons.warning_amber_outlined, 'warning',
            'warnings', warnAlerts, () => goTo(AppTab.metrics.railIndex)),
      if (failedTasks > 0)
        _AttentionItem(Health.warn, Icons.error_outline, 'failed task',
            'failed tasks', failedTasks,
            () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const FailedTasksScreen()))),
      if (stoppedGuests > 0)
        _AttentionItem(Health.warn, Icons.stop_circle_outlined,
            'guest stopped', 'guests stopped', stoppedGuests,
            () => goTo(AppTab.proxmox.railIndex)),
      if (offlinePeers > 0)
        _AttentionItem(Health.offline, Icons.vpn_lock_outlined,
            'peer offline', 'peers offline', offlinePeers,
            // AppTab indexes are desktop rail positions; on iOS the rail
            // omits the desktop-only tabs, so this index would land on the
            // wrong IndexedStack slot — keep the chip inert there (mirrors
            // AppShell._desktop).
            !Platform.isIOS ? () => goTo(AppTab.tailscale.railIndex) : null),
    ];

    final palette = _Palette.of(context.brass);

    if (items.isEmpty) {
      // Calm all-clear row in green enamel (design: the banner only goes
      // oxblood when something actually needs a human).
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.clearTop, palette.clearBottom],
          ),
          border: Border.all(color: palette.clearBorder),
        ),
        child: Row(
          children: [
            const StatusLight(health: Health.ok),
            const SizedBox(width: MolSpace.md),
            // Expanded + ellipsis: widget_test's fallback font renders wider
            // than the real UI font and would overflow a rigid Row.
            Expanded(
              child: Text(
                'All clear — nothing needs attention',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: palette.clearText),
              ),
            ),
          ],
        ),
      );
    }

    // The oxblood Needs-Attention banner (design §Dashboard).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          colors: [palette.bannerLeft, palette.bannerRight],
        ),
        border: Border.all(color: palette.bannerBorder),
        boxShadow: [
          BoxShadow(color: palette.bannerShadow, offset: const Offset(0, 2)),
        ],
      ),
      child: Wrap(
        spacing: MolSpace.md,
        runSpacing: MolSpace.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'NEEDS ATTENTION',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 12 * 0.26,
                  color: palette.label,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Container(width: 1, height: 16, color: palette.divider),
          for (final item in items) _AttentionChip(item: item),
        ],
      ),
    );
  }
}

class _AttentionItem {
  const _AttentionItem(this.health, this.icon, this.singular, this.plural,
      this.count, this.onTap);

  final Health health;
  final IconData icon;
  final String singular;
  final String plural;
  final int count;
  final VoidCallback? onTap;

  String get label => count == 1 ? singular : plural;
}

class _AttentionChip extends StatelessWidget {
  const _AttentionChip({required this.item});

  final _AttentionItem item;

  @override
  Widget build(BuildContext context) {
    // Health.color is the static dark ramp; resolve through brass so chips
    // inherit the light status ramp on parchment.
    final brass = context.brass;
    final color = switch (item.health) {
      Health.ok => brass.ok,
      Health.warn => brass.warn,
      Health.crit => brass.crit,
      // Shared offline grey in the dark; on parchment it deepens to an iron
      // ink (the pale grey sat at ~3:1 on the rose band).
      Health.offline =>
          brass.isDark ? const Color(0xFF6B6B7A) : const Color(0xFF4E4E5A),
    };
    // In light the neutral/info pill gets an opaque cream fill like its
    // warn/stopped siblings read — a 10% grey wash simply vanishes into the
    // rose band, leaving bare ink on the wash.
    final fill = !brass.isDark && item.health == Health.offline
        ? Color.alphaBlend(
            color.withValues(alpha: 0.10), const Color(0xFFF4EEE2))
        : color.withValues(alpha: 0.10);
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(MolRadius.pill),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(MolRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: MolSpace.md, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MolRadius.pill),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusLight(health: item.health, size: 8),
              const SizedBox(width: 8),
              Text(
                '${item.count} ${item.label}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color),
              ),
              if (item.onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 14, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Strip-local colours that differ by brightness (the `attention.*` family in
/// the light mapping). Dark values are verbatim from the dark-only era; light
/// turns the green enamel into green paper and the oxblood banner into rose
/// paper with an umber shadow.
class _Palette {
  const _Palette({
    required this.clearTop,
    required this.clearBottom,
    required this.clearBorder,
    required this.clearText,
    required this.bannerLeft,
    required this.bannerRight,
    required this.bannerBorder,
    required this.bannerShadow,
    required this.label,
    required this.divider,
  });

  static const dark = _Palette(
    clearTop: Color(0xB32E4A30),
    clearBottom: Color(0xCC1C3220),
    clearBorder: Color(0x667BB26A),
    clearText: Color(0xFFA9E099),
    bannerLeft: Color(0x9E662022),
    bannerRight: Color(0x6B301816),
    bannerBorder: Color(0x8CC8544A),
    bannerShadow: Color(0x40000000),
    label: Color(0xFFEAA093),
    divider: Color(0x8CC85A4E),
  );

  static const light = _Palette(
    clearTop: Color(0xB3D6E6C6),
    clearBottom: Color(0xCCC6DBB4),
    clearBorder: Color(0x8C38702E),
    clearText: Color(0xFF2C5222),
    // Calmer rose paper (was 0x9EEEC9C0 / 0x6BE6BCB2 — read as a saturated
    // pink band rather than a tinted parchment banner).
    bannerLeft: Color(0x8CECD8CF),
    bannerRight: Color(0x59E4CFC3),
    bannerBorder: Color(0x8C9E362C),
    bannerShadow: Color(0x2646381F),
    label: Color(0xFF7A241A),
    divider: Color(0x8C9E362C),
  );

  static _Palette of(Brass brass) => brass.isDark ? dark : light;

  final Color clearTop;
  final Color clearBottom;
  final Color clearBorder;
  final Color clearText;
  final Color bannerLeft;
  final Color bannerRight;
  final Color bannerBorder;
  final Color bannerShadow;
  final Color label;
  final Color divider;
}
