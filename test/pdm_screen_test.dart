import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/pdm_api.dart';
import 'package:peira/core/navigation/app_tab.dart';
import 'package:peira/core/providers/navigation_providers.dart';
import 'package:peira/core/providers/pdm_providers.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/screens/pdm/pdm_migrate_dialog.dart';
import 'package:peira/screens/pdm/pdm_screen.dart';

class _MigrationCall {
  const _MigrationCall({
    required this.remote,
    required this.kind,
    required this.vmid,
    required this.target,
    required this.storageMap,
    required this.bridgeMap,
    required this.targetVmid,
    required this.delete,
    this.online,
    this.restart,
    this.timeout,
  });
  final String remote;
  final String kind;
  final int vmid;
  final String target;
  final Map<String, String> storageMap;
  final Map<String, String> bridgeMap;
  final int? targetVmid;
  final bool delete;
  final bool? online;
  final bool? restart;
  final int? timeout;
}

class _FakePdmApi extends PdmApi {
  _FakePdmApi() : super(Dio());

  final actions = <String>[];
  final migrations = <_MigrationCall>[];

  /// Status reads that throw before the real answer (a busy PDM).
  int statusFailures = 0;

  static const office = PdmRemoteInfo(
    id: 'office',
    type: 'pve',
    endpoints: ['100.64.0.70'],
  );
  static const lab = PdmRemoteInfo(
    id: 'lab',
    type: 'pve',
    endpoints: ['10.0.0.2', '100.64.0.80'],
  );
  static const broken = PdmRemoteInfo(
    id: 'broken',
    type: 'pve',
    endpoints: ['10.0.0.3'],
  );
  static const backup = PdmRemoteInfo(id: 'backup', type: 'pbs', endpoints: []);

  static const iacGuest = PdmGuest(
    remote: 'office',
    kind: 'qemu',
    vmid: 101,
    name: 'iac-vm',
    node: 'office-1',
    status: 'stopped',
    template: false,
    cpu: 0,
    maxcpu: 2,
    mem: 0,
    maxmem: 2 << 30,
    disk: 0,
    maxdisk: 20 << 30,
    uptime: 0,
    tags: ['iac'],
  );
  static const rawGuest = PdmGuest(
    remote: 'office',
    kind: 'lxc',
    vmid: 102,
    name: 'gpu-ct',
    node: 'office-1',
    status: 'stopped',
    template: false,
    cpu: 0,
    maxcpu: 2,
    mem: 0,
    maxmem: 2 << 30,
    disk: 0,
    maxdisk: 10 << 30,
    uptime: 0,
    tags: ['gpu'],
  );
  static const runningCt = PdmGuest(
    remote: 'office',
    kind: 'lxc',
    vmid: 103,
    name: 'web-ct',
    node: 'office-1',
    status: 'running',
    template: false,
    cpu: .1,
    maxcpu: 2,
    mem: 1 << 30,
    maxmem: 2 << 30,
    disk: 4 << 30,
    maxdisk: 10 << 30,
    uptime: 100,
    tags: ['web'],
  );
  static const labGuest = PdmGuest(
    remote: 'lab',
    kind: 'qemu',
    vmid: 201,
    name: 'database-vm',
    node: 'lab-1',
    status: 'running',
    template: false,
    cpu: .2,
    maxcpu: 4,
    mem: 2 << 30,
    maxmem: 4 << 30,
    disk: 10 << 30,
    maxdisk: 40 << 30,
    uptime: 200,
    tags: ['db'],
  );

  @override
  Future<List<PdmRemoteInfo>> remotes() async => const [
    office,
    lab,
    broken,
    backup,
  ];

  @override
  Future<PdmClusterStatus> clusterStatus(String remote) async {
    if (remote == 'broken') {
      throw const PdmApiException(502, 'remote unavailable');
    }
    return PdmClusterStatus(
      name: remote,
      quorate: true,
      nodesOnline: 1,
      nodesTotal: 1,
    );
  }

  @override
  Future<PdmResources> resources(String remote) async {
    if (remote == 'broken') {
      throw const PdmApiException(502, 'remote unavailable');
    }
    if (remote == 'office') {
      return const PdmResources(
        nodes: [
          PdmNode(
            remote: 'office',
            name: 'office-1',
            status: 'online',
            cpu: .1,
            maxcpu: 8,
            mem: 8 << 30,
            maxmem: 16 << 30,
            uptime: 1,
          ),
        ],
        guests: [iacGuest, rawGuest, runningCt],
        storages: [
          PdmStorage(
            remote: 'office',
            storage: 'local-lvm',
            node: 'office-1',
            shared: false,
            status: 'available',
            used: 10 << 30,
            total: 100 << 30,
          ),
        ],
      );
    }
    return const PdmResources(
      nodes: [
        PdmNode(
          remote: 'lab',
          name: 'lab-1',
          status: 'online',
          cpu: .2,
          maxcpu: 8,
          mem: 4 << 30,
          maxmem: 16 << 30,
          uptime: 1,
        ),
      ],
      guests: [labGuest],
      storages: [
        PdmStorage(
          remote: 'lab',
          storage: 'local-lvm',
          node: 'lab-1',
          shared: false,
          status: 'available',
          used: 5 << 30,
          total: 100 << 30,
        ),
      ],
    );
  }

  @override
  Future<PdmGuestConfig> guestConfig(
    String remote,
    String kind,
    int vmid,
  ) async => PdmGuestConfig(
    unprivileged: vmid != 103,
    hasRawLxcKeys: vmid == 102,
    storages: const {'local-lvm'},
    bridges: const {'vmbr0'},
  );

  @override
  Future<int> nextId(String remote) async => 250;

  @override
  Future<List<String>> bridges(String remote, String node) async => const [
    'vmbr0',
  ];

  @override
  Future<String> guestAction(
    String remote,
    String kind,
    int vmid,
    String action,
  ) async {
    actions.add(action);
    return 'UPID:$action';
  }

  @override
  Future<PdmTaskStatus> taskStatus(String remote, String upid) async {
    if (statusFailures > 0) {
      statusFailures--;
      throw const PdmApiException(503, 'busy');
    }
    return const PdmTaskStatus(running: false, exitStatus: 'OK');
  }

  @override
  Future<String> remoteMigrate(
    String remote,
    String kind,
    int vmid, {
    required String target,
    required Map<String, String> storageMap,
    required Map<String, String> bridgeMap,
    int? targetVmid,
    bool delete = true,
    bool? online,
    bool? restart,
    int? timeout,
    int? bwlimitKiB,
    String? targetEndpoint,
  }) async {
    migrations.add(
      _MigrationCall(
        remote: remote,
        kind: kind,
        vmid: vmid,
        target: target,
        storageMap: Map.of(storageMap),
        bridgeMap: Map.of(bridgeMap),
        targetVmid: targetVmid,
        delete: delete,
        online: online,
        restart: restart,
        timeout: timeout,
      ),
    );
    return 'UPID:migrate';
  }

  /// What `/remotes/tasks/list?errors=1` really returns: WARNINGS too.
  List<PdmTask> taskRows = const [];

  @override
  Future<List<PdmTask>> tasks({
    int limit = 200,
    bool errorsOnly = false,
    bool runningOnly = false,
  }) async => taskRows;
}

Future<void> _pump(
  WidgetTester tester,
  _FakePdmApi api, {
  Widget? child,
}) async {
  tester.view.physicalSize = const Size(1500, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [pdmApiProvider.overrideWith((ref) async => api)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: child ?? PdmScreen(railIndex: AppTab.pdm.railIndex),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _guestsTab(WidgetTester tester) async {
  await tester.tap(find.text('Guests'));
  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester, String remote, int vmid) async {
  await tester.tap(find.byKey(ValueKey('pdm-menu-$remote-$vmid')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('not-configured state links to Settings', (tester) async {
    final container = ProviderContainer(
      overrides: [
        pdmApiProvider.overrideWith(
          (ref) async => throw const PdmNotConfigured(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: PdmScreen(railIndex: AppTab.pdm.railIndex)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'PDM is not configured — add its URL and an API token in Settings',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Open Settings'));
    expect(container.read(selectedTabProvider), AppTab.settings.railIndex);
    await tester.pump(const Duration(minutes: 1)); // drain retry backoff
  });

  testWidgets('not-configured state shows while the provider is retrying', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        pdmApiProvider.overrideWith(
          (ref) async => throw const PdmNotConfigured(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: PdmScreen(railIndex: AppTab.pdm.railIndex)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(
        'PDM is not configured — add its URL and an API token in Settings',
      ),
      findsOneWidget,
    );
    // Run out Riverpod's retry backoff so no timer outlives the test (the
    // static view schedules no frames, so pumpAndSettle would not wait).
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('overview shows remotes, PBS, and a compact per-remote error', (
    tester,
  ) async {
    await _pump(tester, _FakePdmApi());
    expect(find.text('office'), findsOneWidget);
    expect(find.text('lab'), findsOneWidget);
    expect(find.text('backup'), findsOneWidget);
    expect(find.text('PBS'), findsOneWidget);
    expect(find.text('broken'), findsOneWidget);
    expect(find.text('remote unavailable'), findsOneWidget);
  });

  testWidgets('guest list merges remotes and search filters all fields', (
    tester,
  ) async {
    await _pump(tester, _FakePdmApi());
    await _guestsTab(tester);
    expect(find.text('web-ct'), findsOneWidget);
    expect(find.text('database-vm'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('pdm-guest-search')),
      'db',
    );
    await tester.pump();
    expect(find.text('database-vm'), findsOneWidget);
    expect(find.text('web-ct'), findsNothing);
  });

  testWidgets('IaC-tagged guest disables migration and explains why', (
    tester,
  ) async {
    await _pump(tester, _FakePdmApi());
    await _guestsTab(tester);
    await _openMenu(tester, 'office', 101);
    expect(find.textContaining('Managed by OpenTofu'), findsNWidgets(2));
    // PBS remotes cannot receive a guest, so they are never offered.
    expect(find.textContaining('Migrate to backup'), findsNothing);
    final item = tester.widget<PopupMenuItem<String>>(
      find
          .ancestor(
            of: find.textContaining('Managed by OpenTofu'),
            matching: find.byType(PopupMenuItem<String>),
          )
          .first,
    );
    expect(item.enabled, isFalse);
  });

  testWidgets('raw lxc guest disables migration after configuration check', (
    tester,
  ) async {
    await _pump(tester, _FakePdmApi());
    await _guestsTab(tester);
    await _openMenu(tester, 'office', 102);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await _openMenu(tester, 'office', 102);
    expect(find.textContaining('Has raw lxc.* keys'), findsNWidgets(2));
  });

  testWidgets(
    'migration prefills next id and submits CT maps and restart flags',
    (tester) async {
      final api = _FakePdmApi();
      final overview = [
        PdmRemoteOverview(
          remote: _FakePdmApi.office,
          clusterStatus: await api.clusterStatus('office'),
          resources: await api.resources('office'),
        ),
        PdmRemoteOverview(
          remote: _FakePdmApi.lab,
          clusterStatus: await api.clusterStatus('lab'),
          resources: await api.resources('lab'),
        ),
      ];
      await _pump(
        tester,
        api,
        child: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PdmMigrateDialog(
                  guest: _FakePdmApi.runningCt,
                  target: _FakePdmApi.lab,
                  config: const PdmGuestConfig(
                    unprivileged: false,
                    hasRawLxcKeys: false,
                    storages: {'local-lvm'},
                    bridges: {'vmbr0'},
                  ),
                  overview: overview,
                ),
              ),
              child: const Text('Open migration'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open migration'));
      await tester.pumpAndSettle();
      final vmid = tester.widget<TextFormField>(
        find.byKey(const ValueKey('pdm-target-vmid')),
      );
      expect(vmid.controller!.text, '250');
      await tester.tap(find.byKey(const ValueKey('pdm-migrate-submit')));
      await tester.pump();
      expect(api.migrations, hasLength(1));
      final call = api.migrations.single;
      expect(call.target, 'lab');
      expect(call.targetVmid, 250);
      expect(call.storageMap, {'local-lvm': 'local-lvm'});
      expect(call.bridgeMap, {'vmbr0': 'vmbr0'});
      expect(call.delete, isTrue);
      expect(call.restart, isTrue);
      expect(call.timeout, 180);
      expect(call.online, isNull);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('reboot waits for shutdown success before starting', (
    tester,
  ) async {
    final api = _FakePdmApi();
    await _pump(tester, api);
    await _guestsTab(tester);
    await _openMenu(tester, 'office', 103);
    await tester.tap(find.text('Reboot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(api.actions, ['shutdown']);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(api.actions, ['shutdown', 'start']);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('a few failed status reads do not fail a running job', (
    tester,
  ) async {
    final api = _FakePdmApi()..statusFailures = 3;
    await _pump(tester, api);
    await _guestsTab(tester);
    await _openMenu(tester, 'office', 103);
    await tester.tap(find.text('Reboot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    }
    expect(api.actions, ['shutdown'], reason: 'still waiting, not failed');
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(api.actions, ['shutdown', 'start']);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('Failed shows real failures only, with the reason on its own '
      'line', (tester) async {
    PdmTask row(String id, String status) => PdmTask(
      remote: 'office',
      upid: 'pve:office!UPID:n:1:2:3:x:$id:root@pam:',
      node: 'office-1',
      workerType: 'x',
      workerId: id,
      user: 'root@pam',
      start: DateTime.utc(2026, 10, 21),
      end: DateTime.utc(2026, 10, 21, 0, 0, 1),
      status: status,
    );
    final api = _FakePdmApi()
      ..taskRows = [
        row('warned', 'WARNINGS: 1'),
        row('broken', 'permission check failed - missing Datastore.Prune'),
      ];
    await _pump(tester, api);
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Failed'));
    await tester.pumpAndSettle();

    expect(find.textContaining('warned'), findsNothing);
    expect(find.textContaining('broken'), findsOneWidget);
    expect(find.text('failed'), findsOneWidget, reason: 'short chip');
    expect(
      find.text('permission check failed - missing Datastore.Prune'),
      findsWidgets,
    );
  });
}
