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
import '../../core/widgets/mechanical.dart';
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
TerminalTheme _ansi({
  required Color bg,
  required Color fg,
  required Color cursor,
  required List<Color> c,
}) => TerminalTheme(
  cursor: cursor,
  selection: cursor.withValues(alpha: 0.25),
  foreground: fg,
  background: bg,
  black: c[0],
  red: c[1],
  green: c[2],
  yellow: c[3],
  blue: c[4],
  magenta: c[5],
  cyan: c[6],
  white: c[7],
  brightBlack: c[8],
  brightRed: c[9],
  brightGreen: c[10],
  brightYellow: c[11],
  brightBlue: c[12],
  brightMagenta: c[13],
  brightCyan: c[14],
  brightWhite: c[15],
  searchHitBackground: c[11],
  searchHitBackgroundCurrent: cursor,
  searchHitForeground: bg,
);

/// The shell's colours in each family's idiom: Brass keeps its own; Terminal
/// is green-phosphor monochrome, Ember amber phosphor, Obsidian steel-white
/// on true black, Nord and Catppuccin their official ANSI schemes, Aqua the
/// macOS system colours, Graphite a muted neutral set. Always a dark,
/// self-luminous screen, in light mode too.
TerminalTheme terminalThemeFor(BuildContext context) {
  switch (context.kit) {
    case InstrumentKit.brass:
      return molTerminalTheme;
    case InstrumentKit.terminal:
      return _ansi(
        bg: const Color(0xFF020703),
        fg: const Color(0xFF39FF6A),
        cursor: const Color(0xFF9CFFB4),
        c: const [
          Color(0xFF0A1F0F), Color(0xFF3FD46A), Color(0xFF39FF6A), Color(0xFF9CFFB4),
          Color(0xFF2BB35A), Color(0xFF5FE08A), Color(0xFF7DFFA0), Color(0xFFB8FFCC),
          Color(0xFF1F5A2E), Color(0xFF6CFF94), Color(0xFF7DFFA0), Color(0xFFCCFFDA),
          Color(0xFF4ED67A), Color(0xFF8CFFB0), Color(0xFFA6FFC2), Color(0xFFE6FFEE),
        ],
      );
    case InstrumentKit.ember:
      return _ansi(
        bg: const Color(0xFF120804),
        fg: const Color(0xFFFFB15C),
        cursor: const Color(0xFFFFD49A),
        c: const [
          Color(0xFF2A1406), Color(0xFFFF7A3D), Color(0xFFFFB15C), Color(0xFFFFD08A),
          Color(0xFFC9813E), Color(0xFFE89A5A), Color(0xFFFFC27A), Color(0xFFFFE2BC),
          Color(0xFF6A3A18), Color(0xFFFF9A62), Color(0xFFFFC27A), Color(0xFFFFE0A8),
          Color(0xFFE0A060), Color(0xFFFFB27A), Color(0xFFFFD49A), Color(0xFFFFF1DE),
        ],
      );
    case InstrumentKit.obsidian:
      return _ansi(
        bg: const Color(0xFF000000),
        fg: const Color(0xFFCDD0D6),
        cursor: const Color(0xFFD8DCE2),
        c: const [
          Color(0xFF151515), Color(0xFFD9534A), Color(0xFF7FB86A), Color(0xFFFFB020),
          Color(0xFF6C8EBF), Color(0xFFB07FB8), Color(0xFF6FB3B3), Color(0xFFB8BCC2),
          Color(0xFF3A3A3E), Color(0xFFF07068), Color(0xFF9AD486), Color(0xFFFFCB60),
          Color(0xFF8EACD6), Color(0xFFCB9CD4), Color(0xFF8ED0D0), Color(0xFFE6E8EB),
        ],
      );
    case InstrumentKit.nord:
      return _ansi(
        bg: const Color(0xFF2E3440),
        fg: const Color(0xFFD8DEE9),
        cursor: const Color(0xFFD8DEE9),
        c: const [
          Color(0xFF3B4252), Color(0xFFBF616A), Color(0xFFA3BE8C), Color(0xFFEBCB8B),
          Color(0xFF81A1C1), Color(0xFFB48EAD), Color(0xFF88C0D0), Color(0xFFE5E9F0),
          Color(0xFF4C566A), Color(0xFFBF616A), Color(0xFFA3BE8C), Color(0xFFEBCB8B),
          Color(0xFF81A1C1), Color(0xFFB48EAD), Color(0xFF8FBCBB), Color(0xFFECEFF4),
        ],
      );
    case InstrumentKit.catppuccin:
      return _ansi(
        bg: const Color(0xFF1E1E2E),
        fg: const Color(0xFFCDD6F4),
        cursor: const Color(0xFFF5E0DC),
        c: const [
          Color(0xFF45475A), Color(0xFFF38BA8), Color(0xFFA6E3A1), Color(0xFFF9E2AF),
          Color(0xFF89B4FA), Color(0xFFF5C2E7), Color(0xFF94E2D5), Color(0xFFBAC2DE),
          Color(0xFF585B70), Color(0xFFF38BA8), Color(0xFFA6E3A1), Color(0xFFF9E2AF),
          Color(0xFF89B4FA), Color(0xFFF5C2E7), Color(0xFF94E2D5), Color(0xFFA6ADC8),
        ],
      );
    case InstrumentKit.aqua:
      return _ansi(
        bg: const Color(0xFF1E1E1E),
        fg: const Color(0xFFF2F2F2),
        cursor: const Color(0xFF0A84FF),
        c: const [
          Color(0xFF000000), Color(0xFFFF5F57), Color(0xFF28C840), Color(0xFFFEBC2E),
          Color(0xFF0A84FF), Color(0xFFBF5AF2), Color(0xFF64D2FF), Color(0xFFE5E5EA),
          Color(0xFF636366), Color(0xFFFF7B74), Color(0xFF4CD964), Color(0xFFFFD60A),
          Color(0xFF409CFF), Color(0xFFDA8FFF), Color(0xFF70D7FF), Color(0xFFFFFFFF),
        ],
      );
    case InstrumentKit.graphite:
      return _ansi(
        bg: const Color(0xFF15181B),
        fg: const Color(0xFFD5DADF),
        cursor: const Color(0xFFFF6A00),
        c: const [
          Color(0xFF22272D), Color(0xFFD0675F), Color(0xFF8DBF8B), Color(0xFFD9C27A),
          Color(0xFF7FA5CC), Color(0xFFB9A0CF), Color(0xFF7FC6C6), Color(0xFFC9CED4),
          Color(0xFF4A535C), Color(0xFFE08A83), Color(0xFFA8D4A6), Color(0xFFE8D69A),
          Color(0xFF9ABCDE), Color(0xFFCDB8E0), Color(0xFF9ADADA), Color(0xFFEEF1F4),
        ],
      );
  }
}


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

  static _Chrome of(BuildContext context) => forBrass(Brass.of(context));

  /// This palette for [b]'s family: Brass keeps the authored set; any other
  /// family gets each colour carried onto its own tokens ([themeColor]).
  static final _themed = <Brass, _Chrome>{};
  static _Chrome forBrass(Brass b) {
    final base = b.isDark ? dark : light;
    if (InstrumentKit.of(b) == InstrumentKit.brass) return base;
    return _themed.putIfAbsent(
      b,
      () => _Chrome(
        headerSubtitle: themeColor(base.headerSubtitle, b),
        tabSelectedBg: themeColor(base.tabSelectedBg, b),
        tabIdleBg: themeColor(base.tabIdleBg, b),
        tabSelectedBorder: themeColor(base.tabSelectedBorder, b),
        tabIdleBorder: themeColor(base.tabIdleBorder, b),
        tabSelectedText: themeColor(base.tabSelectedText, b),
        tabIdleText: themeColor(base.tabIdleText, b),
        tabCloseIcon: themeColor(base.tabCloseIcon, b),
        menuGroupHeader: themeColor(base.menuGroupHeader, b),
        connectBg1: themeColor(base.connectBg1, b),
        connectBg2: themeColor(base.connectBg2, b),
        connectBorder: themeColor(base.connectBorder, b),
        connectFg: themeColor(base.connectFg, b),
      ),
    );
  }
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
              iconColor: themeColor(const Color(0xFFDCE8F8), context.brass),
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
                                      style: TextStyle(
                                          color: themeColor(const Color(0xFFDD8078), context.brass)),
                                    ),
                                  )
                                : TerminalView(
                                    s.terminal,
                                    theme: terminalThemeFor(context),
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
                  color: session.exited ? themeColor(const Color(0xFF6A5040), context.brass) : null,
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
    return Center(
      child: Text(
        'No sessions — use Connect to open one.',
        style: TextStyle(
            color: themeColor(const Color(0xFF7F93B0), context.brass)),
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
    // The monitor housing: dark turned metal, screwed at the corners, with
    // the screen set into it.
    final m = context.brass.brassStops;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(m[3], Colors.black, 0.55)!,
            Color.lerp(m[4], Colors.black, 0.7)!,
          ],
        ),
        border: Border.all(color: m[3].withValues(alpha: 0.5)),
        boxShadow: context.brass.cardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _screen(context)),
          const Positioned(left: -5, top: -5, child: ScrewHead(angle: 0.6)),
          const Positioned(right: -5, top: -5, child: ScrewHead(angle: -1)),
          const Positioned(left: -5, bottom: -5, child: ScrewHead(angle: 1.2)),
          const Positioned(right: -5, bottom: -5, child: ScrewHead(angle: 0.2)),
        ],
      ),
    );
  }

  Widget _screen(BuildContext context) {
    final b = context.brass;
    final bg = terminalThemeFor(context).background;
    final titleInk = themeColor(const Color(0xFF7F93B0), b);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(bg, Colors.white, 0.02)!.withValues(alpha: 0.94),
            Color.lerp(bg, Colors.black, 0.25)!.withValues(alpha: 0.97),
          ],
        ),
        border: Border.all(color: themeColor(const Color(0x578CAFE0), b)),
        boxShadow: context.brass.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: themeColor(const Color(0x2E8CAFE0), b)),
              ),
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
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.5,
                      color: titleInk,
                    ),
                  ),
                ),
                // Balance the traffic lights so the title stays centered.
                const SizedBox(width: 50),
              ],
            ),
          ),
          Expanded(child: CrtGlass(child: child)),
        ],
      ),
    );
  }
}
