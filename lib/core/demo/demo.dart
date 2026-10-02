import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ollama_api.dart';
import '../api/prometheus_api.dart';
import '../api/proxmox_api.dart';
import '../api/twin_api.dart';
import '../models/app_settings.dart';
import '../models/grafana_alert.dart';
import '../models/media_server_status.dart';
import '../models/proxmox_container.dart';
import '../models/proxmox_node.dart';
import '../models/proxmox_vm.dart';
import '../models/tailscale_status.dart';
import '../providers/cluster_history_providers.dart';
import '../providers/grafana_providers.dart';
import '../providers/media_providers.dart';
import '../providers/metrics_providers.dart';
import '../providers/ollama_providers.dart';
import '../providers/proxmox_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/tailscale_providers.dart';
import '../settings/settings_repository.dart';
import '../widgets/ai_status_strip.dart';

/// Demo mode: a fully populated, obviously-fake lab with no configuration
/// and no network access — `./Peira.AppImage --demo` (or `MOL_DEMO=1`).
///
/// Every value below is documentation-space by construction (node1…node4,
/// 10.0.0.x, `user@pve!token`) and the whole file ships in the public tree,
/// so it must stay clean for tool/check_public_markers.dart. It reuses the
/// provider-override pattern the widget tests established: overridden
/// providers never construct their network clients, and the one API object
/// that drill-in screens create is backed by an adapter that answers every
/// route with an empty body — graceful empty states, zero sockets.
bool isDemoRequested(List<String> args) =>
    args.contains('--demo') || Platform.environment['MOL_DEMO'] == '1';

/// False in normal runs; overridden to true inside [demoOverrides] so the
/// shell can show the persistent banner.
final demoModeProvider = Provider<bool>((_) => false);

/// The persistent strip above the tab content while demo mode is active.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined,
                size: 16, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'DEMO DATA — every node, guest, and number here is fake',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoSettingsRepository implements SettingsRepository {
  AppSettings _settings = _demoSettings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

/// Answers every HTTP route with an empty Proxmox envelope so drill-in
/// screens (CT detail, node detail) render empty states instead of opening
/// sockets.
class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString('{"data":null}', 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

const _demoSettings = AppSettings(
  proxmoxUrl: 'https://10.0.0.5:8006',
  proxmoxTokenId: 'user@pve!token',
  proxmoxTokenSecret: 'demo',
  ollamaUrl: 'http://10.0.0.7:8080',
  ollamaApiUrl: 'http://10.0.0.7:11434',
  jellyfinUrl: 'http://10.0.0.9:8096',
  jellyfinApiKey: 'demo',
  sshTargets: 'node1=root@10.0.0.5\nnas=admin@10.0.0.9',
);

const _nodes = [
  ProxmoxNode(
      node: 'node1',
      status: 'online',
      cpu: 0.07,
      mem: 9 << 30,
      maxmem: 16 << 30,
      disk: 38 << 30,
      maxdisk: 90 << 30),
  ProxmoxNode(
      node: 'node2',
      status: 'online',
      cpu: 0.03,
      mem: 5 << 30,
      maxmem: 8 << 30,
      disk: 21 << 30,
      maxdisk: 74 << 30),
  ProxmoxNode(
      node: 'node3',
      status: 'online',
      cpu: 0.12,
      mem: 6 << 30,
      maxmem: 8 << 30,
      disk: 46 << 30,
      maxdisk: 90 << 30),
  ProxmoxNode(
      node: 'node4',
      status: 'online',
      cpu: 0.05,
      mem: 10 << 30,
      maxmem: 16 << 30,
      disk: 52 << 30,
      maxdisk: 120 << 30),
];

const _cts = [
  ProxmoxContainer(
      vmid: 100,
      status: 'running',
      name: 'ollama-box',
      node: 'node1',
      mem: 9 << 30,
      maxmem: 14 << 30),
  ProxmoxContainer(
      vmid: 105,
      status: 'running',
      name: 'monitoring',
      node: 'node2',
      mem: 1 << 30,
      maxmem: 2 << 30),
  ProxmoxContainer(
      vmid: 106,
      status: 'running',
      name: 'wiki',
      node: 'node3',
      mem: 1 << 30,
      maxmem: 2 << 30),
  ProxmoxContainer(
      vmid: 104,
      status: 'running',
      name: 'minecraft',
      node: 'node4',
      mem: 3 << 30,
      maxmem: 4 << 30),
  ProxmoxContainer(vmid: 108, status: 'stopped', name: 'valheim', node: 'node4'),
];

const _vms = [
  ProxmoxVm(
      vmid: 201,
      status: 'running',
      name: 'win11-desktop',
      node: 'node2',
      mem: 6 << 30,
      maxmem: 8 << 30),
  ProxmoxVm(vmid: 202, status: 'stopped', name: 'ubuntu-server', node: 'node3'),
];

const _tailscale = TailscaleStatus(
  backendState: 'Running',
  self: TailscaleDevice(
    hostName: 'laptop',
    tailscaleIPs: ['100.64.0.10'],
    os: 'linux',
    online: true,
  ),
  peer: {
    'k1': TailscaleDevice(
      hostName: 'node4',
      tailscaleIPs: ['100.64.0.20'],
      os: 'linux',
      online: true,
      exitNodeOption: true,
    ),
    'k2': TailscaleDevice(
      hostName: 'old-phone',
      tailscaleIPs: ['100.64.0.30'],
      os: 'android',
    ),
  },
);

const _ollamaModels = [
  OllamaModel(
      name: 'qwen2.5:14b',
      sizeBytes: 9663676416,
      parameterSize: '14B',
      quantization: 'Q4_K_M'),
  OllamaModel(
      name: 'llama3.1:8b',
      sizeBytes: 5046586573,
      parameterSize: '8B',
      quantization: 'Q4_K_M'),
  OllamaModel(
      name: 'nomic-embed-text',
      sizeBytes: 287309824,
      parameterSize: '137M',
      quantization: 'F16'),
];

final _alerts = [
  GrafanaAlert(
    labels: const {'alertname': 'Disk Usage High', 'severity': 'warning'},
    annotations: const {'summary': 'node3 / at 82%'},
    startsAt: DateTime.utc(2026, 7, 4, 8),
  ),
  GrafanaAlert(
    labels: const {'alertname': 'Container Not Running', 'severity': 'critical'},
    annotations: const {'summary': 'CT 108 valheim stopped'},
    startsAt: DateTime.utc(2026, 7, 4, 9),
  ),
];

const _jellyfin = MediaServerStatus(
  serverName: 'Demo Jellyfin',
  version: '10.10.3',
  sessions: [
    MediaSession(
        user: 'alex', title: 'The Expanse S02E05', subtitle: 'The Expanse', progress: .41),
  ],
  libraries: [
    MediaLibrary(name: 'Movies', count: 412),
    MediaLibrary(name: 'Shows', count: 87),
    MediaLibrary(name: 'Music', count: 1204),
  ],
  recent: [
    MediaRecentItem(title: 'Dune: Part Two', subtitle: '2024'),
    MediaRecentItem(title: 'Severance S02E01', subtitle: 'Severance'),
  ],
);

class _DemoClusterCpuHistory extends ClusterCpuHistory {
  @override
  List<double> build() => const [
        4, 5, 6, 5, 7, 6, 8, 7, 6, 9, //
        8, 7, 6, 8, 22, 34, 18, 10, 8, 7,
      ];
}

class _DemoNodeCpuHistory extends NodeCpuHistory {
  @override
  Map<String, List<double>> build() => const {
        'node1': [5, 6, 4, 7, 6, 8, 5, 7, 6, 7, 5, 7],
        'node2': [2, 3, 2, 4, 3, 2, 3, 4, 3, 2, 3, 3],
        'node3': [8, 10, 9, 12, 14, 11, 10, 13, 12, 11, 13, 12],
        'node4': [4, 5, 3, 6, 5, 4, 5, 6, 4, 5, 4, 5],
      };
}

List<(double, double)> _wave(double base, double amp, double phase) => [
      for (var i = 0; i < 72; i++)
        (
          1752900000 + i * 60.0,
          base + amp * math.sin(i / 9 + phase) + (i % 5) * amp * 0.06,
        ),
    ];

ClusterMetrics _metrics() {
  List<MetricSeries> panel(double base, double amp) => [
        for (final (i, n) in ['node1', 'node2', 'node3', 'node4'].indexed)
          MetricSeries(label: n, points: _wave(base + i * amp * 0.5, amp, i * 1.7)),
      ];
  return ClusterMetrics(
    cpu: panel(8, 6),
    memory: panel(45, 8),
    disk: panel(30, 2),
    network: panel((2 << 20).toDouble(), (1 << 20).toDouble()),
    temps: panel(46, 5),
  );
}

const _insights = MetricsInsights(
  targetsUp: 8,
  targetsTotal: 8,
  diskRunwayDays: {'node1': 412, 'node2': 388, 'node3': 74, 'node4': 520},
  topGuests: [
    GuestLoad(id: 'lxc/104', name: 'minecraft', node: 'node4', cpuPct: 38, memPct: 71),
    GuestLoad(id: 'lxc/100', name: 'ollama-box', node: 'node1', cpuPct: 22, memPct: 64),
    GuestLoad(id: 'qemu/201', name: 'win11-desktop', node: 'node2', cpuPct: 12, memPct: 55),
    GuestLoad(id: 'lxc/105', name: 'monitoring', node: 'node2', cpuPct: 6, memPct: 48),
    GuestLoad(id: 'lxc/106', name: 'wiki', node: 'node3', cpuPct: 3, memPct: 39),
  ],
);

PowerMetrics _power() => PowerMetrics(
      watts: 126,
      loadPct: 12.6,
      batteryPct: 100,
      runtimeSeconds: 11425,
      inputVolts: 118,
      online: true,
      onBattery: false,
      lowBattery: false,
      avgWatts24h: 121,
      model: 'Demo UPS 1500',
      power: [
        MetricSeries(label: 'Demo UPS 1500', points: _wave(120, 10, 0)),
      ],
      rateUsdPerKwh: 0.30,
    );

const _twin = TwinData(
  scenarios: [
    TwinScenario(
      node: 'node1',
      fits: true,
      guests: 1,
      placements: [
        TwinPlacement(vmid: 100, name: 'ollama-box', target: 'node4', demandGib: 3.2),
      ],
      strandedNames: [],
      recoveryMinutes: 11,
      pbsLost: false,
    ),
    TwinScenario(
      node: 'node2',
      fits: true,
      guests: 2,
      placements: [
        TwinPlacement(vmid: 105, name: 'monitoring', target: 'node1', demandGib: 0.5),
        TwinPlacement(vmid: 201, name: 'win11-desktop', target: 'node1', demandGib: 6.0),
      ],
      strandedNames: [],
      recoveryMinutes: 2,
      pbsLost: false,
    ),
    TwinScenario(
      node: 'node3',
      fits: true,
      guests: 1,
      placements: [
        TwinPlacement(vmid: 106, name: 'wiki', target: 'node1', demandGib: 0.3),
      ],
      strandedNames: [],
      recoveryMinutes: 4,
      pbsLost: false,
    ),
    TwinScenario(
      node: 'node4',
      fits: false,
      guests: 2,
      placements: [
        TwinPlacement(vmid: 108, name: 'valheim', target: 'node1', demandGib: 1.4),
      ],
      strandedNames: ['minecraft'],
      recoveryMinutes: null,
      pbsLost: true,
    ),
  ],
  headroom: [
    TwinHeadroomNode(
        node: 'node1',
        totalGib: 15.1,
        freeGib: 10.5,
        vcpuRatio: 1.25,
        localLvmFreeGib: 283.9,
        largestFit: 'minecraft (1.6 GiB)'),
    TwinHeadroomNode(
        node: 'node2',
        totalGib: 7.2,
        freeGib: 4.3,
        vcpuRatio: 0.75,
        localLvmFreeGib: 81.4,
        largestFit: 'minecraft (1.6 GiB)'),
    TwinHeadroomNode(
        node: 'node3',
        totalGib: 7.2,
        freeGib: 3.6,
        vcpuRatio: 0.88,
        localLvmFreeGib: 55.7,
        largestFit: 'wiki (0.3 GiB)'),
    TwinHeadroomNode(
        node: 'node4',
        totalGib: 15.1,
        freeGib: 7.2,
        vcpuRatio: 1.0,
        localLvmFreeGib: 305.4,
        largestFit: 'ollama-box (3.2 GiB)'),
  ],
);

/// The full override set for demo mode — mirrors the union the widget and
/// screenshot tests use, so every native tab renders populated. (Type
/// inferred: riverpod 3 does not export its `Override` supertype.)
final demoOverrides = [
  demoModeProvider.overrideWithValue(true),
  settingsRepositoryProvider.overrideWithValue(_DemoSettingsRepository()),
  proxmoxApiProvider.overrideWith((ref) => ProxmoxApi(
        Dio(BaseOptions(baseUrl: '${_demoSettings.proxmoxUrl}/api2/json'))
          ..httpClientAdapter = _OfflineAdapter(),
      )),
  serviceReachableProvider.overrideWith((ref, url) async => true),
  nodesProvider.overrideWith((ref) async => _nodes),
  allContainersProvider.overrideWith((ref) async => _cts),
  allVmsProvider.overrideWith((ref) async => _vms),
  recentTasksProvider.overrideWith((ref) async => const []),
  activeAlertsProvider.overrideWith((ref) async => _alerts),
  tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
  ollamaModelsProvider.overrideWith((ref) async => _ollamaModels),
  ollamaRunningProvider.overrideWith((ref) async => {'qwen2.5:14b'}),
  jellyfinStatusProvider.overrideWith((ref) async => _jellyfin),
  clusterCpuHistoryProvider.overrideWith(_DemoClusterCpuHistory.new),
  nodeCpuHistoryProvider.overrideWith(_DemoNodeCpuHistory.new),
  clusterMetricsProvider.overrideWith((ref) async => _metrics()),
  metricsInsightsProvider.overrideWith((ref) async => _insights),
  powerMetricsProvider.overrideWith((ref) async => _power()),
  twinDataProvider.overrideWith((ref) async => _twin),
];
