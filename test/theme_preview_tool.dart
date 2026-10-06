// Not a `_test.dart` file, so `flutter test` does not run it by default.
// Run explicitly to regenerate palette previews:
//   flutter test test/theme_preview_tool.dart
// Writes one PNG per theme family to THEME_PREVIEW_DIR (default /tmp).
// Software rasterizer — no GPU/display needed.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/theme/app_theme.dart';

const _cellW = 600.0;
const _cellH = 360.0;

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
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$outDir/theme-${pack.id}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
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
        child: Builder(builder: _body),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final b = context.brass;
    TextStyle t(Color c, double s, [FontWeight w = FontWeight.w400]) =>
        TextStyle(color: c, fontSize: s, fontWeight: w);

    // Nav-rail mock: the three section nameplates carry each theme's section
    // identity via the vivid bar gradient + plate wash.
    Widget nameplate(String section) {
      final kit = b.kit(section);
      return Container(
        height: 56,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          gradient: kit.plate,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kit.border),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                gradient: kit.bar,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: Text(section, style: t(kit.headerText, 12, FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    Widget chip(Color c) => Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(right: 7),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: b.hairline),
      ),
    );

    Widget meter(double frac) => Container(
      width: 110,
      height: 11,
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

    final onAccent = b.isDark ? b.bg : b.panelTop;

    return Container(
      color: b.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nav rail
          Container(
            width: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [b.railTop, b.railBottom],
              ),
              border: Border(right: BorderSide(color: b.panelBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  child: ShaderMask(
                    shaderCallback: (r) => b.wordmarkGradient.createShader(r),
                    child: Text(
                      'PEIRA',
                      style: t(Colors.white, 20, FontWeight.w800),
                    ),
                  ),
                ),
                nameplate('Control'),
                nameplate('Services'),
                nameplate('System'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${pack.label} · ${b.isDark ? 'dark' : 'light'}',
                          overflow: TextOverflow.ellipsis,
                          style: t(b.textHeading, 16, FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Primary (seed) + secondary (copper) buttons.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: b.bronze,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Primary', style: t(onAccent, 12, FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: b.copper, width: 1.5),
                        ),
                        child: Text('Action', style: t(b.copper, 12, FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: b.panelGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: b.panelBorder),
                        boxShadow: b.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Heading',
                            style: t(b.textHeading, 15, FontWeight.w600),
                          ),
                          Text('Body copy on the panel surface',
                              style: t(b.textBody, 12)),
                          Text('Muted / secondary label',
                              style: t(b.textMuted, 11)),
                          const SizedBox(height: 14),
                          // Theme-specific solid accents (these differ per
                          // theme; jewels are intentionally shared and omitted).
                          Row(
                            children: [
                              chip(b.bronze),
                              chip(b.copper),
                              chip(b.moss),
                              chip(b.ochre),
                              chip(b.madder),
                              chip(b.slate),
                              chip(b.verdigris),
                            ],
                          ),
                          const Spacer(),
                          Row(children: [meter(0.4), meter(0.7), meter(0.92)]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
