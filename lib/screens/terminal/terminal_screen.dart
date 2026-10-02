import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../core/providers/navigation_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/providers/terminal_providers.dart';
import '../../core/terminal/ssh_target.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_icon_badge.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/screen_header.dart';

/// ANSI palette remapped to the brass/navy design (§9) so the shell reads as
/// part of the app: green prompt, sapphire blue, gilt yellow, garnet red.
/// Brightness-invariant by design: the viewport stays a self-luminous dark
/// CRT instrument in both modes (TUI legibility never depends on the page);
/// only the chrome around it re-inks for parchment (see [_Chrome]).
const molTerminalTheme = TerminalTheme(
  cursor: Color(0xFFE0BD63), // gilt bronze — shared across modes
  selection: Color(0x40C89B6A),
  foreground: Color(0xFFDCE2D2),
  background: Color(0xFF090E15),
  black: Color(0xFF1A2230),
  red: Color(0xFFC0554A),
  green: Color(0xFF6F9C5A),
  yellow: Color(0xFFC9A95A),
  blue: Color(0xFF5A86C0),
  magenta: Color(0xFFB08AC8),
  cyan: Color(0xFF6FD0E0),
  white: Color(0xFFC9C8BC),
  brightBlack: Color(0xFF4A5468),
  brightRed: Color(0xFFDD8078),
  brightGreen: Color(0xFF9CC486),
  brightYellow: Color(0xFFE8CB84),
  brightBlue: Color(0xFF8FABD6),
  brightMagenta: Color(0xFFD0B0E4),
  brightCyan: Color(0xFFA0E4F0),
  brightWhite: Color(0xFFF0EFE4),
  searchHitBackground: Color(0xFFC9A95A),
  searchHitBackgroundCurrent: Color(0xFFE0BD63),
  searchHitForeground: Color(0xFF090E15),
);

/// The chrome around the terminal viewport — tab strip, connect button, header
/// subtitle. Unlike the viewport it sits on the page, so it re-inks for
/// parchment: navy wash chips, engraved gilt borders, ink-dark labels. Dark
/// values are verbatim from the dark-only era; everything not listed here
/// (the panel slab, title bar, gems, placeholder inks) draws on the kept-dark
/// slab and stays shared.
class _Chrome {
  const _Chrome({
    required this.headerSubtitle,
    required this.tabSelectedBg,
    required this.tabIdleBg,
    required this.tabSelectedBorder,
    required this.tabIdleBorder,
    required this.tabSelectedText,
    required this.tabIdleText,
    required this.tabCloseIcon,
    required this.menuGroupHeader,
    required this.connectBg1,
    required this.connectBg2,
    required this.connectBorder,
    required this.connectFg,
  });

  static const dark = _Chrome(
    headerSubtitle: Color(0xFF9DB8DD),
    tabSelectedBg: Color(0x40142033),
    tabIdleBg: Color(0x1A0E1620),
    tabSelectedBorder: Color(0x99E8CD78),
    tabIdleBorder: Color(0x3D8CAFE0),
    tabSelectedText: Color(0xFFF0E6CE),
    tabIdleText: Color(0xFFAFC0D8),
    tabCloseIcon: Color(0xFF8098B4),
    menuGroupHeader: Color(0xFF8FA6C4),
    connectBg1: Color(0x40142033),
    connectBg2: Color(0x2A0E1620),
    connectBorder: Color(0x80E8CD78),
    connectFg: Color(0xFFF0D18A),
  );

  static const light = _Chrome(
    headerSubtitle: Color(0xFF425C86),
    tabSelectedBg: Color(0x261D3A6E),
    tabIdleBg: Color(0x0F1D3A6E),
    tabSelectedBorder: Color(0x998A6A2A),
    tabIdleBorder: Color(0x473E5C8C),
    tabSelectedText: Color(0xFF2C3A50),
    tabIdleText: Color(0xFF54688A),
    tabCloseIcon: Color(0xFF5E7292),
    menuGroupHeader: Color(0xFF54688A),
    connectBg1: Color(0x1F1D3A6E),
    connectBg2: Color(0x141D3A6E),
    connectBorder: Color(0x8C8A6A2A),
    connectFg: Color(0xFF7A5A1E),
  );

  final Color headerSubtitle;
  final Color tabSelectedBg;
  final Color tabIdleBg;
  final Color tabSelectedBorder;
  final Color tabIdleBorder;
  final Color tabSelectedText;
  final Color tabIdleText;
  final Color tabCloseIcon;
  final Color menuGroupHeader;
  final Color connectBg1;
  final Color connectBg2;
  final Color connectBorder;
  final Color connectFg;

  static _Chrome of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// One terminal session (a tab) — its own [Terminal] + [Pty]. A local session
/// runs the login shell; an SSH session runs `ssh <args>` (a cluster node, a
/// container via `pct enter`, or a saved device).
class _Session {
  _Session({
    required this.label,
    required this.exec,
    required this.args,
    required this.jewel,
    this.ssh = false,
  });

  final String label;
  final String exec;
  final List<String> args;
  final Jewel jewel;
  final bool ssh;

  final Terminal terminal = Terminal(maxLines: 10000);
  Pty? pty;
  bool started = false;
  bool exited = false;
  Object? error;

  String get title => ssh ? '$exec ${args.join(' ')}' : label;
}

/// Embedded multi-session terminal: a local login shell plus SSH tabs that
/// auto-connect to the cluster's nodes and running containers (addresses pulled
/// live from Proxmox) and to saved devices. The `+` menu opens more; "Add
/// device…" saves a new target for next time. Desktop only.
class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key, required this.tabIndex});

  final int tabIndex;

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  static final String _shell = Platform.environment['SHELL'] ?? '/bin/bash';
  static final String _shellName = _shell.split('/').last;
  static final String _user = Platform.environment['USER'] ?? 'user';
  static final String _host = Platform.localHostname;

  final List<_Session> _sessions = [];
  int _active = 0;
  bool _fatal = false;

  @override
  void initState() {
    super.initState();
    // The local login shell is always the first tab.
    _sessions.add(_Session(
      label: '$_user@$_host',
      exec: _shell,
      args: const ['-l'],
      jewel: Brass.emerald,
    ));
  }

  @override
  void dispose() {
    for (final s in _sessions) {
      s.pty?.kill();
    }
    super.dispose();
  }

  void _start(_Session s) {
    if (s.started) return;
    s.started = true;
    try {
      final pty = Pty.start(
        s.exec,
        arguments: s.args,
        workingDirectory: Platform.environment['HOME'],
        columns: s.terminal.viewWidth,
        rows: s.terminal.viewHeight,
      );
      pty.output
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(s.terminal.write);
      pty.exitCode.then((code) {
        s.terminal.write('\r\n[session ended — code $code]\r\n');
        s.exited = true;
        s.pty = null;
        if (mounted) setState(() {});
      });
      s.terminal.onOutput = (data) => pty.write(utf8.encode(data));
      s.terminal.onResize = (w, h, pw, ph) => pty.resize(h, w);
      s.pty = pty;
    } catch (e) {
      // A missing local shell is fatal for the tab; a failed ssh spawn just
      // errors that one session.
      if (!s.ssh) {
        _fatal = true;
      } else {
        s.error = e;
      }
    }
  }

  void _openTarget(SshTarget t) {
    setState(() {
      _sessions.add(_Session(
        label: t.label,
        exec: 'ssh',
        args: t.args,
        jewel: _jewelFor(t.group),
        ssh: true,
      ));
      _active = _sessions.length - 1;
    });
  }

  void _openLocalShell() {
    setState(() {
      _sessions.add(_Session(
        label: '$_user@$_host',
        exec: _shell,
        args: const ['-l'],
        jewel: Brass.emerald,
      ));
      _active = _sessions.length - 1;
    });
  }

  void _closeSession(int i) {
    _sessions[i].pty?.kill();
    setState(() {
      _sessions.removeAt(i);
      if (_active >= _sessions.length) _active = _sessions.length - 1;
      if (_active < 0) _active = 0;
    });
  }

  /// Green light: reconnect the active session (kill + respawn its process).
  void _reconnectActive() {
    if (_sessions.isEmpty) return;
    final s = _sessions[_active];
    s.pty?.kill();
    s.pty = null;
    s.started = false;
    s.exited = false;
    s.error = null;
    s.terminal.write('\r\n[reconnecting…]\r\n');
    _start(s);
    setState(() {});
  }

  /// Yellow light: clear the active screen (Ctrl-L redraws the prompt).
  void _clearActive() {
    if (_sessions.isEmpty) return;
    _sessions[_active].pty?.write(utf8.encode('\x0c'));
  }

  static Jewel _jewelFor(String group) => switch (group) {
        'Nodes' => Brass.sapphire,
        'Containers' => Brass.topaz,
        _ => Brass.amethyst,
      };

  Future<void> _addDevice() async {
    final labelCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add SSH device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'nas',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: hostCtrl,
              decoration: const InputDecoration(
                labelText: 'user@host',
                hintText: 'admin@10.0.0.5',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save & connect'),
          ),
        ],
      ),
    );
    final label = labelCtrl.text.trim();
    final host = hostCtrl.text.trim();
    labelCtrl.dispose();
    hostCtrl.dispose();
    if (ok != true || host.isEmpty || !mounted) return;

    // Persist it as a saved shortcut for next time, then open it now.
    final current = ref.read(settingsControllerProvider).value;
    if (current != null) {
      final line = label.isEmpty ? host : '$label=$host';
      final joined = current.sshTargets.trim().isEmpty
          ? line
          : '${current.sshTargets.trim()}\n$line';
      await ref
          .read(settingsControllerProvider.notifier)
          .save(current.copyWith(sshTargets: joined));
    }
    _openTarget(SshTarget(
      label: label.isEmpty ? host : label,
      group: 'Saved',
      subtitle: host,
      args: [host],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_fatal) {
      return const Center(
        child: Text(
          'Terminal is not available on this device.',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Only spawn the active shell once the user actually opens the tab.
    final onThisTab = ref.watch(selectedTabProvider) == widget.tabIndex;
    if (onThisTab && _sessions.isNotEmpty) _start(_sessions[_active]);
    if (!onThisTab && !_sessions.any((s) => s.started)) {
      return const SizedBox.shrink();
    }

    final targets = ref.watch(sshTargetsProvider).value ?? const <SshTarget>[];
    final active = _sessions.isEmpty ? null : _sessions[_active];
    final chrome = _Chrome.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              icon: Ph.terminalWindow,
              badgeField: BrassIconBadge.navyField,
              iconColor: const Color(0xFFDCE8F8),
              title: 'Terminal',
              subtitle: '${_host.toUpperCase()} · ${_shellName.toUpperCase()} · '
                  '${_sessions.length} SESSION${_sessions.length == 1 ? '' : 'S'}',
              subtitleColor: chrome.headerSubtitle,
            ),
            const SizedBox(height: 16),
            const SectionDivider.blue(),
            const SizedBox(height: 14),
            _SessionTabs(
              sessions: _sessions,
              active: _active,
              targets: targets,
              onSelect: (i) => setState(() => _active = i),
              onClose: _closeSession,
              onOpenTarget: _openTarget,
              onOpenLocal: _openLocalShell,
              onAddDevice: _addDevice,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _TerminalPanel(
                title: active?.title ?? 'no session',
                onClose:
                    _sessions.isEmpty ? null : () => _closeSession(_active),
                onClear: _sessions.isEmpty ? null : _clearActive,
                onReconnect: _sessions.isEmpty ? null : _reconnectActive,
                child: _sessions.isEmpty
                    ? const _EmptyTerminal()
                    : IndexedStack(
                        index: _active,
                        children: [
                          for (final s in _sessions)
                            s.error != null
                                ? Center(
                                    child: Text(
                                      'Could not start:\n${s.error}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Color(0xFFDD8078)),
                                    ),
                                  )
                                : TerminalView(
                                    s.terminal,
                                    theme: molTerminalTheme,
                                    textStyle: const TerminalStyle(
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                    padding: const EdgeInsets.all(12),
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

/// The session tab strip: a chip per open session (jewel dot + label + close),
/// then a gilt `+` that opens the connect menu.
class _SessionTabs extends StatelessWidget {
  const _SessionTabs({
    required this.sessions,
    required this.active,
    required this.targets,
    required this.onSelect,
    required this.onClose,
    required this.onOpenTarget,
    required this.onOpenLocal,
    required this.onAddDevice,
  });

  final List<_Session> sessions;
  final int active;
  final List<SshTarget> targets;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;
  final ValueChanged<SshTarget> onOpenTarget;
  final VoidCallback onOpenLocal;
  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _Tab(
                session: sessions[i],
                selected: i == active,
                onTap: () => onSelect(i),
                onClose: () => onClose(i),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _AddMenu(
            targets: targets,
            onOpenTarget: onOpenTarget,
            onOpenLocal: onOpenLocal,
            onAddDevice: onAddDevice,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final _Session session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final chrome = _Chrome.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 11, right: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: selected ? chrome.tabSelectedBg : chrome.tabIdleBg,
            border: Border.all(
              color:
                  selected ? chrome.tabSelectedBorder : chrome.tabIdleBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: session.exited
                      ? null
                      : session.jewel.cabochon,
                  color: session.exited ? const Color(0xFF6A5040) : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                session.label,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12.5,
                  color:
                      selected ? chrome.tabSelectedText : chrome.tabIdleText,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Close session',
                iconSize: 13,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 22, minHeight: 22),
                icon: Icon(Ph.x, color: chrome.tabCloseIcon),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The gilt `+` connect menu, grouped Nodes / Containers / Saved plus a local
/// shell and "Add device…".
class _AddMenu extends StatelessWidget {
  const _AddMenu({
    required this.targets,
    required this.onOpenTarget,
    required this.onOpenLocal,
    required this.onAddDevice,
  });

  final List<SshTarget> targets;
  final ValueChanged<SshTarget> onOpenTarget;
  final VoidCallback onOpenLocal;
  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    final chrome = _Chrome.of(context);
    return PopupMenuButton<String>(
      tooltip: 'New session',
      position: PopupMenuPosition.under,
      onSelected: (v) {
        if (v == 'local') return onOpenLocal();
        if (v == 'add') return onAddDevice();
        final i = int.tryParse(v);
        if (i != null && i >= 0 && i < targets.length) onOpenTarget(targets[i]);
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem(
            value: 'local',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Ph.terminalWindow, size: 18),
              title: Text('Local shell'),
            ),
          ),
        ];
        for (final group in const ['Nodes', 'Containers', 'Saved']) {
          final inGroup = [
            for (var i = 0; i < targets.length; i++)
              if (targets[i].group == group) i,
          ];
          if (inGroup.isEmpty) continue;
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem(
            enabled: false,
            height: 26,
            child: Text(
              group.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.4,
                color: chrome.menuGroupHeader,
              ),
            ),
          ));
          for (final i in inGroup) {
            items.add(PopupMenuItem(
              value: '$i',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(targets[i].label),
                subtitle: Text(
                  targets[i].subtitle,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ));
          }
        }
        items.add(const PopupMenuDivider());
        items.add(const PopupMenuItem(
          value: 'add',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Ph.plus, size: 18),
            title: Text('Add device…'),
          ),
        ));
        return items;
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: LinearGradient(
            colors: [chrome.connectBg1, chrome.connectBg2],
          ),
          border: Border.all(color: chrome.connectBorder),
        ),
        child: Row(
          children: [
            Icon(Ph.plus, size: 14, color: chrome.connectFg),
            const SizedBox(width: 7),
            Text(
              'Connect',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12.5,
                color: chrome.connectFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTerminal extends StatelessWidget {
  const _EmptyTerminal();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No sessions — use Connect to open one.',
        style: TextStyle(color: Color(0xFF7F93B0)),
      ),
    );
  }
}

/// The rounded navy-black terminal frame with a mac-style title bar. The three
/// gem "traffic lights" are live: garnet closes the session, topaz clears the
/// screen, emerald reconnects.
class _TerminalPanel extends StatelessWidget {
  const _TerminalPanel({
    required this.title,
    required this.child,
    this.onClose,
    this.onClear,
    this.onReconnect,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final VoidCallback? onClear;
  final VoidCallback? onReconnect;

  Widget _gem(Jewel jewel, String tooltip, VoidCallback? onTap) => Tooltip(
        message: tooltip,
        child: MouseRegion(
          cursor: onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: jewel.cabochon,
                boxShadow: [
                  BoxShadow(
                      color: jewel.mid.withValues(alpha: 0.5), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF0090E15), Color(0xF7060A0F)],
        ),
        border: Border.all(color: const Color(0x578CAFE0)),
        boxShadow: context.brass.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x2E8CAFE0))),
            ),
            child: Row(
              children: [
                _gem(Brass.ruby, 'Close session', onClose),
                const SizedBox(width: 7),
                _gem(Brass.topaz, 'Clear screen', onClear),
                const SizedBox(width: 7),
                _gem(Brass.emerald, 'Reconnect', onReconnect),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.5,
                      color: Color(0xFF7F93B0),
                    ),
                  ),
                ),
                // Balance the traffic lights so the title stays centered.
                const SizedBox(width: 50),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
