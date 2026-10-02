import 'package:flutter/material.dart';

import 'brass.dart';

export 'brass.dart';

/// "Brass Edition" — the HomeLab theme. An antique brass astronomical
/// instrument in a Victorian library: deep bottle-green fields, gilt and
/// polished-brass ornament, jewel-tone accents (emerald / sapphire / ruby /
/// topaz / amethyst), engraved serif type. Exact values from
/// design/brass/README.md §Design Tokens; the class/method surface is kept
/// from the Study theme so call sites survive.
class AppTheme {
  AppTheme._();


  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final brass = Brass.resolve(brightness);
    final scheme = ColorScheme.fromSeed(
      seedColor: brass.seed,
      brightness: brightness,
    ).copyWith(
      secondary: brass.copper,
      tertiary: brass.sand,
      surface: brass.surface,
    );

    // Engraved pairing: Playfair Display carries every display/title role —
    // screen titles, panel headers, gauge numerals — while EB Garamond sets
    // body copy. JetBrains Mono is applied locally where the design calls
    // for it (IPs, torrents, terminal).
    final baseText =
        (isDark ? Typography.material2021().white : Typography.material2021().black)
            .apply(fontFamily: 'EB Garamond');
    TextStyle? serif(TextStyle? t, {double? spacing}) =>
        t?.copyWith(fontFamily: 'Playfair Display', letterSpacing: spacing);
    final textTheme = baseText.copyWith(
      displayLarge: serif(baseText.displayLarge),
      displayMedium: serif(baseText.displayMedium),
      displaySmall: serif(baseText.displaySmall),
      headlineLarge: serif(baseText.headlineLarge),
      headlineMedium: serif(baseText.headlineMedium),
      headlineSmall: serif(baseText.headlineSmall),
      titleLarge: serif(baseText.titleLarge, spacing: -0.2),
      titleMedium: serif(baseText.titleMedium, spacing: -0.1),
      titleSmall: serif(baseText.titleSmall),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'EB Garamond',
      textTheme: textTheme,
      scaffoldBackgroundColor: brass.bg,
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: brass.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: brass.panelBorder, width: 0.5),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: brass.railTop.withValues(alpha: 0.94),
        indicatorColor: brass.bronze.withValues(alpha: isDark ? 0.18 : 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        selectedIconTheme: IconThemeData(color: brass.bronze),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: brass.bronze,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: brass.panelBorder,
        space: 1,
        thickness: 1,
      ),
      // Light only: the M3 default switch pairs a pure-white thumb (never
      // pure white on parchment) with a flat umber track. Selected becomes
      // a giltDeep rail carrying a warm parchment-cream thumb; unselected
      // recesses into the parchment with the hairline ring and an umber
      // ink stud. Dark keeps the M3 defaults verbatim.
      switchTheme: isDark
          ? null
          : SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? brass.panelTop // warm parchment cream #F4EEE2
                    : brass.smallCaps, // umber ink stud
              ),
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? brass.giltDeep
                    : brass.recess,
              ),
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? brass.giltDeep
                    : brass.hairline,
              ),
            ),
    );
  }
}
