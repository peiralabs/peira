import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/qbittorrent_torrent.dart';
import '../../core/providers/media_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/recessed_bar.dart';
import 'media_common.dart';

/// qBittorrent — live torrent list with speeds, start/stop/delete, and an
/// add-magnet action.
class QbittorrentTab extends ConsumerWidget {
  const QbittorrentTab({super.key});

  static bool _isStopped(String state) =>
      state.startsWith('stopped') ||
      state.startsWith('paused') ||
      state == 'queuedDL' ||
      state == 'queuedUP';

  static Color _stateColor(Brass brass, String state) {
    if (state.contains('error') || state.contains('missing')) {
      return brass.crit;
    }
    if (state.startsWith('stalled')) return brass.ochre;
    if (_isStopped(state)) return brass.slate;
    if (state.contains('UP') || state == 'uploading' || state == 'seeding') {
      return brass.ok;
    }
    return brass.copper; // downloading / checking / metaDL
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brass = context.brass;
    final torrents = ref.watch(qbittorrentTorrentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: torrents.hasValue
          ? MediaFab(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _AddMagnetDialog(ref: ref),
              ),
              icon: const Icon(Icons.add_link),
              label: const Text('Add magnet'),
            )
          : null,
      body: torrents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => mediaAsyncState(
          context: context,
          error: e,
          onRetry: () => ref.invalidate(qbittorrentTorrentsProvider),
        ),
        data: (list) {
          final down = list.fold<int>(0, (s, t) => s + t.dlspeed);
          final up = list.fold<int>(0, (s, t) => s + t.upspeed);
          final active = list
              .where((t) => t.dlspeed > 0 || t.upspeed > 0)
              .length;
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(qbittorrentTorrentsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                mediaSummary(context, [
                  ('Torrents', '${list.length}'),
                  ('Active', '$active'),
                  ('↓', formatSpeed(down)),
                  ('↑', formatSpeed(up)),
                ]),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('No torrents')),
                  ),
                for (final t in list)
                  _TorrentTile(
                    torrent: t,
                    stateColor: _stateColor(brass, t.state),
                    stopped: _isStopped(t.state),
                    onToggle: () => runMediaAction(
                      context,
                      action: () async {
                        final api = await ref.read(
                          qbittorrentApiProvider.future,
                        );
                        if (_isStopped(t.state)) {
                          await api.start(t.hash);
                        } else {
                          await api.stop(t.hash);
                        }
                        ref.invalidate(qbittorrentTorrentsProvider);
                      },
                      success: _isStopped(t.state) ? 'Started' : 'Stopped',
                    ),
                    onDelete: () => _confirmDelete(context, ref, t),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    QbittorrentTorrent t,
  ) async {
    var deleteFiles = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Remove torrent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.name),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Also delete downloaded files'),
                value: deleteFiles,
                onChanged: (v) => setState(() => deleteFiles = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    await runMediaAction(
      context,
      action: () async {
        final api = await ref.read(qbittorrentApiProvider.future);
        await api.delete(t.hash, deleteFiles: deleteFiles);
        ref.invalidate(qbittorrentTorrentsProvider);
      },
      success: 'Removed ${t.name}',
    );
  }
}

/// File-local tile inks (mapping `media.*` slice): dark values verbatim from
/// the dark-only era; light is the parchment ink equivalents.
class _TilePalette {
  const _TilePalette({
    required this.ink,
    required this.caption,
    required this.recessBorder,
  });

  /// JetBrains Mono torrent-name ink (parchment on dark, umber ink on paper).
  final Color ink;

  /// Muted sage percent/meta caption ink.
  final Color caption;

  /// Translucent green hairline around the recessed progress track.
  final Color recessBorder;

  static const dark = _TilePalette(
    ink: Color(0xFFE6DFC9),
    caption: Color(0xFF9AA98A),
    recessBorder: Color(0x385FA050),
  );
  static const light = _TilePalette(
    ink: Color(0xFF3A3326),
    caption: Color(0xFF5A6650),
    recessBorder: Color(0x4738702E),
  );

  static _TilePalette of(Brass brass) => brass.isDark ? dark : light;
}

class _TorrentTile extends StatefulWidget {
  const _TorrentTile({
    required this.torrent,
    required this.stateColor,
    required this.stopped,
    required this.onToggle,
    required this.onDelete,
  });

  final QbittorrentTorrent torrent;
  final Color stateColor;
  final bool stopped;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  State<_TorrentTile> createState() => _TorrentTileState();
}

/// Torrent row in the design's §7 language: state cabochon dot + JetBrains
/// Mono name, play/trash actions, a recessed green progress track, and a
/// muted meta line. Hover slides the row right 4px.
class _TorrentTileState extends State<_TorrentTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final palette = _TilePalette.of(brass);
    final torrent = widget.torrent;
    final stateColor = widget.stateColor;
    final stopped = widget.stopped;
    final subtitle = [
      torrent.state,
      if (torrent.category.isNotEmpty) torrent.category,
      formatBytes(torrent.size),
      if (torrent.dlspeed > 0) '↓ ${formatSpeed(torrent.dlspeed)}',
      if (torrent.upspeed > 0) '↑ ${formatSpeed(torrent.upspeed)}',
      if (torrent.eta > 0) formatEta(torrent.eta),
    ].join('  ·  ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(_hover ? 4 : 0, 0, 0),
          child: BrassPanel(
            padding: const EdgeInsets.fromLTRB(14, 9, 8, 12),
            borderColor:
                _hover ? stateColor.withValues(alpha: 0.5) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.44),
                          colors: [
                            Color.lerp(Colors.white, stateColor, 0.25)!,
                            stateColor,
                            Color.lerp(Colors.black, stateColor, 0.4)!,
                          ],
                          stops: const [0, 0.44, 1],
                        ),
                        // Additive halo in the dark; on parchment the dot's
                        // own deep edge becomes an ink drop shadow (mirrors
                        // Brass.jewelHalo).
                        boxShadow: [
                          if (brass.isDark)
                            BoxShadow(
                              color: stateColor.withValues(alpha: 0.6),
                              blurRadius: 8,
                            )
                          else
                            BoxShadow(
                              color: Color.lerp(Colors.black, stateColor, 0.4)!
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        torrent.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13.5,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: stopped ? 'Start' : 'Stop',
                      icon: Icon(stopped ? Icons.play_arrow : Icons.pause),
                      color: brass.clay,
                      onPressed: widget.onToggle,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      color: brass.clay,
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: RecessedBar(
                    fraction: torrent.progress,
                    height: 7,
                    borderColor: palette.recessBorder,
                    gradient: [
                      brass.sparkGreenDeep,
                      brass.sparkGreen,
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(torrent.progress * 100).toStringAsFixed(0)}%  ·  $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 13, color: palette.caption),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMagnetDialog extends StatefulWidget {
  const _AddMagnetDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_AddMagnetDialog> createState() => _AddMagnetDialogState();
}

class _AddMagnetDialogState extends State<_AddMagnetDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final magnet = _controller.text.trim();
    if (magnet.isEmpty) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = await widget.ref.read(qbittorrentApiProvider.future);
      await api.addMagnet(magnet);
      widget.ref.invalidate(qbittorrentTorrentsProvider);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Magnet added')));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add magnet'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'magnet:?xt=…'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _add, child: const Text('Add')),
      ],
    );
  }
}
