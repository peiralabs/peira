import 'package:flutter/material.dart';

import '../build_config.dart';
import '../theme/app_theme.dart';

/// Small shared brass ornaments used across the shell: gem diamonds, rivet
/// studs, gilt rules, 3D ledges, and the gilt wordmark.

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
    final m = context.brass.brassStops;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Polished metal from the theme's own ramp (peak → deep → edge).
        gradient: RadialGradient(
          center: const Alignment(-0.32, -0.4),
          colors: [m[2], context.brass.giltDeep, m[4]],
          stops: const [0, 0.55, 1],
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
    final m = context.brass.brassStops;
    final stud = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Polished metal from the theme's own ramp (peak → mid → edge).
          gradient: RadialGradient(
            center: const Alignment(-0.28, -0.4),
            colors: [m[2], m[3], m[0]],
            stops: const [0, 0.55, 1],
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
    // The rule is simply the theme's deep gilt fading to transparent.
    final g = context.brass.giltDeep;
    final colors = reverse
        ? [g.withValues(alpha: 0), g]
        : [g, g.withValues(alpha: 0.05)];
    return Container(
      height: 1,
      width: width,
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
    );
  }
}

/// A 3D ledge: a recessed well cut into a panel that an instrument sits
/// installed in (grand banner astrolabe and medallions, the instruments
/// tray, the About astrolabe). Lit from above, so the top wall falls into
/// shadow and the lower wall and sill catch the light; every ink comes from
/// the active family (its recess field and metal ramp).
class BrassLedge extends StatelessWidget {
  const BrassLedge({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding = const EdgeInsets.all(10),
    this.depth = 6,
  });

  final Widget child;

  /// Corner radius; [double.infinity] gives a circle or a pill.
  final double radius;
  final EdgeInsetsGeometry padding;

  /// How far the well appears to sink (inner-shadow reach, in px).
  final double depth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LedgePainter(context.brass, radius, depth),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _LedgePainter extends CustomPainter {
  _LedgePainter(this.brass, this.radius, this.depth);

  final Brass brass;
  final double radius;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final b = brass;
    final rect = Offset.zero & size;
    final r = Radius.circular(radius.clamp(0, size.shortestSide / 2));
    final well = RRect.fromRectAndRadius(rect, r);
    // Shadow ink: black in the dark, warm umber on parchment.
    final ink = b.isDark ? const Color(0xFF000000) : const Color(0xFF46381F);
    Shader vertical(List<Color> c, [List<double>? s]) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: c,
      stops: s,
    ).createShader(rect);
    // Light comes from above and a little to the left (as on the astrolabe),
    // so the lip's shadow falls down and slightly right.
    Path lip(Offset shift) => Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(depth * 6))
      ..addRRect(well.shift(shift));

    // Floor: the family's recess field, opening up a touch toward the light
    // that reaches the bottom of the well.
    canvas.drawRRect(
      well,
      Paint()
        ..shader = vertical([
          b.recess,
          Color.lerp(b.recess, b.panelBottom, b.isDark ? 0.4 : 0.3)!,
        ]),
    );

    canvas.save();
    canvas.clipRRect(well);
    // Broad, soft shadow thrown by the top lip deep into the well.
    canvas.drawPath(
      lip(Offset(depth * 0.15, depth * 0.7)),
      Paint()
        ..color = ink.withValues(alpha: b.isDark ? 0.55 : 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 1.3),
    );
    // Tight contact shadow right under the edge (ambient occlusion).
    canvas.drawPath(
      lip(const Offset(0, 1)),
      Paint()
        ..color = ink.withValues(alpha: b.isDark ? 0.6 : 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
    );
    // The lower wall turned toward the light: a faint warm bounce.
    canvas.drawRRect(
      well.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = vertical([
          Colors.transparent,
          Colors.transparent,
          b.giltBright.withValues(alpha: b.isDark ? 0.16 : 0.3),
        ], const [0, 0.55, 1]),
    );
    canvas.restore();

    // The cut edge: a fine chamfer, shadowed along the top where it faces
    // away from the light and catching it along the bottom.
    canvas.drawRRect(
      well.inflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = vertical([
          ink.withValues(alpha: b.isDark ? 0.5 : 0.22),
          b.giltDeep.withValues(alpha: 0.18),
          b.giltBright.withValues(alpha: b.isDark ? 0.35 : 0.5),
        ], const [0, 0.5, 1]),
    );
  }

  @override
  bool shouldRepaint(_LedgePainter old) =>
      !identical(old.brass, brass) ||
      old.radius != radius ||
      old.depth != depth;
}

/// The gilt-filled engraved wordmark ([kWordmark]: PEIRA or HOMELAB).
class GiltWordmark extends StatelessWidget {
  const GiltWordmark({
    super.key,
    this.text = kWordmark,
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
          fontFamily: context.displayFont,
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
              fontFamily: context.displayFont,
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
  final Color wordmarkShadow;
  final Color dividerGilt;
  final Color dividerGiltFlare;
  final Color dividerGarnet;
  final Color dividerGarnetFlare;
  final Color dividerBlue;
  final Color dividerBlueFlare;
  final Color headerTextShadow;

  /// Derived from the active family: gilt rules from the theme's
  /// metal (giltDeep/giltBright), the section dividers from the Control/
  /// Services/System accents (gilt / copper / slate). Shadows stay
  /// brightness-keyed — a shadow carries no theme identity.
  static _Palette of(BuildContext context) {
    final b = context.brass;
    return _Palette(
      studShadow:
          b.isDark ? const Color(0x80000000) : const Color(0x33352511),
      wordmarkShadow:
          b.isDark ? const Color(0x59000000) : const Color(0x66FFFBEE),
      dividerGilt: b.giltDeep,
      dividerGiltFlare: b.giltBright,
      dividerGarnet: b.copper,
      dividerGarnetFlare: b.clay,
      dividerBlue: b.slate,
      dividerBlueFlare: b.indigo,
      headerTextShadow:
          b.isDark ? const Color(0x80000000) : const Color(0x66FFFBEE),
    );
  }
}
