import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../core/api/proxmox_api.dart';
import '../../core/console/proxmox_term_socket.dart';
import '../../core/providers/proxmox_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../terminal/terminal_screen.dart' show molTerminalTheme;

/// Live guest serial console: a native `xterm` terminal wired to Proxmox's
/// `vncwebsocket` PTY stream via [ProxmoxTermSocket]. Opened from the CT detail
/// screen for a running container or VM; the socket is torn down on dispose.
class ConsoleScreen extends ConsumerStatefulWidget {
  const ConsoleScreen({
    super.key,
    required this.kind,
    required this.node,
    required this.vmid,
    required this.title,
  });

  final GuestKind kind;
  final String node;
  final int vmid;
  final String title;

  @override
  ConsumerState<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends ConsumerState<ConsoleScreen> {
  final _terminal = Terminal(maxLines: 10000);
  ProxmoxTermSocket? _socket;
  Object? _error;
  bool _connecting = true;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      final settings = await ref.read(settingsControllerProvider.future);
      final api = await ref.read(proxmoxApiProvider.future);
      final ticket = await api.guestTermProxy(
        widget.kind,
        widget.node,
        widget.vmid,
      );
      final socket = ProxmoxTermSocket(
        settings: settings,
        kind: widget.kind,
        node: widget.node,
        vmid: widget.vmid,
        ticket: ticket,
      );
      socket.output.listen(
        _terminal.write,
        onError: (Object e) {
          if (mounted) setState(() => _error = e);
        },
        onDone: () {
          _terminal.write('\r\n[console closed]\r\n');
        },
      );
      _terminal.onOutput = socket.write;
      _terminal.onResize = (w, h, pw, ph) => socket.resize(w, h);
      await socket.connect(
        cols: _terminal.viewWidth,
        rows: _terminal.viewHeight,
      );
      if (!mounted) {
        socket.dispose();
        return;
      }
      setState(() {
        _socket = socket;
        _connecting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = widget.kind == GuestKind.qemu
              ? 'Could not open the VM serial console. Ensure the VM has a '
                    'serial device configured (for example, serial0: socket), '
                    'then retry.\n$e'
              : e;
          _connecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Console — ${widget.kind.label} ${widget.vmid} ${widget.title}',
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Console unavailable.\n$_error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _connecting = true;
                        });
                        _connect();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reconnect'),
                    ),
                  ],
                ),
              ),
            )
          : _connecting
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  // The console keeps its dark bezel slab in both modes, like
                  // the terminal viewport; only the drop shadow re-inks.
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
                  child: TerminalView(
                    _terminal,
                    // Grab the keyboard on open; without this the console
                    // connects but keystrokes never reach the socket.
                    autofocus: true,
                    theme: molTerminalTheme,
                    textStyle: const TerminalStyle(
                      fontFamily: 'JetBrains Mono',
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
    );
  }
}
