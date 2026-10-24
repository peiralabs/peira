import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pbs_api.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'pbs_providers.g.dart';

class PbsNotConfigured implements Exception {
  const PbsNotConfigured();
}

enum PbsSlot { one, two }

enum PbsTaskFilter { all, failed, running }

class PbsJobOverview {
  const PbsJobOverview(this.job, this.status);
  final PbsJob job;
  final PbsJobStatus status;
}

class PbsOverviewData {
  const PbsOverviewData({
    required this.version,
    required this.datastores,
    required this.jobs,
  });
  final Map<String, dynamic> version;
  final List<PbsDatastoreUsage> datastores;
  final List<PbsJobOverview> jobs;
}

@Riverpod(keepAlive: true)
class SelectedPbsSlot extends _$SelectedPbsSlot {
  @override
  Future<PbsSlot> build() async {
    final settings = await ref.watch(settingsControllerProvider.future);
    if (settings.pbs1Configured) return PbsSlot.one;
    if (settings.pbs2Configured) return PbsSlot.two;
    throw const PbsNotConfigured();
  }

  void select(PbsSlot slot) => state = AsyncData(slot);
}

@riverpod
Future<PbsServerConfig> pbsConfig(Ref ref, PbsSlot slot) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  final configured = switch (slot) {
    PbsSlot.one => settings.pbs1Configured,
    PbsSlot.two => settings.pbs2Configured,
  };
  if (!configured) throw const PbsNotConfigured();
  return switch (slot) {
    PbsSlot.one => PbsServerConfig.slot1(settings),
    PbsSlot.two => PbsServerConfig.slot2(settings),
  };
}

@riverpod
Future<PbsApi> pbsApi(Ref ref, PbsSlot slot) async =>
    PbsApi.fromSlot(await ref.watch(pbsConfigProvider(slot).future));

@Riverpod(keepAlive: true)
class PbsElevation extends _$PbsElevation {
  @override
  Map<PbsSlot, PbsTicket> build() => const {};

  Future<PbsApi> elevate(PbsSlot slot, String password) async {
    final api = await ref.read(pbsApiProvider(slot).future);
    try {
      final ticket = await api.login(password);
      state = {...state, slot: ticket};
      return api.withTicket(ticket);
    } on PbsTfaRequired {
      throw const PbsTfaRequired();
    }
  }

  void lock(PbsSlot slot) => state = {...state}..remove(slot);
  void lockAll() => state = const {};

  Future<PbsApi?> elevatedApi(PbsSlot slot) async {
    final ticket = state[slot];
    if (ticket == null) return null;
    if (ticket.expired) {
      lock(slot);
      return null;
    }
    return (await ref.read(pbsApiProvider(slot).future)).withTicket(ticket);
  }
}

@riverpod
Future<PbsOverviewData> pbsOverview(Ref ref, PbsSlot slot) async {
  final api = await ref.watch(pbsApiProvider(slot).future);
  autoRefresh(ref);
  final version = await api.version();
  final stores = await api.datastores();
  final datastores = await Future.wait(stores.map(api.datastoreStatus));
  final jobLists = await Future.wait([
    api.pruneJobs(),
    api.verifyJobs(),
    api.syncJobs(),
  ]);
  final jobs = jobLists.expand((items) => items).toList();
  return PbsOverviewData(
    version: version,
    datastores: datastores,
    jobs: await Future.wait([
      for (final job in jobs)
        api
            .jobStatus(job.kind, job.id)
            .then((status) => PbsJobOverview(job, status)),
    ]),
  );
}

@riverpod
Future<List<String>> pbsNamespaces(Ref ref, PbsSlot slot, String store) async {
  autoRefresh(ref);
  return (await ref.watch(pbsApiProvider(slot).future)).namespaces(store);
}

@riverpod
Future<List<PbsGroup>> pbsGroups(
  Ref ref,
  PbsSlot slot,
  String store,
  String ns,
) async {
  autoRefresh(ref);
  return (await ref.watch(
    pbsApiProvider(slot).future,
  )).groups(store, ns: ns.isEmpty ? null : ns);
}

@riverpod
Future<List<PbsSnapshot>> pbsSnapshots(
  Ref ref,
  PbsSlot slot,
  String store,
  String ns,
  String type,
  String id,
) async {
  autoRefresh(ref);
  return (await ref.watch(
    pbsApiProvider(slot).future,
  )).snapshots(store, ns: ns.isEmpty ? null : ns, type: type, id: id);
}

@riverpod
Future<List<PbsTask>> pbsTasks(
  Ref ref,
  PbsSlot slot,
  PbsTaskFilter filter,
) async {
  autoRefresh(ref);
  final tasks = await (await ref.watch(pbsApiProvider(slot).future)).tasks(
    errorsOnly: filter == PbsTaskFilter.failed,
    running: filter == PbsTaskFilter.running,
  );
  if (filter != PbsTaskFilter.failed) return tasks;
  return [
    for (final task in tasks)
      if ('${task.raw['status'] ?? task.raw['exitstatus'] ?? ''}' != 'OK') task,
  ];
}
