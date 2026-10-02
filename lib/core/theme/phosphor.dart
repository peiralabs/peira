import 'package:flutter/widgets.dart';

/// Phosphor icon constants over the bundled icon fonts
/// (assets/fonts/Phosphor.ttf / Phosphor-Bold.ttf, OFL — extracted from the
/// phosphor_flutter 2.1.0 package, which no longer compiles against Flutter's
/// final `IconData`). Codepoints are identical across weights; only the font
/// family differs. Add constants here as screens need them.
class Ph {
  Ph._();
  static const _f = 'Phosphor';

  static const squaresFour = IconData(0xe464, fontFamily: _f);
  static const hardDrives = IconData(0xe2a0, fontFamily: _f);
  static const chartLineUp = IconData(0xe156, fontFamily: _f);
  static const robot = IconData(0xe762, fontFamily: _f);
  static const brain = IconData(0xe74e, fontFamily: _f);
  static const bookOpenText = IconData(0xe8f2, fontFamily: _f);
  static const monitorPlay = IconData(0xe58c, fontFamily: _f);
  static const shieldCheck = IconData(0xe40c, fontFamily: _f);
  static const terminalWindow = IconData(0xeae8, fontFamily: _f);
  static const gearSix = IconData(0xe272, fontFamily: _f);
  static const magnifyingGlass = IconData(0xe30c, fontFamily: _f);
  static const chatCircleText = IconData(0xe16e, fontFamily: _f);
  static const caretLeft = IconData(0xe138, fontFamily: _f);
  static const caretRight = IconData(0xe13a, fontFamily: _f);
  static const caretDown = IconData(0xe136, fontFamily: _f);
  static const caretUp = IconData(0xe13c, fontFamily: _f);
  static const arrowsClockwise = IconData(0xe094, fontFamily: _f);
  static const arrowClockwise = IconData(0xe036, fontFamily: _f);
  static const x = IconData(0xe4f6, fontFamily: _f);
  static const minus = IconData(0xe32a, fontFamily: _f);
  static const plus = IconData(0xe3d4, fontFamily: _f);
  static const check = IconData(0xe182, fontFamily: _f);
  static const checkCircle = IconData(0xe184, fontFamily: _f);
  static const play = IconData(0xe3d0, fontFamily: _f);
  static const trash = IconData(0xe4a6, fontFamily: _f);
  static const copy = IconData(0xe1ca, fontFamily: _f);
  static const downloadSimple = IconData(0xe20c, fontFamily: _f);
  static const paperPlaneTilt = IconData(0xe398, fontFamily: _f);
  static const cube = IconData(0xe1da, fontFamily: _f);
  static const filmSlate = IconData(0xe8c2, fontFamily: _f);
  static const televisionSimple = IconData(0xeae6, fontFamily: _f);
  static const detective = IconData(0xe83e, fontFamily: _f);
  static const compass = IconData(0xe1c8, fontFamily: _f);
  static const globeSimple = IconData(0xe28e, fontFamily: _f);
  static const lockSimple = IconData(0xe308, fontFamily: _f);
  static const house = IconData(0xe2c2, fontFamily: _f);
  static const warning = IconData(0xe4e0, fontFamily: _f);
  static const lightning = IconData(0xe2de, fontFamily: _f);
  static const thermometer = IconData(0xe5c6, fontFamily: _f);
  static const cpu = IconData(0xe610, fontFamily: _f);
  static const database = IconData(0xe1de, fontFamily: _f);
  static const stack = IconData(0xe466, fontFamily: _f);
  static const listChecks = IconData(0xeadc, fontFamily: _f);
  static const clockCounterClockwise = IconData(0xe1a0, fontFamily: _f);
  // 2026-08-18 service expansion. Codepoints cross-verified two ways: the
  // official regular-weight map reproduces every pre-existing constant above
  // exactly, and each new codepoint is present in the bundled Phosphor.ttf
  // cmap.
  static const image = IconData(0xe2ca, fontFamily: _f);
  static const bookmarkSimple = IconData(0xe0ea, fontFamily: _f);
  static const fileText = IconData(0xe23a, fontFamily: _f);
  static const eye = IconData(0xe220, fontFamily: _f);
  static const scroll = IconData(0xeb7a, fontFamily: _f);
  static const books = IconData(0xe758, fontFamily: _f);
  static const treeStructure = IconData(0xe67c, fontFamily: _f);
}

/// Bold weights (design uses `ph-bold` for active nav icons, studs, sends).
class PhBold {
  PhBold._();
  static const _f = 'Phosphor-Bold';

  static const caretLeft = IconData(0xe138, fontFamily: _f);
  static const caretRight = IconData(0xe13a, fontFamily: _f);
  static const x = IconData(0xe4f6, fontFamily: _f);
  static const minus = IconData(0xe32a, fontFamily: _f);
  static const check = IconData(0xe182, fontFamily: _f);
  static const hardDrives = IconData(0xe2a0, fontFamily: _f);
  static const chartLineUp = IconData(0xe156, fontFamily: _f);
  static const robot = IconData(0xe762, fontFamily: _f);
  static const brain = IconData(0xe74e, fontFamily: _f);
  static const shieldCheck = IconData(0xe40c, fontFamily: _f);
  static const terminalWindow = IconData(0xeae8, fontFamily: _f);
  static const downloadSimple = IconData(0xe20c, fontFamily: _f);
  static const paperPlaneTilt = IconData(0xe398, fontFamily: _f);
}
