import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/app_tab.dart';
import '../providers/navigation_providers.dart';
import '../theme/app_theme.dart';

/// One sub-view of a hub destination: the strip entry plus its screen.
class HubTab {
  const HubTab({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;
}

/// A hub destination's shell (left-top-top IA): the garnet sub-tab strip —
/// promoted from the Media tab, design §7 — over a TabBarView of sub-views.
/// Selection lives in [hubSubTabProvider] (two-way synced with the strip's
/// controller) so the command palette can jump straight to a sub-view.
///
/// A hub with a single visible sub-view renders it bare, no strip — the
/// public build's Vault/Wiki case.
class HubScaffold extends ConsumerStatefulWidget {
  const HubScaffold({super.key, required this.hub, required this.tabs});

  final AppTab hub;
  final List<HubTab> tabs;

  @override
  ConsumerState<HubScaffold> createState() => _HubScaffoldState();
}

class _HubScaffoldState extends ConsumerState<HubScaffold>
    with SingleTickerProviderStateMixin {
  // Lazy and nullable rather than `late final`: a single-child hub's build
  // never touches the controller, and a `late` field first evaluated inside
  // dispose() would run its ref.read initializer on an already-disposed
  // element (caught by the public-build single-node walk, where the Vault
  // hub is Wiki-only).
  TabController? _controllerOrNull;
  TabController get _controller => _controllerOrNull ??= TabController(
        length: widget.tabs.length,
        vsync: this,
        initialIndex: ref
            .read(hubSubTabProvider(widget.hub))
            .clamp(0, widget.tabs.length - 1),
      )..addListener(_syncFromController);

  /// Keeps the provider honest when the controller moves without a strip tap
  /// (a TabBarView swipe): settle first, then record. Identical values don't
  /// re-notify, so the tap path (provider → animateTo) can't loop through
  /// here.
  void _syncFromController() {
    if (_controller.indexIsChanging) return;
    ref
        .read(hubSubTabProvider(widget.hub).notifier)
        .select(_controller.index);
  }

  @override
  void dispose() {
    _controllerOrNull?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.length == 1) return widget.tabs.single.child;

    ref.listen(hubSubTabProvider(widget.hub), (_, next) {
      if (next != _controller.index && next < widget.tabs.length) {
        _controller.animateTo(next);
      }
    });

    final strip = _Strip.forBrass(context.brass);
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [strip.top, strip.bottom],
              ),
              border: Border(bottom: BorderSide(color: strip.hairline)),
            ),
            child: TabBar(
              controller: _controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              labelColor: strip.selected,
              unselectedLabelColor: strip.idle,
              labelStyle: TextStyle(
                fontFamily: context.displayFont,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
              overlayColor: WidgetStatePropertyAll(strip.overlay),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: _GarnetUnderlineIndicator(strip, context.kit,
                  context.brass),
              onTap: (i) => ref
                  .read(hubSubTabProvider(widget.hub).notifier)
                  .select(i),
              tabs: [
                for (final t in widget.tabs)
                  Tab(icon: Icon(t.icon, size: 19), text: t.label),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [for (final t in widget.tabs) t.child],
          ),
        ),
      ],
    );
  }
}

/// Hub strip palette (mapping `media.*` slice — the strip was born on the
/// Media tab): dark values verbatim from the dark-only era; light is
/// rosewood ink on parchment (the strip pales, the labels and indicator
/// deepen).
class _Strip {
  const _Strip({
    required this.top,
    required this.bottom,
    required this.hairline,
    required this.selected,
    required this.idle,
    required this.overlay,
    required this.indicatorStart,
    required this.indicatorEnd,
  });

  final Color top;
  final Color bottom;
  final Color hairline;
  final Color selected;
  final Color idle;
  final Color overlay;
  final Color indicatorStart;
  final Color indicatorEnd;

  static const dark = _Strip(
    top: Color(0xE0302121),
    bottom: Color(0xD11C1414),
    hairline: Color(0x52E09678),
    selected: Color(0xFFF2C2B6),
    idle: Color(0xFFA98D82),
    overlay: Color(0x14E09678),
    indicatorStart: Color(0xFFF0B0A0),
    indicatorEnd: Color(0xFFC05A4E),
  );
  static const light = _Strip(
    top: Color(0xE0EDDCCF),
    bottom: Color(0xD1E2CDBE),
    hairline: Color(0x668F4A3C),
    selected: Color(0xFF7A2F27),
    idle: Color(0xFF6B554A),
    overlay: Color(0x148F4A3C),
    indicatorStart: Color(0xFF9E4438),
    indicatorEnd: Color(0xFF6E2018),
  );

  /// This palette for [b]'s family: Brass keeps the authored set; any other
  /// family gets each colour carried onto its own tokens ([themeColor]).
  static final _themed = <Brass, _Strip>{};
  static _Strip forBrass(Brass b) {
    final base = b.isDark ? dark : light;
    if (InstrumentKit.of(b) == InstrumentKit.brass) return base;
    return _themed.putIfAbsent(
      b,
      () => _Strip(
        top: themeColor(base.top, b),
        bottom: themeColor(base.bottom, b),
        hairline: themeColor(base.hairline, b),
        selected: themeColor(base.selected, b),
        idle: themeColor(base.idle, b),
        overlay: themeColor(base.overlay, b),
        indicatorStart: themeColor(base.indicatorStart, b),
        indicatorEnd: themeColor(base.indicatorEnd, b),
      ),
    );
  }
}

/// The 2.5px red underline for the active sub-tab
/// (gradient `#f0b0a0 → #c05a4e`, design §7).
/// The selected sub-tab's mark, in the family's idiom: Brass's gradient
/// underline, Graphite's square orange bar, a glowing line on the screen
/// families (Terminal green, Nord cyan, Ember amber, Obsidian thin amber),
/// and a pill behind the tab on Aqua (glossy) and Catppuccin (soft).
class _GarnetUnderlineIndicator extends Decoration {
  const _GarnetUnderlineIndicator(this.strip, this.kit, this.brass);

  final _Strip strip;
  final InstrumentKit kit;
  final Brass brass;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _GarnetUnderlinePainter(strip, kit, brass);
}

class _GarnetUnderlinePainter extends BoxPainter {
  _GarnetUnderlinePainter(this.strip, this.kit, this.brass);

  final _Strip strip;
  final InstrumentKit kit;
  final Brass brass;

  void _glowLine(Canvas canvas, Rect rect, Color c, double h) {
    final line = Rect.fromLTWH(rect.left, rect.bottom - h, rect.width, h);
    canvas.drawRect(line.inflate(1),
        Paint()
          ..color = c.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawRect(line, Paint()..color = c);
  }

  void _pill(Canvas canvas, Rect tab, Color c, {required bool gloss}) {
    final r = RRect.fromRectAndRadius(tab.deflate(5), const Radius.circular(12));
    canvas.drawRRect(r, Paint()..color = c.withValues(alpha: gloss ? 0.28 : 0.18));
    if (gloss) {
      final top = Rect.fromLTWH(r.left + 3, r.top + 2, r.width - 6, r.height * 0.42);
      canvas.drawRRect(RRect.fromRectAndRadius(top, const Radius.circular(9)),
          Paint()..color = Colors.white.withValues(alpha: 0.22));
    }
    canvas.drawRRect(r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = c.withValues(alpha: 0.55));
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final tab = offset & size;
    final under = Rect.fromLTWH(tab.left + 8, tab.top, size.width - 16, size.height);
    switch (kit) {
      case InstrumentKit.graphite:
        canvas.drawRect(
            Rect.fromLTWH(under.left, under.bottom - 3, under.width, 3),
            Paint()..color = const Color(0xFFFF6A00));
        return;
      case InstrumentKit.terminal:
        _glowLine(canvas, under, const Color(0xFF39FF6A), 3);
        return;
      case InstrumentKit.nord:
        _glowLine(canvas, under, const Color(0xFF8FD3E6), 2);
        return;
      case InstrumentKit.ember:
        _glowLine(canvas, under, const Color(0xFFFFA24A), 2.5);
        return;
      case InstrumentKit.obsidian:
        _glowLine(canvas, under, const Color(0xFFFFB020), 1.5);
        return;
      case InstrumentKit.aqua:
        _pill(canvas, tab, brass.giltBright, gloss: true);
        return;
      case InstrumentKit.catppuccin:
        _pill(canvas, tab, brass.giltBright, gloss: false);
        return;
      case InstrumentKit.brass:
        break;
    }
    final rect = Rect.fromLTWH(
      offset.dx + 8,
      offset.dy + size.height - 2.5,
      size.width - 16,
      2.5,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [strip.indicatorStart, strip.indicatorEnd],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );
  }
}
