import 'package:flutter/material.dart';

/// A jewel cabochon — highlight / body / depth triple with helpers for the
/// design's `radial-gradient(circle at 35% 28%, hi, mid 44%, deep)` dots.
/// Jewels are shared across both brightness modes; only their halo treatment
/// differs (see [Brass.jewelHalo]).
class Jewel {
  const Jewel(this.hi, this.mid, this.deep);

  final Color hi;
  final Color mid;
  final Color deep;

  /// The polished-stone dot fill.
  RadialGradient get cabochon => RadialGradient(
    center: const Alignment(-0.3, -0.44),
    radius: 0.9,
    colors: [hi, mid, deep],
    stops: const [0, 0.44, 1],
  );

  /// Soft coloured halo for the dot (dark-mode additive glow).
  @Deprecated('Use Brass.jewelHalo(jewel) — it resolves per brightness')
  List<BoxShadow> get haloShadow => [
    BoxShadow(color: mid.withValues(alpha: 0.6), blurRadius: 9),
  ];
}

/// One nav-rail section's accent kit: the embossed nameplate plate, its
/// border, the left gem bar, and the glow (design §Section accents).
class SectionAccent {
  const SectionAccent({
    required this.plateStart,
    required this.plateEnd,
    required this.border,
    required this.barTop,
    required this.barMid,
    required this.barBottom,
    required this.glow,
    required this.iconActive,
    required this.iconIdle,
    required this.headerText,
    required this.hover,
  });

  final Color plateStart;
  final Color plateEnd;
  final Color border;
  final Color barTop;
  final Color barMid;
  final Color barBottom;
  final Color glow;
  final Color iconActive;
  final Color iconIdle;
  final Color headerText;
  final Color hover;

  LinearGradient get plate => LinearGradient(
    colors: [plateStart, plateEnd],
  );

  LinearGradient get bar => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [barTop, barMid, barBottom],
    stops: const [0, 0.5, 1],
  );
}

/// All Brass Edition design tokens, brightness-resolved.
///
/// Two authored palettes: [Brass.dark] is the original bottle-green /
/// gilt instrument (values verbatim from the dark-only era, so dark renders
/// stay bit-identical), [Brass.light] is the parchment/daylight variant.
/// Resolve once per build — `final brass = context.brass;` — and read tokens
/// off the instance. The instances are canonical consts, so painters can use
/// `identical(old.brass, brass)` as an exact repaint check.
class Brass {
  const Brass._({
    required this.isDark,
    required this.seed,
    required this.bronze,
    required this.giltBright,
    required this.giltDeep,
    required this.copper,
    required this.hairline,
    required this.brassStops,
    required this.wordmarkStops,
    required this.moss,
    required this.ochre,
    required this.madder,
    required this.sand,
    required this.clay,
    required this.sage,
    required this.slate,
    required this.stone,
    required this.verdigris,
    required this.pine,
    required this.indigo,
    required this.navy,
    required this.sparkGreen,
    required this.sparkGreenDeep,
    required this.gaugeCpu,
    required this.gaugeMemory,
    required this.gaugeStorage,
    required this.gaugeContainers,
    required this.textHeading,
    required this.textBody,
    required this.textMuted,
    required this.smallCaps,
    required this.bg,
    required this.surface,
    required this.panelTop,
    required this.panelBottom,
    required this.bannerTop,
    required this.railTop,
    required this.railBottom,
    required this.recess,
    required this.panelBorder,
    required this.control,
    required this.services,
    required this.system,
    required this.cardShadow,
    required this.hoverShadow,
    required this.warnGradEnd,
  });

  /// The original dark instrument — every value verbatim from the dark era.
  static const dark = Brass._(
    isDark: true,
    seed: Color(0xFFE0BD63),
    bronze: Color(0xFFE0BD63),
    giltBright: Color(0xFFF0D18A),
    giltDeep: Color(0xFFC9A24A),
    copper: Color(0xFFC05A4E),
    hairline: Color(0x47C9AA58),
    brassStops: [
      Color(0xFF7D5F26),
      Color(0xFFE9CD7E),
      Color(0xFFFFF6CF),
      Color(0xFFD9B45E),
      Color(0xFF6E5220),
    ],
    wordmarkStops: [Color(0xFFFFF6CF), Color(0xFFE0BD63), Color(0xFFA67F30)],
    moss: Color(0xFF7BB26A),
    ochre: Color(0xFFE0A83F),
    madder: Color(0xFFC8564A),
    sand: Color(0xFFE6D3A0),
    clay: Color(0xFFD79F92),
    sage: Color(0xFFA9C78F),
    slate: Color(0xFF5A86C0),
    stone: Color(0xFFA9A399),
    verdigris: Color(0xFF4FAE96),
    pine: Color(0xFF3B6B4E),
    indigo: Color(0xFF8FABD6),
    navy: Color(0xFF1D3A6E),
    sparkGreen: Color(0xFF8FC16D),
    sparkGreenDeep: Color(0xFF4F8A45),
    gaugeCpu: Color(0xFF8BC06A),
    gaugeMemory: Color(0xFF5A86C0),
    gaugeStorage: Color(0xFFE0BD63),
    gaugeContainers: Color(0xFFC8564A),
    textHeading: Color(0xFFF4EEDA),
    textBody: Color(0xFFD6DEC8),
    textMuted: Color(0xFF94A684),
    smallCaps: Color(0xFFBDA874),
    bg: Color(0xFF0E1912),
    surface: Color(0xFF0F1912),
    panelTop: Color(0xFF223224),
    panelBottom: Color(0xFF0F1912),
    bannerTop: Color(0xFF253727),
    railTop: Color(0xFF1C2C1F),
    railBottom: Color(0xFF0E1811),
    recess: Color(0xFF09100B),
    panelBorder: Color(0x47C9AA58),
    control: SectionAccent(
      plateStart: Color(0x706D8A4F),
      plateEnd: Color(0x29C9AA58),
      border: Color(0x80E8CD78),
      barTop: Color(0xFFFFF6CF),
      barMid: Color(0xFFD9B45E),
      barBottom: Color(0xFF8A6A2A),
      glow: Color(0x99E8CD78),
      iconActive: Color(0xFFF4E8C4),
      iconIdle: Color(0xFF9FB389),
      headerText: Color(0xFFCBAB5C),
      hover: Color(0x14C9AA58),
    ),
    services: SectionAccent(
      plateStart: Color(0x85963436),
      plateEnd: Color(0x2EC9785A),
      border: Color(0x80E49678),
      barTop: Color(0xFFFFCDBF),
      barMid: Color(0xFFC05A4E),
      barBottom: Color(0xFF6E1F1C),
      glow: Color(0x8CE0785A),
      iconActive: Color(0xFFF6D9C4),
      iconIdle: Color(0xFFC19A86),
      headerText: Color(0xFFD4938A),
      hover: Color(0x1AC46A5E),
    ),
    system: SectionAccent(
      plateStart: Color(0x8534568C),
      plateEnd: Color(0x2E78A0D2),
      border: Color(0x808CAFE0),
      barTop: Color(0xFFCFE0FF),
      barMid: Color(0xFF4F86D0),
      barBottom: Color(0xFF1D3A6E),
      glow: Color(0x8C78A0E0),
      iconActive: Color(0xFFCFE0F4),
      iconIdle: Color(0xFF93A6C4),
      headerText: Color(0xFF8FABD6),
      hover: Color(0x1A5F86BF),
    ),
    cardShadow: [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x99000000),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFFD0A045),
  );

  /// Parchment/daylight variant. Fields (bottle-green) become warm paper,
  /// gilt inks darken to engraved bronze, text becomes iron-gall ink, and
  /// black additive shadows become umber ink washes. Brass metal, jewels,
  /// section plate washes, and gauge arcs are shared with dark — the same
  /// instrument, lit instead of backlit. Contrast verified ≥4.5:1 for text
  /// roles and ≥3:1 for iconography on their actual surfaces.
  static const light = Brass._(
    isDark: false,
    seed: Color(0xFF7D5F26),
    bronze: Color(0xFF7D5F26),
    giltBright: Color(0xFF7A5A1E),
    giltDeep: Color(0xFF9A7A2E),
    copper: Color(0xFF9C4136),
    hairline: Color(0x596E5220),
    // Polished brass metal is shared — it reads on both fields.
    brassStops: [
      Color(0xFF7D5F26),
      Color(0xFFE9CD7E),
      Color(0xFFFFF6CF),
      Color(0xFFD9B45E),
      Color(0xFF6E5220),
    ],
    // Engraved (ink-pressed) wordmark instead of luminous gold leaf.
    wordmarkStops: [Color(0xFFC9A24A), Color(0xFF8A6A2A), Color(0xFF5C451A)],
    moss: Color(0xFF38702E),
    ochre: Color(0xFF855C06),
    madder: Color(0xFF9E362C),
    sand: Color(0xFF6E5A28),
    clay: Color(0xFF8F4A3C),
    // Warmed from 0xFF55684A: the grey-green cast read cold against the
    // parchment; same lightness band, hue pulled toward olive.
    sage: Color(0xFF5C6840),
    slate: Color(0xFF3A639C),
    stone: Color(0xFF6B675C),
    verdigris: Color(0xFF2A7160),
    pine: Color(0xFF3B6B4E),
    indigo: Color(0xFF3A5E92),
    navy: Color(0xFF1D3A6E),
    sparkGreen: Color(0xFF4F8A45),
    sparkGreenDeep: Color(0xFF2E5E28),
    // Gauge arcs are shared: they draw on the kept-dark instrument face.
    gaugeCpu: Color(0xFF8BC06A),
    gaugeMemory: Color(0xFF5A86C0),
    gaugeStorage: Color(0xFFE0BD63),
    gaugeContainers: Color(0xFFC8564A),
    textHeading: Color(0xFF2B3423),
    textBody: Color(0xFF3C4634),
    textMuted: Color(0xFF5A6650),
    smallCaps: Color(0xFF6E5A28),
    // Page field deepened from 0xFFEAE2D2 so cards (panelTop 0xFFF4EEE2)
    // stand off the page instead of sitting ~3 levels away.
    bg: Color(0xFFE5DBC7),
    surface: Color(0xFFF1EADC),
    panelTop: Color(0xFFF4EEE2),
    panelBottom: Color(0xFFEDE5D6),
    bannerTop: Color(0xFFF6F0E4),
    railTop: Color(0xFFEFE7D4),
    railBottom: Color(0xFFE4DAC4),
    recess: Color(0xFFDFD3B8),
    panelBorder: Color(0x664A3E28),
    // Section plates keep their dark translucent washes — composited over
    // the parchment rail they become soft heraldic tints (verified ≥4.5:1
    // for their active icons/inks).
    control: SectionAccent(
      plateStart: Color(0x706D8A4F),
      plateEnd: Color(0x29C9AA58),
      border: Color(0x8C8A6A2A),
      barTop: Color(0xFFC9A24A),
      barMid: Color(0xFFA9852F),
      barBottom: Color(0xFF6E5220),
      glow: Color(0x336E5220),
      iconActive: Color(0xFF4A3A14),
      iconIdle: Color(0xFF5F6E50),
      headerText: Color(0xFF6E5620),
      hover: Color(0x148A6A2A),
    ),
    services: SectionAccent(
      plateStart: Color(0x85963436),
      plateEnd: Color(0x2EC9785A),
      border: Color(0x8C9C4136),
      barTop: Color(0xFFC05A4E),
      barMid: Color(0xFF9C4136),
      barBottom: Color(0xFF6E1F1C),
      glow: Color(0x339C4136),
      iconActive: Color(0xFF4A211C),
      iconIdle: Color(0xFF7A5248),
      headerText: Color(0xFF8F3A31),
      hover: Color(0x149C4136),
    ),
    system: SectionAccent(
      // Unlike Control/Services, the kept-dark navy washes composite to a
      // steel-grey smear on the warm rail — so the light plate is authored:
      // a low-alpha ink-navy wash that reads as navy-tinted parchment, with
      // the border / gem bar / navy inks carrying the section identity.
      plateStart: Color(0x2E1D3A6E),
      plateEnd: Color(0x143A5E96),
      border: Color(0x8C3A5E96),
      barTop: Color(0xFF4F86D0),
      barMid: Color(0xFF3A5E96),
      barBottom: Color(0xFF1D3A6E),
      glow: Color(0x333A5E96),
      iconActive: Color(0xFF1E3350),
      iconIdle: Color(0xFF4A6284),
      headerText: Color(0xFF3A5E92),
      hover: Color(0x143A5E96),
    ),
    // Umber ink instead of black: black shadows grey the parchment.
    cardShadow: [BoxShadow(color: Color(0x2E46381F), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x4D46381F),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFF9A6E10),
  );

  final bool isDark;

  // Gilt / brass flats.
  final Color seed;
  final Color bronze;
  final Color giltBright;
  final Color giltDeep;
  final Color copper;
  final Color hairline;
  final List<Color> brassStops;
  final List<Color> wordmarkStops;

  // Status ramp + softer tints.
  final Color moss;
  final Color ochre;
  final Color madder;
  final Color sand;
  final Color clay;
  final Color sage;
  final Color slate;
  final Color stone;
  final Color verdigris;
  final Color pine;
  final Color indigo;
  final Color navy;
  final Color sparkGreen;
  final Color sparkGreenDeep;

  // Instrument-gauge fixed per-metric colours (shared: dark gauge faces).
  final Color gaugeCpu;
  final Color gaugeMemory;
  final Color gaugeStorage;
  final Color gaugeContainers;

  // Text roles.
  final Color textHeading;
  final Color textBody;
  final Color textMuted;
  final Color smallCaps;

  // Fields / surfaces.
  final Color bg;
  final Color surface;
  final Color panelTop;
  final Color panelBottom;
  final Color bannerTop;
  final Color railTop;
  final Color railBottom;
  final Color recess;
  final Color panelBorder;

  // Section accents.
  final SectionAccent control;
  final SectionAccent services;
  final SectionAccent system;

  // Shadows.
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> hoverShadow;
  final Color warnGradEnd;

  // ---- Resolution ----

  /// The canonical instance for the ambient theme. Registers a Theme
  /// dependency, so widgets rebuild on System/Light/Dark flips.
  static Brass of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// For no-context sites (painters, theme factories) that already know
  /// their brightness.
  static Brass resolve(Brightness b) => b == Brightness.dark ? dark : light;

  // ---- Semantic aliases ----
  Color get ok => moss;
  Color get warn => ochre;
  Color get crit => madder;
  Color get ram => slate;

  // Jewels are shared between modes.
  static const emerald = Jewel(
    Color(0xFFE9FFE9),
    Color(0xFF57B566),
    Color(0xFF1C552A),
  );
  static const sapphire = Jewel(
    Color(0xFFDCE8FF),
    Color(0xFF5A86C0),
    Color(0xFF1D3A6E),
  );
  static const ruby = Jewel(
    Color(0xFFFFD6CF),
    Color(0xFFD8564A),
    Color(0xFF6E1F1C),
  );
  static const topaz = Jewel(
    Color(0xFFFFF6CF),
    Color(0xFFD9B45E),
    Color(0xFF7D5F26),
  );
  static const amethyst = Jewel(
    Color(0xFFF0DCFF),
    Color(0xFF9A6FD0),
    Color(0xFF3F2A6E),
  );

  // ---- Gradients ----

  /// Polished vertical brass sheen (design `brassV`): rims, bezels, plates.
  LinearGradient get brassV => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: brassStops,
    stops: const [0, 0.34, 0.5, 0.64, 1],
  );

  /// Gilt wordmark fill (`HOMELAB` masthead / splash / About). Luminous gold
  /// leaf in the dark; engraved ink-pressed bronze on parchment.
  LinearGradient get wordmarkGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: wordmarkStops,
    stops: const [0, 0.55, 1],
  );

  List<Color> get ramGradient => [slate, verdigris];
  List<Color> get brandGradient => [bronze, copper];

  /// Distinct restrained accents cycled across dashboard panels.
  List<Color> get cardAccents => [bronze, verdigris, indigo, sand, sage, slate];

  /// Panel surface: green field gradient in the dark; parchment in light
  /// (never pure white).
  LinearGradient get panelGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      panelTop.withValues(alpha: 0.92),
      panelBottom.withValues(alpha: isDark ? 0.94 : 0.86),
    ],
  );

  // ---- Helpers ----

  /// Micro-glow backlight (hover/focus). Additive halo in the dark; on
  /// parchment it becomes a tinted ink wash grounded by an umber shadow.
  List<BoxShadow> glow(Color color, {double strength = 1}) => isDark
      ? [
          BoxShadow(
            color: color.withValues(alpha: 0.20 * strength),
            blurRadius: 14 * strength,
            spreadRadius: 0.5,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.09 * strength),
            blurRadius: 5 * strength,
          ),
        ]
      : [
          BoxShadow(
            color: color.withValues(alpha: 0.22 * strength),
            blurRadius: 14 * strength,
            spreadRadius: 0.5,
          ),
          BoxShadow(
            color: const Color(0xFF46381F).withValues(alpha: 0.12 * strength),
            blurRadius: 5 * strength,
            offset: const Offset(0, 2),
          ),
        ];

  /// Jewel halo: additive coloured glow in the dark; a deep-tone ink drop
  /// shadow on parchment (glows vanish on light fields).
  List<BoxShadow> jewelHalo(Jewel jewel) => isDark
      ? [BoxShadow(color: jewel.mid.withValues(alpha: 0.6), blurRadius: 9)]
      : [
          BoxShadow(
            color: jewel.deep.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];

  /// Solid status color by load fraction (0..1): emerald → gold → ruby.
  Color loadColor(double fraction) {
    if (fraction >= 0.85) return crit;
    if (fraction >= 0.6) return warn;
    return ok;
  }

  /// Gradient stops for a gauge/meter by load fraction. In light mode the
  /// healthy ramp runs dark→mid so the fill's leading edge keeps ≥3:1
  /// against the recessed track.
  List<Color> loadGradient(double fraction) {
    if (fraction >= 0.85) return [madder, clay];
    if (fraction >= 0.6) return [ochre, warnGradEnd];
    return isDark ? [sparkGreenDeep, sparkGreen] : [sparkGreen, sparkGreenDeep];
  }

  /// A distinct shade of [base] (same hue, varied lightness) for index [i].
  /// The lightness band shifts down on parchment so shades keep contrast.
  Color shade(Color base, int i) {
    const steps = [0.0, 0.14, -0.12, 0.24, -0.20, 0.07, -0.06];
    final hsl = HSLColor.fromColor(base);
    final l = (hsl.lightness + steps[i % steps.length]).clamp(
      isDark ? 0.32 : 0.22,
      isDark ? 0.78 : 0.62,
    );
    return hsl.withLightness(l).toColor();
  }

  /// Section accent kit by rail-section name.
  SectionAccent kit(String section) => switch (section) {
    'Services' => services,
    'System' => system,
    _ => control,
  };

  /// Flat accent colour for a rail section (the old AppTab.accent).
  Color sectionAccent(String section) => switch (section) {
    'Services' => copper,
    'System' => indigo,
    _ => bronze,
  };
}

extension BrassContext on BuildContext {
  /// `context.brass` — the ambient brightness-resolved token set.
  Brass get brass => Brass.of(this);
}
