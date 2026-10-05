// Not a `_test.dart` file, so `flutter test` does not run it by default.
// Run explicitly to regenerate palette previews:
//   flutter test test/theme_preview_tool.dart
// Writes one PNG per theme family to the path in THEME_PREVIEW_DIR
// (default /tmp). Uses the software rasterizer, so it needs no GPU/display.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/theme/app_theme.dart';

const _cellW = 460.0;
const _cellH = 320.0;

void main() {
  final outDir = Platform.environment['THEME_PREVIEW_DIR'] ?? '/tmp';

  for (final pack in ThemePack.all) {
    testWidgets('render ${pack.id}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(_cellW * 2, _cellH));
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                _Cell(pack: pack, brightness: Brightness.dark),
                _Cell(pack: pack, brightness: Brightness.light),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // toImage()/toByteData() resolve on the raster thread, which the test's
      // fake-async clock will not pump — run them on the real event loop.
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$outDir/theme-${pack.id}.png');
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        // ignore: avoid_print
        print('wrote ${file.path} (${pack.label})');
      });
    });
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.pack, required this.brightness});
  final ThemePack pack;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final theme = brightness == Brightness.dark
        ? AppTheme.dark(pack)
        : AppTheme.light(pack);
    return SizedBox(
      width: _cellW,
      height: _cellH,
      child: Theme(
        data: theme,
        child: ActiveTheme(
          pack: pack,
          child: Builder(builder: _body),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final b = context.brass;
    TextStyle t(Color c, double s, [FontWeight w = FontWeight.w400]) =>
        TextStyle(color: c, fontSize: s, fontWeight: w);
    Widget jewel(Jewel j) => Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: j.cabochon,
        boxShadow: b.jewelHalo(j),
      ),
    );
    Widget bar(String section) {
      final kit = b.kit(section);
      return Container(
        width: 90,
        height: 26,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: kit.plate,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kit.border),
        ),
        alignment: Alignment.center,
        child: Text(section, style: t(kit.headerText, 11, FontWeight.w600)),
      );
    }

    Widget meter(double frac) => Container(
      width: 120,
      height: 12,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: b.recess,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        widthFactor: frac,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: b.loadGradient(frac)),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );

    return Container(
      color: b.bg,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pack.label} · ${b.isDark ? 'dark' : 'light'}',
            style: t(b.textHeading, 16, FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: b.panelGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: b.panelBorder),
                boxShadow: b.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Heading', style: t(b.textHeading, 14, FontWeight.w600)),
                  Text('Body copy on panel', style: t(b.textBody, 12)),
                  Text('Muted / secondary', style: t(b.textMuted, 11)),
                  const SizedBox(height: 10),
                  Row(children: [bar('Control'), bar('Services'), bar('System')]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      jewel(Brass.emerald),
                      jewel(Brass.sapphire),
                      jewel(Brass.ruby),
                      jewel(Brass.topaz),
                      jewel(Brass.amethyst),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(children: [meter(0.4), meter(0.7), meter(0.92)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
