import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/loki_api.dart';
import '../../core/providers/loki_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mol_motion.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/screen_header.dart';

/// Native tail over the lab's centralized logs (Loki + Alloy shippers): host
/// filter chips from the live `host` label, a contains filter, and the
/// newest 200 lines of the trailing hour in a recessed mono panel. Loss of a
/// machine no longer means loss of its logs — this is where they surface.
class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  String _host = '';
  final _contains = TextEditingController();
  String _applied = '';

  @override
  void dispose() {
    _contains.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(lokiHostsProvider);
    ref.invalidate(
      lokiTailProvider((host: _host, contains: _applied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hosts = ref.watch(lokiHostsProvider);
    final tail = ref.watch(
      lokiTailProvider((host: _host, contains: _applied)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            icon: Ph.scroll,
            title: 'Logs',
            subtitle: 'LOKI JOURNAL · TRAILING HOUR · NEWEST FIRST',
            trailing: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refresh,
                icon: const Icon(Ph.arrowsClockwise, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionDivider(),
          const SizedBox(height: MolSpace.md),
          // Host chips ride the live label values; 'All machines' is the
          // empty filter. An unreachable Loki leaves just that chip.
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _HostChip(
                        label: 'All machines',
                        selected: _host.isEmpty,
                        onTap: () => setState(() => _host = ''),
                      ),
                      for (final h in hosts.value ?? const <String>[])
                        Padding(
                          padding: const EdgeInsets.only(left: MolSpace.sm),
                          child: _HostChip(
                            label: h,
                            selected: _host == h,
                            onTap: () => setState(() => _host = h),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: MolSpace.md),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _contains,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Contains',
                    hintText: 'error, vzdump, oom…',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => setState(() => _applied = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: MolSpace.md),
          Expanded(
            child: tail.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => e is LokiNotConfigured
                  ? const Center(
                      child: Text(
                        'Loki has no URL yet.\nEnter it in Settings.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _LogsError(error: e, onRetry: _refresh),
              data: (entries) => entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No log lines in the trailing hour for this filter.',
                      ),
                    )
                  : _LogList(entries: entries),
            ),
          ),
          const SizedBox(height: MolSpace.lg),
        ],
      ),
    );
  }
}

class _HostChip extends StatelessWidget {
  const _HostChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(MolRadius.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MolSpace.md,
          vertical: MolSpace.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MolRadius.pill),
          border: Border.all(
            color: selected
                ? brass.giltBright.withValues(alpha: 0.65)
                : brass.hairline,
          ),
          color: selected ? brass.bronze.withValues(alpha: 0.12) : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected ? brass.giltBright : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList({required this.entries});

  final List<LokiEntry> entries;

  static String _hhmmss(DateTime utc) {
    final t = utc.toLocal();
    String p(int v) => v.toString().padLeft(2, '0');
    return '${p(t.hour)}:${p(t.minute)}:${p(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final theme = Theme.of(context);
    return BrassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.md,
        vertical: MolSpace.sm,
      ),
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          final lower = e.line.toLowerCase();
          final trouble = lower.contains('error') ||
              lower.contains('fail') ||
              lower.contains('critical');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hhmmss(e.ts),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: MolSpace.md),
                SizedBox(
                  width: 74,
                  child: Text(
                    e.host,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: brass.bronze,
                    ),
                  ),
                ),
                const SizedBox(width: MolSpace.md),
                Expanded(
                  child: Text(
                    e.unit.isEmpty ? e.line : '[${e.unit}] ${e.line}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.5,
                      height: 1.45,
                      color: trouble
                          ? brass.madder
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LogsError extends StatelessWidget {
  const _LogsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Ph.warning, size: 28),
            const SizedBox(height: MolSpace.sm),
            Text(
              'Loki is not answering.\n$error',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: MolSpace.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Ph.arrowsClockwise, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
}
