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


  static ThemeData light([ThemePack pack = ThemePack.brass]) =>
      _build(Brightness.light, pack);
  static ThemeData dark([ThemePack pack = ThemePack.brass]) =>
      _build(Brightness.dark, pack);

  static ThemeData _build(Brightness brightness, ThemePack pack) {
    final isDark = brightness == Brightness.dark;
    final brass = pack.resolve(brightness);
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
    // body copy; Graphite shares it. Terminal is all JetBrains Mono; the
    // modern/native families (Nord, Ember, Obsidian, Aqua, Catppuccin) use the
    // platform sans (null family). JetBrains Mono is still applied locally
    // where the design calls for it (IPs, torrents, terminal).
    final baseText =
        (isDark ? Typography.material2021().white : Typography.material2021().black)
            .apply(fontFamily: brass.bodyFont);
    TextStyle? display(TextStyle? t, {double? spacing}) =>
        t?.copyWith(fontFamily: brass.displayFont, letterSpacing: spacing);
    final textTheme = baseText.copyWith(
      displayLarge: display(baseText.displayLarge),
      displayMedium: display(baseText.displayMedium),
      displaySmall: display(baseText.displaySmall),
      headlineLarge: display(baseText.headlineLarge),
      headlineMedium: display(baseText.headlineMedium),
      headlineSmall: display(baseText.headlineSmall),
      titleLarge: display(baseText.titleLarge, spacing: -0.2),
      titleMedium: display(baseText.titleMedium, spacing: -0.1),
      titleSmall: display(baseText.titleSmall),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: brass.bodyFont,
      textTheme: textTheme,
      scaffoldBackgroundColor: brass.bg,
      // Carry the resolved token set so `context.brass` (→ Brass.of →
      // Theme.of(context).extension<Brass>()) resolves the active family
      // everywhere a Theme is in scope — routes, dialogs and overlays included.
      extensions: [brass],
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
