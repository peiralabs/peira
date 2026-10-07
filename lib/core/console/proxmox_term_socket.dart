import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../api/proxmox_api.dart';
import '../models/app_settings.dart';

/// A live guest serial console over Proxmox's `vncwebsocket`, speaking the pve-xtermjs
/// wire protocol so it can drive an `xterm` [Terminal] directly.
///
/// Flow (all over the app's API token — no login cookie needed, verified live):
///   1. caller does `ProxmoxApi.guestTermProxy` → [TermProxyTicket]
///   2. [connect] opens `wss://…/vncwebsocket?port=&vncticket=` with the token
///      in the `Authorization` header and the `binary` subprotocol
///   3. first frame sent is the auth line `user:ticket\n`; Proxmox replies `OK`
///      (consumed, not echoed), after which we send the initial terminal size
///
/// Wire framing (client→server): `0:<utf8-bytelen>:<data>` for keystrokes,
/// `1:<cols>:<rows>:` for resize, `2` as a keepalive ping. Server→client frames
/// are raw terminal output written straight to the terminal.
class ProxmoxTermSocket {
  ProxmoxTermSocket({
    required this.settings,
    required this.kind,
    required this.node,
    required this.vmid,
    required this.ticket,
  });

  final AppSettings settings;
  final GuestKind kind;
  final String node;
  final int vmid;
  final TermProxyTicket ticket;

  WebSocket? _ws;
  Timer? _ping;
  bool _authed = false;
  final _output = StreamController<String>();

  /// Terminal output from the guest. Closes when the socket closes.
  Stream<String> get output => _output.stream;

  Future<void> connect({required int cols, required int rows}) async {
    final base = Uri.parse(settings.proxmoxUrl);
    final uri = Uri(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/api2/json/nodes/$node/${kind.pathSegment}/$vmid/vncwebsocket',
      queryParameters: {'port': '${ticket.port}', 'vncticket': ticket.ticket},
    );

    // Host-scoped self-signed trust, mirroring ProxmoxApi.fromSettings — never
    // a global override.
    HttpClient? client;
    if (settings.trustSelfSigned) {
      client = HttpClient()
        ..badCertificateCallback = (cert, host, port) => host == base.host;
    }

    final ws = await WebSocket.connect(
      uri.toString(),
      protocols: const ['binary'],
      headers: {
        'Authorization':
            'PVEAPIToken=${settings.proxmoxTokenId}=${settings.proxmoxTokenSecret}',
      },
      customClient: client,
    );
    _ws = ws;

    // pve-xtermjs auth handshake: the first frame is the login line.
    ws.add('${ticket.user}:${ticket.ticket}\n');
    ws.listen(
      (data) => _onData(data, cols, rows),
      onDone: _close,
      onError: (Object e) {
        if (!_output.isClosed) _output.addError(e);
        _close();
      },
    );

    // Keepalive so the proxy doesn't reap an idle console.
    _ping = Timer.periodic(const Duration(seconds: 30), (_) => _ws?.add('2'));
  }

  void _onData(dynamic data, int cols, int rows) {
    final text = data is String
        ? data
        : utf8.decode(data as List<int>, allowMalformed: true);
    if (!_authed) {
      // Proxmox sends "OK" on a successful auth; swallow it and send the
      // initial terminal size, then stream everything after.
      _authed = true;
      resize(cols, rows);
      return;
    }
    if (!_output.isClosed) _output.add(text);
  }

  /// Sends keystrokes to the guest PTY.
  void write(String input) {
    final len = utf8.encode(input).length;
    _ws?.add('0:$len:$input');
  }

  /// Tells the guest PTY the new window size.
  void resize(int cols, int rows) => _ws?.add('1:$cols:$rows:');

  void _close() {
    _ping?.cancel();
    _ping = null;
    if (!_output.isClosed) _output.close();
  }

  void dispose() {
    _close();
    _ws?.close();
    _ws = null;
  }
}
