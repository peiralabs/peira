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
class Brass extends ThemeExtension<Brass> {
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
    this.displayFont = 'Playfair Display',
    this.bodyFont = 'EB Garamond',
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
    displayFont: 'JetBrains Mono',
    bodyFont: 'JetBrains Mono',
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
    displayFont: 'JetBrains Mono',
    bodyFont: 'JetBrains Mono',
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

  // ===== Nord (arctic blue) — grounded in the Nord palette. =====
  /// Nord dark — Polar Night fields, Frost accents.
  static const nordDark = Brass._(
    isDark: true,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFF88C0D0),
    bronze: Color(0xFF88C0D0),
    giltBright: Color(0xFFA9D4DE),
    giltDeep: Color(0xFF5E81AC),
    copper: Color(0xFFD08770),
    hairline: Color(0x4788C0D0),
    brassStops: [
      Color(0xFF3B5566),
      Color(0xFF6E9DB0),
      Color(0xFFBFE3EC),
      Color(0xFF5E81AC),
      Color(0xFF2E3A44),
    ],
    wordmarkStops: [Color(0xFFECEFF4), Color(0xFF88C0D0), Color(0xFF5E81AC)],
    moss: Color(0xFFA3BE8C),
    ochre: Color(0xFFEBCB8B),
    madder: Color(0xFFBF616A),
    sand: Color(0xFFD8DEE9),
    clay: Color(0xFFD08770),
    sage: Color(0xFFA3BE8C),
    slate: Color(0xFF81A1C1),
    stone: Color(0xFF9AA3B2),
    verdigris: Color(0xFF8FBCBB),
    pine: Color(0xFF4C7A5E),
    indigo: Color(0xFF7E9CC4),
    navy: Color(0xFF3B4C6E),
    sparkGreen: Color(0xFFA3BE8C),
    sparkGreenDeep: Color(0xFF6E8E5A),
    gaugeCpu: Color(0xFFA3BE8C),
    gaugeMemory: Color(0xFF81A1C1),
    gaugeStorage: Color(0xFFEBCB8B),
    gaugeContainers: Color(0xFFBF616A),
    textHeading: Color(0xFFECEFF4),
    textBody: Color(0xFFD8DEE9),
    textMuted: Color(0xFFA3ADBD),
    smallCaps: Color(0xFF88C0D0),
    bg: Color(0xFF2E3440),
    surface: Color(0xFF2E3440),
    panelTop: Color(0xFF3B4252),
    panelBottom: Color(0xFF2E3440),
    bannerTop: Color(0xFF3B4252),
    railTop: Color(0xFF353C4A),
    railBottom: Color(0xFF2E3440),
    recess: Color(0xFF272C36),
    panelBorder: Color(0x664C566A),
    control: SectionAccent(
      plateStart: Color(0x705E81AC),
      plateEnd: Color(0x2988C0D0),
      border: Color(0x8088C0D0),
      barTop: Color(0xFFBFE3EC),
      barMid: Color(0xFF88C0D0),
      barBottom: Color(0xFF3B5566),
      glow: Color(0x9988C0D0),
      iconActive: Color(0xFFECEFF4),
      iconIdle: Color(0xFF9AA3B2),
      headerText: Color(0xFF9FD0DC),
      hover: Color(0x1488C0D0),
    ),
    services: SectionAccent(
      plateStart: Color(0x85804A3A),
      plateEnd: Color(0x2ED08770),
      border: Color(0x80D08770),
      barTop: Color(0xFFE8B49E),
      barMid: Color(0xFFD08770),
      barBottom: Color(0xFF7A4A38),
      glow: Color(0x8CD08770),
      iconActive: Color(0xFFF2D4C6),
      iconIdle: Color(0xFFC4A090),
      headerText: Color(0xFFE09A80),
      hover: Color(0x1AD08770),
    ),
    system: SectionAccent(
      plateStart: Color(0x853B4C6E),
      plateEnd: Color(0x2E7E9CC4),
      border: Color(0x808FABD6),
      barTop: Color(0xFFBFD4F0),
      barMid: Color(0xFF7E9CC4),
      barBottom: Color(0xFF3B4C6E),
      glow: Color(0x8C7E9CC4),
      iconActive: Color(0xFFD4E0F4),
      iconIdle: Color(0xFF93A2C0),
      headerText: Color(0xFF9FB4DC),
      hover: Color(0x1A7E9CC4),
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
    warnGradEnd: Color(0xFFD4B36B),
  );

  /// Nord light — Snow Storm fields, darkened Frost inks.
  static const nordLight = Brass._(
    isDark: false,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFF5E81AC),
    bronze: Color(0xFF5E81AC),
    giltBright: Color(0xFF4E6E96),
    giltDeep: Color(0xFF5E81AC),
    copper: Color(0xFFB5651D),
    hairline: Color(0x594C566A),
    brassStops: [
      Color(0xFF3B5566),
      Color(0xFF6E9DB0),
      Color(0xFFBFE3EC),
      Color(0xFF5E81AC),
      Color(0xFF2E3A44),
    ],
    wordmarkStops: [Color(0xFF5E81AC), Color(0xFF4C6690), Color(0xFF3B4C6E)],
    moss: Color(0xFF4C7A3E),
    ochre: Color(0xFF8A6A1E),
    madder: Color(0xFFA0434B),
    sand: Color(0xFF4C566A),
    clay: Color(0xFF9C5A3C),
    sage: Color(0xFF5C7A4A),
    slate: Color(0xFF3A5E8C),
    stone: Color(0xFF5A6472),
    verdigris: Color(0xFF3A7A6E),
    pine: Color(0xFF3B6B4E),
    indigo: Color(0xFF3A5E8C),
    navy: Color(0xFF2E4068),
    sparkGreen: Color(0xFF4C7A3E),
    sparkGreenDeep: Color(0xFF345628),
    gaugeCpu: Color(0xFFA3BE8C),
    gaugeMemory: Color(0xFF81A1C1),
    gaugeStorage: Color(0xFFEBCB8B),
    gaugeContainers: Color(0xFFBF616A),
    textHeading: Color(0xFF2E3440),
    textBody: Color(0xFF3B4252),
    textMuted: Color(0xFF566076),
    smallCaps: Color(0xFF4C566A),
    bg: Color(0xFFE5E9F0),
    surface: Color(0xFFECEFF4),
    panelTop: Color(0xFFF0F3F8),
    panelBottom: Color(0xFFE5E9F0),
    bannerTop: Color(0xFFF0F3F8),
    railTop: Color(0xFFE9EDF3),
    railBottom: Color(0xFFDDE3EC),
    recess: Color(0xFFD4DAE4),
    panelBorder: Color(0x66434C5E),
    control: SectionAccent(
      plateStart: Color(0x705E81AC),
      plateEnd: Color(0x2988C0D0),
      border: Color(0x8C3A5E8C),
      barTop: Color(0xFF5E81AC),
      barMid: Color(0xFF4C6690),
      barBottom: Color(0xFF3B4C6E),
      glow: Color(0x333B4C6E),
      iconActive: Color(0xFF2E3440),
      iconIdle: Color(0xFF566076),
      headerText: Color(0xFF3A5A8C),
      hover: Color(0x145E81AC),
    ),
    services: SectionAccent(
      plateStart: Color(0x85804A3A),
      plateEnd: Color(0x2ED08770),
      border: Color(0x8CB5651D),
      barTop: Color(0xFFB5651D),
      barMid: Color(0xFF9C5418),
      barBottom: Color(0xFF6E3A10),
      glow: Color(0x33B5651D),
      iconActive: Color(0xFF4A2A0E),
      iconIdle: Color(0xFF7A5436),
      headerText: Color(0xFF9C5418),
      hover: Color(0x14B5651D),
    ),
    system: SectionAccent(
      plateStart: Color(0x2E3B4C6E),
      plateEnd: Color(0x143A5E8C),
      border: Color(0x8C3A5E8C),
      barTop: Color(0xFF4C6690),
      barMid: Color(0xFF3A5E8C),
      barBottom: Color(0xFF2E4068),
      glow: Color(0x333A5E8C),
      iconActive: Color(0xFF223050),
      iconIdle: Color(0xFF4A5A7C),
      headerText: Color(0xFF3A5A8C),
      hover: Color(0x143A5E8C),
    ),
    cardShadow: [BoxShadow(color: Color(0x2E2E3440), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x4D2E3440),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFF6E5214),
  );

  // ===== Ember (garnet / warm red). =====
  /// Ember dark — deep garnet fields, rose-gold ornament.
  static const emberDark = Brass._(
    isDark: true,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFFE27A80),
    bronze: Color(0xFFE27A80),
    giltBright: Color(0xFFF4AEB2),
    giltDeep: Color(0xFFB2424A),
    copper: Color(0xFFD98C4A),
    hairline: Color(0x47E27A80),
    brassStops: [
      Color(0xFF5A2226),
      Color(0xFFB2555C),
      Color(0xFFF2C0C4),
      Color(0xFFA84851),
      Color(0xFF4A1C20),
    ],
    wordmarkStops: [Color(0xFFF4C0C4), Color(0xFFE27A80), Color(0xFFB2424A)],
    moss: Color(0xFF8FC16D),
    ochre: Color(0xFFE0A83F),
    madder: Color(0xFFE24A4A),
    sand: Color(0xFFE0C0A0),
    clay: Color(0xFFD98C7A),
    sage: Color(0xFFA9C78F),
    slate: Color(0xFFC08A90),
    stone: Color(0xFFB0989A),
    verdigris: Color(0xFF4FAE96),
    pine: Color(0xFF6B3B3E),
    indigo: Color(0xFFC08AB0),
    navy: Color(0xFF6E1D3A),
    sparkGreen: Color(0xFF8FC16D),
    sparkGreenDeep: Color(0xFF4F8A45),
    gaugeCpu: Color(0xFF8BC06A),
    gaugeMemory: Color(0xFFC06A90),
    gaugeStorage: Color(0xFFE0A83F),
    gaugeContainers: Color(0xFFE24A4A),
    textHeading: Color(0xFFFCE6E6),
    textBody: Color(0xFFECC8CC),
    textMuted: Color(0xFFC79498),
    smallCaps: Color(0xFFD4888E),
    bg: Color(0xFF1A0E0F),
    surface: Color(0xFF1E1011),
    panelTop: Color(0xFF2E1618),
    panelBottom: Color(0xFF1E1011),
    bannerTop: Color(0xFF331A1C),
    railTop: Color(0xFF241214),
    railBottom: Color(0xFF1A0E0F),
    recess: Color(0xFF120909),
    panelBorder: Color(0x4DB2424A),
    control: SectionAccent(
      plateStart: Color(0x70B2424A),
      plateEnd: Color(0x29E27A80),
      border: Color(0x80E27A80),
      barTop: Color(0xFFF2C0C4),
      barMid: Color(0xFFE27A80),
      barBottom: Color(0xFF7A2A2E),
      glow: Color(0x99E27A80),
      iconActive: Color(0xFFFCE0E2),
      iconIdle: Color(0xFFC79498),
      headerText: Color(0xFFEE969C),
      hover: Color(0x14E27A80),
    ),
    services: SectionAccent(
      plateStart: Color(0x85704A1A),
      plateEnd: Color(0x2ED98C4A),
      border: Color(0x80D98C4A),
      barTop: Color(0xFFF0C089),
      barMid: Color(0xFFD98C4A),
      barBottom: Color(0xFF7A4E1E),
      glow: Color(0x8CD98C4A),
      iconActive: Color(0xFFF6DCBC),
      iconIdle: Color(0xFFC6A47E),
      headerText: Color(0xFFE09A58),
      hover: Color(0x1AD98C4A),
    ),
    system: SectionAccent(
      plateStart: Color(0x85603060),
      plateEnd: Color(0x2EC08AB0),
      border: Color(0x80C08AB0),
      barTop: Color(0xFFE0BCE0),
      barMid: Color(0xFFC08AB0),
      barBottom: Color(0xFF60306E),
      glow: Color(0x8CC08AB0),
      iconActive: Color(0xFFEAD4EA),
      iconIdle: Color(0xFFB096B0),
      headerText: Color(0xFFCE9ECA),
      hover: Color(0x1AC08AB0),
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

  /// Ember light — warm blush paper, garnet ink.
  static const emberLight = Brass._(
    isDark: false,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFFA8323A),
    bronze: Color(0xFFA8323A),
    giltBright: Color(0xFF962E36),
    giltDeep: Color(0xFFB2424A),
    copper: Color(0xFF9C5A1E),
    hairline: Color(0x597A2A2E),
    brassStops: [
      Color(0xFF5A2226),
      Color(0xFFB2555C),
      Color(0xFFF2C0C4),
      Color(0xFFA84851),
      Color(0xFF4A1C20),
    ],
    wordmarkStops: [Color(0xFFB2424A), Color(0xFF962E36), Color(0xFF6E1F24)],
    moss: Color(0xFF4C8A3E),
    ochre: Color(0xFF8A5A0E),
    madder: Color(0xFFC01F2A),
    sand: Color(0xFF6E4A3A),
    clay: Color(0xFF9C5A4C),
    sage: Color(0xFF5C7A4A),
    slate: Color(0xFF9C5A64),
    stone: Color(0xFF6E5A5C),
    verdigris: Color(0xFF2A7160),
    pine: Color(0xFF6B3B3E),
    indigo: Color(0xFF8A4A7A),
    navy: Color(0xFF6E1D3A),
    sparkGreen: Color(0xFF4C8A3E),
    sparkGreenDeep: Color(0xFF2E6A28),
    gaugeCpu: Color(0xFF8BC06A),
    gaugeMemory: Color(0xFFC06A90),
    gaugeStorage: Color(0xFFE0A83F),
    gaugeContainers: Color(0xFFE24A4A),
    textHeading: Color(0xFF3A1416),
    textBody: Color(0xFF4A1F22),
    textMuted: Color(0xFF6E4A4C),
    smallCaps: Color(0xFF7A2A2E),
    bg: Color(0xFFF0E2E0),
    surface: Color(0xFFF8EEEC),
    panelTop: Color(0xFFFBF2F0),
    panelBottom: Color(0xFFEFE0DE),
    bannerTop: Color(0xFFFBF2F0),
    railTop: Color(0xFFF2E4E2),
    railBottom: Color(0xFFE8D6D4),
    recess: Color(0xFFDEC8C6),
    panelBorder: Color(0x667A2A2E),
    control: SectionAccent(
      plateStart: Color(0x70B2424A),
      plateEnd: Color(0x29E27A80),
      border: Color(0x8CA8323A),
      barTop: Color(0xFFA8323A),
      barMid: Color(0xFF962E36),
      barBottom: Color(0xFF6E1F24),
      glow: Color(0x337A2A2E),
      iconActive: Color(0xFF3A1416),
      iconIdle: Color(0xFF6E4A4C),
      headerText: Color(0xFF9C2E36),
      hover: Color(0x14A8323A),
    ),
    services: SectionAccent(
      plateStart: Color(0x85704A1A),
      plateEnd: Color(0x2ED98C4A),
      border: Color(0x8C9C5A1E),
      barTop: Color(0xFF9C5A1E),
      barMid: Color(0xFF824A18),
      barBottom: Color(0xFF5E340E),
      glow: Color(0x339C5A1E),
      iconActive: Color(0xFF3E2609),
      iconIdle: Color(0xFF7A5436),
      headerText: Color(0xFF8A4E18),
      hover: Color(0x149C5A1E),
    ),
    system: SectionAccent(
      plateStart: Color(0x2E603060),
      plateEnd: Color(0x148A4A7A),
      border: Color(0x8C8A4A7A),
      barTop: Color(0xFFA85E96),
      barMid: Color(0xFF8A4A7A),
      barBottom: Color(0xFF5E305E),
      glow: Color(0x338A4A7A),
      iconActive: Color(0xFF4A2444),
      iconIdle: Color(0xFF7A5A74),
      headerText: Color(0xFF8A4A7A),
      hover: Color(0x148A4A7A),
    ),
    cardShadow: [BoxShadow(color: Color(0x2E3A1416), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x4D3A1416),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFF6E4A0E),
  );

  // ===== Obsidian (matte true-black OLED). =====
  /// Obsidian dark — pure-black fields, low-chroma steel ornament.
  static const obsidianDark = Brass._(
    isDark: true,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFFAEB4BE),
    bronze: Color(0xFFAEB4BE),
    giltBright: Color(0xFFD8DCE2),
    giltDeep: Color(0xFF70757E),
    copper: Color(0xFFB98A5A),
    hairline: Color(0x30AEB4BE),
    brassStops: [
      Color(0xFF2A2C30),
      Color(0xFF6E727A),
      Color(0xFFD0D4DA),
      Color(0xFF5E626A),
      Color(0xFF222427),
    ],
    wordmarkStops: [Color(0xFFE4E7EC), Color(0xFFAEB4BE), Color(0xFF70757E)],
    moss: Color(0xFF5BBF7A),
    ochre: Color(0xFFE0A83F),
    madder: Color(0xFFE25555),
    sand: Color(0xFFC0C4CC),
    clay: Color(0xFFC09A8E),
    sage: Color(0xFF8FB7A0),
    slate: Color(0xFF5A9CF0),
    stone: Color(0xFF8A8F98),
    verdigris: Color(0xFF4FAE96),
    pine: Color(0xFF3B6B5E),
    indigo: Color(0xFF7FA8E0),
    navy: Color(0xFF1A2A4D),
    sparkGreen: Color(0xFF5BBF7A),
    sparkGreenDeep: Color(0xFF2E6E45),
    gaugeCpu: Color(0xFF5BBF7A),
    gaugeMemory: Color(0xFF5A9CF0),
    gaugeStorage: Color(0xFFD8DCE2),
    gaugeContainers: Color(0xFFE25555),
    textHeading: Color(0xFFF4F5F7),
    textBody: Color(0xFFCDD0D6),
    textMuted: Color(0xFF9398A0),
    smallCaps: Color(0xFFAEB4BE),
    bg: Color(0xFF000000),
    surface: Color(0xFF050505),
    panelTop: Color(0xFF0E0E10),
    panelBottom: Color(0xFF050505),
    bannerTop: Color(0xFF141416),
    railTop: Color(0xFF0A0A0C),
    railBottom: Color(0xFF000000),
    recess: Color(0xFF000000),
    panelBorder: Color(0x30AEB4BE),
    control: SectionAccent(
      plateStart: Color(0x5070757E),
      plateEnd: Color(0x24AEB4BE),
      border: Color(0x66C0C4CC),
      barTop: Color(0xFFE4E7EC),
      barMid: Color(0xFFAEB4BE),
      barBottom: Color(0xFF5E626A),
      glow: Color(0x66C0C4CC),
      iconActive: Color(0xFFF4F5F7),
      iconIdle: Color(0xFF9398A0),
      headerText: Color(0xFFC6CAD2),
      hover: Color(0x14AEB4BE),
    ),
    services: SectionAccent(
      plateStart: Color(0x70503A1E),
      plateEnd: Color(0x24B98A5A),
      border: Color(0x66B98A5A),
      barTop: Color(0xFFE0B488),
      barMid: Color(0xFFB98A5A),
      barBottom: Color(0xFF6E4E30),
      glow: Color(0x66B98A5A),
      iconActive: Color(0xFFF0D8BE),
      iconIdle: Color(0xFFBC9E80),
      headerText: Color(0xFFD0A070),
      hover: Color(0x14B98A5A),
    ),
    system: SectionAccent(
      plateStart: Color(0x701A2A4D),
      plateEnd: Color(0x245A9CF0),
      border: Color(0x665A9CF0),
      barTop: Color(0xFFA9CCF8),
      barMid: Color(0xFF5A9CF0),
      barBottom: Color(0xFF244A86),
      glow: Color(0x665A9CF0),
      iconActive: Color(0xFFCFE0FA),
      iconIdle: Color(0xFF8AA4C8),
      headerText: Color(0xFF7FB0F4),
      hover: Color(0x145A9CF0),
    ),
    cardShadow: [BoxShadow(color: Color(0x66000000), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0xB3000000),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFFD0A045),
  );

  /// Obsidian light — crisp high-key paper, charcoal ink.
  static const obsidianLight = Brass._(
    isDark: false,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFF3A3E46),
    bronze: Color(0xFF3A3E46),
    giltBright: Color(0xFF32363E),
    giltDeep: Color(0xFF525761),
    copper: Color(0xFF8A5A2E),
    hairline: Color(0x4416171A),
    brassStops: [
      Color(0xFF2A2C30),
      Color(0xFF6E727A),
      Color(0xFFD0D4DA),
      Color(0xFF5E626A),
      Color(0xFF222427),
    ],
    wordmarkStops: [Color(0xFF3A3E46), Color(0xFF26282E), Color(0xFF16171A)],
    moss: Color(0xFF2E8A4A),
    ochre: Color(0xFF855C06),
    madder: Color(0xFFC0303A),
    sand: Color(0xFF52575F),
    clay: Color(0xFF8F5A4A),
    sage: Color(0xFF46705E),
    slate: Color(0xFF2E6AD0),
    stone: Color(0xFF5E636B),
    verdigris: Color(0xFF2A7160),
    pine: Color(0xFF2E6B4E),
    indigo: Color(0xFF3A5EB0),
    navy: Color(0xFF1A2A4D),
    sparkGreen: Color(0xFF2E8A4A),
    sparkGreenDeep: Color(0xFF1E6A34),
    gaugeCpu: Color(0xFF5BBF7A),
    gaugeMemory: Color(0xFF5A9CF0),
    gaugeStorage: Color(0xFFD8DCE2),
    gaugeContainers: Color(0xFFE25555),
    textHeading: Color(0xFF16171A),
    textBody: Color(0xFF26282E),
    textMuted: Color(0xFF55595F),
    smallCaps: Color(0xFF3A3E46),
    bg: Color(0xFFF1F1F3),
    surface: Color(0xFFFAFAFC),
    panelTop: Color(0xFFFFFFFF),
    panelBottom: Color(0xFFF4F4F6),
    bannerTop: Color(0xFFFFFFFF),
    railTop: Color(0xFFF6F6F8),
    railBottom: Color(0xFFEBEBEE),
    recess: Color(0xFFE2E2E6),
    panelBorder: Color(0x3316171A),
    control: SectionAccent(
      plateStart: Color(0x5070757E),
      plateEnd: Color(0x24AEB4BE),
      border: Color(0x8C3A3E46),
      barTop: Color(0xFF3A3E46),
      barMid: Color(0xFF2A2D34),
      barBottom: Color(0xFF16171A),
      glow: Color(0x3316171A),
      iconActive: Color(0xFF16171A),
      iconIdle: Color(0xFF55595F),
      headerText: Color(0xFF2E3138),
      hover: Color(0x143A3E46),
    ),
    services: SectionAccent(
      plateStart: Color(0x70503A1E),
      plateEnd: Color(0x24B98A5A),
      border: Color(0x8C8A5A2E),
      barTop: Color(0xFF8A5A2E),
      barMid: Color(0xFF724A26),
      barBottom: Color(0xFF50341A),
      glow: Color(0x338A5A2E),
      iconActive: Color(0xFF3A2612),
      iconIdle: Color(0xFF725A44),
      headerText: Color(0xFF7A4E26),
      hover: Color(0x148A5A2E),
    ),
    system: SectionAccent(
      plateStart: Color(0x2E1A2A4D),
      plateEnd: Color(0x142E6AD0),
      border: Color(0x8C2E6AD0),
      barTop: Color(0xFF4A86E0),
      barMid: Color(0xFF2E6AD0),
      barBottom: Color(0xFF1A3E86),
      glow: Color(0x332E6AD0),
      iconActive: Color(0xFF16305E),
      iconIdle: Color(0xFF4A6494),
      headerText: Color(0xFF2E6AD0),
      hover: Color(0x142E6AD0),
    ),
    cardShadow: [BoxShadow(color: Color(0x24161718), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x40161718),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFF6E4A06),
  );

  // ===== Aqua (macOS) — Apple HIG system colors. =====
  /// Aqua dark — macOS dark surfaces, system blue.
  static const aquaDark = Brass._(
    isDark: true,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFF0A84FF),
    bronze: Color(0xFF0A84FF),
    giltBright: Color(0xFF5AB0FF),
    giltDeep: Color(0xFF0060DF),
    copper: Color(0xFFFF9F0A),
    hairline: Color(0x40636366),
    brassStops: [
      Color(0xFF0A3A66),
      Color(0xFF2E7AD0),
      Color(0xFFA9D4FF),
      Color(0xFF0A84FF),
      Color(0xFF063A66),
    ],
    wordmarkStops: [Color(0xFFFFFFFF), Color(0xFF0A84FF), Color(0xFF0060DF)],
    moss: Color(0xFF30D158),
    ochre: Color(0xFFFF9F0A),
    madder: Color(0xFFFF453A),
    sand: Color(0xFFC7C7CC),
    clay: Color(0xFFFF9F6A),
    sage: Color(0xFF63DA88),
    slate: Color(0xFF64D2FF),
    stone: Color(0xFF98989F),
    verdigris: Color(0xFF40C8B0),
    pine: Color(0xFF2E8A5E),
    indigo: Color(0xFF5E5CE6),
    navy: Color(0xFF0040A0),
    sparkGreen: Color(0xFF30D158),
    sparkGreenDeep: Color(0xFF248A3D),
    gaugeCpu: Color(0xFF30D158),
    gaugeMemory: Color(0xFF0A84FF),
    gaugeStorage: Color(0xFFFF9F0A),
    gaugeContainers: Color(0xFFFF453A),
    textHeading: Color(0xFFFFFFFF),
    textBody: Color(0xFFEBEBF0),
    textMuted: Color(0xFFAEAEB2),
    smallCaps: Color(0xFF8E8E93),
    bg: Color(0xFF1C1C1E),
    surface: Color(0xFF2C2C2E),
    panelTop: Color(0xFF3A3A3C),
    panelBottom: Color(0xFF2C2C2E),
    bannerTop: Color(0xFF3A3A3C),
    railTop: Color(0xFF2C2C2E),
    railBottom: Color(0xFF1C1C1E),
    recess: Color(0xFF161618),
    panelBorder: Color(0x54545458),
    control: SectionAccent(
      plateStart: Color(0x700060DF),
      plateEnd: Color(0x290A84FF),
      border: Color(0x800A84FF),
      barTop: Color(0xFFA9D4FF),
      barMid: Color(0xFF0A84FF),
      barBottom: Color(0xFF0040A0),
      glow: Color(0x990A84FF),
      iconActive: Color(0xFFD4E8FF),
      iconIdle: Color(0xFF98989F),
      headerText: Color(0xFF5AB0FF),
      hover: Color(0x140A84FF),
    ),
    services: SectionAccent(
      plateStart: Color(0x85704400),
      plateEnd: Color(0x2EFF9F0A),
      border: Color(0x80FF9F0A),
      barTop: Color(0xFFFFCB73),
      barMid: Color(0xFFFF9F0A),
      barBottom: Color(0xFF7A4E00),
      glow: Color(0x8CFF9F0A),
      iconActive: Color(0xFFFFE0B3),
      iconIdle: Color(0xFFC9A86E),
      headerText: Color(0xFFFFB84D),
      hover: Color(0x1AFF9F0A),
    ),
    system: SectionAccent(
      plateStart: Color(0x85302E86),
      plateEnd: Color(0x2E5E5CE6),
      border: Color(0x805E5CE6),
      barTop: Color(0xFFB0AFF4),
      barMid: Color(0xFF5E5CE6),
      barBottom: Color(0xFF302E86),
      glow: Color(0x8C5E5CE6),
      iconActive: Color(0xFFD4D4FA),
      iconIdle: Color(0xFF9A98C4),
      headerText: Color(0xFF8E8CF0),
      hover: Color(0x1A5E5CE6),
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
    warnGradEnd: Color(0xFFFFC94D),
  );

  /// Aqua light — macOS light surfaces, system blue.
  static const aquaLight = Brass._(
    isDark: false,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFF007AFF),
    bronze: Color(0xFF007AFF),
    giltBright: Color(0xFF0A84FF),
    giltDeep: Color(0xFF0060DF),
    copper: Color(0xFFC25E00),
    hairline: Color(0x59C6C6C8),
    brassStops: [
      Color(0xFF0A3A66),
      Color(0xFF2E7AD0),
      Color(0xFFA9D4FF),
      Color(0xFF0A84FF),
      Color(0xFF063A66),
    ],
    wordmarkStops: [Color(0xFF007AFF), Color(0xFF0060DF), Color(0xFF003E96)],
    moss: Color(0xFF248A3D),
    ochre: Color(0xFFB25E00),
    madder: Color(0xFFD70015),
    sand: Color(0xFF8E8E93),
    clay: Color(0xFFC8663C),
    sage: Color(0xFF3C8A5E),
    slate: Color(0xFF0071A4),
    stone: Color(0xFF6E6E73),
    verdigris: Color(0xFF2A8A76),
    pine: Color(0xFF2E6B4E),
    indigo: Color(0xFF3634A3),
    navy: Color(0xFF003E96),
    sparkGreen: Color(0xFF248A3D),
    sparkGreenDeep: Color(0xFF1A6B2E),
    gaugeCpu: Color(0xFF30D158),
    gaugeMemory: Color(0xFF0A84FF),
    gaugeStorage: Color(0xFFFF9F0A),
    gaugeContainers: Color(0xFFFF453A),
    textHeading: Color(0xFF000000),
    textBody: Color(0xFF1C1C1E),
    textMuted: Color(0xFF6E6E73),
    smallCaps: Color(0xFF3A3A3C),
    bg: Color(0xFFECECEE),
    surface: Color(0xFFFFFFFF),
    panelTop: Color(0xFFFFFFFF),
    panelBottom: Color(0xFFF2F2F7),
    bannerTop: Color(0xFFFFFFFF),
    railTop: Color(0xFFF2F2F7),
    railBottom: Color(0xFFE8E8ED),
    recess: Color(0xFFE0E0E6),
    panelBorder: Color(0x66C6C6C8),
    control: SectionAccent(
      plateStart: Color(0x700060DF),
      plateEnd: Color(0x290A84FF),
      border: Color(0x8C007AFF),
      barTop: Color(0xFF007AFF),
      barMid: Color(0xFF0060DF),
      barBottom: Color(0xFF003E96),
      glow: Color(0x33007AFF),
      iconActive: Color(0xFF003060),
      iconIdle: Color(0xFF5A6472),
      headerText: Color(0xFF0066D6),
      hover: Color(0x14007AFF),
    ),
    services: SectionAccent(
      plateStart: Color(0x85704400),
      plateEnd: Color(0x2EFF9F0A),
      border: Color(0x8CC25E00),
      barTop: Color(0xFFC25E00),
      barMid: Color(0xFFA24E00),
      barBottom: Color(0xFF6E3600),
      glow: Color(0x33C25E00),
      iconActive: Color(0xFF3E2200),
      iconIdle: Color(0xFF7A5A36),
      headerText: Color(0xFFA85200),
      hover: Color(0x14C25E00),
    ),
    system: SectionAccent(
      plateStart: Color(0x2E302E86),
      plateEnd: Color(0x143634A3),
      border: Color(0x8C3634A3),
      barTop: Color(0xFF5250C0),
      barMid: Color(0xFF3634A3),
      barBottom: Color(0xFF222070),
      glow: Color(0x333634A3),
      iconActive: Color(0xFF1C1A54),
      iconIdle: Color(0xFF5A5A8A),
      headerText: Color(0xFF3634A3),
      hover: Color(0x143634A3),
    ),
    cardShadow: [BoxShadow(color: Color(0x1F000000), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x33000000),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFF8A4600),
  );

  // ===== Catppuccin (Mocha / Latte) — the published Catppuccin palettes. =====
  /// Catppuccin Mocha (dark).
  static const catppuccinDark = Brass._(
    isDark: true,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFFCBA6F7),
    bronze: Color(0xFFCBA6F7),
    giltBright: Color(0xFFDABEFC),
    giltDeep: Color(0xFFA77DE8),
    copper: Color(0xFFFAB387),
    hairline: Color(0x476C7086),
    brassStops: [
      Color(0xFF45475A),
      Color(0xFF8087B0),
      Color(0xFFB4BEFE),
      Color(0xFF7E82C0),
      Color(0xFF3A3C52),
    ],
    wordmarkStops: [Color(0xFFF5E0DC), Color(0xFFCBA6F7), Color(0xFF89B4FA)],
    moss: Color(0xFFA6E3A1),
    ochre: Color(0xFFF9E2AF),
    madder: Color(0xFFF38BA8),
    sand: Color(0xFFBAC2DE),
    clay: Color(0xFFEBA0AC),
    sage: Color(0xFF94E2D5),
    slate: Color(0xFF89B4FA),
    stone: Color(0xFF9399B2),
    verdigris: Color(0xFF94E2D5),
    pine: Color(0xFF4A7A6E),
    indigo: Color(0xFFB4BEFE),
    navy: Color(0xFF4A4A7A),
    sparkGreen: Color(0xFFA6E3A1),
    sparkGreenDeep: Color(0xFF5E9E5A),
    gaugeCpu: Color(0xFFA6E3A1),
    gaugeMemory: Color(0xFF89B4FA),
    gaugeStorage: Color(0xFFF9E2AF),
    gaugeContainers: Color(0xFFF38BA8),
    textHeading: Color(0xFFCDD6F4),
    textBody: Color(0xFFBAC2DE),
    textMuted: Color(0xFF9399B2),
    smallCaps: Color(0xFFB4BEFE),
    bg: Color(0xFF1E1E2E),
    surface: Color(0xFF232338),
    panelTop: Color(0xFF313244),
    panelBottom: Color(0xFF1E1E2E),
    bannerTop: Color(0xFF313244),
    railTop: Color(0xFF181825),
    railBottom: Color(0xFF11111B),
    recess: Color(0xFF11111B),
    panelBorder: Color(0x4D6C7086),
    control: SectionAccent(
      plateStart: Color(0x70A77DE8),
      plateEnd: Color(0x29CBA6F7),
      border: Color(0x80CBA6F7),
      barTop: Color(0xFFDABEFC),
      barMid: Color(0xFFCBA6F7),
      barBottom: Color(0xFF7A52C0),
      glow: Color(0x99CBA6F7),
      iconActive: Color(0xFFE8DAFC),
      iconIdle: Color(0xFF9399B2),
      headerText: Color(0xFFCBA6F7),
      hover: Color(0x14CBA6F7),
    ),
    services: SectionAccent(
      plateStart: Color(0x85804A2A),
      plateEnd: Color(0x2EFAB387),
      border: Color(0x80FAB387),
      barTop: Color(0xFFFCD0B0),
      barMid: Color(0xFFFAB387),
      barBottom: Color(0xFF8A5A3A),
      glow: Color(0x8CFAB387),
      iconActive: Color(0xFFFCE0CC),
      iconIdle: Color(0xFFC6A48E),
      headerText: Color(0xFFFAB387),
      hover: Color(0x1AFAB387),
    ),
    system: SectionAccent(
      plateStart: Color(0x85344A8C),
      plateEnd: Color(0x2E89B4FA),
      border: Color(0x8089B4FA),
      barTop: Color(0xFFBFD4FE),
      barMid: Color(0xFF89B4FA),
      barBottom: Color(0xFF3A4C86),
      glow: Color(0x8C89B4FA),
      iconActive: Color(0xFFD4E0FE),
      iconIdle: Color(0xFF9399B2),
      headerText: Color(0xFF89B4FA),
      hover: Color(0x1A89B4FA),
    ),
    cardShadow: [BoxShadow(color: Color(0x4D11111B), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x9911111B),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFFE0C87F),
  );

  /// Catppuccin Latte (light).
  static const catppuccinLight = Brass._(
    isDark: false,
    displayFont: null,
    bodyFont: null,
    seed: Color(0xFF8839EF),
    bronze: Color(0xFF8839EF),
    giltBright: Color(0xFF7A2EDC),
    giltDeep: Color(0xFF8839EF),
    copper: Color(0xFFD4540A),
    hairline: Color(0x597C7F93),
    brassStops: [
      Color(0xFF45475A),
      Color(0xFF8087B0),
      Color(0xFFB4BEFE),
      Color(0xFF7E82C0),
      Color(0xFF3A3C52),
    ],
    wordmarkStops: [Color(0xFF8839EF), Color(0xFF1E66F5), Color(0xFF209FB5)],
    moss: Color(0xFF40A02B),
    ochre: Color(0xFFB5740D),
    madder: Color(0xFFD20F39),
    sand: Color(0xFF5C5F77),
    clay: Color(0xFFC94B3C),
    sage: Color(0xFF3C8A6E),
    slate: Color(0xFF1E66F5),
    stone: Color(0xFF6C6F85),
    verdigris: Color(0xFF179299),
    pine: Color(0xFF2E6B4E),
    indigo: Color(0xFF5A5FD0),
    navy: Color(0xFF1E40A0),
    sparkGreen: Color(0xFF40A02B),
    sparkGreenDeep: Color(0xFF2E7A1E),
    gaugeCpu: Color(0xFFA6E3A1),
    gaugeMemory: Color(0xFF89B4FA),
    gaugeStorage: Color(0xFFF9E2AF),
    gaugeContainers: Color(0xFFF38BA8),
    textHeading: Color(0xFF4C4F69),
    textBody: Color(0xFF5C5F77),
    textMuted: Color(0xFF7C7F93),
    smallCaps: Color(0xFF8839EF),
    bg: Color(0xFFEFF1F5),
    surface: Color(0xFFF5F6F9),
    panelTop: Color(0xFFFFFFFF),
    panelBottom: Color(0xFFE6E9EF),
    bannerTop: Color(0xFFFFFFFF),
    railTop: Color(0xFFE6E9EF),
    railBottom: Color(0xFFDCE0E8),
    recess: Color(0xFFCCD0DA),
    panelBorder: Color(0x557C7F93),
    control: SectionAccent(
      plateStart: Color(0x70A77DE8),
      plateEnd: Color(0x29CBA6F7),
      border: Color(0x8C8839EF),
      barTop: Color(0xFF8839EF),
      barMid: Color(0xFF7A2EDC),
      barBottom: Color(0xFF5A1EA8),
      glow: Color(0x338839EF),
      iconActive: Color(0xFF3A1A64),
      iconIdle: Color(0xFF6C6F85),
      headerText: Color(0xFF8030E0),
      hover: Color(0x148839EF),
    ),
    services: SectionAccent(
      plateStart: Color(0x85804A2A),
      plateEnd: Color(0x2EFAB387),
      border: Color(0x8CD4540A),
      barTop: Color(0xFFD4540A),
      barMid: Color(0xFFB84608),
      barBottom: Color(0xFF7A3006),
      glow: Color(0x33D4540A),
      iconActive: Color(0xFF4A2006),
      iconIdle: Color(0xFF7A5436),
      headerText: Color(0xFFC24C08),
      hover: Color(0x14D4540A),
    ),
    system: SectionAccent(
      plateStart: Color(0x2E344A8C),
      plateEnd: Color(0x141E66F5),
      border: Color(0x8C1E66F5),
      barTop: Color(0xFF4A82F8),
      barMid: Color(0xFF1E66F5),
      barBottom: Color(0xFF1240A0),
      glow: Color(0x331E66F5),
      iconActive: Color(0xFF123060),
      iconIdle: Color(0xFF5A6492),
      headerText: Color(0xFF1E5ED6),
      hover: Color(0x141E66F5),
    ),
    cardShadow: [BoxShadow(color: Color(0x244C4F69), offset: Offset(0, 3))],
    hoverShadow: [
      BoxShadow(
        color: Color(0x404C4F69),
        offset: Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    warnGradEnd: Color(0xFF8A5600),
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

  // ---- Typography ----
  //
  // Family-level (the same for a family's dark and light members). A null
  // family resolves to the platform's default sans — the authentic choice for
  // the modern/native themes (and macOS-flavoured Aqua), with zero bundled
  // font footprint. JetBrains Mono for IPs / torrents / the terminal is still
  // applied at those call sites regardless.

  /// Display / title / header / gauge-numeral family.
  final String? displayFont;

  /// Body / default family.
  final String? bodyFont;

  // ---- ThemeExtension ----

  /// Tokens are canonical immutable const sets, selected whole per theme —
  /// never partially modified — so [copyWith] returns the instance unchanged.
  @override
  Brass copyWith() => this;

  /// Palettes snap rather than lerp: a half-blended instrument looks broken,
  /// not transitional (and [themeAnimationDuration] is zero). Cross the
  /// midpoint to the target.
  @override
  Brass lerp(ThemeExtension<Brass>? other, double t) =>
      t < 0.5 ? this : (other as Brass? ?? this);

  // ---- Resolution ----

  /// The ambient token set. Carried on [ThemeData] as a [ThemeExtension], so
  /// it propagates to every widget, route, dialog and overlay under the app's
  /// [Theme] — a System/Light/Dark flip or a theme-family switch rebuilds
  /// dependents automatically. Falls back to [dark] only when no [Brass]
  /// extension is in scope (a bare `Theme`/`MaterialApp` with no theme set).
  static Brass of(BuildContext context) =>
      Theme.of(context).extension<Brass>() ?? dark;

  /// For no-context sites (painters, theme factories) that already know
  /// their brightness. NOTE: resolves the Brass family only, not the active
  /// theme — prefer [of] wherever a BuildContext is available.
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

  /// The active theme's display/title family (null = platform sans). Use for
  /// the hand-styled titles and headers that don't go through the textTheme.
  String? get displayFont => Brass.of(this).displayFont;
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

  /// Nord (arctic blue). See [Brass.nordDark].
  static const nord = ThemePack(
    id: 'nord',
    label: 'Nord',
    dark: Brass.nordDark,
    light: Brass.nordLight,
  );

  /// Ember (garnet / warm red). See [Brass.emberDark].
  static const ember = ThemePack(
    id: 'ember',
    label: 'Ember',
    dark: Brass.emberDark,
    light: Brass.emberLight,
  );

  /// Obsidian (matte true-black OLED). See [Brass.obsidianDark].
  static const obsidian = ThemePack(
    id: 'obsidian',
    label: 'Obsidian',
    dark: Brass.obsidianDark,
    light: Brass.obsidianLight,
  );

  /// Aqua (macOS system colors). See [Brass.aquaDark].
  static const aqua = ThemePack(
    id: 'aqua',
    label: 'Aqua',
    dark: Brass.aquaDark,
    light: Brass.aquaLight,
  );

  /// Catppuccin (Mocha / Latte). See [Brass.catppuccinDark].
  static const catppuccin = ThemePack(
    id: 'catppuccin',
    label: 'Catppuccin',
    dark: Brass.catppuccinDark,
    light: Brass.catppuccinLight,
  );

  /// Registry order is the settings-picker order. [brass] is first and is the
  /// canonical fallback for an unknown or missing stored id.
  static const all = <ThemePack>[
    brass,
    graphite,
    terminal,
    nord,
    ember,
    obsidian,
    aqua,
    catppuccin,
  ];

  /// The family for a stored [id], falling back to [brass].
  static ThemePack byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => brass);
}
