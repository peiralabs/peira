import 'package:flutter/widgets.dart';

import 'brass.dart';

/// Each theme family's instrument language. The shared instrument widgets
/// (readouts, meters, dials, charts, lamps, toggles, fasteners) draw in the
/// active family's kit, so every tab changes character with the theme.
enum InstrumentKit {
  /// Victorian instrument maker: split-flap counters, liquid glass tubes,
  /// mercury dials, jewel lamps, bat toggles, slotted screws.
  brass,

  /// Braun lab equipment: reflective LCD digits, 10-cell bar graphs, a thin
  /// needle with an orange pointer, flat rockers, hex bolts.
  graphite,

  /// Green-phosphor CRT: glowing 7-segment digits, block bars, vector-scope
  /// rings, LED dots, slide switches, a moulded case (no screws).
  terminal,

  /// Glass cockpit: digital value boxes, thin LED strips, labelled arc
  /// gauges, lit push-buttons, cross-head screws.
  nord,

  /// 1950s tube hi-fi: Nixie tubes, magic-eye indicators, VU needles on
  /// cream faces, amber pilot lamps, chrome toggles.
  ember,

  /// Matte true-black with low-chroma steel: steel segment readouts, steel
  /// cell bars, steel graticules, smoked guarded toggles, matte rivets.
  obsidian,

  /// 2000s Aqua: glossy lozenges, striped gel bars, glass dials, candy beads.
  aqua,

  /// Soft synth gear: pastel pills, chunky rounded segments, soft rings,
  /// rounded rockers, soft rivets.
  catppuccin;

  /// The kit of the family whose palette [b] is. Each family's palettes are
  /// canonical const instances, so identity picks the family; anything
  /// unrecognised (a lerped or test palette) falls back to [brass].
  static InstrumentKit of(Brass b) {
    for (final pack in ThemePack.all) {
      if (identical(pack.dark, b) || identical(pack.light, b)) {
        return InstrumentKit.values.firstWhere(
          (k) => k.name == pack.id,
          orElse: () => InstrumentKit.brass,
        );
      }
    }
    return InstrumentKit.brass;
  }
}

extension InstrumentKitContext on BuildContext {
  /// The active theme family's instrument kit.
  InstrumentKit get kit => InstrumentKit.of(Brass.of(this));
}

/// Each family's chart inks: the per-metric series colours of the Metrics
/// charts (node lines are shades of these). Brass keeps its authored period
/// inks, so it has none here. Every family gets distinct hues per metric, in
/// its own character, with deeper variants for light mode.
class ChartInks {
  const ChartInks(
    this.cpu,
    this.memory,
    this.disk,
    this.network,
    this.temp,
    this.aiTokens,
    this.aiLatency,
    this.twin,
    this.power,
    this.cost,
  );

  final Color cpu, memory, disk, network, temp;
  final Color aiTokens, aiLatency, twin, power, cost;

  static ChartInks? of(InstrumentKit kit, bool dark) => switch (kit) {
    InstrumentKit.brass => null,
    // Braun lab: signal orange, steel blue, warm grey, lab green, amber.
    InstrumentKit.graphite => dark
        ? const ChartInks(Color(0xFFFF7A1A), Color(0xFF8FA8BF), Color(0xFFC2BAAD),
            Color(0xFF7FC08F), Color(0xFFE0A040), Color(0xFF9ABCDE),
            Color(0xFFB8BEC6), Color(0xFFD5DADF), Color(0xFFE8C46A), Color(0xFF8FC09A))
        : const ChartInks(Color(0xFFD9530A), Color(0xFF3F5E7A), Color(0xFF7A7166),
            Color(0xFF2E7A45), Color(0xFFB07A10), Color(0xFF2F6A9E),
            Color(0xFF5A6470), Color(0xFF2B3036), Color(0xFF9A7A10), Color(0xFF2E7A4F)),
    // Terminal's own palette: phosphor green, cyan, verdigris, blue, amber.
    InstrumentKit.terminal => dark
        ? const ChartInks(Color(0xFF5BFF8F), Color(0xFF5AC8FA), Color(0xFF2EE6C0),
            Color(0xFF7FB0FF), Color(0xFFFFB000), Color(0xFF9CFFC0),
            Color(0xFF6FD98A), Color(0xFF9FE0A8), Color(0xFFFFB000), Color(0xFF6FD98A))
        : const ChartInks(Color(0xFF1F7A3D), Color(0xFF0369A1), Color(0xFF0F766E),
            Color(0xFF1D4ED8), Color(0xFFA16207), Color(0xFF1C6E37),
            Color(0xFF2E7A45), Color(0xFF3F6E48), Color(0xFFA16207), Color(0xFF2E7A45)),
    // Nord: aurora and frost.
    InstrumentKit.nord => dark
        ? const ChartInks(Color(0xFFA3BE8C), Color(0xFF81A1C1), Color(0xFFEBCB8B),
            Color(0xFF88C0D0), Color(0xFFD08770), Color(0xFF8FBCBB),
            Color(0xFF5E81AC), Color(0xFFB48EAD), Color(0xFFEBCB8B), Color(0xFFA3BE8C))
        : const ChartInks(Color(0xFF5A7D3F), Color(0xFF4C6E96), Color(0xFFA77B1E),
            Color(0xFF2E7A8C), Color(0xFFB0573A), Color(0xFF3F7E7A),
            Color(0xFF3B5B8A), Color(0xFF8A5C82), Color(0xFFA77B1E), Color(0xFF5A7D3F)),
    // Tube hi-fi: amber, cream, copper, orange glow, red.
    InstrumentKit.ember => dark
        ? const ChartInks(Color(0xFFFFB15C), Color(0xFFEBDCC0), Color(0xFFD0884A),
            Color(0xFFFF7A3D), Color(0xFFE24A4A), Color(0xFFFFC27A),
            Color(0xFFD9B99A), Color(0xFFE89A7A), Color(0xFFFFD08A), Color(0xFFC9A06A))
        : const ChartInks(Color(0xFFB4650F), Color(0xFF7A5A3A), Color(0xFF9A5420),
            Color(0xFFC2410C), Color(0xFFB91C1C), Color(0xFFA0570F),
            Color(0xFF6E4E30), Color(0xFF9A3412), Color(0xFFA16207), Color(0xFF7A5A1E)),
    // Obsidian's own low-chroma tokens: moss, steel blue, silver, verdigris,
    // ochre.
    InstrumentKit.obsidian => dark
        ? const ChartInks(Color(0xFF5BBF7A), Color(0xFF5A9CF0), Color(0xFFD8DCE2),
            Color(0xFF4FAE96), Color(0xFFE0A83F), Color(0xFF8FB7A0),
            Color(0xFF7FA8E0), Color(0xFF8A8F98), Color(0xFFE0A83F), Color(0xFF5BBF7A))
        : const ChartInks(Color(0xFF2E8A4A), Color(0xFF2563C9), Color(0xFF4B5058),
            Color(0xFF2E7D68), Color(0xFFA86E10), Color(0xFF4E7A62),
            Color(0xFF3B5FA0), Color(0xFF5E636B), Color(0xFFA86E10), Color(0xFF2E8A4A)),
    // macOS system colours.
    InstrumentKit.aqua => dark
        ? const ChartInks(Color(0xFF30D158), Color(0xFF0A84FF), Color(0xFFFF9F0A),
            Color(0xFFBF5AF2), Color(0xFFFF453A), Color(0xFF64D2FF),
            Color(0xFF5E5CE6), Color(0xFFFF375F), Color(0xFFFFD60A), Color(0xFF30D158))
        : const ChartInks(Color(0xFF248A3D), Color(0xFF0071E3), Color(0xFFC93400),
            Color(0xFF8944AB), Color(0xFFD70015), Color(0xFF0071A4),
            Color(0xFF3634A3), Color(0xFFD30F45), Color(0xFFB25000), Color(0xFF248A3D)),
    // Catppuccin Mocha / Latte accents.
    InstrumentKit.catppuccin => dark
        ? const ChartInks(Color(0xFFA6E3A1), Color(0xFF89B4FA), Color(0xFFF9E2AF),
            Color(0xFFCBA6F7), Color(0xFFFAB387), Color(0xFF94E2D5),
            Color(0xFF74C7EC), Color(0xFFF5C2E7), Color(0xFFF9E2AF), Color(0xFFA6E3A1))
        : const ChartInks(Color(0xFF40A02B), Color(0xFF1E66F5), Color(0xFFDF8E1D),
            Color(0xFF8839EF), Color(0xFFFE640B), Color(0xFF179299),
            Color(0xFF209FB5), Color(0xFFEA76CB), Color(0xFFDF8E1D), Color(0xFF40A02B)),
  };
}
