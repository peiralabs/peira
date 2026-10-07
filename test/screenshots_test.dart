// Machine-independent visual regression tests for key screens. Every screen
// renders in both brightness modes under Alchemist's CI-golden configuration.
@Tags(['golden'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:alchemist/alchemist.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/app.dart';
import 'package:peira/core/api/ask_api.dart';
import 'package:peira/core/api/loki_api.dart';
import 'package:peira/core/api/ollama_api.dart';
import 'package:peira/core/api/prometheus_api.dart';
import 'package:peira/core/api/proxmox_api.dart';
import 'package:peira/core/api/twin_api.dart';
import 'package:peira/core/build_config.dart';
import 'package:peira/core/models/app_settings.dart';
import 'package:peira/core/models/grafana_alert.dart';
import 'package:peira/core/models/media_server_status.dart';
import 'package:peira/core/models/proxmox_container.dart';
import 'package:peira/core/models/proxmox_node.dart';
import 'package:peira/core/models/proxmox_task.dart';
import 'package:peira/core/models/proxmox_vm.dart';
import 'package:peira/core/models/radarr_movie.dart';
import 'package:peira/core/models/servarr_queue_item.dart';
import 'package:peira/core/models/tailscale_status.dart';
import 'package:peira/core/providers/cluster_history_providers.dart';
import 'package:peira/core/providers/grafana_providers.dart';
import 'package:peira/core/providers/loki_providers.dart';
import 'package:peira/core/providers/media_providers.dart';
import 'package:peira/core/providers/metrics_providers.dart';
import 'package:peira/core/providers/ollama_providers.dart';
import 'package:peira/core/providers/proxmox_providers.dart';
import 'package:peira/core/providers/settings_providers.dart';
import 'package:peira/core/providers/tailscale_providers.dart';
import 'package:peira/core/settings/settings_repository.dart';
import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';
import 'package:peira/core/widgets/astrolabe.dart';
import 'package:peira/core/widgets/command_palette.dart';
import 'package:peira/core/widgets/instrument_gauge.dart';
import 'package:peira/screens/ask/ask_screen.dart';
import 'package:peira/screens/hermes/hermes_screen.dart';
import 'package:peira/screens/metrics/metrics_screen.dart';
import 'package:peira/screens/proxmox/ct_detail_screen.dart';
import 'package:peira/screens/proxmox/failed_tasks_screen.dart';
import 'package:peira/screens/proxmox/node_detail_screen.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);
  AppSettings _settings;
  @override
  Future<AppSettings> load() async => _settings;
  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

/// 'dark' | 'light' — doubles as the golden suffix and the settings
/// themeMode value.
String _modeName(Brightness brightness) =>
    brightness == Brightness.dark ? 'dark' : 'light';

/// HomeLabApp resolves ThemeMode from settings.themeMode — pin the fixture
/// per variant so each golden exercises the real selection path.
AppSettings _withMode(AppSettings settings, Brightness brightness) =>
    settings.copyWith(themeMode: _modeName(brightness));

/// For screens pumped in a bare MaterialApp (no HomeLabApp theme wiring).
ThemeData _appTheme(Brightness brightness) =>
    brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();

/// Seeds the dashboard sparkline so the golden shows a real trend curve
/// instead of the "collecting…" placeholder.
class _SeededCpuHistory extends ClusterCpuHistory {
  @override
  List<double> build() => const [
    4, 5, 6, 5, 7, 6, 8, 7, 6, 9, //
    8, 7, 6, 8, 22, 34, 18, 10, 8, 7,
  ];
}

/// Seeds each node's CPU history so the node cards show their micro-sparkline
/// instead of a bare gauge.
class _SeededNodeCpuHistory extends NodeCpuHistory {
  @override
  Map<String, List<double>> build() => const {
    'node1': [5, 6, 4, 7, 6, 8, 5, 7, 6, 7, 5, 7],
    'node2': [2, 3, 2, 4, 3, 2, 3, 4, 3, 2, 3, 3],
    'node3': [8, 10, 9, 12, 14, 11, 10, 13, 12, 11, 13, 12],
    'node4': [4, 5, 3, 6, 5, 4, 5, 6, 4, 5, 4, 5],
  };
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);
  final Map<String, String> routes;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = routes[options.uri.path] ?? '{"data":null}';
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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

const _configured = AppSettings(
  proxmoxUrl: 'https://pve.example:8006',
  proxmoxTokenId: 'user@pve!token',
  proxmoxTokenSecret: 'secret',
  grafanaUrl: 'http://grafana.example:3000',
  grafanaApiKey: 'test-grafana-key',
  ollamaUrl: 'http://ollama.example:8080',
  ollamaApiUrl: 'http://ollama.example:11434',
  hermesUrl: 'http://hermes.example',
  hermesApiUrl: 'http://hermes.example:8642',
  hermesApiKey: 'test-hermes-key',
  wikiUrl: 'http://wiki.example:3000',
);

const _ollamaModels = [
  OllamaModel(
    name: 'qwen2.5:14b',
    sizeBytes: 9663676416,
    parameterSize: '14B',
    quantization: 'Q4_K_M',
  ),
  OllamaModel(
    name: 'llama3.1:8b',
    sizeBytes: 5046586573,
    parameterSize: '8B',
    quantization: 'Q4_K_M',
  ),
  OllamaModel(
    name: 'nomic-embed-text',
    sizeBytes: 287309824,
    parameterSize: '137M',
    quantization: 'F16',
  ),
];
const _ollamaRunning = {'qwen2.5:14b'};

const _nodes = [
  ProxmoxNode(
    node: 'node1',
    status: 'online',
    cpu: 0.07,
    mem: 9 << 30,
    maxmem: 16 << 30,
    disk: 38 << 30,
    maxdisk: 90 << 30,
  ),
  ProxmoxNode(
    node: 'node2',
    status: 'online',
    cpu: 0.03,
    mem: 5 << 30,
    maxmem: 8 << 30,
    disk: 21 << 30,
    maxdisk: 74 << 30,
  ),
  ProxmoxNode(
    node: 'node3',
    status: 'online',
    cpu: 0.12,
    mem: 6 << 30,
    maxmem: 8 << 30,
    disk: 46 << 30,
    maxdisk: 90 << 30,
  ),
  ProxmoxNode(
    node: 'node4',
    status: 'online',
    cpu: 0.05,
    mem: 10 << 30,
    maxmem: 16 << 30,
    disk: 52 << 30,
    maxdisk: 120 << 30,
  ),
];

const _cts = [
  ProxmoxContainer(
    vmid: 100,
    status: 'running',
    name: 'ollama-node1',
    node: 'node1',
    mem: 9 << 30,
    maxmem: 14 << 30,
  ),
  ProxmoxContainer(
    vmid: 107,
    status: 'running',
    name: 'hermesagent',
    node: 'node1',
    mem: 1 << 30,
    maxmem: 2 << 30,
  ),
  ProxmoxContainer(
    vmid: 104,
    status: 'running',
    name: 'minecraft-box',
    node: 'node4',
    mem: 3 << 30,
    maxmem: 4 << 30,
  ),
  ProxmoxContainer(
    vmid: 108,
    status: 'stopped',
    name: 'explore-minecraft',
    node: 'node4',
  ),
];

const _vms = [
  ProxmoxVm(
    vmid: 201,
    status: 'running',
    name: 'win11-desktop',
    node: 'node2',
    mem: 6 << 30,
    maxmem: 8 << 30,
  ),
  ProxmoxVm(vmid: 202, status: 'stopped', name: 'ubuntu-server', node: 'node3'),
];

/// Believable per-node series for the Metrics golden: gentle waves with
/// distinct baselines so the four lines separate visually.
ClusterMetrics _fakeMetrics() {
  List<(double, double)> wave(double base, double amp, double phase) => [
    for (var i = 0; i < 72; i++)
      (
        1752900000 + i * 60.0,
        base + amp * math.sin(i / 9 + phase) + (i % 5) * amp * 0.06,
      ),
  ];
  List<MetricSeries> panel(double base, double amp) => [
    for (final (i, n) in ['node1', 'node2', 'node3', 'node4'].indexed)
      MetricSeries(label: n, points: wave(base + i * amp * 0.5, amp, i * 1.7)),
  ];
  return ClusterMetrics(
    cpu: panel(8, 6),
    memory: panel(45, 8),
    disk: panel(30, 2),
    network: panel((2 << 20).toDouble(), (1 << 20).toDouble()),
    temps: panel(46, 5),
  );
}

MetricsInsights _fakeInsights() => const MetricsInsights(
  targetsUp: 8,
  targetsTotal: 8,
  diskRunwayDays: {'node1': 412, 'node2': 388, 'node3': 74, 'node4': 520},
  topGuests: [
    GuestLoad(
      id: 'lxc/104',
      name: 'minecraft-box',
      node: 'node4',
      cpuPct: 38,
      memPct: 71,
    ),
    GuestLoad(
      id: 'lxc/100',
      name: 'ollama-node1',
      node: 'node1',
      cpuPct: 22,
      memPct: 64,
    ),
    GuestLoad(
      id: 'qemu/201',
      name: 'win11-desktop',
      node: 'node2',
      cpuPct: 12,
      memPct: 55,
    ),
    GuestLoad(
      id: 'lxc/105',
      name: 'monitoring',
      node: 'node2',
      cpuPct: 6,
      memPct: 48,
    ),
    GuestLoad(
      id: 'lxc/107',
      name: 'hermesagent',
      node: 'node1',
      cpuPct: 3,
      memPct: 39,
    ),
  ],
);

/// Deterministic AI telemetry for the Metrics golden: three token sources,
/// p50/p95 latency, and a stat strip exercising both ok and warn lights.
AiMetrics _fakeAiMetrics() {
  List<(double, double)> wave(double base, double amp, double phase) => [
    for (var i = 0; i < 72; i++)
      (1752900000 + i * 60.0, base + amp * math.sin(i / 9 + phase)),
  ];
  return AiMetrics(
    tokens: [
      MetricSeries(label: 'Hermes', points: wave(220000, 90000, 0)),
      MetricSeries(label: 'Claude Code', points: wave(90000, 40000, 1.3)),
      MetricSeries(label: 'Codex', points: wave(30000, 15000, 2.6)),
    ],
    latency: [
      MetricSeries(label: 'p50', points: wave(2.1, 0.6, 0)),
      MetricSeries(label: 'p95', points: wave(6.4, 1.8, 0.9)),
    ],
    hermesCostUsd: 0.42,
    claudeCodeCostUsd: 1.87,
    codexQuotaPct: 14,
    cacheHitPct: 93,
    fallbacks: 2,
  );
}

/// Deterministic UPS power telemetry for the Metrics golden: a steady draw
/// off the CyberPower, on line at full charge, with a modelled cost so the
/// energy + $/mo + $/yr cards all render.
PowerMetrics _fakePowerMetrics() {
  final points = [
    for (var i = 0; i < 72; i++)
      (1752900000 + i * 60.0, 118 + 14 * math.sin(i / 8) + (i % 6) * 2.0),
  ];
  return PowerMetrics(
    watts: 126,
    loadPct: 12.6,
    batteryPct: 100,
    runtimeSeconds: 11425,
    inputVolts: 118,
    online: true,
    onBattery: false,
    lowBattery: false,
    avgWatts24h: 121,
    model: 'CP1500PFCLCDa',
    power: [MetricSeries(label: 'CP1500PFCLCDa', points: points)],
    rateUsdPerKwh: 0.30,
  );
}

/// Deterministic disk-health data mirroring the live fleet: four node NVMe
/// (scraped) + four NAS RAID bays (pushed), all SMART-passed, with the real
/// wear/temperature spread so the section renders believably.
SmartHealth _fakeSmartHealth() {
  List<(double, double)> wave(double base, double amp, double phase) => [
    for (var i = 0; i < 72; i++)
      (1752900000 + i * 60.0, base + amp * math.sin(i / 10 + phase)),
  ];
  DiskHealth nvme(String host, String model, double temp, double wear) =>
      DiskHealth(
        host: host,
        device: '/dev/nvme0',
        model: model,
        passed: true,
        tempC: temp,
        wearPct: wear,
        mediaErrors: 0,
        criticalWarning: 0,
        reallocated: null,
        pending: null,
      );
  DiskHealth bay(String device, double temp) => DiskHealth(
    host: 'nas',
    device: device,
    model: 'ST8000VN0022-2EL112',
    passed: true,
    tempC: temp,
    wearPct: null,
    mediaErrors: null,
    criticalWarning: null,
    reallocated: 0,
    pending: 0,
  );
  final disks = [
    nvme('node1', 'SAMSUNG MZVLB512HAJQ-000H7', 49, 6),
    nvme('node2', 'KBG30ZMV256G TOSHIBA', 59, 14),
    nvme('node3', 'WDC PC SN520 SDAPNUW-256G-1006', 61, 8),
    nvme('node4', 'WDC PC SN720 SDAQNTW-512G-1006', 45, 4),
    bay('/dev/sda', 54),
    bay('/dev/sdb', 50),
    bay('/dev/sdc', 54),
    bay('/dev/sdd', 53),
  ];
  return SmartHealth(
    disks: disks,
    temps: [
      for (final (i, d) in disks.indexed)
        MetricSeries(
          label: '${d.host} ${d.shortDevice}',
          points: wave(d.tempC! - 1, 1.6, i * 0.9),
        ),
    ],
  );
}

/// Deterministic WAN/offsite data mirroring the live pipeline's first day:
/// asymmetric circuits, a direct tailnet path, and the offsite rate pinned
/// under the model line by the still-active NAS buffer clamp.
WanMetrics _fakeWanMetrics() {
  List<(double, double)> wave(double base, double amp, double phase) => [
    for (var i = 0; i < 72; i++)
      (1752900000 + i * 60.0, base + amp * math.sin(i / 7 + phase)),
  ];
  return WanMetrics(
    circuits: [
      MetricSeries(label: 'home ↓', points: wave(925e6, 28e6, 0)),
      MetricSeries(label: 'home ↑', points: wave(103e6, 7e6, 1.1)),
      MetricSeries(label: 'office ↓', points: wave(85e6, 6e6, 2.2)),
      MetricSeries(label: 'office ↑', points: wave(45e6, 4e6, 3.3)),
    ],
    offsite: [
      MetricSeries(label: 'offsite write', points: wave(382e3, 55e3, 0.4)),
    ],
    siteDownBps: const {'home': 925.5e6, 'office': 85.0e6},
    siteUpBps: const {'home': 103.6e6, 'office': 44.6e6},
    pathOnline: true,
    pathDirect: true,
    pathRttMs: 47,
    pathLossPct: 0,
    offsiteBps: 385572,
    rmemMaxBytes: 212992,
    rcvbufErrDelta: 41200,
  );
}

/// Log lines for the Logs golden: journal-shaped traffic across all five
/// hosts, one failure line exercising the trouble tint.
const _lokiHosts = ['nas', 'node1', 'node2', 'node3', 'node4'];

List<LokiEntry> _fakeLokiEntries() {
  final base = DateTime.utc(2026, 8, 18, 19, 45, 12);
  const rows = [
    ('node4', 'pvedaemon', 'INFO: starting new backup job: vzdump 104'),
    ('node4', 'vzdump', 'INFO: Finished Backup of VM 104 (00:02:11)'),
    ('nas', 'dockerd', 'level=info msg="volume mount ok" container=plex'),
    ('node2', 'systemd', 'Started Proxmox VE replication runner.'),
    ('node1', 'alloy', 'level=info msg="tailing journal" path=/var/log'),
    ('node3', 'kernel', 'usb 1-4: new high-speed USB device number 7'),
    ('nas', 'systemd', 'alloy.service: Failed with result exit-code'),
    ('node1', 'pveproxy', 'worker 2214 finished'),
    ('node2', 'cron', '(root) CMD (/usr/local/bin/speedtest_push.py)'),
    ('node4', 'smartd', 'Device /dev/nvme0, SMART status: PASSED'),
  ];
  return [
    for (final (i, r) in rows.indexed)
      LokiEntry(
        ts: base.subtract(Duration(seconds: i * 47)),
        host: r.$1,
        unit: r.$2,
        line: r.$3,
      ),
  ];
}

/// Deterministic what-if planner data mirroring the live twin's shapes: three
/// clean node-loss verdicts, plus node4 exercising the crit (stranded) and
/// warn (PBS-lost) paths in one card.
TwinData _fakeTwinData() => const TwinData(
  scenarios: [
    TwinScenario(
      node: 'node1',
      fits: true,
      guests: 3,
      placements: [
        TwinPlacement(
          vmid: 100,
          name: 'ollama-node1',
          target: 'node4',
          demandGib: 3.2,
        ),
        TwinPlacement(
          vmid: 107,
          name: 'hermesagent',
          target: 'node2',
          demandGib: 0.9,
        ),
        TwinPlacement(
          vmid: 109,
          name: 'demo-lab',
          target: 'node4',
          demandGib: 0.6,
        ),
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
        TwinPlacement(
          vmid: 105,
          name: 'monitoring',
          target: 'node1',
          demandGib: 0.5,
        ),
        TwinPlacement(
          vmid: 101,
          name: 'ollama-node2',
          target: 'node1',
          demandGib: 0.4,
        ),
      ],
      strandedNames: [],
      recoveryMinutes: 2,
      pbsLost: false,
    ),
    TwinScenario(
      node: 'node3',
      fits: true,
      guests: 3,
      placements: [
        TwinPlacement(
          vmid: 102,
          name: 'ollama-node3',
          target: 'node4',
          demandGib: 0.4,
        ),
        TwinPlacement(
          vmid: 103,
          name: 'open-webui',
          target: 'node1',
          demandGib: 0.5,
        ),
        TwinPlacement(
          vmid: 106,
          name: 'wikijs',
          target: 'node1',
          demandGib: 0.3,
        ),
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
        TwinPlacement(
          vmid: 108,
          name: 'explore-minecraft',
          target: 'node1',
          demandGib: 1.4,
        ),
      ],
      strandedNames: ['minecraft-box'],
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
      largestFit: 'minecraft-box (1.6 GiB)',
    ),
    TwinHeadroomNode(
      node: 'node2',
      totalGib: 7.2,
      freeGib: 4.3,
      vcpuRatio: 0.75,
      localLvmFreeGib: 81.4,
      largestFit: 'minecraft-box (1.6 GiB)',
    ),
    TwinHeadroomNode(
      node: 'node3',
      totalGib: 7.2,
      freeGib: 3.6,
      vcpuRatio: 0.88,
      localLvmFreeGib: 55.7,
      largestFit: 'ollama-node2 (1.9 GiB)',
    ),
    TwinHeadroomNode(
      node: 'node4',
      totalGib: 15.1,
      freeGib: 7.2,
      vcpuRatio: 1.0,
      localLvmFreeGib: 305.4,
      largestFit: 'ollama-node1 (3.2 GiB)',
    ),
  ],
);

String _fixture(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();

/// Recent cluster window for the failed-tasks screen: two failures among
/// ordinary traffic. Absolute epochs — the screen renders absolute times, so
/// the goldens stay deterministic.
const _tasksWithFailures = [
  ProxmoxTask(
    upid: 'UPID:node4:000A1B2C:00F00001:6A490B34:vzdump:108:root@pam:',
    node: 'node4',
    type: 'vzdump',
    id: '108',
    starttime: 1783080001,
    endtime: 1783080034,
    status:
        "unable to activate storage 'nas-backup' - directory "
        "'/mnt/pve/nas-backup' does not exist or is unreachable",
  ),
  ProxmoxTask(
    upid: 'UPID:node2:000B2C3D:00F00002:6A491C45:qmstart:202:root@pam:',
    node: 'node2',
    type: 'qmstart',
    id: '202',
    starttime: 1783085000,
    endtime: 1783085003,
    status: 'start failed: QEMU exited with code 1',
  ),
  ProxmoxTask(
    upid: 'UPID:node4:000A1C99:00F10800:6A492000:vzdump:104:root@pam:',
    node: 'node4',
    type: 'vzdump',
    id: '104',
    starttime: 1783091488,
    endtime: 1783091559,
    status: 'OK',
  ),
  ProxmoxTask(
    upid: 'UPID:node3:000C0001:00F40000:6A495000:aptupdate::root@pam:',
    node: 'node3',
    type: 'aptupdate',
    starttime: 1783059050,
    endtime: 1783059054,
    status: 'OK',
  ),
];

final _alerts = [
  GrafanaAlert(
    labels: const {'alertname': 'Disk Usage High', 'severity': 'warning'},
    annotations: const {'summary': 'node3 / at 82%'},
    startsAt: DateTime.utc(2026, 7, 4, 8),
  ),
  GrafanaAlert(
    labels: const {
      'alertname': 'Container Not Running',
      'severity': 'critical',
    },
    annotations: const {'summary': 'CT 108 explore-minecraft stopped'},
    startsAt: DateTime.utc(2026, 7, 4, 9),
  ),
];

typedef _GoldenPump = Future<void> Function(Widget child);

class _GoldenStage extends StatelessWidget {
  const _GoldenStage(this.child);

  final ValueListenable<Widget> child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Widget>(
    valueListenable: child,
    builder: (context, value, _) => value,
  );
}

void main() {
  /// Defines one screen as two CI goldens so every screen is checked in both
  /// brightness modes. [pump] builds the tree and runs any interactions;
  /// it receives the target brightness and must route it through the real
  /// theme path for that screen (settings.themeMode for HomeLabApp pumps,
  /// AppTheme.dark()/light() for bare MaterialApp pumps).
  void screenshotBoth(
    String description,
    String golden,
    Future<void> Function(
      WidgetTester tester,
      Brightness brightness,
      _GoldenPump pumpWidget,
    )
    pump, {
    bool directCapture = false,
  }) {
    for (final brightness in const [Brightness.dark, Brightness.light]) {
      final mode = _modeName(brightness);
      final stagedChild = ValueNotifier<Widget>(const SizedBox.shrink());

      goldenTest(
        'screenshot: $description ($mode)',
        fileName: '${golden}_$mode',
        constraints: const BoxConstraints.tightFor(width: 1200, height: 800),
        builder: () => _GoldenStage(stagedChild),
        pumpWidget: directCapture
            ? (tester, alchemistWrapper) async {
                // CommandPalette.show targets the root navigator. Alchemist's
                // normal wrapper adds a navigator outside the app, so retain
                // its capture keys but remove that extra navigator for this
                // nested full-app case.
                await tester.pumpWidget(alchemistWrapper);
                final stageElement = find
                    .byType(_GoldenStage)
                    .evaluate()
                    .single;
                Key? alchemistChildKey;
                stageElement.visitAncestorElements((ancestor) {
                  if (ancestor.widget case Center(key: final Key key)) {
                    alchemistChildKey = key;
                    return false;
                  }
                  return true;
                });
                assert(alchemistChildKey != null);
                await tester.pumpWidget(
                  RepaintBoundary(
                    key: alchemistWrapper.key,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: 1200,
                        minHeight: 800,
                        maxWidth: 1200,
                        maxHeight: 800,
                        child: SizedBox(
                          key: alchemistChildKey,
                          width: 1200,
                          height: 800,
                          child: stageElement.widget,
                        ),
                      ),
                    ),
                  ),
                );
              }
            : onlyPumpWidget,
        pumpBeforeTest: (tester) async {
          addTearDown(stagedChild.dispose);
          await pump(tester, brightness, (child) async {
            stagedChild.value = child;
            await tester.pump();
          });
        },
      );
    }
  }

  // Personal-only screens (Ask, What-if/twin, AI-telemetry) are compiled out of
  // the public build, so their cases would navigate to widgets that don't exist.
  // Skip them when kPublicBuild; they still run in the personal build.
  void screenshotPersonal(
    String description,
    String golden,
    Future<void> Function(
      WidgetTester tester,
      Brightness brightness,
      _GoldenPump pumpWidget,
    )
    pump,
  ) {
    if (kPublicBuild) return;
    screenshotBoth(description, golden, pump);
  }

  screenshotBoth('dashboard', 'dashboard', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_withMode(_configured, brightness)),
          ),
          ollamaModelsProvider.overrideWith((ref) async => _ollamaModels),
          ollamaRunningProvider.overrideWith((ref) async => _ollamaRunning),
          nodesProvider.overrideWith((ref) async => _nodes),
          allContainersProvider.overrideWith((ref) async => _cts),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
          activeAlertsProvider.overrideWith((ref) async => _alerts),
          allVmsProvider.overrideWith((ref) async => _vms),
          clusterCpuHistoryProvider.overrideWith(_SeededCpuHistory.new),
          nodeCpuHistoryProvider.overrideWith(_SeededNodeCpuHistory.new),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
  });

  screenshotBoth('command palette', 'command_palette', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_withMode(_configured, brightness)),
          ),
          ollamaModelsProvider.overrideWith((ref) async => _ollamaModels),
          ollamaRunningProvider.overrideWith((ref) async => _ollamaRunning),
          nodesProvider.overrideWith((ref) async => _nodes),
          allContainersProvider.overrideWith((ref) async => _cts),
          allVmsProvider.overrideWith((ref) async => _vms),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
          activeAlertsProvider.overrideWith((ref) async => _alerts),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(CommandPalette),
        matching: find.byType(TextField),
      ),
      'lab',
    );
    await tester.pumpAndSettle();
  }, directCapture: true);

  screenshotBoth('tailscale tab', 'tailscale_tab', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_withMode(_configured, brightness)),
          ),
          ollamaModelsProvider.overrideWith((ref) async => _ollamaModels),
          ollamaRunningProvider.overrideWith((ref) async => _ollamaRunning),
          nodesProvider.overrideWith((ref) async => _nodes),
          allContainersProvider.overrideWith((ref) async => _cts),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    // The rail scrolls; the System section can sit below the fold, where a
    // blind tap lands on the pinned Settings item instead.
    await tester.ensureVisible(find.text('Tailscale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tailscale'));
    await tester.pumpAndSettle();
  });

  screenshotBoth('proxmox tab', 'proxmox_tab', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    // The wide split layout embeds the live CT detail pane, which polls a
    // real client — back it with fixture responses.
    final api = ProxmoxApi(
      Dio(BaseOptions(baseUrl: 'https://x/api2/json'))
        ..httpClientAdapter = _FakeAdapter({
          '/api2/json/nodes/node4/lxc/104/status/current': _fixture(
            'container_status',
          ),
          '/api2/json/nodes/node4/lxc/104/config':
              '{"data":{"hostname":"minecraft-box","ostype":"debian",'
              '"cores":2,"memory":4096,'
              '"net0":"name=eth0,bridge=vmbr0,ip=10.0.0.74/24"}}',
          '/api2/json/nodes/node4/lxc/104/snapshot':
              '{"data":[{"name":"pre-modpack","snaptime":1751600000,'
              '"description":"before adding mods"},{"name":"current"}]}',
        }),
    );
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_withMode(_configured, brightness)),
          ),
          ollamaModelsProvider.overrideWith((ref) async => _ollamaModels),
          ollamaRunningProvider.overrideWith((ref) async => _ollamaRunning),
          proxmoxApiProvider.overrideWith((ref) async => api),
          nodesProvider.overrideWith((ref) async => _nodes),
          allContainersProvider.overrideWith((ref) async => _cts),
          allVmsProvider.overrideWith((ref) async => _vms),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proxmox'));
    await tester.pumpAndSettle();
    // Select a container into the detail pane, then pump the poll timer
    // explicitly (pumpAndSettle would never settle on the periodic timer).
    // The brass node cards make the list pane taller than the viewport, so
    // the guest rows build lazily — drag until the target row exists.
    await tester.dragUntilVisible(
      find.textContaining('minecraft-box'),
      find.byType(ListView).first,
      const Offset(0, -220),
    );
    await tester.pump();
    await tester.tap(find.textContaining('minecraft-box').first);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 5));
    }
    await tester.pump(const Duration(milliseconds: 300));
  });

  // Closure (not a declaration) so the overrides-list type is inferred —
  // riverpod 3 doesn't re-export the sealed Override type, so a declaration
  // couldn't name its return type.
  // ignore: prefer_function_declarations_over_variables
  final metricsTabOverrides = (Brightness brightness) => [
    // No network in widget tests — pin reachability pills to healthy.
    serviceReachableProvider.overrideWith((ref, url) async => true),
    settingsRepositoryProvider.overrideWithValue(
      _FakeSettingsRepository(_withMode(_configured, brightness)),
    ),
    ollamaModelsProvider.overrideWith((ref) async => _ollamaModels),
    ollamaRunningProvider.overrideWith((ref) async => _ollamaRunning),
    nodesProvider.overrideWith((ref) async => _nodes),
    allContainersProvider.overrideWith((ref) async => _cts),
    allVmsProvider.overrideWith((ref) async => _vms),
    recentTasksProvider.overrideWith((ref) async => const []),
    tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
    activeAlertsProvider.overrideWith((ref) async => _alerts),
    clusterMetricsProvider.overrideWith((ref) async => _fakeMetrics()),
    metricsInsightsProvider.overrideWith((ref) async => _fakeInsights()),
    aiMetricsProvider.overrideWith((ref) async => _fakeAiMetrics()),
    powerMetricsProvider.overrideWith((ref) async => _fakePowerMetrics()),
    twinDataProvider.overrideWith((ref) async => _fakeTwinData()),
    smartHealthProvider.overrideWith((ref) async => _fakeSmartHealth()),
    wanMetricsProvider.overrideWith((ref) async => _fakeWanMetrics()),
    lokiHostsProvider.overrideWith((ref) async => _lokiHosts),
    lokiTailProvider.overrideWith((ref, filter) async => _fakeLokiEntries()),
  ];

  screenshotBoth('metrics tab', 'metrics_tab', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: metricsTabOverrides(brightness),
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
  });

  // The AI-telemetry section lives below the 1200x800 fold — a second golden
  // scrolled down to it keeps the section eyeball-inspectable.
  screenshotPersonal('metrics tab AI section', 'metrics_tab_ai', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: metricsTabOverrides(brightness),
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(MetricsScreen),
      matching: find.byType(ListView),
    );
    await tester.dragUntilVisible(
      find.text('AI telemetry'),
      list,
      const Offset(0, -260),
    );
    await tester.drag(list, const Offset(0, -520));
    await tester.pumpAndSettle();
  });

  // The what-if planner is the last section — scroll to its header, then
  // clamp to the list end so the scenario cards + headroom + form all show.
  screenshotPersonal('metrics tab what-if section', 'metrics_tab_twin', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: metricsTabOverrides(brightness),
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(MetricsScreen),
      matching: find.byType(ListView),
    );
    await tester.dragUntilVisible(
      find.text('What-if planner'),
      list,
      const Offset(0, -260),
    );
    await tester.drag(list, const Offset(0, -800));
    await tester.pumpAndSettle();
  });

  // The Power & cost section sits between AI telemetry and the what-if
  // planner — scroll to its header so the status strip, power chart, and
  // energy/cost cards are all eyeball-inspectable.
  screenshotBoth('metrics tab power section', 'metrics_tab_power', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: metricsTabOverrides(brightness),
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(MetricsScreen),
      matching: find.byType(ListView),
    );
    await tester.dragUntilVisible(
      find.text('Power & cost'),
      list,
      const Offset(0, -260),
    );
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
  });

  // The Disk-health section (both builds) sits below Power & cost — scroll
  // to its header so the summary cards, temperature chart, and disk rows
  // are eyeball-inspectable.
  screenshotBoth('metrics tab disk health', 'metrics_tab_smart', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: metricsTabOverrides(brightness),
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(MetricsScreen),
      matching: find.byType(ListView),
    );
    await tester.dragUntilVisible(
      find.text('Disk health'),
      list,
      const Offset(0, -260),
    );
    await tester.drag(list, const Offset(0, -560));
    await tester.pumpAndSettle();
  });

  // The WAN & offsite section (personal build) follows Disk health — scroll
  // to its header so the path strip, circuit cards, and both charts show.
  screenshotPersonal('metrics tab WAN section', 'metrics_tab_wan', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: metricsTabOverrides(brightness),
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(MetricsScreen),
      matching: find.byType(ListView),
    );
    await tester.dragUntilVisible(
      find.text('WAN & offsite path'),
      list,
      const Offset(0, -260),
    );
    await tester.drag(list, const Offset(0, -620));
    await tester.pumpAndSettle();
  });

  // The native Loki tail behind the Metrics hub's Logs sub-tab.
  screenshotBoth('logs tab', 'logs_tab', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: metricsTabOverrides(brightness),
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
  });

  screenshotBoth('setup wizard', 'setup_wizard', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    // Unconfigured repo → the first-run wizard (t_abe366ce) gates the shell;
    // themeMode stays 'system', so the mode resolves through the platform
    // brightness instead of the settings path.
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(const AppSettings()),
          ),
          nodesProvider.overrideWith((ref) async => _nodes),
          allContainersProvider.overrideWith((ref) async => _cts),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
  });

  screenshotBoth('media tab (Radarr)', 'media_tab', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    const media = AppSettings(
      proxmoxUrl: 'https://pve.example:8006',
      proxmoxTokenId: 'user@pve!token',
      proxmoxTokenSecret: 'secret',
      radarrUrl: 'http://nas.example:7878',
      radarrApiKey: 'radarr-key',
    );
    const movies = [
      RadarrMovie(
        id: 1,
        title: 'Dune: Part Two',
        year: 2024,
        monitored: true,
        hasFile: true,
        sizeOnDisk: 18 << 30,
      ),
      RadarrMovie(
        id: 2,
        title: 'The Batman',
        year: 2022,
        monitored: true,
        hasFile: true,
        sizeOnDisk: 24 << 30,
      ),
      RadarrMovie(
        id: 3,
        title: 'Project Hail Mary',
        year: 2026,
        monitored: true,
      ),
    ];
    final queue = [
      const ServarrQueueItem(
        id: 9,
        title: 'Oppenheimer 2023 2160p',
        status: 'downloading',
        size: 30 << 30,
        sizeleft: 12 << 30,
        timeleft: '00:14:20',
      ),
    ];
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_withMode(media, brightness)),
          ),
          nodesProvider.overrideWith((ref) async => _nodes),
          allContainersProvider.overrideWith((ref) async => _cts),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
          radarrMoviesProvider.overrideWith((ref) async => movies),
          radarrQueueProvider.overrideWith((ref) async => queue),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Media'));
    await tester.pumpAndSettle();
    // The media servers now lead the strip — this shot stays on Radarr.
    await tester.tap(find.text('Radarr').first);
    await tester.pumpAndSettle();
  });

  screenshotBoth('media tab (Jellyfin)', 'media_tab_jellyfin', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    const media = AppSettings(
      proxmoxUrl: 'https://pve.example:8006',
      proxmoxTokenId: 'user@pve!token',
      proxmoxTokenSecret: 'secret',
      jellyfinUrl: 'http://media.example:8096',
      jellyfinApiKey: 'jf-key',
    );
    const status = MediaServerStatus(
      serverName: 'den-jellyfin',
      version: '10.10.3',
      sessions: [
        MediaSession(
          user: 'living-room',
          title: 'Cold Harbor',
          subtitle: 'Severance',
          progress: 0.42,
        ),
        MediaSession(
          user: 'tablet',
          title: 'Dune: Part Two',
          subtitle: '2024',
          paused: true,
          progress: 0.71,
        ),
      ],
      libraries: [
        MediaLibrary(name: 'Movies', count: 412),
        MediaLibrary(name: 'Shows', count: 58),
        MediaLibrary(name: 'Episodes', count: 3210),
      ],
      recent: [
        MediaRecentItem(title: 'Slow Horses', subtitle: 'Season 4'),
        MediaRecentItem(title: 'The Batman', subtitle: '2022'),
        MediaRecentItem(title: 'Andor', subtitle: 'Season 2'),
      ],
    );
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_withMode(media, brightness)),
          ),
          nodesProvider.overrideWith((ref) async => _nodes),
          allContainersProvider.overrideWith((ref) async => _cts),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
          jellyfinStatusProvider.overrideWith((ref) async => status),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Media'));
    await tester.pumpAndSettle();
  });

  screenshotBoth('ct detail with live charts', 'ct_detail', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    // Real client against fixture responses; CPU/RAM samples accumulate as
    // the 5s poll timer fires.
    final api = ProxmoxApi(
      Dio(BaseOptions(baseUrl: 'https://x/api2/json'))
        ..httpClientAdapter = _FakeAdapter({
          '/api2/json/nodes/node4/lxc/104/status/current': _fixture(
            'container_status',
          ),
          '/api2/json/nodes/node4/lxc/104/config':
              '{"data":{"hostname":"minecraft-box","ostype":"debian",'
              '"cores":2,"memory":4096,'
              '"net0":"name=eth0,bridge=vmbr0,ip=10.0.0.74/24"}}',
          '/api2/json/nodes/node4/lxc/104/snapshot':
              '{"data":[{"name":"pre-modpack","snaptime":1751600000,'
              '"description":"before adding mods"},'
              '{"name":"clean-install","snaptime":1751500000,'
              '"description":""},{"name":"current"}]}',
        }),
    );
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_configured),
          ),
          ollamaModelsProvider.overrideWith((ref) async => _ollamaModels),
          ollamaRunningProvider.overrideWith((ref) async => _ollamaRunning),
          proxmoxApiProvider.overrideWith((ref) async => api),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _appTheme(brightness),
          home: CtDetailScreen(container: _cts[2]),
        ),
      ),
    );
    // Let the poll timer fire enough times to fill the charts, then let the
    // chart's implicit animation finish. pumpAndSettle would never settle
    // (periodic timer), so pump explicitly.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 5));
    }
    await tester.pump(const Duration(milliseconds: 300));
  });

  screenshotBoth('ollama tab', 'ollama_tab', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_withMode(_configured, brightness)),
          ),
          ollamaModelsProvider.overrideWith((ref) async => _ollamaModels),
          ollamaRunningProvider.overrideWith((ref) async => _ollamaRunning),
          nodesProvider.overrideWith((ref) async => _nodes),
          allContainersProvider.overrideWith((ref) async => _cts),
          allVmsProvider.overrideWith((ref) async => _vms),
          recentTasksProvider.overrideWith((ref) async => const []),
          tailscaleStatusProvider.overrideWith((ref) async => _tailscale),
          activeAlertsProvider.overrideWith((ref) async => _alerts),
        ],
        child: const HomeLabApp(),
      ),
    );
    await tester.pumpAndSettle();
    // The model library is the AI hub's Models sub-view.
    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Models'));
    await tester.pumpAndSettle();
  });

  screenshotBoth('hermes tab', 'hermes_tab', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    const transcript = <HermesTurn>[
      (
        role: 'assistant',
        text:
            'Good morning, User. All 4 Proxmox nodes are nominal and '
            '10/10 guests are running. One backup task failed overnight — '
            'the qbittorrent CT snapshot on node3.',
      ),
      (role: 'user', text: 'Why did the snapshot fail?'),
      (
        role: 'assistant',
        text:
            'Storage pool "local-zfs" on node3 was at 94% when the '
            'job ran. The snapshot needs ~6 GB free. I can prune the three '
            'oldest vzdump archives to reclaim ~22 GB — want me to queue '
            'that?',
      ),
      (role: 'user', text: 'Yes, prune them and retry the snapshot.'),
    ];
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_configured),
          ),
          ollamaModelsProvider.overrideWith((ref) async => _ollamaModels),
          ollamaRunningProvider.overrideWith((ref) async => _ollamaRunning),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _appTheme(brightness),
          home: const Scaffold(body: HermesScreen(testTranscript: transcript)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  screenshotPersonal('ask tab', 'ask_tab', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    const transcript = <AskEntry>[
      AskEntry(role: 'user', text: 'Why did media-sync page at 5am?'),
      AskEntry(
        role: 'assistant',
        text:
            'Uptime Kuma\'s media-sync heartbeat paged after Plex Cloud '
            'returned 522s and timeouts [1]. The hardened plex_get() now '
            'retries 3× with backoff and only pages after 3 consecutive '
            'failed runs (~45 min) — real local failures still page '
            'immediately [2].',
        sources: [
          AskSource(
            n: 1,
            wikiPath: 'journal/2026-07-22-media-sync-plex-cloud-denoise',
            anchor: 'alert',
            title: 'Media-sync Plex-cloud flap de-noise',
            heading: 'Alert',
            score: 0.7,
            snippet:
                'Uptime Kuma media-sync heartbeat paged down with '
                'Fatal: TimeoutError and HTTPError 522.',
          ),
          AskSource(
            n: 2,
            wikiPath: 'journal/2026-07-22-media-sync-plex-cloud-denoise',
            anchor: 'fix',
            title: 'Media-sync Plex-cloud flap de-noise',
            heading: 'Fix',
            score: 0.65,
            snippet:
                'plex_get() retry+backoff; degradation counter pages '
                'only after PLEX_DEGRADE_RUNS consecutive fails.',
          ),
        ],
        revision: '1e76a95bb35ee6bfa70529c5b6d7388ebc408006',
        model: 'claude-haiku-4-5-20251001',
      ),
      AskEntry(role: 'user', text: 'And the NAS double-hop?'),
      AskEntry(
        role: 'assistant',
        text:
            'Reach the NAS via ssh homelab, then ssh '
            'admin@100.64.0.76. For anything non-trivial, base64-pipe a '
            'script file through the hop — stdin piping silently exits 2 [1].',
        sources: [
          AskSource(
            n: 1,
            wikiPath: 'runbooks/claude/hardware-operations',
            anchor: 'nas-command-transport',
            title: 'Hardware Operations',
            heading: 'NAS command transport',
            score: 0.72,
            snippet:
                'Write a script to a file and base64-pipe it through '
                'the double-hop.',
          ),
        ],
        revision: '1e76a95bb35ee6bfa70529c5b6d7388ebc408006',
        stale: true,
        model: 'claude-haiku-4-5-20251001',
      ),
    ];
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_configured),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _appTheme(brightness),
          home: const Scaffold(body: AskScreen(testTranscript: transcript)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  screenshotBoth('brass instruments', 'brass_instruments', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    await pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _appTheme(brightness),
          home: Scaffold(
            backgroundColor: Brass.resolve(brightness).bg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Astrolabe(size: 220),
                      SizedBox(width: 40),
                      Astrolabe(size: 96, detail: AstrolabeDetail.compact),
                      SizedBox(width: 40),
                      Astrolabe(size: 46, detail: AstrolabeDetail.compact),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gauge metric colors are brightness-shared (they draw on
                      // the kept-dark instrument face), so the dark set is fine.
                      InstrumentGauge(
                        fraction: 0.02,
                        color: Brass.dark.gaugeCpu,
                        display: '2%',
                      ),
                      const SizedBox(width: 18),
                      InstrumentGauge(
                        fraction: 0.32,
                        color: Brass.dark.gaugeMemory,
                        display: '32%',
                      ),
                      const SizedBox(width: 18),
                      InstrumentGauge(
                        fraction: 0.20,
                        color: Brass.dark.gaugeStorage,
                        display: '20%',
                      ),
                      const SizedBox(width: 18),
                      InstrumentGauge(
                        fraction: 1,
                        color: Brass.dark.gaugeContainers,
                        display: '10/10',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  screenshotBoth('failed tasks', 'failed_tasks', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    // Tiles auto-expand and fetch each task's log from the API.
    final api = ProxmoxApi(
      Dio(BaseOptions(baseUrl: 'https://x/api2/json'))
        ..httpClientAdapter = _FakeAdapter({
          '/api2/json/nodes/node4/tasks/${_tasksWithFailures[0].upid}/log':
              _fixture('task_log'),
          '/api2/json/nodes/node2/tasks/${_tasksWithFailures[1].upid}/log':
              '{"data":[{"n":1,"t":"start failed: QEMU exited with code 1"},'
              '{"n":2,"t":"TASK ERROR: start failed: QEMU exited with '
              'code 1"}]}',
        }),
    );
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_configured),
          ),
          proxmoxApiProvider.overrideWith((ref) async => api),
          recentTasksProvider.overrideWith((ref) async => _tasksWithFailures),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _appTheme(brightness),
          home: const FailedTasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  screenshotBoth('node detail', 'node_detail', (
    tester,
    brightness,
    pumpWidget,
  ) async {
    // The screen polls a real client (status/rrddata/storage/tasks) and the
    // guest families call through the same fake adapter.
    final api = ProxmoxApi(
      Dio(BaseOptions(baseUrl: 'https://x/api2/json'))
        ..httpClientAdapter = _FakeAdapter({
          '/api2/json/nodes/node4/status': _fixture('node_status'),
          '/api2/json/nodes/node4/rrddata': _fixture('node_rrddata'),
          '/api2/json/nodes/node4/storage': _fixture('node_storage'),
          '/api2/json/nodes/node4/tasks': _fixture('node_tasks'),
          '/api2/json/nodes/node4/lxc': _fixture('containers'),
        }),
    );
    await pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability pills to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(_configured),
          ),
          proxmoxApiProvider.overrideWith((ref) async => api),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _appTheme(brightness),
          home: NodeDetailScreen(node: _nodes[3]),
        ),
      ),
    );
    // One load cycle fills everything (RRD arrives with history); pump past
    // the async fetches + chart animation without tripping the 30s pollers.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 5));
    }
    await tester.pump(const Duration(milliseconds: 300));
  });
}
