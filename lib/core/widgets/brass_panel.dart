import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Brass Edition card/panel surface (design §Design Tokens "Greens"):
/// green-field gradient, gilt hairline border, `0 3px 0` contact shadow with
/// an inset top highlight, optional top gilt rule, and the standard hover
/// lift (translateY(-3px) + brighter border + deeper shadow).
class BrassPanel extends StatefulWidget {
  const BrassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.banner = false,
    this.topRule = false,
    this.topRuleColor,
    this.hoverLift = false,
    this.onTap,
    this.fill,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Banner variant: radius 16, deeper gradient, inner vignette (grand
  /// banner / instruments panel).
  final bool banner;

  /// Draw the 2px gilt hairline along the top edge (node/telemetry cards).
  final bool topRule;

  /// Tint of the top rule's center (defaults to gilt).
  final Color? topRuleColor;

  final bool hoverLift;
  final VoidCallback? onTap;

  /// Optional surface override: e.g. the Ollama screen's garnet-tinted model
  /// cards. Callers resolve it per brightness; null keeps the field gradient.
  final LinearGradient? fill;

  /// Optional resting border override to match [fill].
  final Color? borderColor;

  @override
  State<BrassPanel> createState() => _BrassPanelState();
}

class _BrassPanelState extends State<BrassPanel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = brass.isDark ? _Palette.dark : _Palette.light;
    final radius = BorderRadius.circular(widget.banner ? 16 : 14);
    final lifted = widget.hoverLift && _hover;

    final gradient = widget.fill ??
        (widget.banner
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pal.bannerTop, pal.bannerBottom],
              )
            : brass.isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xEB223224), Color(0xF00F1912)],
                  )
                : brass.panelGradient);
    final borderColor = lifted
        ? pal.hoverBorder
        : widget.borderColor ??
            (widget.banner ? pal.bannerBorder : brass.panelBorder);

    Widget panel = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, lifted ? -3 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: gradient,
        border: Border.all(color: borderColor),
        boxShadow: lifted ? brass.hoverShadow : brass.cardShadow,
      ),
      // Inset top highlight lip.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border(top: BorderSide(color: pal.topLip)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            if (widget.banner)
              // Inner vignette: inset 0 0 60px rgba(0,0,0,.35) — umber ink
              // instead of black on parchment.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.2,
                        colors: [
                          Colors.transparent,
                          brass.isDark
                              ? Colors.black.withValues(alpha: 0.35)
                              : const Color(0x1F46381F),
                        ],
                        stops: const [0.62, 1],
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.topRule)
              Positioned(
                top: 0,
                left: 14,
                right: 14,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (widget.topRuleColor ?? pal.topRuleGilt)
                            .withValues(alpha: 0),
                        widget.topRuleColor ?? pal.topRuleGilt,
                        widget.topRuleColor ?? pal.topRuleCenter,
                        widget.topRuleColor ?? pal.topRuleGilt,
                        (widget.topRuleColor ?? pal.topRuleGilt)
                            .withValues(alpha: 0),
                      ],
                      stops: const [0, 0.3, 0.5, 0.7, 1],
                    ),
                  ),
                ),
              ),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );

    if (widget.hoverLift || widget.onTap != null) {
      panel = MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: widget.onTap != null
            ? GestureDetector(onTap: widget.onTap, child: panel)
            : panel,
      );
    }
    return panel;
  }
}

/// File-local dark/light pairs for the panel dress. Dark values are verbatim
/// from the dark-only era; light values come from the parchment mapping
/// (sunlit banner paper, bronze-ink borders, a warm paper-sheen lip, and a
/// top rule whose cream hot-spot inverts to the darkest bronze).
class _Palette {
  const _Palette({
    required this.bannerTop,
    required this.bannerBottom,
    required this.hoverBorder,
    required this.bannerBorder,
    required this.topLip,
    required this.topRuleGilt,
    required this.topRuleCenter,
  });

  final Color bannerTop;
  final Color bannerBottom;
  final Color hoverBorder;
  final Color bannerBorder;
  final Color topLip;
  final Color topRuleGilt;
  final Color topRuleCenter;

  static const dark = _Palette(
    bannerTop: Color(0xF0253727),
    bannerBottom: Color(0xF50F1A12),
    hoverBorder: Color(0x80E8CD78),
    bannerBorder: Color(0x5CC9AA58),
    topLip: Color(0x1AFFF4C8),
    topRuleGilt: Color(0xFFD9B45E),
    topRuleCenter: Color(0xFFFFF6CF),
  );

  static const light = _Palette(
    bannerTop: Color(0xF0F6F0E4),
    bannerBottom: Color(0xF5EAE0CA),
    hoverBorder: Color(0x998A6A2A),
    bannerBorder: Color(0x668A6A2A),
    topLip: Color(0x66FFFBEE),
    topRuleGilt: Color(0xFFA9852F),
    topRuleCenter: Color(0xFF6E5220),
  );
}
