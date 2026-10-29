// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pbs_api.dart';
import '../../core/providers/pbs_jobs.dart';
import '../../core/providers/pbs_providers.dart';
import '../../core/providers/proxmox_providers.dart';
import '../../core/widgets/mechanical.dart';
import 'pbs_elevate_dialog.dart';

typedef PbsJobEditResult = ({
  Map<String, dynamic> changes,
  List<String> delete,
});

String pbsRestoreVolid(String storage, PbsSnapshot snap) {
  final time = DateTime.fromMillisecondsSinceEpoch(
    snap.time * 1000,
    isUtc: true,
  );
  String two(int value) => value.toString().padLeft(2, '0');
  final stamp =
      '${time.year.toString().padLeft(4, '0')}-${two(time.month)}-'
      '${two(time.day)}T${two(time.hour)}:${two(time.minute)}:${two(time.second)}Z';
  return '$storage:backup/${snap.type}/${snap.id}/$stamp';
}

PbsJobEditResult pbsJobEditPayload(
  Map<String, dynamic> original,
  Map<String, dynamic> edited,
) {
  final changes = <String, dynamic>{};
  final delete = <String>[];
  for (final entry in edited.entries) {
    if ((entry.value == null || entry.value == '') &&
        original[entry.key] != null) {
      delete.add(entry.key);
    } else if (!_jobValuesEqual(original[entry.key], entry.value) &&
        entry.value != null &&
        entry.value != '') {
      changes[entry.key] = entry.value;
    }
  }
  return (changes: changes, delete: delete);
}

bool _jobValuesEqual(dynamic original, dynamic edited) {
  if (original == edited) return true;
  if (original == null && edited == false) return true;
  return original != null && edited != null && '$original' == '$edited';
}

List<PopupMenuEntry<void>> pbsSnapshotActions(
  BuildContext context,
  WidgetRef ref,
  PbsSlot slot,
  String store,
  PbsSnapshot snapshot,
) => [
  _item('Verify', () => _verifySnapshot(context, ref, slot, store, snapshot)),
  _item(
    snapshot.protected ? 'Unprotect' : 'Protect',
    () => _protect(context, ref, slot, store, snapshot),
  ),
  _item(
    'Edit notes',
    () => _editSnapshotNotes(context, ref, slot, store, snapshot),
  ),
  _item('Browse files', () => _browse(context, ref, slot, store, snapshot)),
  PopupMenuItem<void>(
    enabled: _restoreReason(ref, slot, snapshot) == null,
    onTap: () => Future.microtask(() => _restore(context, ref, slot, snapshot)),
    child: Tooltip(
      message: _restoreReason(ref, slot, snapshot) ?? '',
      child: const Text('Restore…'),
    ),
  ),
  _item('Delete', () => _deleteSnapshot(context, ref, slot, store, snapshot)),
];

List<PopupMenuEntry<void>> pbsGroupActions(
  BuildContext context,
  WidgetRef ref,
  PbsSlot slot,
  String store,
  PbsGroup group,
) => [
  _item('Verify group', () => _verifyGroup(context, ref, slot, store, group)),
  _item(
    'Edit group notes',
    () => _editGroupNotes(context, ref, slot, store, group),
  ),
  _item('Change owner', () => _changeOwner(context, ref, slot, store, group)),
  _item('Prune…', () => _pruneGroup(context, ref, slot, store, group)),
  _item('Delete group', () => _deleteGroup(context, ref, slot, store, group)),
];

List<PopupMenuEntry<void>> pbsDatastoreActions(
  BuildContext context,
  WidgetRef ref,
  PbsSlot slot,
  String store,
) => [
  _item('Start GC', () => _startGc(context, ref, slot, store)),
  _item('Verify datastore', () => _verifyDatastore(context, ref, slot, store)),
  _item('Prune datastore…', () => _pruneDatastore(context, ref, slot, store)),
];

List<PopupMenuEntry<void>> pbsJobActions(
  BuildContext context,
  WidgetRef ref,
  PbsSlot slot,
  PbsJob job,
) => [
  _item('Run now', () => _runJob(context, ref, slot, job)),
  _item('Edit…', () => _editJob(context, ref, slot, job)),
];

PopupMenuItem<void> _item(String label, Future<void> Function() action) =>
    PopupMenuItem<void>(
      onTap: () => Future.microtask(action),
      child: Text(label),
    );

void _snack(BuildContext context, String message) {
  if (context.mounted)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _guarded(
  BuildContext context,
  WidgetRef ref,
  PbsSlot slot,
  Future<void> Function() body,
) async {
  try {
    await body();
  } on PbsApiException catch (error) {
    if (error.statusCode == 401) {
      ref.read(pbsElevationProvider.notifier).lock(slot);
      _snack(context, 'Session expired, unlock again');
    } else {
      _snack(context, error.message);
    }
  } catch (error) {
    _snack(context, '$error');
  }
}

void _track(WidgetRef ref, PbsSlot slot, String label, String upid) {
  if (upid.isNotEmpty)
    ref.read(pbsJobsProvider.notifier).track(slot, label, upid);
}

void _invalidateBackups(WidgetRef ref, PbsSlot slot) {
  ref.invalidate(pbsOverviewProvider(slot));
  ref.invalidate(pbsGroupsProvider);
  ref.invalidate(pbsSnapshotsProvider);
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String initial,
}) async {
  final controller = TextEditingController(text: initial);
  final value = await _ownedDialog<String>(
    owned: [controller],
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  return value;
}

@visibleForTesting
Future<bool> pbsTypedConfirm(
  BuildContext context,
  String title,
  String expected,
) async {
  final controller = TextEditingController();
  final result = await _ownedDialog<bool>(
    owned: [controller],
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type $expected to confirm.'),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('pbs-delete-confirm'),
              controller: controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: controller.text == expected
                ? () => Navigator.pop(context, true)
                : null,
            child: const Text('Delete'),
          ),
        ],
      ),
    ),
  );
  return result == true;
}

Future<void> _verifySnapshot(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsSnapshot snap,
) => _guarded(c, r, s, () async {
  final api = await r.read(pbsApiProvider(s).future);
  _track(
    r,
    s,
    'Verify ${snap.type}/${snap.id}',
    await api.verify(
      store,
      ns: snap.namespace,
      type: snap.type,
      id: snap.id,
      time: snap.time,
    ),
  );
});

Future<void> _verifyGroup(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsGroup group,
) => _guarded(c, r, s, () async {
  final api = await r.read(pbsApiProvider(s).future);
  _track(
    r,
    s,
    'Verify ${group.type}/${group.id}',
    await api.verify(
      store,
      ns: group.namespace,
      type: group.type,
      id: group.id,
    ),
  );
});

Future<void> _protect(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsSnapshot snap,
) => _guarded(c, r, s, () async {
  final api = await requireElevated(c, r, s);
  if (api == null) return;
  await api.setProtected(store, snap, !snap.protected);
  _invalidateBackups(r, s);
});

Future<void> _editSnapshotNotes(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsSnapshot snap,
) async {
  final api = await requireElevated(c, r, s);
  if (api == null || !c.mounted) return;
  final value = await _textDialog(
    c,
    title: 'Edit snapshot notes',
    label: 'Notes',
    initial: snap.comment,
  );
  if (value == null || !c.mounted) return;
  await _guarded(c, r, s, () async {
    await api.setNotes(store, snap, value);
    _invalidateBackups(r, s);
  });
}

Future<void> _editGroupNotes(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsGroup group,
) async {
  final api = await requireElevated(c, r, s);
  if (api == null || !c.mounted) return;
  final value = await _textDialog(
    c,
    title: 'Edit group notes',
    label: 'Notes',
    initial: group.comment,
  );
  if (value == null || !c.mounted) return;
  await _guarded(c, r, s, () async {
    await api.setGroupNotes(store, group, value);
    _invalidateBackups(r, s);
  });
}

Future<void> _changeOwner(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsGroup group,
) async {
  final api = await requireElevated(c, r, s);
  if (api == null || !c.mounted) return;
  final value = await _textDialog(
    c,
    title: 'Change owner',
    label: 'Owner',
    initial: group.owner,
  );
  if (value == null || value.isEmpty || !c.mounted) return;
  await _guarded(c, r, s, () async {
    await api.changeOwner(store, group, value);
    _invalidateBackups(r, s);
  });
}

Future<void> _deleteSnapshot(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsSnapshot snap,
) async {
  if (snap.protected) {
    _snack(c, 'Protected snapshots cannot be deleted');
    return;
  }
  final api = await requireElevated(c, r, s);
  if (api == null || !c.mounted) return;
  if (!await pbsTypedConfirm(
        c,
        'Delete snapshot?',
        '${snap.type}/${snap.id}',
      ) ||
      !c.mounted)
    return;
  await _guarded(c, r, s, () async {
    await api.deleteSnapshot(store, snap);
    _invalidateBackups(r, s);
  });
}

Future<void> _deleteGroup(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsGroup group,
) async {
  final api = await requireElevated(c, r, s);
  if (api == null || !c.mounted) return;
  if (!await pbsTypedConfirm(
        c,
        'Delete backup group?',
        '${group.type}/${group.id}',
      ) ||
      !c.mounted)
    return;
  await _guarded(c, r, s, () async {
    await api.deleteGroup(store, group);
    _invalidateBackups(r, s);
  });
}

PbsKeep _keepFrom(Map<String, TextEditingController> fields) => PbsKeep(
  last: int.tryParse(fields['keep-last']!.text),
  hourly: int.tryParse(fields['keep-hourly']!.text),
  daily: int.tryParse(fields['keep-daily']!.text),
  weekly: int.tryParse(fields['keep-weekly']!.text),
  monthly: int.tryParse(fields['keep-monthly']!.text),
  yearly: int.tryParse(fields['keep-yearly']!.text),
);

Map<String, TextEditingController> _keepControllers([
  Map<String, dynamic> raw = const {},
]) => {
  for (final key in const [
    'keep-last',
    'keep-hourly',
    'keep-daily',
    'keep-weekly',
    'keep-monthly',
    'keep-yearly',
  ])
    key: TextEditingController(text: raw[key]?.toString() ?? ''),
};

Widget _keepFields(Map<String, TextEditingController> fields) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    for (final e in fields.entries)
      SizedBox(
        width: 150,
        child: TextField(
          key: ValueKey('pbs-${e.key}'),
          controller: e.value,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: e.key),
        ),
      ),
  ],
);

Future<void> _pruneGroup(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsGroup group,
) async {
  final api = await requireElevated(c, r, s);
  if (api == null || !c.mounted) return;
  Map<String, dynamic> preset = const {};
  try {
    preset =
        (await api.pruneJobs())
            .where((j) => j.store == store)
            .firstOrNull
            ?.raw ??
        const {};
  } catch (_) {}
  final fields = _keepControllers(preset);
  List<PbsPruneEntry>? preview;
  bool busy = false;
  PbsKeep? selected;
  final prune = await _ownedDialog<bool>(
    owned: fields.values,
    context: c,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Prune ${group.type}/${group.id}'),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _keepFields(fields),
                const SizedBox(height: 12),
                if (busy) const CircularProgressIndicator(),
                if (preview != null)
                  for (final row in preview!)
                    ListTile(
                      key: ValueKey('pbs-prune-${row.time}'),
                      dense: true,
                      title: Text(
                        DateTime.fromMillisecondsSinceEpoch(
                          row.time * 1000,
                        ).toLocal().toString(),
                      ),
                      subtitle: row.protected ? const Text('protected') : null,
                      trailing: Text(
                        row.keep || row.protected ? 'KEEP' : 'REMOVE',
                      ),
                    ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      final rows = await api.prunePreview(
                        store,
                        group,
                        _keepFrom(fields),
                      );
                      setState(() => preview = rows);
                    } catch (e) {
                      _snack(c, '$e');
                    } finally {
                      setState(() => busy = false);
                    }
                  },
            child: const Text('Preview'),
          ),
          FilledButton(
            onPressed: preview == null
                ? null
                : () {
                    selected = _keepFrom(fields);
                    Navigator.pop(context, true);
                  },
            child: Text(
              'Prune ${preview?.where((e) => !e.keep && !e.protected).length ?? 0} snapshots',
            ),
          ),
        ],
      ),
    ),
  );
  if (prune != true || selected == null || !c.mounted) return;
  await _guarded(c, r, s, () async {
    await api.pruneGroup(store, group, selected!);
    _invalidateBackups(r, s);
  });
}

Future<void> _startGc(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
) async {
  final api = await requireElevated(c, r, s);
  if (api == null || !c.mounted) return;
  final ok = await showDialog<bool>(
    context: c,
    builder: (context) => AlertDialog(
      title: Text('Start garbage collection on $store?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Start GC'),
        ),
      ],
    ),
  );
  if (ok == true)
    await _guarded(c, r, s, () async {
      _track(r, s, 'GC $store', await api.startGc(store));
    });
}

Future<void> _verifyDatastore(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
) async {
  var ignore = false;
  final days = TextEditingController();
  final ok = await _ownedDialog<bool>(
    owned: [days],
    context: c,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Verify $store'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrassSwitchTile(
              title: const Text('Ignore already verified'),
              value: ignore,
              onChanged: (v) => setState(() => ignore = v),
            ),
            TextField(
              controller: days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Outdated after (days)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    ),
  );
  final outdated = int.tryParse(days.text);
  if (ok != true) return;
  await _guarded(c, r, s, () async {
    final api = await r.read(pbsApiProvider(s).future);
    _track(
      r,
      s,
      'Verify $store',
      await api.verify(store, ignoreVerified: ignore, outdatedAfter: outdated),
    );
  });
}

Future<void> _pruneDatastore(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
) async {
  final api = await requireElevated(c, r, s);
  if (api == null || !c.mounted) return;
  final fields = _keepControllers();
  int? removeCount;
  bool busy = false;
  PbsKeep? selected;
  final ok = await _ownedDialog<bool>(
    owned: fields.values,
    context: c,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Prune datastore $store'),
        content: SizedBox(
          width: 650,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _keepFields(fields),
              if (busy) const CircularProgressIndicator(),
              if (removeCount != null)
                Text('$removeCount snapshots would be removed'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      final result = await api.pruneDatastorePreview(
                        store,
                        _keepFrom(fields),
                      );
                      if (result is List)
                        setState(
                          () => removeCount = result
                              .where(
                                (e) =>
                                    e is Map &&
                                    e['keep'] != true &&
                                    e['protected'] != true,
                              )
                              .length,
                        );
                    } catch (e) {
                      _snack(c, '$e');
                    } finally {
                      setState(() => busy = false);
                    }
                  },
            child: const Text('Preview'),
          ),
          FilledButton(
            onPressed: () {
              selected = _keepFrom(fields);
              Navigator.pop(context, true);
            },
            child: const Text('Prune datastore'),
          ),
        ],
      ),
    ),
  );
  if (ok == true && selected != null)
    await _guarded(c, r, s, () async {
      _track(r, s, 'Prune $store', await api.pruneDatastore(store, selected!));
    });
}

Future<void> _runJob(BuildContext c, WidgetRef r, PbsSlot s, PbsJob job) =>
    _guarded(c, r, s, () async {
      final api = job.kind == 'verify'
          ? await r.read(pbsApiProvider(s).future)
          : await requireElevated(c, r, s);
      if (api != null)
        _track(
          r,
          s,
          'Run ${job.kind} ${job.id}',
          await api.runJob(job.kind, job.id),
        );
    });

Future<void> _editJob(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  PbsJob job,
) async {
  final api = await requireElevated(c, r, s);
  if (api == null || !c.mounted) return;
  final keys = <String>[
    'schedule',
    'comment',
    if (job.kind == 'prune') ...[
      'keep-last',
      'keep-hourly',
      'keep-daily',
      'keep-weekly',
      'keep-monthly',
      'keep-yearly',
      'ns',
      'max-depth',
    ],
    if (job.kind == 'verify') 'outdated-after',
  ];
  final controllers = {
    for (final key in keys)
      key: TextEditingController(
        text:
            job.raw[key]?.toString() ?? (key == 'schedule' ? job.schedule : ''),
      ),
  };
  var disable = job.raw['disable'] == true || job.raw['disable'] == 1;
  var ignore =
      job.raw['ignore-verified'] == true || job.raw['ignore-verified'] == 1;
  var remove =
      job.raw['remove-vanished'] == true || job.raw['remove-vanished'] == 1;
  final edited = await _ownedDialog<Map<String, dynamic>>(
    owned: controllers.values,
    context: c,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Edit ${job.kind} job'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in controllers.entries)
                  TextField(
                    controller: e.value,
                    decoration: InputDecoration(labelText: e.key),
                  ),
                BrassSwitchTile(
                  title: const Text('Disabled'),
                  value: disable,
                  onChanged: (v) => setState(() => disable = v),
                ),
                if (job.kind == 'verify')
                  BrassSwitchTile(
                    title: const Text('Ignore verified'),
                    value: ignore,
                    onChanged: (v) => setState(() => ignore = v),
                  ),
                if (job.kind == 'sync')
                  BrassSwitchTile(
                    title: const Text('Remove vanished'),
                    value: remove,
                    onChanged: (v) => setState(() => remove = v),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, <String, dynamic>{
              for (final e in controllers.entries) e.key: e.value.text,
              'disable': disable,
              if (job.kind == 'verify') 'ignore-verified': ignore,
              if (job.kind == 'sync') 'remove-vanished': remove,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  if (edited == null) return;
  final payload = pbsJobEditPayload(job.raw, edited);
  await _guarded(c, r, s, () async {
    await api.updateJob(
      job.kind,
      job.id,
      payload.changes,
      delete: payload.delete,
      digest: job.raw['digest']?.toString(),
    );
    r.invalidate(pbsOverviewProvider(s));
  });
}

String? _restoreReason(WidgetRef ref, PbsSlot slot, PbsSnapshot snap) {
  final config = ref.read(pbsConfigProvider(slot)).value;
  if (config == null || config.pveStorage.isEmpty)
    return 'Configure the PVE storage for this PBS server';
  if ((snap.namespace ?? '').isNotEmpty)
    return 'Restore is available only for the root namespace';
  if (snap.type != 'vm' && snap.type != 'ct')
    return 'Only VM and CT backups can be restored';
  return null;
}

Future<void> _restore(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  PbsSnapshot snap,
) async {
  await _guarded(c, r, s, () async {
    final config = await r.read(pbsConfigProvider(s).future);
    final pve = await r.read(proxmoxApiProvider.future);
    final nodes = await pve.getNodes();
    if (!c.mounted || nodes.isEmpty) return;
    var node = nodes.first.node;
    var vmid = await pve.nextVmid();
    var start = false;
    var unique = false;
    var storages = await pve.getStorages(
      node,
      content: snap.type == 'vm' ? 'images' : 'rootdir',
    );
    var storage = storages.isEmpty ? '' : '${storages.first['storage']}';
    final ok = await showDialog<bool>(
      context: c,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Restore ${snap.type}/${snap.id}'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: node,
                  decoration: const InputDecoration(labelText: 'Target node'),
                  items: [
                    for (final n in nodes)
                      DropdownMenuItem(value: n.node, child: Text(n.node)),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    final values = await pve.getStorages(
                      v,
                      content: snap.type == 'vm' ? 'images' : 'rootdir',
                    );
                    setState(() {
                      node = v;
                      storages = values;
                      storage = values.isEmpty
                          ? ''
                          : '${values.first['storage']}';
                    });
                  },
                ),
                TextFormField(
                  initialValue: '$vmid',
                  decoration: const InputDecoration(labelText: 'New VMID'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => vmid = int.tryParse(v) ?? 0,
                ),
                DropdownButtonFormField<String>(
                  value: storage.isEmpty ? null : storage,
                  decoration: const InputDecoration(
                    labelText: 'Target storage',
                  ),
                  items: [
                    for (final st in storages)
                      DropdownMenuItem(
                        value: '${st['storage']}',
                        child: Text('${st['storage']}'),
                      ),
                  ],
                  onChanged: (v) => storage = v ?? '',
                ),
                BrassSwitchTile(
                  title: const Text('Start after restore'),
                  value: start,
                  onChanged: (v) => setState(() => start = v),
                ),
                if (snap.type == 'vm')
                  BrassSwitchTile(
                    title: const Text('Regenerate MAC addresses'),
                    value: unique,
                    onChanged: (v) => setState(() => unique = v),
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
              onPressed: storage.isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !c.mounted) return;
    if (vmid < 100) {
      _snack(c, 'Enter a VMID of 100 or more');
      return;
    }
    final used =
        (await pve.getAllVms()).any((guest) => guest.vmid == vmid) ||
        (await pve.getAllContainers()).any((guest) => guest.vmid == vmid);
    if (used) {
      _snack(c, 'VMID $vmid already exists');
      return;
    }
    final archive = pbsRestoreVolid(config.pveStorage, snap);
    final upid = snap.type == 'vm'
        ? await pve.restoreVm(
            node,
            vmid: vmid,
            archive: archive,
            storage: storage,
            unique: unique,
            start: start,
          )
        : await pve.restoreCt(
            node,
            vmid: vmid,
            ostemplate: archive,
            storage: storage,
            start: start,
          );
    _snack(c, 'Restore started on $node ($upid)');
  });
}

Future<void> _browse(
  BuildContext c,
  WidgetRef r,
  PbsSlot s,
  String store,
  PbsSnapshot snap,
) async {
  final api = await r.read(pbsApiProvider(s).future);
  if (!c.mounted) return;
  var path = '/';
  List<PbsCatalogEntry> entries = const [];
  bool loading = true;
  bool started = false;
  await showDialog<void>(
    context: c,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> load(String next) async {
          setState(() => loading = true);
          try {
            final rows = await api.catalog(store, snap, next);
            setState(() {
              path = next;
              entries = rows;
            });
          } catch (e) {
            _snack(c, '$e');
          } finally {
            setState(() => loading = false);
          }
        }

        if (!started) {
          started = true;
          Future.microtask(() => load(path));
        }
        return AlertDialog(
          title: Text('Browse $path'),
          content: SizedBox(
            width: 700,
            height: 480,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      if (path != '/')
                        ListTile(
                          title: const Text('..'),
                          onTap: () {
                            final cut = path.lastIndexOf('/');
                            load(cut <= 0 ? '/' : path.substring(0, cut));
                          },
                        ),
                      for (final e in entries)
                        ListTile(
                          title: Text(e.text),
                          subtitle: Text(
                            e.leaf ? '${e.size} bytes' : 'Directory',
                          ),
                          onTap: e.leaf ? null : () => load(e.filepath),
                          trailing: IconButton(
                            tooltip: e.leaf ? 'Download' : 'Download as zip',
                            icon: const Icon(Icons.download),
                            onPressed: () async {
                              final name = (e.filename ?? e.text).replaceAll(
                                '/',
                                '_',
                              );
                              final home =
                                  Platform.environment['HOME'] ??
                                  Directory.systemTemp.path;
                              final downloads = Directory('$home/Downloads');
                              if (!downloads.existsSync())
                                downloads.createSync(recursive: true);
                              final save =
                                  '${downloads.path}/$name${e.leaf ? '' : '.zip'}';
                              try {
                                await api.downloadFile(
                                  store,
                                  snap,
                                  e.filepath,
                                  save,
                                );
                                _snack(c, 'Saved to $save');
                              } catch (error) {
                                _snack(c, '$error');
                              }
                            },
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    ),
  );
}

/// [showDialog] that disposes [owned] once the dialog route is removed, not
/// when its future completes — the exit animation still builds the fields.
Future<T?> _ownedDialog<T>({
  required Iterable<ChangeNotifier> owned,
  required BuildContext context,
  required WidgetBuilder builder,
}) => showDialog<T>(
  context: context,
  builder: (context) => _Owns(owned: owned.toList(), child: builder(context)),
);

class _Owns extends StatefulWidget {
  const _Owns({required this.owned, required this.child});

  final List<ChangeNotifier> owned;
  final Widget child;

  @override
  State<_Owns> createState() => _OwnsState();
}

class _OwnsState extends State<_Owns> {
  @override
  void dispose() {
    for (final notifier in widget.owned) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
