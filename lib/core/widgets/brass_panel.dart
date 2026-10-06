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
    final radius = BorderRadius.circular(widget.banner ? 16 : 14);
    final lifted = widget.hoverLift && _hover;
    // Panel dress, all from the active family: the banner variant deepens the
    // field; the lip and top rule read off the theme's metal.
    final hoverBorder = brass.giltBright.withValues(alpha: brass.isDark ? 0.5 : 0.6);
    final topLip = brass.brassStops[2].withValues(alpha: brass.isDark ? 0.1 : 0.4);
    final topRuleGilt = brass.brassStops[3];
    final topRuleCenter = brass.brassStops[2];
    // The top-rule gradient's edge and mid inks (an optional override, else
    // the theme's metal).
    final ruleEdge = widget.topRuleColor ?? topRuleGilt;
    final ruleMid = widget.topRuleColor ?? topRuleCenter;

    final gradient = widget.fill ??
        (widget.banner
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brass.bannerTop, brass.panelBottom],
              )
            : brass.panelGradient);
    final borderColor =
        lifted ? hoverBorder : widget.borderColor ?? brass.panelBorder;

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
        border: Border(top: BorderSide(color: topLip)),
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
                        ruleEdge.withValues(alpha: 0),
                        ruleEdge,
                        ruleMid,
                        ruleEdge,
                        ruleEdge.withValues(alpha: 0),
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

