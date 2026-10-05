import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/theme/app_theme.dart';

void main() {
  group('ThemePack registry', () {
    test('byId resolves known families', () {
      expect(ThemePack.byId('brass'), same(ThemePack.brass));
      expect(ThemePack.byId('graphite'), same(ThemePack.graphite));
    });

    test('byId falls back to Brass for null / unknown ids', () {
      expect(ThemePack.byId(null), same(ThemePack.brass));
      expect(ThemePack.byId(''), same(ThemePack.brass));
      expect(ThemePack.byId('does-not-exist'), same(ThemePack.brass));
    });

    test('Brass is first in the registry (default/fallback order)', () {
      expect(ThemePack.all.first, same(ThemePack.brass));
    });

    test('each family resolves distinct dark/light token sets', () {
      for (final pack in ThemePack.all) {
        expect(pack.resolve(Brightness.dark), same(pack.dark));
        expect(pack.resolve(Brightness.light), same(pack.light));
        expect(pack.dark.isDark, isTrue);
        expect(pack.light.isDark, isFalse);
      }
    });
  });

  group('AppTheme is family-aware', () {
    test('defaults to Brass when no pack is passed', () {
      expect(
        AppTheme.dark().scaffoldBackgroundColor,
        Brass.dark.bg,
      );
    });

    test('builds from the requested family', () {
      expect(
        AppTheme.dark(ThemePack.graphite).scaffoldBackgroundColor,
        Brass.graphiteDark.bg,
      );
      expect(
        AppTheme.light(ThemePack.graphite).scaffoldBackgroundColor,
        Brass.graphiteLight.bg,
      );
    });

    test('families produce visibly different backgrounds', () {
      expect(
        AppTheme.dark(ThemePack.graphite).scaffoldBackgroundColor,
        isNot(AppTheme.dark().scaffoldBackgroundColor),
      );
    });
  });

  group('ActiveTheme propagation', () {
    testWidgets('context.brass resolves the injected family', (tester) async {
      late Brass seen;
      await tester.pumpWidget(
        ActiveTheme(
          pack: ThemePack.graphite,
          child: MaterialApp(
            theme: AppTheme.dark(ThemePack.graphite),
            home: Builder(
              builder: (context) {
                seen = context.brass;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(seen, same(Brass.graphiteDark));
    });

    testWidgets('falls back to Brass with no ActiveTheme in scope', (
      tester,
    ) async {
      late Brass seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              seen = context.brass;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(Brass.dark));
    });
  });
}
