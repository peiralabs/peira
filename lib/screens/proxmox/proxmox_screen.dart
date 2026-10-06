import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/proxmox_container.dart';
import '../../core/models/proxmox_node.dart';
import '../../core/models/proxmox_vm.dart';
import '../../core/providers/cluster_history_providers.dart';
import '../../core/providers/proxmox_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/micro_spark.dart';
import '../../core/widgets/recessed_bar.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/status_light.dart';
import 'backups_screen.dart';
import 'create_container_screen.dart';
import 'create_vm_screen.dart';
import 'ct_detail_screen.dart';
import 'node_detail_screen.dart';
import 'pdm_panel.dart';
import 'vm_detail_screen.dart';

/// The wide-layout selection: what the right-hand detail pane shows — a
/// guest ([ProxmoxContainer]/[ProxmoxVm]) or a whole node ([ProxmoxNode]).
/// Null = empty-state hint.
class SelectedGuest extends Notifier<Object?> {
  @override
  Object? build() => null;

  void select(Object? guest) => state = guest;
}

final selectedGuestProvider =
    NotifierProvider<SelectedGuest, Object?>(SelectedGuest.new);

/// Native Proxmox view in the Brass Edition language (design §2): brass
/// screen header with stat chips, gilt divider, node instrument cards, and
/// jewel-pilled guest rows grouped by node.
///
/// Wide windows (>= [_splitBreakpoint]) get a master-detail split: the node +
/// guest list docks left and selecting a container opens its live detail in
/// the right pane instead of pushing a full-screen route.
class ProxmoxScreen extends ConsumerWidget {
  const ProxmoxScreen({super.key});

  // Chosen so the split engages at the app's minimum window width (1100)
  // with the rail collapsed (78), and in goldens (1200 viewport, rail
  // expanded to 244 under FLUTTER_TEST).
  static const _splitBreakpoint = 940.0;
  static const _listPaneWidth = 380.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brass = context.brass;
    final nodes = ref.watch(nodesProvider);

    return nodes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e),
      data: (nodeList) {
        final containers = ref.watch(allContainersProvider).value ?? const [];
        final vms = ref.watch(allVmsProvider).value ?? const [];
        final guests = containers.length + vms.length;
        final running = containers.where((c) => c.status == 'running').length +
            vms.where((v) => v.status == 'running').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
              child: ScreenHeader(
                icon: Ph.hardDrives,
                title: 'Proxmox VE',
                subtitle: 'VIRTUAL ENVIRONMENT · ${nodeList.length} '
                    'NODE${nodeList.length == 1 ? '' : 'S'}',
                trailing: [
                  const SizedBox(width: 12),
                  _StatChip(value: '$guests', label: 'Guests'),
                  const SizedBox(width: 10),
                  _StatChip(value: '$running', label: 'Running'),
                  const SizedBox(width: 10),
                  _StatChip(value: '${guests - running}', label: 'Stopped'),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BackupsScreen(),
                      ),
                    ),
                    child: const Text('Backups'),
                  ),
                  const SizedBox(width: 10),
                  _NewButton(
                    label: 'New CT',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateContainerScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _NewButton(
                    label: 'New VM',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateVmScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: SectionDivider(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= _splitBreakpoint;
                  final list = _list(context, ref, nodeList, wide);
                  if (!wide) return list;
                  final selected = ref.watch(selectedGuestProvider);
                  final detail = switch (selected) {
                    final ProxmoxContainer ct => CtDetailScreen(
                        key: ValueKey('ct-${ct.vmid}'),
                        container: ct,
                        embedded: true,
                      ),
                    final ProxmoxVm vm => VmDetailScreen(
                        key: ValueKey('vm-${vm.vmid}'),
                        vm: vm,
                        embedded: true,
                      ),
                    final ProxmoxNode n => NodeDetailScreen(
                        key: ValueKey('node-${n.node}'),
                        node: n,
                        embedded: true,
                        onSelectGuest:
                            ref.read(selectedGuestProvider.notifier).select,
                      ),
                    _ => const _DetailPlaceholder(),
                  };
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: _listPaneWidth, child: list),
                      Container(width: 1, color: brass.hairline),
                      Expanded(child: detail),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    List<ProxmoxNode> nodeList,
    bool wide,
  ) {
    final brass = context.brass;
    final containers = ref.watch(allContainersProvider);
    final vms = ref.watch(allVmsProvider);
    final histories = ref.watch(nodeCpuHistoryProvider);
    // Node cards and group headers open the per-node detail: into the split
    // pane when wide, as a pushed route when narrow.
    void openNode(ProxmoxNode n) => wide
        ? ref.read(selectedGuestProvider.notifier).select(n)
        : Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => NodeDetailScreen(node: n),
            ),
          );
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(nodesProvider);
        ref.invalidate(allContainersProvider);
        ref.invalidate(allVmsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        children: [
          const BrassSectionHeader(title: 'Nodes'),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = (constraints.maxWidth / 300)
                  .floor()
                  .clamp(1, nodeList.length.clamp(1, 4));
              final w = (constraints.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final n in nodeList)
                    SizedBox(
                      width: w,
                      child: _NodeCard(
                        node: n,
                        cpuHistory: histories[n.node] ?? const [],
                        guestCount: (containers.value ?? const [])
                                .where((c) => c.node == n.node)
                                .length +
                            (vms.value ?? const [])
                                .where((v) => v.node == n.node)
                                .length,
                        onOpen: () => openNode(n),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          const BrassSectionHeader(title: 'Containers'),
          const SizedBox(height: 10),
          containers.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Failed to load containers: $e'),
            data: (cts) => Column(
              children: [
                for (final n in nodeList)
                  if (cts.any((c) => c.node == n.node))
                    _NodeContainerGroup(
                      node: n.node,
                      containers:
                          cts.where((c) => c.node == n.node).toList(),
                      onOpenNode: () => openNode(n),
                      onSelect: wide
                          ? ref.read(selectedGuestProvider.notifier).select
                          : null,
                      selectedVmid: switch (
                          wide ? ref.watch(selectedGuestProvider) : null) {
                        final ProxmoxContainer ct => ct.vmid,
                        _ => null,
                      },
                    ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const BrassSectionHeader(title: 'Virtual machines'),
          const SizedBox(height: 10),
          vms.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Failed to load VMs: $e'),
            data: (vmList) => vmList.isEmpty
                ? Text(
                    'No virtual machines.',
                    style: TextStyle(color: brass.textMuted),
                  )
                : Column(
                    children: [
                      for (final n in nodeList)
                        if (vmList.any((v) => v.node == n.node))
                          _NodeVmGroup(
                            node: n.node,
                            vms: vmList
                                .where((v) => v.node == n.node)
                                .toList(),
                            onOpenNode: () => openNode(n),
                            onSelect: wide
                                ? ref
                                    .read(selectedGuestProvider.notifier)
                                    .select
                                : null,
                            selectedVmid: switch (wide
                                ? ref.watch(selectedGuestProvider)
                                : null) {
                              final ProxmoxVm vm => vm.vmid,
                              _ => null,
                            },
                          ),
                    ],
                  ),
          ),
          // Datacenter Manager status — renders only once a PDM URL is
          // configured (see PdmPanel).
          const SizedBox(height: 26),
          const PdmPanel(),
        ],
      ),
    );
  }
}

/// Rounded-11 hairline stat chip: Playfair gilt value + small-caps label.
class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final palette = _Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: brass.hairline),
        color: palette.statChipBg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: context.displayFont,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              height: 1,
              color: palette.statChipValue,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 10 * 0.14,
              color: palette.chipLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// The gilt hairline "New …" create button, used in the header action row.
class _NewButton extends StatelessWidget {
  const _NewButton({required this.onPressed, this.label = 'New'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: palette.newBtnFg,
        side: BorderSide(color: palette.newBtnBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        // Derive from labelLarge: a bare TextStyle here would REPLACE the
        // theme style (ButtonStyle.textStyle doesn't merge), dropping the
        // EB Garamond family.
        textStyle:
            Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13),
      ),
      icon: const Icon(Ph.plus, size: 14),
      label: Text(label),
    );
  }
}

/// Right-pane hint before anything is selected in the wide split layout.
class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 40, color: brass.textMuted),
          const SizedBox(height: 12),
          Text(
            'Select a node or guest to inspect it here',
            style: TextStyle(color: brass.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = error is ProxmoxNotConfigured
        ? 'Proxmox is not configured yet.\nEnter the URL and API token in Settings.'
        : 'Failed to reach Proxmox:\n$error';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          if (error is! ProxmoxNotConfigured)
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(nodesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// A node instrument card (design §2): health cabochon + Playfair name +
/// "N guests" pill, CPU LOAD readout over a sparkline, recessed RAM (green)
/// and Disk (gold) bars, and the hairline-topped Uptime footer.
class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.cpuHistory,
    required this.guestCount,
    required this.onOpen,
  });

  final ProxmoxNode node;
  final List<double> cpuHistory;
  final int guestCount;

  /// Opens the per-node detail (split pane when wide, route when narrow).
  final VoidCallback onOpen;

  static String _gb(int? bytes) =>
      ((bytes ?? 0) / (1 << 30)).round().toString();

  static Health _health(ProxmoxNode n) {
    if (n.status != 'online') return Health.offline;
    final cpu = n.cpu ?? 0;
    final ram = (n.maxmem ?? 0) > 0 ? (n.mem ?? 0) / n.maxmem! : 0.0;
    return Health.fromLoad(math.max(cpu, ram).clamp(0.0, 1.0));
  }

  static String _uptime(int? seconds) {
    final s = seconds ?? 0;
    if (s <= 0) return '—';
    final d = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final palette = _Palette.of(context);
    final online = node.status == 'online';
    final cpu = (node.cpu ?? 0).clamp(0.0, 1.0);
    final maxmem = node.maxmem ?? 0;
    final ramFrac =
        maxmem > 0 ? ((node.mem ?? 0) / maxmem).clamp(0.0, 1.0) : 0.0;
    final maxdisk = node.maxdisk ?? 0;
    final diskFrac =
        maxdisk > 0 ? ((node.disk ?? 0) / maxdisk).clamp(0.0, 1.0) : 0.0;

    return BrassPanel(
      topRule: true,
      hoverLift: true,
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusLight(health: _health(node), size: 9),
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
              const SizedBox(width: 8),
              _GuestsPill(count: guestCount),
            ],
          ),
          const SizedBox(height: 12),
          if (online) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'CPU LOAD',
                    overflow: TextOverflow.ellipsis,
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
                    fontSize: 20,
                    height: 1,
                    color: brass.textHeading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: cpuHistory.length < 2
                  ? const SizedBox.expand()
                  : CustomPaint(
                      painter: MicroSpark(cpuHistory, brass.sparkGreen),
                      child: const SizedBox.expand(),
                    ),
            ),
          ] else
            SizedBox(
              height: 62,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel, color: brass.crit, size: 24),
                    const SizedBox(height: 3),
                    Text('offline', style: TextStyle(color: brass.clay)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'RAM',
                  overflow: TextOverflow.ellipsis,
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
                  color: palette.readoutText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          RecessedBar(
            fraction: online ? ramFrac.toDouble() : 0,
            gradient: palette.ramBar,
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'DISK',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 12 * 0.16,
                    color: brass.smallCaps,
                  ),
                ),
              ),
              Text(
                '${(diskFrac * 100).round()}%',
                style: TextStyle(
                  fontFamily: context.displayFont,
                  fontSize: 14,
                  color: palette.readoutText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          RecessedBar(
            fraction: online ? diskFrac.toDouble() : 0,
            gradient: palette.diskBar,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: brass.hairline)),
            ),
            child: Row(
              children: [
                Text(
                  'Cores',
                  style: TextStyle(fontSize: 13, color: palette.footerLabel),
                ),
                const SizedBox(width: 7),
                Text(
                  node.maxcpu != null ? '${node.maxcpu}' : '—',
                  style: TextStyle(fontSize: 13, color: palette.footerValue),
                ),
                const Spacer(),
                Text(
                  'Uptime',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: palette.footerLabel),
                ),
                const SizedBox(width: 7),
                Text(
                  online ? _uptime(node.uptime) : '—',
                  style: TextStyle(fontSize: 13, color: palette.footerValue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "N guests" pill on a node card.
class _GuestsPill extends StatelessWidget {
  const _GuestsPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.guestsPillBorder),
        color: palette.guestsPillBg,
      ),
      child: Text(
        '$count guest${count == 1 ? '' : 's'}',
        style: TextStyle(fontSize: 11, color: palette.guestsPillText),
      ),
    );
  }
}

/// Node-name group header for the guest lists: cabochon dot + small-caps
/// name + bulk-actions menu. The dot+name span opens the per-node detail.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.node, required this.menu, this.onTap});

  final String node;
  final Widget menu;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Padding(
              // Vertical padding grows the hit target toward its siblings'
              // (~32px); the row height is set by the menu button, so this
              // doesn't move the visual baseline.
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 4, right: 9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: Brass.emerald.cabochon,
                      boxShadow: brass.jewelHalo(Brass.emerald),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      node.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 11.5 * 0.16,
                        color: brass.smallCaps,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        menu,
      ],
    );
  }
}

/// Jewel guest-type pill: sapphire "VM" / garnet "CT".
class _TypePill extends StatelessWidget {
  const _TypePill({required this.vm});

  final bool vm;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: vm ? palette.vmPillBorder : palette.ctPillBorder,
        ),
        color: vm ? palette.vmPillBg : palette.ctPillBg,
      ),
      child: Text(
        vm ? 'VM' : 'CT',
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          color: vm ? palette.vmPillText : palette.ctPillText,
        ),
      ),
    );
  }
}

/// One guest row: health dot + Playfair name + jewel type pill + right-hand
/// status/RAM readout. Hover highlight, gilt selection ring.
class _GuestRow extends StatefulWidget {
  const _GuestRow({
    required this.vmid,
    required this.name,
    required this.running,
    required this.isVm,
    required this.selected,
    required this.onTap,
    this.ramPct,
  });

  final int vmid;
  final String name;
  final bool running;
  final bool isVm;
  final bool selected;
  final VoidCallback onTap;
  final int? ramPct;

  @override
  State<_GuestRow> createState() => _GuestRowState();
}

class _GuestRowState extends State<_GuestRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final palette = _Palette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: w.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: _hover || w.selected ? palette.rowHover : Colors.transparent,
            border: Border.all(
              color: w.selected ? palette.rowSelectedRing : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              StatusLight(
                health: w.running ? Health.ok : Health.offline,
                size: 8,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  w.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: palette.guestName,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TypePill(vm: w.isVm),
              const SizedBox(width: 10),
              SizedBox(
                width: 58,
                child: Text(
                  w.running
                      ? (w.ramPct != null ? '${w.ramPct}%' : 'running')
                      : 'stopped',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: w.running
                        ? palette.statusRunning
                        : palette.statusStopped,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Ph.caretRight,
                size: 13,
                color: w.selected
                    ? palette.chevronSelected
                    : palette.chevronIdle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeContainerGroup extends ConsumerWidget {
  const _NodeContainerGroup({
    required this.node,
    required this.containers,
    required this.onOpenNode,
    this.onSelect,
    this.selectedVmid,
  });

  final String node;
  final List<ProxmoxContainer> containers;

  /// Header tap → per-node detail.
  final VoidCallback onOpenNode;

  /// Wide split layout: select into the detail pane instead of pushing a
  /// full-screen route.
  final ValueChanged<ProxmoxContainer>? onSelect;
  final int? selectedVmid;

  Future<void> _bulk(BuildContext context, WidgetRef ref, bool start) async {
    final verb = start ? 'Start' : 'Stop';
    final targets = containers
        .where((c) => c.status == (start ? 'stopped' : 'running'))
        .toList();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No containers to $verb on $node.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$verb all on $node?'),
        content: Text(
          '$verb ${targets.length} container${targets.length == 1 ? '' : 's'}: '
          '${targets.map((c) => c.vmid).join(', ')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: start
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(verb),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      for (final c in targets) {
        if (start) {
          await api.startContainer(node, c.vmid);
        } else {
          await api.stopContainer(node, c.vmid);
        }
      }
      ref.invalidate(allContainersProvider);
      ref.invalidate(recentTasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$verb requested for ${targets.length} CTs')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$verb failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupHeader(
            node: node,
            onTap: onOpenNode,
            menu: PopupMenuButton<bool>(
              tooltip: 'Bulk actions',
              icon: Icon(Icons.more_horiz,
                  size: 20, color: palette.chevronIdle),
              onSelected: (start) => _bulk(context, ref, start),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: true,
                  child: ListTile(
                    leading: Icon(Icons.play_arrow),
                    title: Text('Start all'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: false,
                  child: ListTile(
                    leading: Icon(Icons.stop),
                    title: Text('Stop all'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          BrassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              children: [
                for (final ct in containers)
                  _GuestRow(
                    vmid: ct.vmid,
                    name: '${ct.vmid} — ${ct.name ?? 'unnamed'}',
                    running: ct.status == 'running',
                    isVm: false,
                    selected: ct.vmid == selectedVmid,
                    ramPct: ct.status == 'running' && (ct.maxmem ?? 0) > 0
                        ? ((ct.mem ?? 0) / ct.maxmem! * 100).round()
                        : null,
                    onTap: onSelect != null
                        ? () => onSelect!(ct)
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CtDetailScreen(container: ct),
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

class _NodeVmGroup extends ConsumerWidget {
  const _NodeVmGroup({
    required this.node,
    required this.vms,
    required this.onOpenNode,
    this.onSelect,
    this.selectedVmid,
  });

  final String node;
  final List<ProxmoxVm> vms;

  /// Header tap → per-node detail.
  final VoidCallback onOpenNode;

  /// Wide split layout: select into the detail pane instead of pushing a
  /// full-screen route.
  final ValueChanged<ProxmoxVm>? onSelect;
  final int? selectedVmid;

  Future<void> _bulk(BuildContext context, WidgetRef ref, bool start) async {
    final verb = start ? 'Start' : 'Shutdown';
    final targets = vms
        .where((v) => v.status == (start ? 'stopped' : 'running'))
        .toList();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No VMs to $verb on $node.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$verb all on $node?'),
        content: Text(
          '$verb ${targets.length} VM${targets.length == 1 ? '' : 's'}: '
          '${targets.map((v) => v.vmid).join(', ')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: start
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(verb),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = await ref.read(proxmoxApiProvider.future);
      for (final v in targets) {
        if (start) {
          await api.startVm(node, v.vmid);
        } else {
          await api.shutdownVm(node, v.vmid);
        }
      }
      ref.invalidate(allVmsProvider);
      ref.invalidate(recentTasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$verb requested for ${targets.length} VMs')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$verb failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupHeader(
            node: node,
            onTap: onOpenNode,
            menu: PopupMenuButton<bool>(
              tooltip: 'Bulk actions',
              icon: Icon(Icons.more_horiz,
                  size: 20, color: palette.chevronIdle),
              onSelected: (start) => _bulk(context, ref, start),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: true,
                  child: ListTile(
                    leading: Icon(Icons.play_arrow),
                    title: Text('Start all'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: false,
                  child: ListTile(
                    leading: Icon(Icons.power_settings_new),
                    title: Text('Shutdown all'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          BrassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              children: [
                for (final vm in vms)
                  _GuestRow(
                    vmid: vm.vmid,
                    name: '${vm.vmid} — ${vm.name ?? 'unnamed'}',
                    running: vm.status == 'running',
                    isVm: true,
                    selected: vm.vmid == selectedVmid,
                    ramPct: vm.status == 'running' && (vm.maxmem ?? 0) > 0
                        ? ((vm.mem ?? 0) / vm.maxmem! * 100).round()
                        : null,
                    onTap: onSelect != null
                        ? () => onSelect!(vm)
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => VmDetailScreen(vm: vm),
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

/// File-local Proxmox palette (the `proxmox.*` family of the brass mapping):
/// [dark] is verbatim from the dark-only era so dark renders stay
/// bit-identical; [light] is the parchment slice — jewel pill washes become
/// paper tints and the recessed-bar gradients run dark→mid so their leading
/// edge keeps ≥3:1 against the light track.
class _Palette {
  const _Palette({
    required this.statChipBg,
    required this.statChipValue,
    required this.chipLabel,
    required this.newBtnFg,
    required this.newBtnBorder,
    required this.nodeName,
    required this.readoutText,
    required this.ramBar,
    required this.diskBar,
    required this.footerLabel,
    required this.footerValue,
    required this.guestsPillBorder,
    required this.guestsPillBg,
    required this.guestsPillText,
    required this.vmPillBorder,
    required this.vmPillBg,
    required this.vmPillText,
    required this.ctPillBorder,
    required this.ctPillBg,
    required this.ctPillText,
    required this.rowHover,
    required this.rowSelectedRing,
    required this.guestName,
    required this.statusRunning,
    required this.statusStopped,
    required this.chevronSelected,
    required this.chevronIdle,
  });

  static const dark = _Palette(
    statChipBg: Color(0x66131F14),
    statChipValue: Color(0xFFF0D18A),
    chipLabel: Color(0xFF9DB089),
    newBtnFg: Color(0xFFF0D18A),
    newBtnBorder: Color(0x80E8CD78),
    nodeName: Color(0xFFF2ECD6),
    readoutText: Color(0xFFD9E0CC),
    ramBar: [Color(0xFF4F8A45), Color(0xFF8FC16D)],
    diskBar: [Color(0xFFB8923F), Color(0xFFEACA77)],
    footerLabel: Color(0xFF94A684),
    footerValue: Color(0xFFC2CDB4),
    guestsPillBorder: Color(0x597BB26A),
    guestsPillBg: Color(0x662E4A30),
    guestsPillText: Color(0xFFA9C78F),
    vmPillBorder: Color(0x738CAFE0),
    vmPillBg: Color(0x80203048),
    vmPillText: Color(0xFF9CC0EC),
    ctPillBorder: Color(0x73E09678),
    ctPillBg: Color(0x80302121),
    ctPillText: Color(0xFFD79F92),
    rowHover: Color(0x14C9AA58),
    rowSelectedRing: Color(0x80E8CD78),
    guestName: Color(0xFFEEE4C9),
    statusRunning: Color(0xFFC2CDB4),
    statusStopped: Color(0xFF94A684),
    chevronSelected: Color(0xFFF0D18A),
    chevronIdle: Color(0xFF8BA079),
  );

  static const light = _Palette(
    statChipBg: Color(0x2E3B6B4E),
    statChipValue: Color(0xFF7A5A1E),
    chipLabel: Color(0xFF55684A),
    newBtnFg: Color(0xFF7A5A1E),
    newBtnBorder: Color(0x998A6A2A),
    nodeName: Color(0xFF2E3324),
    readoutText: Color(0xFF3E4A36),
    ramBar: [Color(0xFF2E5E28), Color(0xFF45803A)],
    diskBar: [Color(0xFF6E5216), Color(0xFF8F6D1E)],
    footerLabel: Color(0xFF5A6650),
    footerValue: Color(0xFF4A5540),
    guestsPillBorder: Color(0x8C38702E),
    guestsPillBg: Color(0x264F8A45),
    guestsPillText: Color(0xFF2C5222),
    vmPillBorder: Color(0x8C3A5E96),
    vmPillBg: Color(0x293A639C),
    vmPillText: Color(0xFF24457A),
    ctPillBorder: Color(0x8C9C4136),
    ctPillBg: Color(0x299C4136),
    ctPillText: Color(0xFF7A2F27),
    rowHover: Color(0x148A6A2A),
    rowSelectedRing: Color(0x998A6A2A),
    guestName: Color(0xFF3A3326),
    statusRunning: Color(0xFF38702E),
    statusStopped: Color(0xFF5A6650),
    chevronSelected: Color(0xFF7A5A1E),
    chevronIdle: Color(0xFF5F6E50),
  );

  /// Resolve once per build; registers a Theme dependency like [Brass.of].
  static _Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  final Color statChipBg;
  final Color statChipValue;
  final Color chipLabel;
  final Color newBtnFg;
  final Color newBtnBorder;
  final Color nodeName;
  final Color readoutText;
  final List<Color> ramBar;
  final List<Color> diskBar;
  final Color footerLabel;
  final Color footerValue;
  final Color guestsPillBorder;
  final Color guestsPillBg;
  final Color guestsPillText;
  final Color vmPillBorder;
  final Color vmPillBg;
  final Color vmPillText;
  final Color ctPillBorder;
  final Color ctPillBg;
  final Color ctPillText;
  final Color rowHover;
  final Color rowSelectedRing;
  final Color guestName;
  final Color statusRunning;
  final Color statusStopped;
  final Color chevronSelected;

  /// Guest-row idle chevron; also the group-header bulk-actions menu icon.
  final Color chevronIdle;
}
