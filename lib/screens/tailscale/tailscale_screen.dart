import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/tailscale_cli.dart';
import '../../core/models/tailscale_status.dart';
import '../../core/providers/tailscale_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_icon_badge.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/screen_header.dart';

/// Native Tailscale view in the Brass Edition language (design §8): navy
/// screen header with the backend-state enamel pill, blue divider, a navy
/// "This device" card, then the peer roster (online first). Tapping the copy
/// stud copies a device's Tailscale IP.
class TailscaleScreen extends ConsumerWidget {
  const TailscaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(tailscaleStatusProvider);

    return status.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              e is TailscaleUnavailable
                  ? 'Tailscale is not available on this device.\n$e'
                  : 'Failed to read Tailscale status:\n$e',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(tailscaleStatusProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (s) {
        final palette = _Palette.of(context);
        final deviceCount = s.peers.length + 1;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tailscaleStatusProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
            children: [
              ScreenHeader(
                icon: Ph.shieldCheck,
                badgeField: BrassIconBadge.navyField,
                iconColor: const Color(0xFFDCE8F8),
                title: 'Tailscale',
                subtitle: 'TAILNET MESH · $deviceCount DEVICE'
                    '${deviceCount == 1 ? '' : 'S'}',
                subtitleColor: palette.subtitle,
                trailing: [
                  const SizedBox(width: 12),
                  _StatePill(
                      running: s.running, backendState: s.backendState),
                ],
              ),
              const SizedBox(height: 16),
              const SectionDivider.blue(),
              const SizedBox(height: 18),
              const _NavyLabel('This device'),
              const SizedBox(height: 8),
              _DeviceRow(device: s.self, isSelf: true),
              const SizedBox(height: 18),
              _NavyLabel('Peers (${s.peers.length})'),
              const SizedBox(height: 8),
              for (final p in s.peers) _DeviceRow(device: p),
            ],
          ),
        );
      },
    );
  }
}

/// Small-caps navy section label (`THIS DEVICE` / `PEERS (N)`).
class _NavyLabel extends StatelessWidget {
  const _NavyLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.5,
        letterSpacing: 11.5 * 0.16,
        color: _Palette.of(context).sectionLabel,
      ),
    );
  }
}

/// Green enamel backend-state pill ("Running") — red-tinted when stopped.
class _StatePill extends StatelessWidget {
  const _StatePill({required this.running, required this.backendState});

  final bool running;
  final String backendState;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final dotJewel = running ? Brass.emerald : Brass.ruby;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: running
              ? const [Color(0xCC2E4A30), Color(0xCC182B1A)]
              : const [Color(0xCC4A2B28), Color(0xCC2B1715)],
        ),
        border: Border.all(
          color: running ? const Color(0x8C7BB26A) : const Color(0x8CC8564A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: dotJewel.cabochon,
              boxShadow: brass.jewelHalo(dotJewel),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            backendState,
            style: TextStyle(
              fontSize: 12.5,
              color: running
                  ? const Color(0xFFC8E6BA)
                  : const Color(0xFFE6BAB4),
            ),
          ),
        ],
      ),
    );
  }
}

/// A navy device card/row. The self card is heavier (design §8); peers are a
/// lighter wash and slide right 4px with a brightened border on hover.
class _DeviceRow extends StatefulWidget {
  const _DeviceRow({required this.device, this.isSelf = false});

  final TailscaleDevice device;
  final bool isSelf;

  @override
  State<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends State<_DeviceRow> {
  bool _hover = false;

  /// OS cabochon: linux = emerald, iOS/android = sapphire, offline = muted.
  Jewel get _jewel {
    if (!widget.isSelf && !widget.device.online) {
      return const Jewel(
          Color(0xFF9BA6B8), Color(0xFF5A6578), Color(0xFF2A3140));
    }
    final os = widget.device.os.toLowerCase();
    if (os.contains('ios') || os.contains('android')) {
      return Brass.sapphire;
    }
    return Brass.emerald;
  }

  Future<void> _copyIp(BuildContext context) async {
    final ip = widget.device.ip;
    await Clipboard.setData(ClipboardData(text: ip));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Copied $ip')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final brass = context.brass;
    final device = widget.device;
    final isSelf = widget.isSelf;
    final online = isSelf || device.online;
    final meta = [
      if (device.ip.isNotEmpty) device.ip,
      if (device.os.isNotEmpty) device.os,
      if (device.exitNodeOption) 'exit node',
      if (!online) 'offline',
    ].join(' · ');
    final jewel = _jewel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform:
              Matrix4.translationValues(!isSelf && _hover ? 4 : 0, 0, 0),
          padding: EdgeInsets.symmetric(
              horizontal: 15, vertical: isSelf ? 13 : 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelf
                  ? [palette.selfCardTop, palette.selfCardBottom]
                  : [palette.peerCardTop, palette.peerCardBottom],
            ),
            border: Border.all(
              color: isSelf || _hover
                  ? palette.cardBorderHover
                  : palette.cardBorderRest,
            ),
            boxShadow: brass.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: isSelf ? 10 : 9,
                height: isSelf ? 10 : 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: jewel.cabochon,
                  boxShadow: online ? brass.jewelHalo(jewel) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSelf
                          ? '${device.hostName} (this device)'
                          : device.hostName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontWeight:
                            isSelf ? FontWeight.w700 : FontWeight.w600,
                        fontSize: isSelf ? 18 : 16,
                        color: palette.hostname,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          color: palette.meta,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (device.ip.isNotEmpty)
                IconButton(
                  tooltip: 'Copy Tailscale IP',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Ph.copy, size: 16),
                  color: palette.copyStud,
                  onPressed: () => _copyIp(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// This tab's navy ink family, brightness-resolved. Dark values are verbatim
/// from the dark-only era; light is the parchment navy-paper slice. The
/// enamel state pill and the offline grey jewel are shared dark objects and
/// keep their literals above.
class _Palette {
  const _Palette({
    required this.subtitle,
    required this.sectionLabel,
    required this.selfCardTop,
    required this.selfCardBottom,
    required this.peerCardTop,
    required this.peerCardBottom,
    required this.cardBorderHover,
    required this.cardBorderRest,
    required this.hostname,
    required this.meta,
    required this.copyStud,
  });

  final Color subtitle;
  final Color sectionLabel;
  final Color selfCardTop;
  final Color selfCardBottom;
  final Color peerCardTop;
  final Color peerCardBottom;
  final Color cardBorderHover;
  final Color cardBorderRest;
  final Color hostname;
  final Color meta;
  final Color copyStud;

  static const dark = _Palette(
    subtitle: Color(0xFF9DB8DD),
    sectionLabel: Color(0xFF8FABD6),
    selfCardTop: Color(0xB8203048),
    selfCardBottom: Color(0xD1101926),
    peerCardTop: Color(0x80203048),
    peerCardBottom: Color(0xA6101926),
    cardBorderHover: Color(0x668CAFE0),
    cardBorderRest: Color(0x3D8CAFE0),
    hostname: Color(0xFFEEF2F8),
    meta: Color(0xFF9DB8DD),
    copyStud: Color(0xFF8FABD6),
  );

  static const light = _Palette(
    subtitle: Color(0xFF425C86),
    sectionLabel: Color(0xFF3A5E92),
    // Parchment paper with a subtle navy tint (self ≈8% navy over the panel
    // family, peers ≈5%) — the earlier periwinkle fills read as cool
    // grey-blue islands on the warm field. The navy hairline border and
    // inks keep the section identity.
    // Warmed again (was 0xFFE5E2DC / 0xFFDFDAD1): even the 8% navy wash
    // read as a grey island; the self card now stays parchment-warm and a
    // step deeper than the peers, with the navy border carrying identity.
    selfCardTop: Color(0xFFE4DECC),
    selfCardBottom: Color(0xFFDBD2BC),
    peerCardTop: Color(0xFFEBE7DE),
    peerCardBottom: Color(0xFFE4DED3),
    cardBorderHover: Color(0x8C3A5E96),
    cardBorderRest: Color(0x4D3A5E96),
    hostname: Color(0xFF22304A),
    meta: Color(0xFF3E5A86),
    copyStud: Color(0xFF3A5E92),
  );

  static _Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
