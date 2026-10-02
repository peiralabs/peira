import 'dart:io' show Platform;

import 'package:flutter/material.dart';

/// Design tokens for the HomeLab "frosted glass" language.
///
/// One spring, one ease, one set of durations, one spacing scale, one radius
/// scale, one set of glass tiers — referenced everywhere so the app reads as
/// *designed* rather than assembled. Consistency is the antidote to an
/// amateurish feel.
///
/// True when running under `flutter test`. Use this where the semantic is
/// "we are in tests" (e.g. the rail renders expanded so tap-by-label tests
/// work); use [kMolAnimationsEnabled] where the semantic is "animate".
final bool kUnderTest = Platform.environment.containsKey('FLUTTER_TEST');

/// [kMolAnimationsEnabled] is false under `flutter test` so repeating
/// animations (status-light breathing, ambient orbs) don't prevent
/// `pumpAndSettle` from ever settling. Triggered/implicit animations settle
/// on their own and are left on.
final bool kMolAnimationsEnabled = !kUnderTest;

/// Standard motion durations + curves.
abstract final class MolMotion {
  /// A quick tactile response — press feedback, small state flips.
  static const fast = Duration(milliseconds: 160);

  /// The default transition length for most animated properties.
  static const base = Duration(milliseconds: 260);

  /// The standard easing for entrances and property changes.
  static const standard = Curves.easeOutCubic;
}

/// Spacing scale (logical px). Vertical rhythm and component gaps both draw
/// from this so nothing is a magic number.
abstract final class MolSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
}

/// Corner-radius scale.
abstract final class MolRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;

  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
}

