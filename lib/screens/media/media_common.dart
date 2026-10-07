import 'package:flutter/material.dart';

import '../../core/providers/media_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/recessed_bar.dart';

/// Human-readable byte size (e.g. `4.2 GB`).
String formatBytes(num bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value >= 100 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// Byte/sec transfer rate (e.g. `3.1 MB/s`).
String formatSpeed(int bytesPerSec) =>
    bytesPerSec <= 0 ? '—' : '${formatBytes(bytesPerSec)}/s';

/// qBittorrent's "infinity" ETA sentinel.
const _etaInfinity = 8640000;

/// ETA seconds → compact string (`3m`, `1h 20m`, `∞`).
String formatEta(int seconds) {
  if (seconds <= 0 || seconds >= _etaInfinity) return '∞';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return '${seconds}s';
}

/// Shared async-state scaffolding for a media sub-tab: a "configure me" panel
/// when the service isn't set up, a retryable error, and a spinner.
Widget mediaAsyncState({
  required BuildContext context,
  required Object error,
  required VoidCallback onRetry,
}) {
  if (error is MediaNotConfigured) {
    // Name the credential the Settings field actually asks for — Plex
    // authenticates with a token, everything else here with an API key.
    final secret = error.service == 'Plex' ? 'token' : 'API key';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              '${error.service} is not configured.\n'
              'Add its URL and $secret in Settings.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Failed to load:\n$error', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

/// File-local media inks (mapping `media.*` slice): dark values verbatim from
/// the dark-only era; light is the parchment ink equivalents.
class MediaTilePalette {
  const MediaTilePalette({
    required this.ink,
    required this.caption,
    required this.recessBorder,
  });

  /// JetBrains Mono tile-title ink (parchment on dark, umber ink on paper).
  final Color ink;

  /// Muted sage caption / small-caps stat-label ink.
  final Color caption;

  /// Translucent green hairline around the recessed progress track.
  final Color recessBorder;

  static const dark = MediaTilePalette(
    ink: Color(0xFFE6DFC9),
    caption: Color(0xFF9AA98A),
    recessBorder: Color(0x385FA050),
  );
  static const light = MediaTilePalette(
    ink: Color(0xFF3A3326),
    caption: Color(0xFF5A6650),
    recessBorder: Color(0x4738702E),
  );

  static MediaTilePalette of(Brass brass) => brass.isDark ? dark : light;
}

/// Brass stat strip (design §7): Playfair w800 values over small-caps labels
/// in a hairline-bordered panel.
Widget mediaSummary(BuildContext context, List<(String, String)> stats) {
  final brass = context.brass;
  final palette = MediaTilePalette.of(brass);
  return BrassPanel(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        for (final (label, value) in stats)
          Expanded(
            child: Column(
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 27,
                    height: 1.05,
                    color: brass.textHeading,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 10.5 * 0.14,
                    color: palette.caption,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Small-caps section label used between a media tab's lists (design idiom).
class MediaSectionTitle extends StatelessWidget {
  const MediaSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.5,
        letterSpacing: 11.5 * 0.16,
        color: context.brass.smallCaps,
      ),
    );
  }
}

/// A download-queue row with a progress bar and a remove button — shared by
/// the Radarr and Sonarr tabs.
class MediaQueueTile extends StatelessWidget {
  const MediaQueueTile({
    super.key,
    required this.title,
    required this.progress,
    required this.subtitle,
    required this.onDelete,
  });

  final String title;
  final double progress;
  final String subtitle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final palette = MediaTilePalette.of(brass);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrassPanel(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13.5,
                      color: palette.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: brass.clay,
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: RecessedBar(
                fraction: progress,
                height: 7,
                borderColor: palette.recessBorder,
                gradient: [brass.sparkGreenDeep, brass.sparkGreen],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%  ·  $subtitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: palette.caption),
            ),
          ],
        ),
      ),
    );
  }
}

/// The media tabs' extended FAB. Dark keeps the stock elevated mount
/// verbatim (its near-black glow-mount vanishes on bottle-green); on
/// parchment that mount read as a harsh black sticker ring, so the light
/// FAB flattens (elevation 0) and sits on a soft umber ink shadow instead
/// (brass.cardShadow family).
class MediaFab extends StatelessWidget {
  const MediaFab({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    if (context.brass.isDark) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: icon,
        label: label,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        // Matches the M3 extended-FAB stadium so the ink shadow hugs it.
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3846381F),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 1,
        highlightElevation: 1,
        disabledElevation: 0,
        icon: icon,
        label: label,
      ),
    );
  }
}

/// Shared search-and-add dialog used by the Servarr media tabs.
class MediaLookupDialog<T> extends StatefulWidget {
  const MediaLookupDialog({
    super.key,
    required this.title,
    required this.hintText,
    required this.lookup,
    required this.add,
    required this.itemTitle,
    required this.itemSubtitle,
  });

  final String title;
  final String hintText;
  final Future<List<T>> Function(String term) lookup;
  final Future<void> Function(T item) add;
  final String Function(T item) itemTitle;
  final String? Function(T item) itemSubtitle;

  @override
  State<MediaLookupDialog<T>> createState() => _MediaLookupDialogState<T>();
}

class _MediaLookupDialogState<T> extends State<MediaLookupDialog<T>> {
  final _controller = TextEditingController();
  List<T> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final term = _controller.text.trim();
    if (term.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.lookup(term);
      setState(() => _results = results);
    } on Object catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(T item) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.add(item);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Added ${widget.itemTitle(item)}')),
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hintText,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null) Text(_error!),
            if (!_loading)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in _results.take(20))
                      ListTile(
                        dense: true,
                        title: Text(
                          widget.itemTitle(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: switch (widget.itemSubtitle(item)) {
                          final text? => Text(text),
                          null => null,
                        },
                        trailing: const Icon(Icons.add),
                        onTap: () => _add(item),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// A small snackbar helper that runs [action] and reports success/failure.
Future<void> runMediaAction(
  BuildContext context, {
  required Future<void> Function() action,
  required String success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(success)));
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
  }
}
