import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pdm_api.dart';
import '../../core/providers/pdm_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mol_motion.dart';
import '../../core/theme/phosphor.dart';
import '../../core/util/open_url.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/status_light.dart';

/// Proxmox Datacenter Manager status on the Proxmox tab: reachability, the
/// registered remotes with their cluster state (audit-scope API token), and
/// the browser deep-link — PDM's own UI stays the place for anything deeper
/// (its self-signed cert keeps it out of the embedded webviews).
///
/// Renders nothing until a PDM URL is configured, so operators without PDM
/// never see it.
class PdmPanel extends ConsumerWidget {
  const PdmPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brass = context.brass;
    final settings = ref.watch(settingsControllerProvider).value;
    if (settings == null || !settings.pdmConfigured) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(pdmPanelProvider);

    Future<void> open() async {
      final err = await openUrl(settings.pdmUrl);
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }

    final (health, healthText) = switch (state) {
      AsyncData(:final value) when !value.reachable => (
          Health.crit,
          'not answering'
        ),
      AsyncData(:final value) when value.tokenRejected => (
          Health.warn,
          'token rejected'
        ),
      AsyncData() => (Health.ok, 'online'),
      AsyncError() => (Health.warn, 'error'),
      _ => (Health.offline, 'checking…'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BrassSectionHeader(title: 'Datacenter'),
        const SizedBox(height: 10),
        BrassPanel(
          padding: const EdgeInsets.fromLTRB(
            MolSpace.lg,
            MolSpace.md,
            MolSpace.lg,
            MolSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Ph.treeStructure, size: 18, color: brass.bronze),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Datacenter Manager',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: brass.sand,
                      ),
                    ),
                  ),
                  StatusLight(health: health, size: 8),
                  const SizedBox(width: 8),
                  Text(
                    healthText,
                    style: TextStyle(fontSize: 12, color: brass.textMuted),
                  ),
                  const SizedBox(width: MolSpace.md),
                  TextButton(
                    onPressed: open,
                    child: const Text('Open PDM'),
                  ),
                ],
              ),
              switch (state) {
                AsyncData(:final value) => _body(context, value),
                AsyncError(:final error) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'PDM error: $error',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12, color: brass.textMuted),
                    ),
                  ),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, PdmPanelState state) {
    final brass = context.brass;
    Widget note(String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: brass.textMuted),
          ),
        );
    if (!state.reachable) {
      return note(
        'PDM is not answering — check the URL, and that the certificate '
        'fingerprint in Settings matches (self-signed certs are pinned, '
        'not blanket-trusted).',
      );
    }
    if (state.tokenRejected) {
      return note('PDM rejected the API token (401) — re-check the token '
          'ID and secret in Settings.');
    }
    final remotes = state.status?.remotes;
    if (remotes == null) {
      return note('Add a PDM API token in Settings to see remote status '
          'here natively.');
    }
    if (remotes.isEmpty) {
      return note('No remotes registered in PDM yet.');
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [for (final r in remotes) _RemoteRow(remote: r)],
      ),
    );
  }
}

class _RemoteRow extends StatelessWidget {
  const _RemoteRow({required this.remote});

  final PdmRemote remote;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final r = remote;
    final String detail;
    final Health health;
    if (r.type == 'pbs') {
      detail = 'backup server';
      health = Health.ok;
    } else if (r.nodesTotal == null) {
      detail = 'status unavailable';
      health = Health.warn;
    } else {
      final q = switch (r.quorate) {
        true => ' · quorate',
        false => ' · NO QUORUM',
        null => '',
      };
      detail = '${r.nodesOnline}/${r.nodesTotal} nodes online$q';
      health = r.quorate == false || r.nodesOnline != r.nodesTotal
          ? Health.warn
          : Health.ok;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          StatusLight(health: health, size: 7),
          const SizedBox(width: 10),
          Text(
            r.type.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: brass.bronze,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              r.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: brass.textHeading,
              ),
            ),
          ),
          Text(
            detail,
            style: TextStyle(fontSize: 12, color: brass.textMuted),
          ),
        ],
      ),
    );
  }
}
