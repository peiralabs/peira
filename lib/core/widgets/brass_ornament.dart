import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small shared brass ornaments used across the shell: gem diamonds, rivet
/// studs, gilt rules, corner brackets, and the gilt wordmark.

/// A rotated-square jewel accent (design: 6px diamond with a cabochon fill).
class GemDiamond extends StatelessWidget {
  const GemDiamond({super.key, this.jewel, this.size = 6});

  /// Cabochon jewel (defaults to amethyst; jewels are shared across modes).
  final Jewel? jewel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final jewel = this.jewel ?? Brass.amethyst;
    return Transform.rotate(
      angle: 0.785398, // 45°
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: jewel.cabochon,
          // Additive glow in the dark; deep-tone ink drop on parchment.
          boxShadow: brass.isDark
              ? [
                  BoxShadow(
                      color: jewel.mid.withValues(alpha: 0.6), blurRadius: 7),
                ]
              : brass.jewelHalo(jewel),
        ),
      ),
    );
  }
}

/// A small polished-brass rivet stud.
class RivetStud extends StatelessWidget {
  const RivetStud({super.key, this.size = 9});

  final double size;

  @override
  Widget build(BuildContext context) {
    final pal = _Palette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Physical brass — shared between modes.
        gradient: const RadialGradient(
          center: Alignment(-0.32, -0.4),
          colors: [Color(0xFFFFF6CF), Color(0xFFC9A24A), Color(0xFF6E5220)],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
              color: pal.studShadow, offset: const Offset(0, 1), blurRadius: 1),
        ],
      ),
    );
  }
}

/// A larger domed brass stud that acts as a button (masthead close, About
/// close).
class BrassStud extends StatelessWidget {
  const BrassStud({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 28,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pal = _Palette.of(context);
    final stud = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Physical brass — shared between modes.
          gradient: const RadialGradient(
            center: Alignment(-0.28, -0.4),
            colors: [Color(0xFFFFF6CF), Color(0xFFD9B45E), Color(0xFF8A6A2A)],
            stops: [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(
                color: pal.studShadow,
                offset: const Offset(0, 2),
                blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: size * 0.46, color: const Color(0xFF3A2E14)),
      ),
    );
    return tooltip == null
        ? stud
        : Tooltip(message: tooltip!, child: MouseRegion(cursor: SystemMouseCursors.click, child: stud));
  }
}

/// A 1px gilt hairline rule fading toward [fadeEnd] (design section headers).
class GiltRule extends StatelessWidget {
  const GiltRule({super.key, this.width, this.reverse = false});

  /// Fixed width, or null to expand.
  final double? width;

  /// Fade from transparent → gilt instead of gilt → transparent.
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final pal = _Palette.of(context);
    final colors = reverse
        ? [pal.ruleFadeIn, pal.ruleBright]
        : [pal.ruleGilt, pal.ruleFadeOut];
    return Container(
      height: 1,
      width: width,
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
    );
  }
}

/// Four gilt corner brackets laid over a panel (grand banner, About card).
class CornerBrackets extends StatelessWidget {
  const CornerBrackets({super.key, this.size = 16, this.inset = 9});

  final double size;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final c = _Palette.of(context).bracket;
    Widget corner({bool top = false, bool left = false}) => Positioned(
      top: top ? inset : null,
      bottom: top ? null : inset,
      left: left ? inset : null,
      right: left ? null : inset,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border(
            top: top ? BorderSide(color: c, width: 1.5) : BorderSide.none,
            bottom: top ? BorderSide.none : BorderSide(color: c, width: 1.5),
            left: left ? BorderSide(color: c, width: 1.5) : BorderSide.none,
            right: left ? BorderSide.none : BorderSide(color: c, width: 1.5),
          ),
        ),
      ),
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            corner(top: true, left: true),
            corner(top: true),
            corner(left: true),
            corner(),
          ],
        ),
      ),
    );
  }
}

/// The gilt-filled engraved wordmark ("HOMELAB").
class GiltWordmark extends StatelessWidget {
  const GiltWordmark({
    super.key,
    this.text = 'HOMELAB',
    this.fontSize = 17,
    this.letterSpacingEm = 0.32,
  });

  final String text;
  final double fontSize;
  final double letterSpacingEm;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _Palette.of(context);
    return ShaderMask(
      shaderCallback: (bounds) =>
          brass.wordmarkGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Playfair Display',
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          letterSpacing: fontSize * letterSpacingEm,
          color: Colors.white,
          shadows: [
            Shadow(
                offset: const Offset(0, 1),
                blurRadius: 1,
                color: pal.wordmarkShadow),
          ],
        ),
      ),
    );
  }
}

/// The 2px section divider rule under a screen header: a bright flare near
/// the left edge fading out to the right, tinted per section accent
/// (gilt for Control, garnet for Services, sapphire-blue for System).
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key, this.color, this.flare})
      : _variant = _DividerVariant.gilt;

  /// Garnet divider (Services screens).
  const SectionDivider.garnet({super.key})
      : color = null,
        flare = null,
        _variant = _DividerVariant.garnet;

  /// Sapphire-blue divider (System screens — design §8/§9).
  const SectionDivider.blue({super.key})
      : color = null,
        flare = null,
        _variant = _DividerVariant.blue;

  /// Explicit tint overrides (default: the section palette pair).
  final Color? color;
  final Color? flare;
  final _DividerVariant _variant;

  @override
  Widget build(BuildContext context) {
    final pal = _Palette.of(context);
    final (base, hot) = switch (_variant) {
      _DividerVariant.gilt => (pal.dividerGilt, pal.dividerGiltFlare),
      _DividerVariant.garnet => (pal.dividerGarnet, pal.dividerGarnetFlare),
      _DividerVariant.blue => (pal.dividerBlue, pal.dividerBlueFlare),
    };
    final tint = color ?? base;
    final flareTint = flare ?? hot;
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tint, flareTint, tint, tint.withValues(alpha: 0.06)],
          stops: const [0, 0.06, 0.12, 1],
        ),
      ),
    );
  }
}

enum _DividerVariant { gilt, garnet, blue }

/// Section header: gem diamond + gilt Playfair title + fading rule + end
/// diamond (design §Dashboard "Section header").
class BrassSectionHeader extends StatelessWidget {
  const BrassSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _Palette.of(context);
    return Row(
      children: [
        const GemDiamond(jewel: Brass.topaz, size: 8),
        const SizedBox(width: 13),
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w700,
              fontSize: 19,
              color: brass.giltBright,
              shadows: [
                Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                    color: pal.headerTextShadow),
              ],
            ),
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(child: GiltRule()),
        const SizedBox(width: 13),
        trailing ??
            Transform.rotate(
              angle: 0.785398,
              child: Container(width: 5, height: 5, color: brass.giltDeep),
            ),
      ],
    );
  }
}

/// File-local dark/light pairs for the ornament inks. Dark values are
/// verbatim from the dark-only era; light values come from the parchment
/// mapping (engraved bronze rules, sepia stud shadows, and the letterpress
/// flip — warm-white emboss instead of black under now-dark inks).
class _Palette {
  const _Palette({
    required this.studShadow,
    required this.ruleGilt,
    required this.ruleBright,
    required this.ruleFadeIn,
    required this.ruleFadeOut,
    required this.bracket,
    required this.wordmarkShadow,
    required this.dividerGilt,
    required this.dividerGiltFlare,
    required this.dividerGarnet,
    required this.dividerGarnetFlare,
    required this.dividerBlue,
    required this.dividerBlueFlare,
    required this.headerTextShadow,
  });

  final Color studShadow;
  final Color ruleGilt;
  final Color ruleBright;
  final Color ruleFadeIn;
  final Color ruleFadeOut;
  final Color bracket;
  final Color wordmarkShadow;
  final Color dividerGilt;
  final Color dividerGiltFlare;
  final Color dividerGarnet;
  final Color dividerGarnetFlare;
  final Color dividerBlue;
  final Color dividerBlueFlare;
  final Color headerTextShadow;

  static _Palette of(BuildContext context) =>
      context.brass.isDark ? dark : light;

  static const dark = _Palette(
    studShadow: Color(0x80000000),
    ruleGilt: Color(0xFFC9A24A),
    ruleBright: Color(0xFFD9B45E),
    ruleFadeIn: Color(0x00C9A24A),
    ruleFadeOut: Color(0x0DC9AA58),
    bracket: Color(0xB3E8CD78), // rgba(232,205,120,.7)
    wordmarkShadow: Color(0x59000000),
    dividerGilt: Color(0xFFC9A24A),
    dividerGiltFlare: Color(0xFFFFF6CF),
    dividerGarnet: Color(0xFFC05A4E),
    dividerGarnetFlare: Color(0xFFF0B0A0),
    dividerBlue: Color(0xFF4F86D0),
    dividerBlueFlare: Color(0xFFA9C8F0),
    headerTextShadow: Color(0x80000000),
  );

  static const light = _Palette(
    studShadow: Color(0x33352511), // sepia-umber, never black on paper
    ruleGilt: Color(0xFFA9852F),
    ruleBright: Color(0xFFA9852F),
    ruleFadeIn: Color(0x00A9852F),
    ruleFadeOut: Color(0x0DA9852F), // fades preserved, bronze-ink hue
    bracket: Color(0xB38A6A2A),
    wordmarkShadow: Color(0x66FFFBEE), // letterpress flip
    dividerGilt: Color(0xFF8A6A2A),
    dividerGiltFlare: Color(0xFF6E5220), // flare inverts to darkest
    dividerGarnet: Color(0xFF9C4136),
    dividerGarnetFlare: Color(0xFF6E2018),
    dividerBlue: Color(0xFF3A5E96),
    dividerBlueFlare: Color(0xFF24457C),
    headerTextShadow: Color(0x66FFFBEE),
  );
}
