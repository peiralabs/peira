import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../screens/guide/guide_screen.dart';
import '../theme/app_theme.dart';
import '../theme/phosphor.dart';
import '../update/update_check.dart';
import 'astrolabe.dart';
import 'brass_ornament.dart';
import 'raised_dial.dart';

/// The About overlay (design §Overlays): dimmed backdrop (click to dismiss),
/// gilded card, the full astrolabe installed in a ledge, wordmark, and the
/// engraved plate line.
Future<void> showAboutHomeLab(BuildContext context) {
  // The guide opens from the caller's context once the sheet has closed.
  final host = context;
  // The barrier is a route property, fixed at show time; the card itself
  // re-resolves in pageBuilder on theme flips.
  final barrier = _Palette.forBrass(context.brass);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'About',
    barrierColor: barrier.barrier,
    pageBuilder: (context, _, _) {
      final brass = context.brass;
      final palette = _Palette.forBrass(brass);
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.cardTop, palette.cardBottom],
              ),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  offset: const Offset(0, 34),
                  blurRadius: 74,
                  spreadRadius: -20,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Inside the Stack bounds — RenderStack rejects hit tests
                // outside its rect even with Clip.none, so the stud lives at
                // the card corner (where the design puts it anyway).
                Positioned(
                  top: 12,
                  right: 12,
                  child: BrassStud(
                    icon: PhBold.x,
                    size: 26,
                    tooltip: 'Close',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 34, 44, 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrassLedge(
                        radius: double.infinity,
                        padding: EdgeInsets.all(12),
                        depth: 8,
                        child: RaisedDial(
                          diameter: 150,
                          child: Astrolabe(size: 150),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const GiltWordmark(fontSize: 26, letterSpacingEm: 0.16),
                      const SizedBox(height: 8),
                      Text(
                        'CONTROL ROOM',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 12 * 0.24,
                          color: palette.subtitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: GiltRule(reverse: true)),
                          const SizedBox(width: 12),
                          Transform.rotate(
                            angle: 0.785398,
                            child: Container(
                              width: 5,
                              height: 5,
                              color: brass.giltDeep,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: GiltRule()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '4 NODES · 55 W IDLE · SELF-HOSTED',
                        style: TextStyle(
                          fontSize: 14.5,
                          letterSpacing: 14.5 * 0.14,
                          color: palette.tagline,
                        ),
                      ),
                      const SizedBox(height: 6),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse('https://peiralabs.com'),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Text(
                            'PEIRALABS.COM',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 13,
                              color: brass.bronze,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (host.mounted) showGuide(host);
                        },
                        icon: const Icon(Icons.menu_book_outlined, size: 16),
                        label: const Text('Open the guide'),
                      ),
                      Text(
                        'v$kAppVersion · Brass Edition',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.version,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// About-card inks, resolved per brightness: dark values verbatim from the
/// dark-only era; light is parchment card, bronze rule border, and umber ink
/// shadow (never black on paper).
class _Palette {
  const _Palette({
    required this.barrier,
    required this.cardTop,
    required this.cardBottom,
    required this.border,
    required this.shadow,
    required this.subtitle,
    required this.tagline,
    required this.version,
  });

  final Color barrier;
  final Color cardTop;
  final Color cardBottom;
  final Color border;
  final Color shadow;
  final Color subtitle;
  final Color tagline;
  final Color version;

  static const dark = _Palette(
    barrier: Color(0xB8060A07), // rgba(6,10,7,.72)
    cardTop: Color(0xFA253727),
    cardBottom: Color(0xFC0F1A12),
    border: Color(0x66C9AA58),
    shadow: Color(0xD1000000),
    subtitle: Color(0xFF9DB089),
    tagline: Color(0xFFC9B98A),
    version: Color(0xFF7F8B70),
  );

  static const light = _Palette(
    barrier: Color(0x8C46381F), // 55% umber dim, not black
    cardTop: Color(0xFAF6F0E2),
    cardBottom: Color(0xFCEAE0CA),
    border: Color(0x736E5220),
    shadow: Color(0x5946381F),
    subtitle: Color(0xFF55684A),
    tagline: Color(0xFF6E5A28),
    version: Color(0xFF6B675C),
  );

  /// This palette for [b]'s family: Brass keeps the authored set; any other
  /// family gets each colour carried onto its own tokens ([themeColor]).
  static final _themed = <Brass, _Palette>{};
  static _Palette forBrass(Brass b) {
    final base = b.isDark ? dark : light;
    if (InstrumentKit.of(b) == InstrumentKit.brass) return base;
    return _themed.putIfAbsent(
      b,
      () => _Palette(
        barrier: themeColor(base.barrier, b),
        cardTop: themeColor(base.cardTop, b),
        cardBottom: themeColor(base.cardBottom, b),
        border: themeColor(base.border, b),
        shadow: themeColor(base.shadow, b),
        subtitle: themeColor(base.subtitle, b),
        tagline: themeColor(base.tagline, b),
        version: themeColor(base.version, b),
      ),
    );
  }
}
