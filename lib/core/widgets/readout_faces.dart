part of 'flip_readout.dart';

/// How a theme family's readouts look: the window the characters sit in,
/// how each character is drawn, and whether characters flip or crossfade.
class ReadoutLook {
  const ReadoutLook({
    required this.window,
    required this.face,
    required this.flap,
    this.gap = 0.08,
  });

  final Decoration window;
  final Widget Function(String char) face;
  final bool flap;

  /// Space between characters, as a fraction of the font size.
  final double gap;

  static ReadoutLook of(BuildContext context, double fs) {
    final b = context.brass;
    final dark = b.isDark;
    final r = BorderRadius.circular(fs * 0.22);
    switch (context.kit) {
      case InstrumentKit.brass:
        return ReadoutLook(
          window: BoxDecoration(
            color: const Color(0xFF060806),
            borderRadius: r,
            border: Border.all(
              color: b.brassStops[3].withValues(alpha: 0.45),
              width: 0.8,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x33FFF3D0), offset: Offset(0, 0.8)),
            ],
          ),
          face: (c) => _CardFace(
            char: c,
            height: fs * 1.32,
            fontSize: fs,
            font: b.displayFont,
          ),
          flap: true,
        );
      case InstrumentKit.graphite:
        // A reflective grey-green LCD behind a dark bezel; segments are ink.
        return ReadoutLook(
          window: BoxDecoration(
            borderRadius: BorderRadius.circular(fs * 0.12),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFC9CEC1), Color(0xFFB0B6A8)],
            ),
            border: Border.all(color: const Color(0xFF3E4349), width: 1.5),
          ),
          face: (c) => _SegmentFace(
            char: c,
            fs: fs,
            on: const Color(0xFF1C201B),
            ghost: const Color(0x14000000),
          ),
          flap: false,
          gap: 0.1,
        );
      case InstrumentKit.terminal:
        return ReadoutLook(
          window: BoxDecoration(
            color: const Color(0xFF020703),
            borderRadius: BorderRadius.circular(fs * 0.12),
            border: Border.all(color: const Color(0x8039FF6A)),
            boxShadow: const [
              BoxShadow(color: Color(0x3339FF6A), blurRadius: 8),
            ],
          ),
          face: (c) => _SegmentFace(
            char: c,
            fs: fs,
            on: const Color(0xFF39FF6A),
            ghost: const Color(0x1439FF6A),
            glow: true,
          ),
          flap: false,
          gap: 0.1,
        );
      case InstrumentKit.obsidian:
        return ReadoutLook(
          window: BoxDecoration(
            color: const Color(0xFF060606),
            borderRadius: BorderRadius.circular(fs * 0.1),
            border: Border.all(color: const Color(0xFF2C2C30)),
          ),
          face: (c) => _SegmentFace(
            char: c,
            fs: fs,
            on: const Color(0xFFFFB020),
            ghost: const Color(0x0FFFB020),
            glow: true,
          ),
          flap: false,
          gap: 0.1,
        );
      case InstrumentKit.nord:
        // Cockpit value box: navy glass, cyan digits, fine cyan frame.
        return ReadoutLook(
          window: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(fs * 0.16),
            border: Border.all(color: const Color(0xB388C0D0)),
          ),
          face: (c) => _GlyphFace(
            char: c,
            fs: fs,
            color: const Color(0xFF8FD3E6),
            font: 'JetBrains Mono',
            weight: FontWeight.w600,
            glow: const Color(0x6688C0D0),
          ),
          flap: false,
          gap: 0.02,
        );
      case InstrumentKit.ember:
        // A row of Nixie tubes on a dark chassis.
        return ReadoutLook(
          window: BoxDecoration(
            color: const Color(0xFF120A08),
            borderRadius: BorderRadius.circular(fs * 0.14),
            border: Border.all(color: const Color(0x998B6F5A)),
          ),
          face: (c) => _NixieFace(char: c, fs: fs),
          flap: false,
          gap: 0.06,
        );
      case InstrumentKit.aqua:
        // A glossy Aqua lozenge: a hard highlight split across the top half.
        return ReadoutLook(
          window: BoxDecoration(
            borderRadius: BorderRadius.circular(fs),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? const [
                      Color(0xFF6A6A70),
                      Color(0xFF48484C),
                      Color(0xFF2E2E32),
                      Color(0xFF404044),
                    ]
                  : const [
                      Color(0xFFFFFFFF),
                      Color(0xFFEFF4FA),
                      Color(0xFFD9E5F2),
                      Color(0xFFF5F9FD),
                    ],
              stops: const [0, 0.5, 0.5, 1],
            ),
            border: Border.all(
              color: dark ? const Color(0xFF7A7A80) : const Color(0xFF9DB3CC),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.4 : 0.15),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          face: (c) => _GlyphFace(
            char: c,
            fs: fs,
            color: b.giltBright,
          ),
          flap: false,
          gap: 0.0,
        );
      case InstrumentKit.catppuccin:
        return ReadoutLook(
          window: BoxDecoration(
            borderRadius: BorderRadius.circular(fs),
            color: dark ? const Color(0xFF313244) : const Color(0xFFE6E9EF),
            border: Border.all(color: b.giltBright.withValues(alpha: 0.5)),
          ),
          face: (c) => _GlyphFace(
            char: c,
            fs: fs,
            color: b.giltBright,
            weight: FontWeight.w800,
          ),
          flap: false,
          gap: 0.0,
        );
    }
  }
}

bool _narrow(String c) => c == '/' || c == '.' || c == ':' || c == ' ';

/// A plain glyph (value boxes and pills).
class _GlyphFace extends StatelessWidget {
  const _GlyphFace({
    required this.char,
    required this.fs,
    required this.color,
    this.font,
    this.weight = FontWeight.w700,
    this.glow,
  });

  final String char;
  final double fs;
  final Color color;
  final String? font;
  final FontWeight weight;
  final Color? glow;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: fs * (_narrow(char) ? 0.4 : 0.64),
    height: fs * 1.25,
    child: Center(
      child: Text(
        char,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: font ?? context.displayFont,
          fontWeight: weight,
          fontSize: fs,
          height: 1,
          color: color,
          fontFeatures: const [
            FontFeature.liningFigures(),
            FontFeature.tabularFigures(),
          ],
          shadows: glow == null ? null : [Shadow(color: glow!, blurRadius: 6)],
        ),
      ),
    ),
  );
}

/// One Nixie tube: a glass envelope with its anode mesh, the numeral's
/// cathode glowing orange, and the faint unlit cathodes stacked behind.
class _NixieFace extends StatelessWidget {
  const _NixieFace({required this.char, required this.fs});

  final String char;
  final double fs;

  static const _glow = Color(0xFFFF8A3D);

  @override
  Widget build(BuildContext context) {
    final narrow = _narrow(char);
    final w = fs * (narrow ? 0.46 : 0.8);
    final h = fs * 1.5;
    TextStyle numeral(Color c, {List<Shadow>? shadows}) => TextStyle(
      fontWeight: FontWeight.w300,
      fontSize: fs * 1.08,
      height: 1,
      color: c,
      shadows: shadows,
    );
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Envelope: smoked glass, domed at the top, lit along its left edge.
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(w / 2),
                bottom: Radius.circular(fs * 0.12),
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFF3A2A22), Color(0xFF1A110D), Color(0xFF241812)],
                stops: [0, 0.35, 1],
              ),
              border: Border.all(color: const Color(0x55E8C9A8), width: 0.6),
            ),
          ),
          CustomPaint(size: Size(w, h), painter: const _MeshPainter()),
          if (!narrow)
            Text('8', textScaler: TextScaler.noScaling,
                style: numeral(const Color(0x14FF8A3D))),
          Text(
            char,
            textScaler: TextScaler.noScaling,
            style: numeral(
              const Color(0xFFFFC27A),
              shadows: const [
                Shadow(color: _glow, blurRadius: 4),
                Shadow(color: _glow, blurRadius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The anode mesh in front of a Nixie's cathodes: a fine diagonal lattice.
class _MeshPainter extends CustomPainter {
  const _MeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x18E8C9A8)
      ..strokeWidth = 0.5;
    for (var x = -size.height; x < size.width; x += 3) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
      canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => false;
}

/// A seven-segment digit (LCD or LED), its unlit segments faintly visible.
/// Characters with no segment form (%, /) are drawn as glyphs in the same ink.
class _SegmentFace extends StatelessWidget {
  const _SegmentFace({
    required this.char,
    required this.fs,
    required this.on,
    required this.ghost,
    this.glow = false,
  });

  final String char;
  final double fs;
  final Color on;
  final Color ghost;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final digit = _segments.containsKey(char);
    final w = fs * (_narrow(char) ? 0.34 : 0.62);
    final h = fs * 1.15;
    if (!digit) {
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Text(
            char,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w700,
              fontSize: fs * 0.82,
              height: 1,
              color: on,
              shadows: glow ? [Shadow(color: on, blurRadius: 6)] : null,
            ),
          ),
        ),
      );
    }
    return CustomPaint(
      size: Size(w, h),
      painter: _SegmentPainter(_segments[char]!, on, ghost, glow),
    );
  }

  // Segments a (top), b (upper right), c (lower right), d (bottom),
  // e (lower left), f (upper left), g (middle).
  static const _segments = <String, String>{
    '0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc',
    '5': 'afgcd', '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg',
    '-': 'g', ' ': '',
  };
}

class _SegmentPainter extends CustomPainter {
  _SegmentPainter(this.lit, this.on, this.ghost, this.glow);

  final String lit;
  final Color on;
  final Color ghost;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = w * 0.17; // segment thickness
    final g = t * 0.18; // gap between segments
    final skew = w * 0.08; // a slight italic, as on real displays
    Offset p(double x, double y) => Offset(x + skew * (1 - y / h), y);
    Path hseg(double y) => Path()
      ..moveTo(p(t / 2 + g, y).dx, y)
      ..lineTo(p(t + g, y - t / 2).dx, y - t / 2)
      ..lineTo(p(w - t - g, y - t / 2).dx, y - t / 2)
      ..lineTo(p(w - t / 2 - g, y).dx, y)
      ..lineTo(p(w - t - g, y + t / 2).dx, y + t / 2)
      ..lineTo(p(t + g, y + t / 2).dx, y + t / 2)
      ..close();
    Path vseg(double x, double y0, double y1) => Path()
      ..moveTo(p(x, y0 + g).dx, y0 + g)
      ..lineTo(p(x + t / 2, y0 + t / 2 + g).dx, y0 + t / 2 + g)
      ..lineTo(p(x + t / 2, y1 - t / 2 - g).dx, y1 - t / 2 - g)
      ..lineTo(p(x, y1 - g).dx, y1 - g)
      ..lineTo(p(x - t / 2, y1 - t / 2 - g).dx, y1 - t / 2 - g)
      ..lineTo(p(x - t / 2, y0 + t / 2 + g).dx, y0 + t / 2 + g)
      ..close();
    final top = t / 2, mid = h / 2, bot = h - t / 2;
    final left = t / 2, right = w - t / 2 - skew;
    final segs = <String, Path>{
      'a': hseg(top),
      'g': hseg(mid),
      'd': hseg(bot),
      'f': vseg(left, top, mid),
      'b': vseg(right, top, mid),
      'e': vseg(left, mid, bot),
      'c': vseg(right, mid, bot),
    };
    for (final e in segs.entries) {
      final isOn = lit.contains(e.key);
      if (isOn && glow) {
        canvas.drawPath(
          e.value,
          Paint()
            ..color = on.withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      canvas.drawPath(e.value, Paint()..color = isOn ? on : ghost);
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      old.lit != lit || old.on != on || old.ghost != ghost || old.glow != glow;
}
