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

  // ---------------------------------------------------------------------------
  // "Graphite" family — pending visual/aesthetic sign-off (not yet default).
  //
  // The same instrument re-cast in brushed steel instead of brass: cool
  // graphite fields, silver/steel ornament, a warm-copper "Services" accent
  // kept for section legibility, and a cyan-shifted storage gauge. Jewels and
  // gauge arcs are shared with Brass (they draw on the instrument face).
  //
  // Contrast verified ≥4.5:1 for text roles and ≥3:1 for muted text and
  // iconography on their actual surfaces (section headers composited over the
  // rail), matching the bar the Brass light palette documents. What remains is
  // a taste call on the hue/tone, not an accessibility one.
  // ---------------------------------------------------------------------------

  /// Graphite dark — brushed steel on near-black graphite.
  static const graphiteDark = Brass._(
    isDark: true,
    seed: Color(0xFF9FB1C2),
    bronze: Color(0xFF9FB1C2),
    giltBright: Color(0xFFC9D6E2),
    giltDeep: Color(0xFF6E7E8E),
    copper: Color(0xFFC88A5A),
    hairline: Color(0x478AA2C4),
    brassStops: [
      Color(0xFF43505C),
      Color(0xFF8FA4B6),
      Color(0xFFE4EEF6),
      Color(0xFF7E93A6),
      Color(0xFF3A454F),
    ],
    wordmarkStops: [Color(0xFFE4EEF6), Color(0xFF9FB1C2), Color(0xFF5E6E7E)],
    moss: Color(0xFF6FBF8A),
    ochre: Color(0xFFE0A83F),
    madder: Color(0xFFD9594E),
    sand: Color(0xFFC7D2DC),
    clay: Color(0xFFC98F84),
    sage: Color(0xFF8FB7A0),
    slate: Color(0xFF5A86C0),
    stone: Color(0xFF99A3AD),
    verdigris: Color(0xFF4FAE96),
    pine: Color(0xFF3B6B5E),
    indigo: Color(0xFF8FABD6),
    navy: Color(0xFF1D3A6E),
    sparkGreen: Color(0xFF7FC08F),
    sparkGreenDeep: Color(0xFF3F7A55),
    gaugeCpu: Color(0xFF8BC06A),
    gaugeMemory: Color(0xFF5A86C0),
    gaugeStorage: Color(0xFF5AB6C0),
    gaugeContainers: Color(0xFFC8564A),
    textHeading: Color(0xFFE8EEF4),
    textBody: Color(0xFFC6D0DA),
    textMuted: Color(0xFF8795A3),
    smallCaps: Color(0xFF9FB1C2),
    bg: Color(0xFF121417),
    surface: Color(0xFF14171A),
    panelTop: Color(0xFF20252B),
    panelBottom: Color(0xFF14171A),
    bannerTop: Color(0xFF232A31),
    railTop: Color(0xFF1A1F24),
    railBottom: Color(0xFF121417),
    recess: Color(0xFF0C0E10),
    panelBorder: Color(0x478AA2C4),
    control: SectionAccent(
      plateStart: Color(0x705A7E92),
      plateEnd: Color(0x298AA2C4),
      border: Color(0x80B6CCDE),
      barTop: Color(0xFFE4EEF6),
      barMid: Color(0xFF8FA4B6),
      barBottom: Color(0xFF43505C),
      glow: Color(0x99B6CCDE),
      iconActive: Color(0xFFE8F0F6),
      iconIdle: Color(0xFF93A4B2),
      headerText: Color(0xFFAFC2D2),
      hover: Color(0x148AA2C4),
    ),
    services: SectionAccent(
      plateStart: Color(0x85963436),
      plateEnd: Color(0x2EC9785A),
      border: Color(0x80E49678),
      barTop: Color(0xFFFFCDBF),
      barMid: Color(0xFFC88A5A),
      barBottom: Color(0xFF6E3A1C),
      glow: Color(0x8CE0785A),
      iconActive: Color(0xFFF6E0CC),
      iconIdle: Color(0xFFC3A48E),
      headerText: Color(0xFFD6A078),
      hover: Color(0x1AC4885E),
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

  /// Graphite light — steel ink on cool paper.
  static const graphiteLight = Brass._(
    isDark: false,
    seed: Color(0xFF4A5A6A),
    bronze: Color(0xFF4A5A6A),
    giltBright: Color(0xFF45535F),
    giltDeep: Color(0xFF5E6E7E),
    copper: Color(0xFF9C5A36),
    hairline: Color(0x594A5A6A),
    brassStops: [
      Color(0xFF43505C),
      Color(0xFF8FA4B6),
      Color(0xFFE4EEF6),
      Color(0xFF7E93A6),
      Color(0xFF3A454F),
    ],
    wordmarkStops: [Color(0xFF6E7E8E), Color(0xFF4A5A6A), Color(0xFF333F49)],
    moss: Color(0xFF2E7A4A),
    ochre: Color(0xFF855C06),
    madder: Color(0xFF9E362C),
    sand: Color(0xFF556573),
    clay: Color(0xFF8F4A3C),
    sage: Color(0xFF46705E),
    slate: Color(0xFF3A639C),
    stone: Color(0xFF5F6B76),
    verdigris: Color(0xFF2A7160),
    pine: Color(0xFF3B6B5E),
    indigo: Color(0xFF3A5E92),
    navy: Color(0xFF1D3A6E),
    sparkGreen: Color(0xFF3F7A55),
    sparkGreenDeep: Color(0xFF255E3A),
    gaugeCpu: Color(0xFF8BC06A),
    gaugeMemory: Color(0xFF5A86C0),
    gaugeStorage: Color(0xFF5AB6C0),
    gaugeContainers: Color(0xFFC8564A),
    textHeading: Color(0xFF1E2A33),
    textBody: Color(0xFF2E3A44),
    textMuted: Color(0xFF51606C),
    smallCaps: Color(0xFF4A5A6A),
    bg: Color(0xFFE6EAEF),
    surface: Color(0xFFF1F4F7),
    panelTop: Color(0xFFF5F7FA),
    panelBottom: Color(0xFFEDF1F4),
    bannerTop: Color(0xFFF6F8FB),
    railTop: Color(0xFFEEF2F5),
    railBottom: Color(0xFFE4E9EE),
    recess: Color(0xFFDADFE5),
    panelBorder: Color(0x662E3A45),
    control: SectionAccent(
      plateStart: Color(0x705A7E92),
      plateEnd: Color(0x298AA2C4),
      border: Color(0x8C4A5A6A),
      barTop: Color(0xFF6E7E8E),
      barMid: Color(0xFF53636F),
      barBottom: Color(0xFF3A454F),
      glow: Color(0x333A454F),
      iconActive: Color(0xFF1E2A33),
      iconIdle: Color(0xFF53636F),
      headerText: Color(0xFF3F4E5A),
      hover: Color(0x144A5A6A),
    ),
    services: SectionAccent(
      plateStart: Color(0x85963436),
      plateEnd: Color(0x2EC9785A),
      border: Color(0x8C9C5A36),
      barTop: Color(0xFFC88A5A),
      barMid: Color(0xFF9C5A36),
      barBottom: Color(0xFF6E3A1C),
      glow: Color(0x339C5A36),
      iconActive: Color(0xFF4A2A14),
      iconIdle: Color(0xFF7A5848),
      headerText: Color(0xFF8F5230),
      hover: Color(0x149C5A36),
    ),
    system: SectionAccent(
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
    cardShadow: [BoxShadow(color: Color(0x2E1F2830), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x4D1F2830),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFF9A6E10),
  );

  // ---------------------------------------------------------------------------
  // "Terminal" family — hacker phosphor: neon green on near-black, amber-CRT
  // "Services" accent, cyan "System". Pending visual sign-off; contrast
  // verified ≥4.5:1 text / ≥3:1 muted+icon on actual surfaces (both variants).
  // ---------------------------------------------------------------------------

  /// Terminal dark — green phosphor on black.
  static const terminalDark = Brass._(
    isDark: true,
    seed: Color(0xFF3BFF6B),
    bronze: Color(0xFF3BFF6B),
    giltBright: Color(0xFF9CFFC0),
    giltDeep: Color(0xFF1FA64D),
    copper: Color(0xFFFFB000),
    hairline: Color(0x473BFF6B),
    brassStops: [
      Color(0xFF0E4D23),
      Color(0xFF2FBF5E),
      Color(0xFFB6FFCF),
      Color(0xFF27A64F),
      Color(0xFF0C3D1C),
    ],
    wordmarkStops: [Color(0xFFB6FFCF), Color(0xFF3BFF6B), Color(0xFF1FA64D)],
    moss: Color(0xFF3BFF6B),
    ochre: Color(0xFFFFB000),
    madder: Color(0xFFFF5B5B),
    sand: Color(0xFF9FE0A8),
    clay: Color(0xFFE09A8A),
    sage: Color(0xFF6FD98A),
    slate: Color(0xFF5AC8FA),
    stone: Color(0xFF8FA896),
    verdigris: Color(0xFF2EE6C0),
    pine: Color(0xFF1F7A4D),
    indigo: Color(0xFF7FB0FF),
    navy: Color(0xFF0A2A4D),
    sparkGreen: Color(0xFF5BFF8F),
    sparkGreenDeep: Color(0xFF1FA64D),
    gaugeCpu: Color(0xFF5BFF8F),
    gaugeMemory: Color(0xFF5AC8FA),
    gaugeStorage: Color(0xFFFFB000),
    gaugeContainers: Color(0xFFFF5B5B),
    textHeading: Color(0xFFD6FFE0),
    textBody: Color(0xFFA6ECB8),
    textMuted: Color(0xFF6FBF88),
    smallCaps: Color(0xFF55CC7E),
    bg: Color(0xFF050806),
    surface: Color(0xFF070B07),
    panelTop: Color(0xFF0C140C),
    panelBottom: Color(0xFF070B07),
    bannerTop: Color(0xFF0E180E),
    railTop: Color(0xFF0A110A),
    railBottom: Color(0xFF050806),
    recess: Color(0xFF030503),
    panelBorder: Color(0x4D1FA64D),
    control: SectionAccent(
      plateStart: Color(0x701FA64D),
      plateEnd: Color(0x293BFF6B),
      border: Color(0x803BFF6B),
      barTop: Color(0xFFB6FFCF),
      barMid: Color(0xFF3BFF6B),
      barBottom: Color(0xFF156B32),
      glow: Color(0x993BFF6B),
      iconActive: Color(0xFFD6FFE0),
      iconIdle: Color(0xFF6FBF88),
      headerText: Color(0xFF7BFF9F),
      hover: Color(0x143BFF6B),
    ),
    services: SectionAccent(
      plateStart: Color(0x85704A00),
      plateEnd: Color(0x2EFFB000),
      border: Color(0x80FFB000),
      barTop: Color(0xFFFFD98A),
      barMid: Color(0xFFFFB000),
      barBottom: Color(0xFF7A5400),
      glow: Color(0x8CFFB000),
      iconActive: Color(0xFFFFE6B3),
      iconIdle: Color(0xFFC9A86E),
      headerText: Color(0xFFFFC94D),
      hover: Color(0x1AFFB000),
    ),
    system: SectionAccent(
      plateStart: Color(0x85164A6E),
      plateEnd: Color(0x2E5AC8FA),
      border: Color(0x805AC8FA),
      barTop: Color(0xFFBFE8FF),
      barMid: Color(0xFF5AC8FA),
      barBottom: Color(0xFF13486E),
      glow: Color(0x8C5AC8FA),
      iconActive: Color(0xFFCFEEFF),
      iconIdle: Color(0xFF7FA8C4),
      headerText: Color(0xFF6FD0FA),
      hover: Color(0x1A5AC8FA),
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
    warnGradEnd: Color(0xFFFFCA45),
  );

  /// Terminal light — dark-green ink on pale phosphor paper.
  static const terminalLight = Brass._(
    isDark: false,
    seed: Color(0xFF1F7A3D),
    bronze: Color(0xFF1F7A3D),
    giltBright: Color(0xFF1C6E37),
    giltDeep: Color(0xFF2A8A4C),
    copper: Color(0xFF8A5A00),
    hairline: Color(0x591F7A3D),
    brassStops: [
      Color(0xFF0E4D23),
      Color(0xFF2FBF5E),
      Color(0xFFB6FFCF),
      Color(0xFF27A64F),
      Color(0xFF0C3D1C),
    ],
    wordmarkStops: [Color(0xFF2A8A4C), Color(0xFF1F7A3D), Color(0xFF145229)],
    moss: Color(0xFF1F7A3D),
    ochre: Color(0xFF8A5A00),
    madder: Color(0xFFB23A32),
    sand: Color(0xFF4A6B50),
    clay: Color(0xFF8F4A3C),
    sage: Color(0xFF3C6E4E),
    slate: Color(0xFF1E7FA6),
    stone: Color(0xFF566B5A),
    verdigris: Color(0xFF177A66),
    pine: Color(0xFF1F6B45),
    indigo: Color(0xFF2F5E92),
    navy: Color(0xFF0A2A4D),
    sparkGreen: Color(0xFF1F7A3D),
    sparkGreenDeep: Color(0xFF125227),
    gaugeCpu: Color(0xFF5BFF8F),
    gaugeMemory: Color(0xFF5AC8FA),
    gaugeStorage: Color(0xFFFFB000),
    gaugeContainers: Color(0xFFFF5B5B),
    textHeading: Color(0xFF0A2A14),
    textBody: Color(0xFF16331F),
    textMuted: Color(0xFF3E5E48),
    smallCaps: Color(0xFF2A6B3D),
    bg: Color(0xFFE4EFE6),
    surface: Color(0xFFF0F6F1),
    panelTop: Color(0xFFF4F9F5),
    panelBottom: Color(0xFFEBF3EC),
    bannerTop: Color(0xFFF5FAF6),
    railTop: Color(0xFFEDF5EE),
    railBottom: Color(0xFFE2EDE4),
    recess: Color(0xFFD8E6DA),
    panelBorder: Color(0x66175229),
    control: SectionAccent(
      plateStart: Color(0x701FA64D),
      plateEnd: Color(0x293BFF6B),
      border: Color(0x8C1F7A3D),
      barTop: Color(0xFF2A8A4C),
      barMid: Color(0xFF1F7A3D),
      barBottom: Color(0xFF145229),
      glow: Color(0x33175229),
      iconActive: Color(0xFF0A2A14),
      iconIdle: Color(0xFF3E5E48),
      headerText: Color(0xFF1C6E37),
      hover: Color(0x141F7A3D),
    ),
    services: SectionAccent(
      plateStart: Color(0x85704A00),
      plateEnd: Color(0x2EFFB000),
      border: Color(0x8C8A5A00),
      barTop: Color(0xFFB07400),
      barMid: Color(0xFF8A5A00),
      barBottom: Color(0xFF5E3D00),
      glow: Color(0x338A5A00),
      iconActive: Color(0xFF3E2900),
      iconIdle: Color(0xFF7A5A28),
      headerText: Color(0xFF7A5000),
      hover: Color(0x148A5A00),
    ),
    system: SectionAccent(
      plateStart: Color(0x2E13486E),
      plateEnd: Color(0x141E7FA6),
      border: Color(0x8C1E7FA6),
      barTop: Color(0xFF3A9EC4),
      barMid: Color(0xFF1E7FA6),
      barBottom: Color(0xFF13486E),
      glow: Color(0x331E7FA6),
      iconActive: Color(0xFF123A50),
      iconIdle: Color(0xFF466E84),
      headerText: Color(0xFF1E7FA6),
      hover: Color(0x141E7FA6),
    ),
    cardShadow: [BoxShadow(color: Color(0x2E0A2A14), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x4D0A2A14),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFF6E4A00),
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

  /// The canonical instance for the ambient theme. Registers both a Theme
  /// dependency (so widgets rebuild on System/Light/Dark flips) and an
  /// [ActiveTheme] dependency (so they rebuild when the operator switches
  /// theme family). Falls back to the Brass family when no [ActiveTheme] is
  /// in scope (bare-MaterialApp test pumps), preserving the old behaviour.
  static Brass of(BuildContext context) =>
      ActiveTheme.of(context).resolve(Theme.of(context).brightness);

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

/// A selectable theme family: a named pair of [Brass] token sets, one per
/// brightness. The app always owns a light and a dark [Brass] (the operator's
/// System/Light/Dark switch picks between them); a family bundles both so the
/// switch keeps working after a family change.
class ThemePack {
  const ThemePack({
    required this.id,
    required this.label,
    required this.dark,
    required this.light,
  });

  /// Stable key persisted in settings — never localise or rename once shipped.
  final String id;

  /// Human label for the settings picker.
  final String label;

  final Brass dark;
  final Brass light;

  Brass resolve(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// The original Brass Edition — the default and fallback family.
  static const brass = ThemePack(
    id: 'brass',
    label: 'Brass Edition',
    dark: Brass.dark,
    light: Brass.light,
  );

  /// Graphite (brushed steel). See [Brass.graphiteDark].
  static const graphite = ThemePack(
    id: 'graphite',
    label: 'Graphite',
    dark: Brass.graphiteDark,
    light: Brass.graphiteLight,
  );

  /// Terminal (hacker phosphor). See [Brass.terminalDark].
  static const terminal = ThemePack(
    id: 'terminal',
    label: 'Terminal',
    dark: Brass.terminalDark,
    light: Brass.terminalLight,
  );

  /// Registry order is the settings-picker order. [brass] is first and is the
  /// canonical fallback for an unknown or missing stored id.
  static const all = <ThemePack>[brass, graphite, terminal];

  /// The family for a stored [id], falling back to [brass].
  static ThemePack byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => brass);
}

/// Carries the active [ThemePack] down the tree so [Brass.of] resolves the
/// operator's chosen family (not just a hardcoded Brass pair). Inject it once,
/// above the Navigator, via `MaterialApp.builder`.
class ActiveTheme extends InheritedWidget {
  const ActiveTheme({required this.pack, required super.child, super.key});

  final ThemePack pack;

  /// The active family, or [ThemePack.brass] when none is in scope — so bare
  /// `MaterialApp` test pumps (no [ActiveTheme]) behave exactly as before.
  static ThemePack of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActiveTheme>()?.pack ??
      ThemePack.brass;

  @override
  bool updateShouldNotify(ActiveTheme oldWidget) =>
      oldWidget.pack.id != pack.id;
}
