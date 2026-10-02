import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../build_config.dart';
import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';
import '../theme/phosphor.dart';
import 'astrolabe.dart';
import 'status_light.dart';

/// One navigation destination with its own accent identity and section.
class NavDest {
  const NavDest({
    required this.icon,
    required this.label,
    required this.accent,
    required this.section,
    this.pinnedBottom = false,
  });

  final IconData icon;
  final String label;

  /// The colour this destination contributes to the backdrop/palette.
  final Color accent;

  /// Group heading ("Control" / "Services" / "System"). Empty groups render
  /// without a header.
  final String section;

  /// Pinned to the bottom of the dock (e.g. Settings) instead of the scrolling
  /// section list.
  final bool pinnedBottom;
}

/// File-local rail inks (navRail.* family): dark values verbatim from the
/// dark-only era, light values from the parchment mapping. The milled-brass
/// knob and the nameplate bevel catch-light stay shared literals — physical
/// hardware that reads on both fields.
class _RailPalette {
  const _RailPalette({
    required this.panelTop,
    required this.panelBottom,
    required this.edgeHairline,
    required this.brandTitle,
    required this.brandTitleShadow,
    required this.subtitle,
    required this.searchBorder,
    required this.searchIcon,
    required this.searchHint,
    required this.cmdKBorder,
    required this.cmdKText,
    required this.nameplateInnerShadow,
    required this.labelSelected,
    required this.labelIdle,
    required this.footerBorder,
    required this.footerText,
  });

  final Color panelTop;
  final Color panelBottom;
  final Color edgeHairline;
  final Color brandTitle;
  final Color brandTitleShadow;
  final Color subtitle;
  final Color searchBorder;
  final Color searchIcon;
  final Color searchHint;
  final Color cmdKBorder;
  final Color cmdKText;
  final Color nameplateInnerShadow;
  final Color labelSelected;
  final Color labelIdle;
  final Color footerBorder;
  final Color footerText;

  static const dark = _RailPalette(
    panelTop: Color(0xF01C2C1F),
    panelBottom: Color(0xF00E1811),
    edgeHairline: Color(0x4DC9AA58),
    brandTitle: Color(0xFFF2ECD6),
    brandTitleShadow: Color(0x80000000),
    subtitle: Color(0xFF99B085),
    searchBorder: Color(0x47C9AA58),
    searchIcon: Color(0xFFD9BD72),
    searchHint: Color(0xFF8FA07D),
    cmdKBorder: Color(0x57C9AA58),
    cmdKText: Color(0xFFC1AD6F),
    nameplateInnerShadow: Color(0x66000000),
    labelSelected: Color(0xFFF7F0DA),
    labelIdle: Color(0xFFCDD6BF),
    footerBorder: Color(0x33C9AA58),
    footerText: Color(0xFF93A681),
  );

  static const light = _RailPalette(
    panelTop: Color(0xF0EFE7D4),
    panelBottom: Color(0xF0E4DAC4),
    edgeHairline: Color(0x596E5220),
    brandTitle: Color(0xFF2E3324),
    brandTitleShadow: Color(0x66FFFBEE),
    subtitle: Color(0xFF55684A),
    searchBorder: Color(0x4D6E5220),
    searchIcon: Color(0xFF8A6A2A),
    searchHint: Color(0xFF4F5C44),
    cmdKBorder: Color(0x596E5220),
    cmdKText: Color(0xFF5F4E20),
    nameplateInnerShadow: Color(0x2E46381F),
    labelSelected: Color(0xFF3A2E14),
    labelIdle: Color(0xFF4A5540),
    footerBorder: Color(0x406E5220),
    footerText: Color(0xFF55684A),
  );

  static _RailPalette of(BuildContext context) =>
      Brass.of(context).isDark ? dark : light;
}

/// The Brass Edition navigation rail (design §Navigation rail): a bottle-green
/// sidebar with a milled brass knob that toggles between 246px (labels +
/// gem section headers) and a 78px icon dock. The active item wears an
/// embossed brass "nameplate" in its section's accent with a left gem bar.
///
/// Under `flutter test` the rail renders expanded (labels present + hittable)
/// so tap-by-label tests keep working and goldens show the full state.
class GlassNavRail extends StatelessWidget {
  const GlassNavRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    this.badges = const {},
    this.onSearch,
    this.footer,
    this.collapsed = false,
    this.onToggleCollapse,
    this.onReconnect,
  });

  final List<NavDest> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// index → count; a non-zero count shows a breathing warning dot on the item.
  final Map<int, int> badges;

  /// Rendered at the very bottom of the dock, under the connected footer —
  /// e.g. the theme toggle.
  final Widget? footer;

  /// Opens the command palette (⌘K). When set, the recessed search field
  /// appears under the brand row.
  final VoidCallback? onSearch;

  /// Collapsed to the icon dock. Ignored (always expanded) under FLUTTER_TEST.
  final bool collapsed;
  final VoidCallback? onToggleCollapse;

  /// Footer "laptop · connected" tap → reconnect splash.
  final VoidCallback? onReconnect;

  static const collapsedWidth = 78.0;
  static const expandedWidth = 246.0;

  // "In tests" semantic (rail renders expanded so tap-by-label tests work),
  // not an animation gate.
  static final bool _test = kUnderTest;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final rail = brass.isDark ? _RailPalette.dark : _RailPalette.light;
    final expanded = _test || !collapsed;
    final dests = destinations;

    // Split into scrolling sections (preserving order) + pinned-bottom items.
    final pinned = <int>[];
    final sections = <String, List<int>>{};
    for (var i = 0; i < dests.length; i++) {
      if (dests[i].pinnedBottom) {
        pinned.add(i);
      } else {
        sections.putIfAbsent(dests[i].section, () => []).add(i);
      }
    }

    Widget item(int i) => _NavItem(
      dest: dests[i],
      kit: brass.kit(dests[i].section),
      selected: i == selectedIndex,
      expanded: expanded,
      badge: badges[i] ?? 0,
      onTap: () => onSelect(i),
    );

    final groups = <Widget>[];
    sections.forEach((section, indices) {
      final kit = brass.kit(section);
      if (section.isNotEmpty && expanded) {
        groups.add(_SectionLabel(text: section, kit: kit));
      } else if (section.isNotEmpty) {
        groups.add(const SizedBox(height: MolSpace.md));
      }
      groups.addAll(indices.map(item));
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: const Cubic(0.4, 0, 0.2, 1),
      width: expanded ? expandedWidth : collapsedWidth,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rail.panelTop, rail.panelBottom],
        ),
        border: Border(right: BorderSide(color: rail.edgeHairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandRow(
            expanded: expanded,
            onToggle: onToggleCollapse,
            collapsed: collapsed,
          ),
          const SizedBox(height: 8),
          if (onSearch != null) ...[
            _SearchField(expanded: expanded, onTap: onSearch!),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: groups,
              ),
            ),
          ),
          if (pinned.isNotEmpty) ...pinned.map(item),
          _ConnectedFooter(expanded: expanded, onTap: onReconnect),
          ?footer,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({
    required this.expanded,
    required this.collapsed,
    this.onToggle,
  });

  final bool expanded;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final rail = _RailPalette.of(context);
    const brand = Astrolabe(size: 46, detail: AstrolabeDetail.compact);
    final knob = _BrassKnob(collapsed: collapsed, onTap: onToggle);
    if (!expanded) {
      // Collapsed: column so the knob stays visible in the narrow rail.
      return Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 12),
        child: Column(children: [brand, const SizedBox(height: 12), knob]),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 3, 6, 12),
      child: Row(
        children: [
          brand,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FittedBox: under system text scaling (laptop runs 1.15)
                // these lines outgrow the slot and clip mid-glyph against the
                // knob — scale-to-fit instead of shearing the trailing M.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    kAppName,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      height: 1,
                      color: rail.brandTitle,
                      shadows: [
                        Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                            color: rail.brandTitleShadow),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CONTROL ROOM',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 10.5 * 0.2,
                      color: rail.subtitle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          knob,
        ],
      ),
    );
  }
}

/// The milled brass collapse/expand knob: repeating-conic rim, domed face,
/// two engraved rivet dots, caret.
class _BrassKnob extends StatefulWidget {
  const _BrassKnob({required this.collapsed, this.onTap});

  final bool collapsed;
  final VoidCallback? onTap;

  @override
  State<_BrassKnob> createState() => _BrassKnobState();
}

class _BrassKnobState extends State<_BrassKnob> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: const ValueKey('rail-knob'),
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.collapsed ? 'Expand rail' : 'Collapse rail',
          child: SizedBox(
            width: 31,
            height: 31,
            child: CustomPaint(
              painter: _KnobPainter(brighten: _hover),
              child: Icon(
                widget.collapsed
                    ? PhBold.caretRight
                    : PhBold.caretLeft,
                size: 13,
                color: const Color(0xFF4A3512),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  const _KnobPainter({required this.brighten});

  final bool brighten;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Milled rim: alternating brass wedges every 7°.
    final light = brighten ? const Color(0xFFFFE9A3) : const Color(0xFFEFD487);
    final dark = brighten ? const Color(0xFFB58F45) : const Color(0xFFA37F38);
    final wedge = Paint();
    const step = 7 * math.pi / 180;
    for (var i = 0; i < 52; i++) {
      wedge.color = i.isEven ? light : dark;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), i * step, step, true, wedge);
    }
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x80281C08),
    );
    // Domed face.
    canvas.drawCircle(
      c,
      r - 4,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.28, -0.44),
          colors: [Color(0xFFFFF6CF), Color(0xFFD9B45E), Color(0xFF7D5F26)],
          stops: [0, 0.48, 0.92],
        ).createShader(Rect.fromCircle(center: c, radius: r - 4)),
    );
    // Engraved rivet dots north + south.
    final dot = Paint()..color = const Color(0xFF4A3512);
    canvas.drawCircle(Offset(c.dx, 5.5), 1, dot);
    canvas.drawCircle(Offset(c.dx, size.height - 5.5), 1, dot);
  }

  @override
  bool shouldRepaint(_KnobPainter old) => old.brighten != brighten;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.kit});

  final String text;
  final SectionAccent kit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 13, 8, 5),
      child: Row(
        children: [
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [kit.barTop, kit.barMid, kit.barBottom],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 11 * 0.22,
              color: kit.headerText,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kit.barMid.withValues(alpha: 0.75),
                    kit.barMid.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The recessed search field with the palette-shortcut chip (⌘K / Ctrl+K).
class _SearchField extends StatelessWidget {
  const _SearchField({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final rail = brass.isDark ? _RailPalette.dark : _RailPalette.light;
    // Ctrl+K off Apple platforms: it's the binding users actually press
    // there, and ⌘ (U+2318) isn't covered by the bundled fonts — it only
    // renders via system fallback, which the golden harness lacks.
    final isApple = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        key: const ValueKey('nav-search'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: rail.searchBorder),
            color: brass.recess.withValues(alpha: 0.6),
          ),
          child: Row(
            children: [
              Icon(Ph.magnifyingGlass, size: 16, color: rail.searchIcon),
              if (expanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search…',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: TextStyle(color: rail.searchHint, fontSize: 15),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: rail.cmdKBorder),
                  ),
                  child: Text(
                    isApple ? '⌘K' : 'Ctrl+K',
                    style: TextStyle(fontSize: 11, color: rail.cmdKText),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.dest,
    required this.kit,
    required this.selected,
    required this.expanded,
    required this.badge,
    required this.onTap,
  });

  final NavDest dest;
  final SectionAccent kit;
  final bool selected;
  final bool expanded;
  final int badge;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final rail = _RailPalette.of(context);
    final kit = widget.kit;
    final selected = widget.selected;

    final iconBox = SizedBox(
      width: 44,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            widget.dest.icon,
            size: 19,
            color: selected ? kit.iconActive : kit.iconIdle,
          ),
          if (widget.badge > 0)
            const Positioned(
              top: 2,
              right: 4,
              child: StatusLight(health: Health.warn, size: 8),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 43,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Embossed nameplate for the active item.
                if (selected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        gradient: kit.plate,
                        border: Border.all(color: kit.border),
                        boxShadow: [
                          BoxShadow(
                              color: rail.nameplateInnerShadow,
                              offset: const Offset(0, -2),
                              blurRadius: 3,
                              spreadRadius: -2),
                        ],
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        border: const Border(
                          top: BorderSide(color: Color(0x47FFF4C8)),
                        ),
                      ),
                    ),
                  )
                else if (_hover)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        color: kit.hover,
                      ),
                    ),
                  ),
                // Left gem bar hanging into the rail gutter.
                if (selected)
                  Positioned(
                    left: -10,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 3.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: kit.bar,
                        boxShadow: [
                          BoxShadow(color: kit.glow, blurRadius: 9),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    iconBox,
                    if (widget.expanded)
                      Flexible(
                        child: Text(
                          widget.dest.label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 16,
                            color: selected
                                ? rail.labelSelected
                                : rail.labelIdle,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer: emerald cabochon + `<hostname> · connected`; tap → reconnect.
class _ConnectedFooter extends StatelessWidget {
  const _ConnectedFooter({required this.expanded, this.onTap});

  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final rail = brass.isDark ? _RailPalette.dark : _RailPalette.light;
    final host = Platform.localHostname;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: const ValueKey('rail-reconnect'),
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 11),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: rail.footerBorder)),
            ),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: Brass.emerald.cabochon,
                    boxShadow: brass.jewelHalo(Brass.emerald),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      '$host · connected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                          fontSize: 14, color: rail.footerText),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
