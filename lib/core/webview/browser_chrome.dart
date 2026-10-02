import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../theme/phosphor.dart';

/// The Brass Edition embedded-browser chrome bar (design §6): a garnet-tinted
/// strip (dark glass in the dark; rose parchment in light mode) with caret nav
/// icons, a recessed lock+address readout, and an `Embedded · <service>` pill.
///
/// The `url` is a listenable so the platform web views can push live URL changes
/// (CEF onUrlChanged / WKWebView onUrlChange) without rebuilding the page.
class BrowserChromeBar extends StatelessWidget {
  const BrowserChromeBar({
    super.key,
    required this.url,
    required this.pillLabel,
    this.onBack,
    this.onForward,
    this.onReload,
    this.onHome,
  });

  final ValueListenable<String> url;

  /// Pill text, e.g. `Embedded · Wiki.js`.
  final String pillLabel;

  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onReload;
  final VoidCallback? onHome;

  /// Compact `host/path` readout for the address field.
  static String displayUrl(String raw) {
    final u = Uri.tryParse(raw);
    if (u == null || u.host.isEmpty) return raw;
    final port = u.hasPort ? ':${u.port}' : '';
    final path = (u.path.isEmpty || u.path == '/') ? '' : u.path;
    return '${u.host}$port$path';
  }

  Widget _navIcon(
    _ChromePalette palette,
    IconData icon,
    String tooltip,
    VoidCallback? onTap,
  ) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 17),
      color: palette.icon,
      disabledColor: palette.iconDisabled,
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? _ChromePalette.dark
        : _ChromePalette.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.barTop, palette.barBottom],
        ),
        border: Border(bottom: BorderSide(color: palette.hairline)),
      ),
      child: Row(
        children: [
          _navIcon(palette, Ph.caretLeft, 'Back', onBack),
          _navIcon(palette, Ph.caretRight, 'Forward', onForward),
          _navIcon(palette, Ph.arrowClockwise, 'Reload', onReload),
          _navIcon(palette, Ph.house, 'Home', onHome),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: palette.addressFill,
                border: Border.all(color: palette.addressBorder),
              ),
              child: Row(
                children: [
                  Icon(Ph.lockSimple, size: 13, color: palette.lockIcon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: url,
                      builder: (_, value, _) => Text(
                        displayUrl(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14,
                          color: palette.urlText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.pillBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Ph.globeSimple, size: 12, color: palette.pillFg),
                const SizedBox(width: 6),
                Text(
                  pillLabel,
                  style: TextStyle(fontSize: 11.5, color: palette.pillFg),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Chrome-bar palette pair (the `chrome.*` token family). [dark] keeps every
/// value verbatim from the dark-only era; [light] is the parchment variant —
/// rose paper strip, umber recess wash, and rust/moss inks.
class _ChromePalette {
  const _ChromePalette({
    required this.icon,
    required this.iconDisabled,
    required this.barTop,
    required this.barBottom,
    required this.hairline,
    required this.addressFill,
    required this.addressBorder,
    required this.lockIcon,
    required this.urlText,
    required this.pillBorder,
    required this.pillFg,
  });

  final Color icon;
  final Color iconDisabled;
  final Color barTop;
  final Color barBottom;
  final Color hairline;
  final Color addressFill;
  final Color addressBorder;
  final Color lockIcon;
  final Color urlText;
  final Color pillBorder;
  final Color pillFg;

  static const dark = _ChromePalette(
    icon: Color(0xFFCCA08F),
    iconDisabled: Color(0xFF6E5A52),
    barTop: Color(0xE0302121),
    barBottom: Color(0xD11C1414),
    hairline: Color(0x52E09678),
    addressFill: Color(0x8009100B),
    addressBorder: Color(0x47E09678),
    lockIcon: Color(0xFF7BB26A),
    urlText: Color(0xFFB6A89B),
    pillBorder: Color(0x57E09678),
    pillFg: Color(0xFFD79F92),
  );

  static const light = _ChromePalette(
    icon: Color(0xFF7A4438),
    iconDisabled: Color(0xFFB09A8C),
    barTop: Color(0xE0EDDFD0),
    barBottom: Color(0xD1E2CFBC),
    hairline: Color(0x668F4A3C),
    addressFill: Color(0x2E46381F),
    addressBorder: Color(0x4D8F4A3C),
    lockIcon: Color(0xFF38702E),
    urlText: Color(0xFF5C5248),
    pillBorder: Color(0x668F4A3C),
    pillFg: Color(0xFF8F4A3C),
  );
}
