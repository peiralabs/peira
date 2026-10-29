import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/widgets/flip_readout.dart';

import 'support/render_fonts.dart';

/// Digits shown in the readout right now (flap halves duplicate glyphs, so
/// collect the distinct ones).
Set<String> _shown(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .toSet();

Widget _host(String text, {int epoch = 0, Key? key}) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(
    backgroundColor: const Color(0xFF0F1912),
    body: Center(
      child: RepaintBoundary(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FlipReadout(text: text, fontSize: 40, epoch: epoch),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() => FlipReadout.debugForceMotion = true);
  tearDown(() => FlipReadout.debugForceMotion = false);

  testWidgets('counts up from zero through every digit, then rests', (
    tester,
  ) async {
    await tester.pumpWidget(_host('63%'));
    expect(_shown(tester), containsAll(['0', '%']));
    final seen = <String>{};
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      seen.addAll(_shown(tester));
    }
    await tester.pumpAndSettle();
    // The tens flap clicked forward 1..6 on its way, never skipping.
    expect(seen, containsAll(['1', '2', '3', '4', '5', '6']));
    expect(_shown(tester), {'6', '3', '%'});
  });

  testWidgets('a change clicks forward only; a new epoch replays', (
    tester,
  ) async {
    await tester.pumpWidget(_host('8'));
    await tester.pumpAndSettle();
    expect(_shown(tester), {'8'});

    // 8 → 1 goes the long way round a real flap: 9, 0, then 1.
    await tester.pumpWidget(_host('1'));
    final seen = <String>{};
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      seen.addAll(_shown(tester));
    }
    await tester.pumpAndSettle();
    expect(seen, containsAll(['9', '0']));
    expect(_shown(tester), {'1'});

    // A replay rolls on round through 0 and counts back up to the value.
    await tester.pumpWidget(_host('1', epoch: 1));
    final replay = <String>{};
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      replay.addAll(_shown(tester));
    }
    await tester.pumpAndSettle();
    expect(replay, containsAll(['5', '0']));
    expect(_shown(tester), {'1'});
  });

  testWidgets('a replay arriving mid-count does not drop the flip in flight', (
    tester,
  ) async {
    // The boot splash bumps the sweep epoch while the first count-up is
    // still running; the flap must carry on and land on its value.
    await tester.pumpWidget(_host('63%'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(_host('63%', epoch: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_shown(tester), {'6', '3', '%'});
  });

  // Opt-in: FLIP_FILMSTRIP=<dir> writes frames of a count-up to PNG, to look
  // at the flaps mid-flip (motion is off in every other test).
  final dir = Platform.environment['FLIP_FILMSTRIP'];
  testWidgets('filmstrip', skip: dir == null, (tester) async {
    await loadRealFonts();
    final key = GlobalKey();
    await tester.pumpWidget(_host('42%', key: key));
    for (var f = 0; f < 18; f++) {
      await tester.pump(const Duration(milliseconds: 35));
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$dir/frame-${f.toString().padLeft(2, '0')}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
    await tester.pumpAndSettle();
  });
}
