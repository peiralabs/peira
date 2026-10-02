import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/docker_api.dart';
import '../../core/models/docker_container.dart';
import '../../core/models/docker_image.dart';
import '../../core/providers/docker_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/screen_header.dart';

/// Standalone native Docker Engine control screen.
class DockerScreen extends ConsumerWidget {
  const DockerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containers = ref.watch(dockerContainersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: containers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(error: error),
        data: (items) {
          final sorted = [...items]
            ..sort((a, b) {
              final state = _runningRank(a).compareTo(_runningRank(b));
              return state != 0 ? state : a.name.compareTo(b.name);
            });
          final running = sorted.where(_isRunning).length;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dockerContainersProvider);
              ref.invalidate(dockerImagesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              children: [
                ScreenHeader(
                  icon: Ph.cube,
                  title: 'Docker',
                  subtitle:
                      'ENGINE API · ${sorted.length} CONTAINER'
                      '${sorted.length == 1 ? '' : 'S'}',
                  trailing: [
                    _StatChip(value: '$running', label: 'Running'),
                    const SizedBox(width: 10),
                    _StatChip(
                      value: '${sorted.length - running}',
                      label: 'Stopped',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SectionDivider(),
                const SizedBox(height: 18),
                Text(
                  'Containers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (sorted.isEmpty)
                  const _EmptyPanel(message: 'No containers on this host')
                else
                  for (final container in sorted) ...[
                    _ContainerPanel(container: container),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 10),
                Text('Images', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const _ImagesSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  static bool _isRunning(DockerContainer container) =>
      container.state == 'running';

  static int _runningRank(DockerContainer container) =>
      _isRunning(container) ? 0 : 1;
}

class _ContainerPanel extends ConsumerWidget {
  const _ContainerPanel({required this.container});

  final DockerContainer container;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brass = context.brass;
    final running = container.state == 'running';
    final stateColor = running ? brass.ok : brass.crit;
    final displayName = container.name.isEmpty
        ? _shortId(container.id)
        : container.name;
    final ports = _formatPorts(container.ports);

    return BrassPanel(
      topRule: true,
      topRuleColor: stateColor,
      padding: const EdgeInsets.fromLTRB(18, 15, 12, 15),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: stateColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: stateColor.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${container.image} · ${container.status}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: brass.textMuted),
                ),
                if (ports.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ports,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: brass.smallCaps,
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Logs',
            onPressed: () => _showLogs(context, ref, displayName),
            icon: const Icon(Ph.fileText),
          ),
          if (running)
            IconButton(
              tooltip: 'Stop',
              color: brass.crit,
              onPressed: () => _confirmStop(context, ref, displayName),
              icon: const Icon(Icons.stop_rounded),
            )
          else
            IconButton(
              tooltip: 'Start',
              color: brass.ok,
              onPressed: () => _runAction(
                context,
                ref,
                action: (api) => api.startContainer(container.id),
                success: 'Started $displayName',
              ),
              icon: const Icon(Ph.play),
            ),
          IconButton(
            tooltip: 'Restart',
            color: brass.copper,
            onPressed: () => _runAction(
              context,
              ref,
              action: (api) => api.restartContainer(container.id),
              success: 'Restarted $displayName',
            ),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmStop(
    BuildContext context,
    WidgetRef ref,
    String displayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop container?'),
        content: Text('Stop $displayName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _runAction(
      context,
      ref,
      action: (api) => api.stopContainer(container.id),
      success: 'Stopped $displayName',
    );
  }

  Future<void> _showLogs(
    BuildContext context,
    WidgetRef ref,
    String displayName,
  ) async {
    final api = await ref.read(dockerApiProvider.future);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$displayName logs'),
        content: SizedBox(
          width: 760,
          height: 500,
          child: FutureBuilder<String>(
            future: api.getContainerLogs(container.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Failed to load logs:\n${snapshot.error}'),
                );
              }
              final logs = snapshot.data ?? '';
              return SingleChildScrollView(
                child: SelectableText(
                  logs.isEmpty ? 'No logs returned.' : logs,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref, {
    required Future<void> Function(DockerApi api) action,
    required String success,
  }) async {
    try {
      final api = await ref.read(dockerApiProvider.future);
      await action(api);
      ref.invalidate(dockerContainersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Docker action failed: $error')));
      }
    }
  }

  static String _shortId(String id) =>
      id.length > 12 ? id.substring(0, 12) : id;

  static String _formatPorts(List<Map<String, dynamic>> ports) => ports
      .map((port) {
        final privatePort = port['PrivatePort'];
        final publicPort = port['PublicPort'];
        final type = port['Type'] ?? 'tcp';
        if (publicPort == null) return '$privatePort/$type';
        final ip = port['IP'];
        final host = ip is String && ip.isNotEmpty ? '$ip:' : '';
        return '$host$publicPort→$privatePort/$type';
      })
      .join(', ');
}

class _ImagesSection extends ConsumerWidget {
  const _ImagesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(dockerImagesProvider);
    return images.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => BrassPanel(
        child: Row(
          children: [
            Expanded(child: Text('Failed to load images: $error')),
            OutlinedButton(
              onPressed: () => ref.invalidate(dockerImagesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (items) => items.isEmpty
          ? const _EmptyPanel(message: 'No images on this host')
          : BrassPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _ImageRow(image: items[i]),
                    if (i != items.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ImageRow extends StatelessWidget {
  const _ImageRow({required this.image});

  final DockerImage image;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final tags = image.repoTags.where((tag) => tag != '<none>:<none>').toList();
    return ListTile(
      leading: Icon(Ph.image, color: brass.bronze),
      title: Text(tags.isEmpty ? _shortId(image.id) : tags.join(', ')),
      subtitle: Text(_shortId(image.id)),
      trailing: Text(_formatBytes(image.size)),
    );
  }

  static String _shortId(String id) {
    final clean = id.startsWith('sha256:') ? id.substring(7) : id;
    return clean.length > 12 ? clean.substring(0, 12) : clean;
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1 << 30) return '${(bytes / (1 << 30)).toStringAsFixed(1)} GB';
    if (bytes >= 1 << 20) return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
    if (bytes >= 1 << 10) return '${(bytes / (1 << 10)).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notConfigured = error is DockerNotConfigured;
    final message = notConfigured
        ? 'Docker is not configured yet.\nEnter the Engine API URL in Settings.'
        : 'Failed to reach Docker:\n$error';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (!notConfigured) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(dockerContainersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => BrassPanel(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(message, style: TextStyle(color: context.brass.textMuted)),
      ),
    ),
  );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: TextStyle(color: brass.smallCaps, fontSize: 11)),
      ],
    );
  }
}
