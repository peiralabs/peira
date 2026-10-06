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

    final strip = context.brass.isDark ? _Strip.dark : _Strip.light;
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
              indicator: _GarnetUnderlineIndicator(strip),
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
}

/// The 2.5px red underline for the active sub-tab
/// (gradient `#f0b0a0 → #c05a4e`, design §7).
class _GarnetUnderlineIndicator extends Decoration {
  const _GarnetUnderlineIndicator(this.strip);

  final _Strip strip;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _GarnetUnderlinePainter(strip);
}

class _GarnetUnderlinePainter extends BoxPainter {
  _GarnetUnderlinePainter(this.strip);

  final _Strip strip;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
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
