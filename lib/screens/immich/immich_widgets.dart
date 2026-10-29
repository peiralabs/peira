import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/immich_api.dart';
import '../../core/providers/immich_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/service_frame.dart';

/// Runs an Immich call, reporting success or failure in a snackbar.
Future<bool> immichAct(
  BuildContext context,
  Future<void> Function(ImmichApi api) body, {
  String? done,
  required WidgetRef ref,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await body(await ref.read(immichApiProvider.future));
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeServiceError(e))));
    return false;
  }
}

Future<bool> immichConfirm(
  BuildContext context,
  String title,
  String body,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// An authenticated Immich image (thumbnail, preview, or face).
class ImmichImage extends ConsumerWidget {
  const ImmichImage({super.key, required this.url, this.fit = BoxFit.cover});
  final String Function(ImmichApi api) url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(immichApiProvider).value;
    if (api == null) return const ColoredBox(color: Colors.black26);
    return Image.network(
      url(api),
      headers: api.imageHeaders,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Colors.black26,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}

/// A paged grid of assets. [load] fetches one page; the grid asks for the
/// next page when the operator presses "Load more".
class ImmichAssetGrid extends ConsumerStatefulWidget {
  const ImmichAssetGrid({
    super.key,
    required this.load,
    this.empty = 'Nothing here.',
    this.header,
    this.onChanged,
  });
  final Future<ImmichAssetPage> Function(ImmichApi api, int page) load;
  final String empty;
  final Widget? header;

  /// Called after the viewer changed an asset (favourite, trash…).
  final VoidCallback? onChanged;

  @override
  ConsumerState<ImmichAssetGrid> createState() => ImmichAssetGridState();
}

class ImmichAssetGridState extends ConsumerState<ImmichAssetGrid> {
  final _assets = <ImmichAsset>[];
  int? _next = 1;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _more();
  }

  /// Starts over from page 1 (after a change or a new query).
  void reload() {
    setState(() {
      _assets.clear();
      _next = 1;
      _error = null;
    });
    _more();
  }

  Future<void> _more() async {
    final page = _next;
    if (page == null || _loading) return;
    setState(() => _loading = true);
    try {
      final api = await ref.read(immichApiProvider.future);
      final res = await widget.load(api, page);
      if (!mounted) return;
      setState(() {
        _assets.addAll(res.assets);
        _next = res.assets.isEmpty ? null : res.nextPage;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _assets.isEmpty) {
      return ServiceError(error: _error!, onRetry: reload);
    }
    return CustomScrollView(
      slivers: [
        if (widget.header != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            sliver: SliverToBoxAdapter(child: widget.header),
          ),
        if (_assets.isEmpty && !_loading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(widget.empty)),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: _assets.length,
            itemBuilder: (context, i) => _Thumb(
              asset: _assets[i],
              onTap: () async {
                final changed = await showImmichViewer(context, _assets[i]);
                if (changed == true) {
                  reload();
                  widget.onChanged?.call();
                }
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : _next != null && _assets.isNotEmpty
                  ? OutlinedButton(
                      onPressed: _more,
                      child: const Text('Load more'),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.asset, required this.onTap});
  final ImmichAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('immich-${asset.id}'),
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImmichImage(url: (api) => api.thumbnailUrl(asset.id)),
          if (asset.isVideo)
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(Icons.play_circle_fill, color: Colors.white70),
            ),
          if (asset.isFavorite)
            const Positioned(
              left: 4,
              bottom: 4,
              child: Icon(Icons.favorite, color: Colors.white, size: 18),
            ),
        ],
      ),
    ),
  );
}

/// Full view of one asset with its details and actions. Resolves to true
/// when the asset changed.
Future<bool?> showImmichViewer(BuildContext context, ImmichAsset asset) =>
    showDialog<bool>(
      context: context,
      builder: (_) => _Viewer(assetId: asset.id),
    );

class _Viewer extends ConsumerStatefulWidget {
  const _Viewer({required this.assetId});
  final String assetId;

  @override
  ConsumerState<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends ConsumerState<_Viewer> {
  bool _changed = false;

  Future<void> _do(Future<void> Function(ImmichApi) body, String done) async {
    if (await immichAct(context, body, done: done, ref: ref)) {
      _changed = true;
      ref.invalidate(immichAssetProvider(widget.assetId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = ref.watch(immichAssetProvider(widget.assetId));
    final brass = context.brass;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: size.width * 0.9,
        height: size.height * 0.88,
        child: asset.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ServiceError(
            error: e,
            onRetry: () => ref.invalidate(immichAssetProvider(widget.assetId)),
          ),
          data: (a) => Row(
            children: [
              Expanded(
                child: ColoredBox(
                  color: Colors.black,
                  child: ImmichImage(
                    url: (api) => api.thumbnailUrl(a.id, size: 'preview'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(
                width: 320,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.fileName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context, _changed),
                        ),
                      ],
                    ),
                    if (a.taken != null)
                      Text(
                        a.taken!.toString().substring(0, 16),
                        style: TextStyle(color: brass.textMuted),
                      ),
                    if (a.isVideo)
                      Text(
                        'Video: play it in the browser.',
                        style: TextStyle(color: brass.textMuted),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: a.isFavorite ? 'Unfavourite' : 'Favourite',
                          icon: Icon(
                            a.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          onPressed: () => _do(
                            (api) => api.updateAssets([
                              a.id,
                            ], isFavorite: !a.isFavorite),
                            a.isFavorite ? 'Unfavourited' : 'Favourited',
                          ),
                        ),
                        IconButton(
                          tooltip: a.visibility == 'archive'
                              ? 'Unarchive'
                              : 'Archive',
                          icon: Icon(
                            a.visibility == 'archive'
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                          ),
                          onPressed: () => _do(
                            (api) => api.updateAssets(
                              [a.id],
                              visibility: a.visibility == 'archive'
                                  ? 'timeline'
                                  : 'archive',
                            ),
                            a.visibility == 'archive'
                                ? 'Unarchived'
                                : 'Archived',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Add to album',
                          icon: const Icon(Icons.photo_album_outlined),
                          onPressed: () => _addToAlbum(a),
                        ),
                        IconButton(
                          tooltip: 'Open in browser',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () async {
                            final api = await ref.read(
                              immichApiProvider.future,
                            );
                            if (context.mounted) {
                              await openInBrowser(context, api.webUrl(a.id));
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Move to trash',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (!await immichConfirm(
                              context,
                              'Move to trash?',
                              '${a.fileName} can be restored from the trash.',
                              'Move to trash',
                            )) {
                              return;
                            }
                            if (!context.mounted) return;
                            if (await immichAct(
                                  context,
                                  (api) => api.deleteAssets([a.id]),
                                  done: 'Moved to trash',
                                  ref: ref,
                                ) &&
                                context.mounted) {
                              Navigator.pop(context, true);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    if (a.people.isNotEmpty)
                      _row(context, 'People', a.people.join(', ')),
                    for (final (label, key) in const [
                      ('Camera', 'model'),
                      ('Make', 'make'),
                      ('Lens', 'lensModel'),
                      ('Aperture', 'fNumber'),
                      ('Exposure', 'exposureTime'),
                      ('ISO', 'iso'),
                      ('Focal length', 'focalLength'),
                      ('City', 'city'),
                      ('State', 'state'),
                      ('Country', 'country'),
                      ('Description', 'description'),
                    ])
                      if (a.exif[key] != null && '${a.exif[key]}'.isNotEmpty)
                        _row(context, label, '${a.exif[key]}'),
                    if (a.exif['exifImageWidth'] != null)
                      _row(
                        context,
                        'Size',
                        '${a.exif['exifImageWidth']} × ${a.exif['exifImageHeight']}',
                      ),
                    if (a.exif['fileSizeInByte'] != null)
                      _row(
                        context,
                        'File',
                        '${((a.exif['fileSizeInByte'] as num) / 1048576).toStringAsFixed(1)} MB',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(k, style: TextStyle(color: context.brass.textMuted)),
        ),
        Expanded(child: SelectableText(v)),
      ],
    ),
  );

  Future<void> _addToAlbum(ImmichAsset a) async {
    final albums = await ref.read(immichAlbumsProvider.future);
    if (!mounted) return;
    final newName = TextEditingController();
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to album'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final al in albums)
                ListTile(
                  title: Text(al.name),
                  subtitle: Text('${al.assetCount} items'),
                  onTap: () => Navigator.pop(context, al.id),
                ),
              TextField(
                controller: newName,
                decoration: const InputDecoration(
                  labelText: 'Or a new album named…',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              newName.text.trim().isEmpty ? null : 'new:${newName.text.trim()}',
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    newName.dispose();
    if (choice == null || !mounted) return;
    await _do(
      (api) => choice.startsWith('new:')
          ? api.createAlbum(choice.substring(4), assetIds: [a.id])
          : api.addToAlbum(choice, [a.id]),
      'Added to album',
    );
    ref.invalidate(immichAlbumsProvider);
  }
}
