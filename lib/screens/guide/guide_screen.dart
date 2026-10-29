import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_config.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';

/// The in-app guide: what the app does and how to connect everything. It
/// opens by itself once the first Proxmox connection exists, until the
/// operator ticks "Don't show this again" (AppSettings.guideDismissed);
/// Settings, the About sheet and the command palette reopen it.
Future<void> showGuide(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const GuideDialog(),
);

class _Page {
  const _Page(this.icon, this.title, this.body);
  final IconData icon;
  final String title;

  /// Paragraphs; a line starting with "• " renders as a bullet.
  final List<String> body;
}

const _pages = [
  _Page(Ph.squaresFour, 'Welcome to $kAppName', [
    '$kAppName is one control room for your homelab: Proxmox VE and the '
        'services around it, each driven through its own API rather than '
        'an embedded web page.',
    '• Start, stop, snapshot, migrate and back up guests.',
    '• Request films, search documents and photos, control Home '
        'Assistant, chat with your models, watch pages for changes.',
    '• Every service tab has an Open in browser button for whatever its '
        'API cannot do.',
    'This guide walks through connecting everything. Use Next and Back, '
        'or close it at any time; it is always in Settings › Guide.',
  ]),
  _Page(Ph.hardDrives, 'Connect Proxmox', [
    'Proxmox VE is the centre. In the Proxmox web UI open Datacenter › '
        'Permissions › API Tokens and create a token for a user.',
    '• Read-only: give the user the PVEAuditor role. The dashboard and '
        'inventory work.',
    '• Management (start/stop, snapshots, create, delete): a role with '
        'write privileges, such as PVEAdmin.',
    'Enter the URL (https://your-host:8006), the token ID '
        '(user@realm!token) and the secret in Settings › Proxmox. '
        'Self-signed certificates are accepted for that host when "Trust '
        'self-signed certificate" is on.',
    'Several clusters? Settings › Connection profiles keeps one setup per '
        'cluster and switches between them.',
  ]),
  _Page(Ph.lockSimple, 'Add your services', [
    'Each service needs its URL and, for most, an API key. Both go in '
        'Settings; the keys are stored in your system keychain, never in a '
        'plain file. A tab appears in the sidebar once its service has a '
        'URL, and tells you exactly what is missing until it works.',
    '• Home Assistant: your profile › Security › Long-lived access tokens',
    '• Paperless-ngx: My Profile › API Auth Token',
    '• Immich: Account Settings › API Keys',
    '• Karakeep: Settings › API Keys',
    '• Seerr / Jellyseerr: Settings › General › API Key',
    '• Open WebUI: an admin first enables API keys (Admin Panel › '
        'Settings › General), then Settings › Account › API keys',
    '• changedetection.io: Settings › API',
    '• Wiki.js: Administration › API Access (enable the API, then create '
        'a key)',
    '• SearXNG: no key; its settings.yml must list json in '
        'search.formats',
    '• Jellyfin, Plex, Radarr, Sonarr, Prowlarr, qBittorrent, PDM, PBS, '
        'Grafana, Prometheus and Loki have their own sections in Settings.',
    'A key reaches only its own service, and the app can do no more than '
        'the key allows.',
  ]),
  _Page(Ph.fileText, 'Set everything up at once', [
    'Instead of typing each field, fill in the setup file once:',
    '• Copy setup/setup.example.json from the repository and fill in the '
        'services you run. Blank values are ignored, so a half-filled file '
        'never clears a working setting.',
    '• Import it from Settings › Setup file › Import setup file, or save '
        'it as ~/.config/peira/seed.json: the app imports it at the '
        'next launch and then deletes it, so your keys do not stay in a '
        'plain file.',
    'docs/setup-file.md lists every key and where each credential comes '
        'from.',
  ]),
  _Page(Ph.treeStructure, 'What each tab does', [
    '• Dashboard: cluster health, what needs attention, recent tasks.',
    '• Proxmox: nodes, containers and VMs, consoles, snapshots, backups.',
    '• PDM and PBS: every cluster in one view; backup datastores, '
        'snapshots, jobs and restores.',
    '• Docker: containers and images on a Docker host.',
    '• Metrics: Telemetry (Prometheus), Logs (Loki), Watches '
        '(changedetection.io).',
    '• AI: chat, the Ollama model library, Open WebUI, and private web '
        'search (SearXNG).',
    '• Media: Jellyfin, Plex, Radarr, Sonarr, qBittorrent, Prowlarr, '
        'Discover (Seerr) and Photos (Immich).',
    '• Home Assistant: every entity with its controls, services, logbook, '
        'lists and system tools.',
    '• Wiki: your Wiki.js pages, search, history and tags.',
    '• Library: Bookmarks (Karakeep) and Documents (Paperless-ngx).',
    '• Tailscale and Terminal: your tailnet, and shells into nodes and '
        'containers.',
  ]),
  _Page(Ph.compass, 'Tips', [
    '• Ctrl+K opens the command palette: jump to any tab or sub-view by '
        'name.',
    '• Hidden a tab you want? Settings › Show tabs for services not set '
        'up lists them all.',
    '• Run with --demo to explore with fake data; nothing is read or '
        'written.',
    '• Settings › Appearance changes the theme family and light or dark '
        'mode.',
    '• Destructive actions (delete, empty trash, restart) always ask '
        'first.',
    'You can reopen this guide from Settings › Guide, the About sheet or '
        'the command palette.',
  ]),
];

class GuideDialog extends ConsumerStatefulWidget {
  const GuideDialog({super.key});

  @override
  ConsumerState<GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends ConsumerState<GuideDialog> {
  final _pager = PageController();
  int _page = 0;
  late bool _dontShow =
      ref.read(settingsControllerProvider).value?.guideDismissed ?? false;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final s = ref.read(settingsControllerProvider).value;
    if (s != null && s.guideDismissed != _dontShow) {
      await ref
          .read(settingsControllerProvider.notifier)
          .save(s.copyWith(guideDismissed: _dontShow));
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _go(int page) => _pager.animateToPage(
    page,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final size = MediaQuery.sizeOf(context);
    final last = _page == _pages.length - 1;
    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: SizedBox(
        width: size.width.clamp(0, 860).toDouble(),
        height: size.height.clamp(0, 640).toDouble(),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pager,
                onPageChanged: (p) => setState(() => _page = p),
                children: [for (final p in _pages) _PageView(page: p)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: Row(
                children: [
                  Checkbox(
                    value: _dontShow,
                    onChanged: (v) => setState(() => _dontShow = v ?? false),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _dontShow = !_dontShow),
                    child: const Text("Don't show this again"),
                  ),
                  const Spacer(),
                  Text(
                    '${_page + 1} / ${_pages.length}',
                    style: TextStyle(color: brass.textMuted),
                  ),
                  const SizedBox(width: 16),
                  TextButton(onPressed: _close, child: const Text('Close')),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _page == 0 ? null : () => _go(_page - 1),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: last ? _close : () => _go(_page + 1),
                    child: Text(last ? 'Done' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});
  final _Page page;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 12),
      children: [
        Row(
          children: [
            Icon(page.icon, size: 30, color: brass.giltBright),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                page.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final line in page.body)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: line.startsWith('• ')
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 6, right: 10),
                        child: Text('•', style: TextStyle(color: brass.giltBright)),
                      ),
                      Expanded(child: SelectableText(line.substring(2))),
                    ],
                  )
                : SelectableText(line),
          ),
      ],
    );
  }
}
