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

  /// Military stealth: amber LCD segments, dim bars, night-vision
  /// graticules, guarded toggles, matte rivets.
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
