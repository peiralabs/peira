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

    // Family-invariant tokens (the metal ramp, the shared-dark gauge faces,
    // and typography) must stay identical between a family's dark and light
    // members. They're stored on both for a flat `context.brass` access path;
    // this guards against editing one member and silently leaving the other
    // behind.
    test('family-invariant tokens match across each dark/light pair', () {
      for (final pack in ThemePack.all) {
        final d = pack.dark;
        final l = pack.light;
        expect(d.brassStops, l.brassStops, reason: '${pack.id} brassStops');
        expect(d.gaugeCpu, l.gaugeCpu, reason: '${pack.id} gaugeCpu');
        expect(d.gaugeMemory, l.gaugeMemory, reason: '${pack.id} gaugeMemory');
        expect(d.gaugeStorage, l.gaugeStorage,
            reason: '${pack.id} gaugeStorage');
        expect(d.gaugeContainers, l.gaugeContainers,
            reason: '${pack.id} gaugeContainers');
        expect(d.displayFont, l.displayFont, reason: '${pack.id} displayFont');
        expect(d.bodyFont, l.bodyFont, reason: '${pack.id} bodyFont');
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

  group('ThemeExtension propagation', () {
    testWidgets('context.brass resolves the theme\'s Brass extension', (
      tester,
    ) async {
      late Brass seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(ThemePack.graphite),
          home: Builder(
            builder: (context) {
              seen = context.brass;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(Brass.graphiteDark));
    });

    testWidgets('light theme resolves the light member of the family', (
      tester,
    ) async {
      late Brass seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemePack.terminal),
          home: Builder(
            builder: (context) {
              seen = context.brass;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(Brass.terminalLight));
    });

    testWidgets('falls back to Brass dark when no Brass extension is set', (
      tester,
    ) async {
      late Brass seen;
      await tester.pumpWidget(
        MaterialApp(
          // A ThemeData with no Brass extension at all.
          theme: ThemeData(brightness: Brightness.dark),
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
