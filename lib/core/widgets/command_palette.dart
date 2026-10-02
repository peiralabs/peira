import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/app_tab.dart';
import '../providers/grafana_providers.dart';
import '../providers/navigation_providers.dart';
import '../providers/proxmox_providers.dart';
import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';
import 'brass_panel.dart';

/// A navigation destination the palette can jump to (mirrors the nav dock).
/// With [hub] + [subIndex] set it addresses a hub's sub-view: the jump
/// selects the rail tab *and* the hub's strip position.
class PaletteDest {
  const PaletteDest({
    required this.index,
    required this.label,
    required this.icon,
    required this.accent,
    this.hub,
    this.subIndex,
  });

  final int index;
  final String label;
  final IconData icon;
  final Color accent;
  final AppTab? hub;
  final int? subIndex;
}

/// One runnable palette entry.
class _Command {
  _Command({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.group,
    required this.onRun,
    this.keywords = const [],
  });

  final String title;
  final String subtitle;
  final String group;
  final IconData icon;
  final Color accent;
  final VoidCallback onRun;
  final List<String> keywords;

  Iterable<String> get _haystack => [title, subtitle, group, ...keywords];
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.delta);
  final int delta;
}

class _RunIntent extends Intent {
  const _RunIntent();
}

class _CloseIntent extends Intent {
  const _CloseIntent();
}

/// A ⌘K / Ctrl-K command palette: fuzzy-search every node, container, VM,
/// navigation target and quick action, drive it entirely from the keyboard
/// (↑/↓ to move, ↵ to run, esc to close), and execute in place. Presented as a
/// floating glass overlay.
class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key, required this.destinations});

  final List<PaletteDest> destinations;

  static Future<void> show(
    BuildContext context,
    List<PaletteDest> destinations,
  ) {
    // Black scrim over the dark glass; a sepia ink wash over parchment.
    return showDialog<void>(
      context: context,
      barrierColor: context.brass.isDark
          ? Colors.black.withValues(alpha: 0.45)
          // Eased 0x59→0x42: the heavier umber wash greyed the parchment.
          : const Color(0x424A3A1C),
      barrierLabel: 'Command palette',
      builder: (_) => CommandPalette(destinations: destinations),
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  int _selected = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  int get _proxmoxIndex => widget.destinations
      .firstWhere(
        (d) => d.label == 'Proxmox',
        orElse: () => widget.destinations.first,
      )
      .index;

  void _go(int tab) => ref.read(selectedTabProvider.notifier).select(tab);

  List<_Command> _all(BuildContext context) {
    final brass = context.brass;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final cmds = <_Command>[];

    for (final d in widget.destinations) {
      final hub = d.hub;
      cmds.add(
        _Command(
          title: d.label,
          subtitle: hub == null
              ? 'Go to ${d.label}'
              : 'Go to ${hub.label} › ${d.label}',
          icon: d.icon,
          accent: d.accent,
          group: 'Go to',
          keywords: const ['open', 'tab', 'navigate'],
          onRun: () {
            _go(d.index);
            if (hub != null && d.subIndex != null) {
              ref.read(hubSubTabProvider(hub).notifier).select(d.subIndex!);
            }
          },
        ),
      );
    }

    for (final c in ref.watch(allContainersProvider).value ?? const []) {
      final running = c.status == 'running';
      cmds.add(
        _Command(
          title: 'CT ${c.vmid}  ${c.name ?? ''}'.trimRight(),
          subtitle: '${c.node ?? '—'}  ·  ${c.status ?? '—'}',
          icon: Icons.inventory_2_outlined,
          accent: running ? brass.moss : muted,
          group: 'Containers',
          keywords: ['container', 'lxc', '${c.vmid}'],
          onRun: () => _go(_proxmoxIndex),
        ),
      );
    }

    for (final v in ref.watch(allVmsProvider).value ?? const []) {
      final running = v.status == 'running';
      cmds.add(
        _Command(
          title: 'VM ${v.vmid}  ${v.name ?? ''}'.trimRight(),
          subtitle: '${v.node ?? '—'}  ·  ${v.status ?? '—'}',
          icon: Icons.desktop_windows_outlined,
          accent: running ? brass.moss : muted,
          group: 'Virtual machines',
          keywords: ['vm', 'qemu', '${v.vmid}'],
          onRun: () => _go(_proxmoxIndex),
        ),
      );
    }

    for (final n in ref.watch(nodesProvider).value ?? const []) {
      cmds.add(
        _Command(
          title: n.node,
          subtitle: 'Proxmox node  ·  ${n.status}',
          icon: Icons.dns_outlined,
          accent: n.status == 'online' ? brass.copper : brass.crit,
          group: 'Nodes',
          keywords: const ['host', 'server'],
          onRun: () => _go(_proxmoxIndex),
        ),
      );
    }

    cmds.add(
      _Command(
        title: 'Refresh cluster data',
        subtitle: 'Reload nodes, containers and alerts',
        icon: Icons.refresh,
        accent: brass.copper,
        group: 'Actions',
        keywords: const ['reload', 'sync', 'update'],
        onRun: () {
          ref.invalidate(nodesProvider);
          ref.invalidate(allContainersProvider);
          ref.invalidate(activeAlertsProvider);
        },
      ),
    );

    return cmds;
  }

  /// null = no match; lower score = better. Prefers contiguous substrings, then
  /// falls back to a subsequence match.
  int? _score(String query, _Command c) {
    if (query.isEmpty) return 0;
    final q = query.toLowerCase();
    var best = _matchScore(q, c.title.toLowerCase());
    for (final h in c._haystack.skip(1)) {
      final s = _matchScore(q, h.toLowerCase());
      if (s != null && (best == null || s + 5 < best)) best = s + 5;
    }
    return best;
  }

  int? _matchScore(String q, String text) {
    final idx = text.indexOf(q);
    if (idx >= 0) return idx; // contiguous; earlier position ranks higher
    var ti = 0, qi = 0, gaps = 0;
    while (ti < text.length && qi < q.length) {
      if (text[ti] == q[qi]) {
        qi++;
      } else {
        gaps++;
      }
      ti++;
    }
    return qi == q.length ? 100 + gaps : null;
  }

  List<_Command> _filter(List<_Command> all) {
    if (_query.isEmpty) return all;
    final scored = <(int, _Command)>[];
    for (final c in all) {
      final s = _score(_query, c);
      if (s != null) scored.add((s, c));
    }
    scored.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final e in scored) e.$2];
  }

  void _move(int delta, int len) {
    if (len == 0) return;
    setState(() => _selected = (_selected + delta).clamp(0, len - 1));
  }

  void _run(List<_Command> filtered, int sel) {
    if (filtered.isEmpty) return;
    final cmd = filtered[sel];
    Navigator.of(context).pop();
    cmd.onRun();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brass = context.brass;
    final filtered = _filter(_all(context));
    final sel = filtered.isEmpty ? 0 : _selected.clamp(0, filtered.length - 1);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.enter): _RunIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): _RunIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CloseIntent(),
      },
      child: Actions(
        actions: {
          _MoveIntent: CallbackAction<_MoveIntent>(
            onInvoke: (i) => _move(i.delta, filtered.length),
          ),
          _RunIntent: CallbackAction<_RunIntent>(
            onInvoke: (_) => _run(filtered, sel),
          ),
          _CloseIntent: CallbackAction<_CloseIntent>(
            onInvoke: (_) => Navigator.of(context).maybePop(),
          ),
        },
        child: Align(
          alignment: const Alignment(0, -0.55),
          child: Padding(
            padding: const EdgeInsets.all(MolSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 460),
              child: Material(
                type: MaterialType.transparency,
                child: BrassPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _searchField(theme, brass),
                      Divider(
                        height: 1,
                        color: brass.panelBorder,
                      ),
                      Flexible(
                        child: filtered.isEmpty
                            ? _empty(theme)
                            : ListView.builder(
                                controller: _scroll,
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(MolSpace.sm),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) => _Row(
                                  command: filtered[i],
                                  selected: i == sel,
                                  onHover: () => setState(() => _selected = i),
                                  onTap: () => _run(filtered, i),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField(ThemeData theme, Brass brass) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MolSpace.lg,
        MolSpace.sm,
        MolSpace.md,
        MolSpace.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: MolSpace.md),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: theme.textTheme.titleMedium,
              cursorColor: brass.bronze,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search nodes, containers, actions…',
                hintStyle: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              onChanged: (v) => setState(() {
                _query = v;
                _selected = 0;
              }),
            ),
          ),
          const _KeyCap(text: 'esc'),
        ],
      ),
    );
  }

  Widget _empty(ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MolSpace.xxl),
    child: Center(
      child: Text(
        'No matches',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.command,
    required this.selected,
    required this.onHover,
    required this.onTap,
  });

  final _Command command;
  final bool selected;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = command.accent;
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: MolMotion.fast,
          curve: MolMotion.standard,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: MolSpace.md,
            vertical: MolSpace.sm + 2,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(MolRadius.md),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(MolRadius.sm),
                ),
                child: Icon(command.icon, size: 17, color: accent),
              ),
              const SizedBox(width: MolSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      command.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      command.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MolSpace.sm),
              Text(
                command.group,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                  letterSpacing: 0.4,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: MolSpace.sm),
                const _KeyCap(text: '↵'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A small keyboard-cap chip (esc / ↵).
class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.brass.panelBorder),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
