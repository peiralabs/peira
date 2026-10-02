import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_config.dart';
import '../../core/models/app_settings.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/brass.dart';
import '../../core/theme/mol_motion.dart';
import '../../core/theme/phosphor.dart';
import '../../core/util/open_url.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/screen_header.dart';
import 'setup_probe.dart';

/// First-run setup: the app used to gate on a blank Settings screen with a
/// ~30-field model and no guidance (the adoption cliff, card t_abe366ce).
/// This asks for the ONLY three values that matter — Proxmox URL, token id,
/// token secret — proves them with a real connection test that names the
/// actual failure, and says out loud that everything else is optional.
class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  final _url = TextEditingController();
  final _tokenId = TextEditingController();
  final _secret = TextEditingController();
  bool _trust = true; // virtually every homelab PVE is self-signed
  bool _testing = false;
  ProbeResult? _result;

  static const _pveumCommands = 'pveum user add app@pve\n'
      'pveum acl modify / --users app@pve --roles PVEAuditor\n'
      'pveum user token add app@pve homelab --privsep 0';

  static const _docsUrl =
      'https://pve.proxmox.com/wiki/User_Management#pveum_tokens';

  bool get _filled =>
      _url.text.trim().isNotEmpty &&
      _tokenId.text.trim().isNotEmpty &&
      _secret.text.trim().isNotEmpty;

  @override
  void dispose() {
    _url.dispose();
    _tokenId.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    final probe = ref.read(setupProbeProvider);
    final result = await probe(
      url: _url.text.trim(),
      tokenId: _tokenId.text.trim(),
      tokenSecret: _secret.text.trim(),
      trustSelfSigned: _trust,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = result;
    });
  }

  Future<void> _save() async {
    // Preserve anything a seed file already provided; only the wizard's
    // fields are overwritten.
    final base =
        ref.read(settingsControllerProvider).value ?? const AppSettings();
    await ref.read(settingsControllerProvider.notifier).save(base.copyWith(
          proxmoxUrl: _url.text.trim(),
          proxmoxTokenId: _tokenId.text.trim(),
          proxmoxTokenSecret: _secret.text.trim(),
          trustSelfSigned: _trust,
        ));
    // The shell watches settings; once configured it swaps this screen for
    // the dashboard on its own.
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MolSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: BrassPanel(
              child: Padding(
                padding: const EdgeInsets.all(MolSpace.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenHeader(
                      icon: Ph.hardDrives,
                      title: 'Connect your Proxmox',
                      subtitle: 'ONE NODE IS ENOUGH',
                    ),
                    const SizedBox(height: MolSpace.lg),
                    Text(
                      'Three values and you have a dashboard. Everything '
                      'else in Settings is optional and can wait.',
                      style: TextStyle(color: brass.textBody),
                    ),
                    const SizedBox(height: MolSpace.lg),
                    _field(_url, 'Proxmox URL', 'https://10.0.0.5:8006'),
                    const SizedBox(height: MolSpace.md),
                    _field(_tokenId, 'API token ID', 'app@pve!homelab'),
                    const SizedBox(height: MolSpace.md),
                    _field(_secret, 'API token secret',
                        'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                        obscure: true),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _trust,
                      onChanged: (v) => setState(() => _trust = v),
                      title: Text("Trust this host's certificate",
                          style: TextStyle(color: brass.textBody)),
                      subtitle: Text(
                        'Proxmox ships self-signed; this accepts that '
                        'certificate for the Proxmox host only. Services you '
                        'add later (Prometheus, media, wiki) are not covered '
                        'by this exception — give them real certificates or '
                        'plain HTTP.',
                        style:
                            TextStyle(color: brass.textMuted, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: MolSpace.md),
                    Wrap(
                      spacing: MolSpace.md,
                      runSpacing: MolSpace.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _filled && !_testing ? _test : null,
                          icon: _testing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Ph.lightning, size: 16),
                          label: const Text('Test connection'),
                        ),
                        FilledButton.icon(
                          onPressed: _filled && !_testing ? _save : null,
                          icon: const Icon(Ph.house, size: 16),
                          label: const Text('Save & open dashboard'),
                        ),
                      ],
                    ),
                    if (_result != null) ...[
                      const SizedBox(height: MolSpace.md),
                      _ResultPanel(result: _result!),
                    ],
                    const SizedBox(height: MolSpace.lg),
                    const _TokenHelp(
                        commands: _pveumCommands, docsUrl: _docsUrl),
                    const SizedBox(height: MolSpace.lg),
                    const _LaterList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, String hint,
          {bool obscure = false}) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result});

  final ProbeResult result;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final (color, icon, text) = switch (result) {
      ProbeSuccess(:final version, :final nodes) => (
          brass.moss,
          Ph.checkCircle,
          'Proxmox $version — found ${nodes.length} '
              'node${nodes.length == 1 ? '' : 's'}: ${nodes.join(', ')}',
        ),
      ProbeFailure(:final message) => (brass.madder, Ph.warning, message),
    };
    return Container(
      padding: const EdgeInsets.all(MolSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MolRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        color: color.withValues(alpha: 0.10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: MolSpace.sm),
          Expanded(
            child: Text(text, style: TextStyle(color: brass.textBody)),
          ),
        ],
      ),
    );
  }
}

class _TokenHelp extends StatelessWidget {
  const _TokenHelp({required this.commands, required this.docsUrl});

  final String commands;
  final String docsUrl;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NEED A TOKEN?',
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 11 * 0.18,
                color: brass.smallCaps)),
        const SizedBox(height: MolSpace.sm),
        Text(
          'Run this on the Proxmox host — read-only to start; swap '
          'PVEAuditor for PVEAdmin later if you want start/stop/create '
          'from the app. The token ID is then app@pve!homelab.',
          style: TextStyle(color: brass.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: MolSpace.sm),
        Container(
          padding: const EdgeInsets.all(MolSpace.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MolRadius.md),
            color: brass.bg.withValues(alpha: 0.55),
            border: Border.all(color: brass.hairline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  commands,
                  style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.5,
                      height: 1.6,
                      color: brass.textBody),
                ),
              ),
              IconButton(
                tooltip: 'Copy commands',
                icon: const Icon(Ph.copy, size: 16),
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: commands)),
              ),
            ],
          ),
        ),
        const SizedBox(height: MolSpace.sm),
        InkWell(
          onTap: () => openUrl(docsUrl),
          child: Text(
            'Proxmox docs: User Management › API tokens',
            style: TextStyle(
                color: brass.verdigris,
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: brass.verdigris),
          ),
        ),
      ],
    );
  }
}

/// Which tabs light up as services get added — so "optional" is concrete.
class _LaterList extends StatelessWidget {
  const _LaterList();

  static const _rows = [
    (Ph.chartLineUp, 'Metrics', 'Prometheus with node_exporter'),
    (
      Ph.brain,
      'AI',
      kPublicBuild
          ? 'any OpenAI-compatible endpoint (Ollama, LiteLLM, vLLM…)'
          : 'Ollama + Hermes',
    ),
    (Ph.monitorPlay, 'Media',
        'Jellyfin, Plex, Radarr, Sonarr, qBittorrent, Prowlarr'),
    (
      Ph.bookOpenText,
      kPublicBuild ? 'Wiki' : 'Vault',
      kPublicBuild ? 'Wiki.js' : 'Wiki.js + Ask',
    ),
    (Ph.terminalWindow, 'Terminal & Tailscale',
        'work now on desktop — nothing to configure'),
  ];

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LIGHTS UP LATER, FROM SETTINGS',
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 11 * 0.18,
                color: brass.smallCaps)),
        const SizedBox(height: MolSpace.sm),
        for (final (icon, tab, needs) in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 15, color: brass.sage),
                const SizedBox(width: MolSpace.sm),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '$tab — ',
                          style: TextStyle(color: brass.textBody)),
                      TextSpan(
                          text: needs,
                          style: TextStyle(color: brass.textMuted)),
                    ]),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
