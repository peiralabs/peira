import 'package:flutter/painting.dart';

import 'brass.dart';
import 'instrument_kit.dart';

/// Carries a colour hand-tuned for the Brass family into another family.
///
/// Many screens keep small palettes of colours authored against Brass (a
/// strip's garnet tint, a terminal's navy chrome...). For any other family,
/// each such colour is matched to the nearest Brass token (surface, text,
/// gilt, status...) and replaced by the same token of the active family,
/// keeping the original's alpha and its small lightness/saturation offset
/// from that token. Status colours (ok / warn / crit) map to the family's
/// own status tokens, so meaning is preserved. Brass itself is untouched.
Color themeColor(Color c, Brass target) {
  if (InstrumentKit.of(target) == InstrumentKit.brass) return c;
  final key = (c.toARGB32(), identityHashCode(target));
  return _cache.putIfAbsent(key, () => _transfer(c, target));
}

final _cache = <(int, int), Color>{};

List<Color> _tokens(Brass x) => [
  x.bg, x.surface, x.panelTop, x.panelBottom, x.bannerTop, x.railTop,
  x.railBottom, x.recess, x.panelBorder, x.hairline,
  x.giltBright, x.giltDeep, x.bronze, x.copper,
  x.textHeading, x.textBody, x.textMuted, x.smallCaps,
  x.sand, x.clay, x.sage, x.slate, x.stone, x.moss, x.ochre, x.madder,
  x.verdigris, x.pine, x.indigo, x.navy, x.sparkGreen, x.sparkGreenDeep,
];

Color _transfer(Color c, Brass target) {
  final source = target.isDark ? Brass.dark : Brass.light;
  final from = _tokens(source);
  final to = _tokens(target);
  var best = 0;
  var bestD = double.infinity;
  for (var i = 0; i < from.length; i++) {
    final t = from[i];
    // Perceptually weighted RGB distance; alpha is carried separately.
    final dr = (c.r - t.r) * 255, dg = (c.g - t.g) * 255, db = (c.b - t.b) * 255;
    final rm = (c.r + t.r) * 255 / 2;
    final d = (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db;
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  final src = HSLColor.fromColor(from[best].withValues(alpha: 1));
  final dst = HSLColor.fromColor(to[best].withValues(alpha: 1));
  final orig = HSLColor.fromColor(c.withValues(alpha: 1));
  final light = (dst.lightness + (orig.lightness - src.lightness)).clamp(0.0, 1.0);
  final sat = src.saturation > 0.05
      ? (dst.saturation * orig.saturation / src.saturation).clamp(0.0, 1.0)
      : dst.saturation;
  return dst
      .withLightness(light)
      .withSaturation(sat)
      .toColor()
      .withValues(alpha: c.a);
}

/// [themeColor] over a gradient's stops.
LinearGradient themeGradient(LinearGradient g, Brass target) => LinearGradient(
  begin: g.begin,
  end: g.end,
  colors: [for (final c in g.colors) themeColor(c, target)],
  stops: g.stops,
  tileMode: g.tileMode,
);

/// [themeColor] over shadows' colours.
List<BoxShadow> themeShadows(List<BoxShadow> s, Brass target) => [
  for (final x in s) x.copyWith(color: themeColor(x.color, target)),
];
