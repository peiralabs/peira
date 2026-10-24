import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pbs_api.dart';
import '../../core/providers/pbs_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/screen_header.dart';
import '../pdm/pdm_format.dart';
import 'pbs_actions.dart';

class PbsBackupsView extends ConsumerStatefulWidget {
  const PbsBackupsView({super.key, required this.slot});
  final PbsSlot slot;
  @override
  ConsumerState<PbsBackupsView> createState() => _PbsBackupsViewState();
}

class _PbsBackupsViewState extends ConsumerState<PbsBackupsView> {
  String? _store;
  String _namespace = '';

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(pbsOverviewProvider(widget.slot));
    return overview.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Failed to load backups: $error')),
      data: (data) {
        final stores = [for (final item in data.datastores) item.store];
        final store = stores.contains(_store) ? _store! : stores.firstOrNull;
        if (store == null) return const Center(child: Text('No datastores'));
        final namespaces = ref.watch(pbsNamespacesProvider(widget.slot, store));
        final groups = ref.watch(
          pbsGroupsProvider(widget.slot, store, _namespace),
        );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
              child: ScreenHeader(
                icon: Ph.database,
                title: 'Backups',
                subtitle: 'GROUPS AND SNAPSHOTS',
                trailing: [
                  DropdownButton<String>(
                    value: store,
                    items: [
                      for (final item in stores)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (value) => setState(() {
                      _store = value;
                      _namespace = '';
                    }),
                  ),
                  const SizedBox(width: 12),
                  namespaces.when(
                    loading: () => const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => const Text('Namespaces unavailable'),
                    data: (items) {
                      final values = [
                        '',
                        ...items.where((item) => item.isNotEmpty),
                      ];
                      final selected = values.contains(_namespace)
                          ? _namespace
                          : '';
                      return DropdownButton<String>(
                        value: selected,
                        items: [
                          for (final ns in values)
                            DropdownMenuItem(
                              value: ns,
                              child: Text(ns.isEmpty ? 'Root namespace' : ns),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _namespace = value ?? ''),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: groups.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Failed to load groups: $error')),
                data: (items) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                      pbsGroupsProvider(widget.slot, store, _namespace),
                    );
                    await ref.read(
                      pbsGroupsProvider(widget.slot, store, _namespace).future,
                    );
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => _GroupTile(
                      slot: widget.slot,
                      store: store,
                      namespace: _namespace,
                      group: items[index],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile({
    required this.slot,
    required this.store,
    required this.namespace,
    required this.group,
  });
  final PbsSlot slot;
  final String store;
  final String namespace;
  final PbsGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BrassPanel(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      leading: Icon(switch (group.type) {
        'ct' => Ph.cube,
        'vm' => Ph.hardDrives,
        _ => Ph.database,
      }),
      title: Text('${group.type}/${group.id}'),
      subtitle: Text(
        '${group.backupCount} backups  •  ${_date(group.lastBackup)}  •  ${group.owner}${group.comment.isEmpty ? '' : '\n${group.comment}'}',
      ),
      trailing: PopupMenuButton<void>(
        itemBuilder: (context) =>
            pbsGroupActions(context, ref, slot, store, group),
      ),
      children: [
        _Snapshots(
          slot: slot,
          store: store,
          namespace: namespace,
          group: group,
        ),
      ],
    ),
  );
}

class _Snapshots extends ConsumerWidget {
  const _Snapshots({
    required this.slot,
    required this.store,
    required this.namespace,
    required this.group,
  });
  final PbsSlot slot;
  final String store;
  final String namespace;
  final PbsGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(
      pbsSnapshotsProvider(slot, store, namespace, group.type, group.id),
    );
    return snapshots.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(18),
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(18),
        child: Text('Failed to load snapshots: $error'),
      ),
      data: (items) => Column(
        children: [
          for (final snapshot in items)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 48, right: 8),
              leading: const Icon(Ph.clockCounterClockwise),
              title: Text(
                '${_date(snapshot.time)}  •  ${pdmBytes(snapshot.size)}',
              ),
              subtitle: Text(
                snapshot.comment.isEmpty ? snapshot.owner : snapshot.comment,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VerifyChip(snapshot.verification?.state),
                  if (snapshot.protected)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Ph.lockSimple, size: 17),
                    ),
                  if (snapshot.encrypted)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Ph.shieldCheck, size: 17),
                    ),
                  PopupMenuButton<void>(
                    itemBuilder: (context) =>
                        pbsSnapshotActions(context, ref, slot, store, snapshot),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VerifyChip extends StatelessWidget {
  const _VerifyChip(this.state);
  final String? state;
  @override
  Widget build(BuildContext context) {
    final label = state == null || state!.isEmpty ? 'none' : state!;
    final color = label == 'ok' || label == 'OK'
        ? context.brass.ok
        : label == 'none'
        ? context.brass.textMuted
        : context.brass.crit;
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color),
    );
  }
}

String _date(int epoch) => DateTime.fromMillisecondsSinceEpoch(
  epoch * 1000,
).toLocal().toString().substring(0, 16);
