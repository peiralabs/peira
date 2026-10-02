import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/prometheus_api.dart';
import '../api/twin_api.dart';
import 'refresh.dart';
import 'settings_providers.dart';

part 'metrics_providers.g.dart';

/// Thrown while no Prometheus endpoint can be derived from settings.
class PrometheusNotConfigured implements Exception {
  const PrometheusNotConfigured();
}

/// Selectable history window for the Metrics tab.
enum MetricsRange {
  h1('1h', Duration(hours: 1)),
  h6('6h', Duration(hours: 6)),
  d1('24h', Duration(days: 1)),
  w1('7d', Duration(days: 7));

  const MetricsRange(this.label, this.duration);

  final String label;
  final Duration duration;
}

/// The four cluster panels' series, one fetch per range selection.
class ClusterMetrics {
  const ClusterMetrics({
    required this.cpu,
    required this.memory,
    required this.disk,
    required this.network,
    required this.temps,
  });

  final List<MetricSeries> cpu; // % per node
  final List<MetricSeries> memory; // % per node
  final List<MetricSeries> disk; // % per node (root fs)
  final List<MetricSeries> network; // bytes/s in per node
  final List<MetricSeries> temps; // hottest sensor °C per node
}

@riverpod
class SelectedMetricsRange extends _$SelectedMetricsRange {
  @override
  MetricsRange build() => MetricsRange.h1;

  void select(MetricsRange range) => state = range;
}

@riverpod
Future<PrometheusApi> prometheusApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  if (settings.prometheusEndpoint.isEmpty) {
    throw const PrometheusNotConfigured();
  }
  return PrometheusApi.fromSettings(settings);
}

// Queries validated against the live Prometheus (node-exporter on all four
// nodes). The device regex excludes loopback and the Proxmox-generated veth/
// firewall/tap interfaces so "network" means the physical NIC.
const _cpuQ =
    '100 - avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m]))*100';
const _memQ =
    '(1 - node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes)*100';
const _diskQ =
    '(1 - node_filesystem_avail_bytes{mountpoint="/"}'
    '/node_filesystem_size_bytes{mountpoint="/"})*100';
const _netQ =
    'sum by(instance)(rate(node_network_receive_bytes_total'
    '{device!~"lo|veth.*|fwbr.*|fwln.*|fwpr.*|tap.*"}[5m]))';

@riverpod
Future<ClusterMetrics> clusterMetrics(Ref ref) async {
  final api = await ref.watch(prometheusApiProvider.future);
  final range = ref.watch(selectedMetricsRangeProvider).duration;
  autoRefresh(ref);
  final names = await api.nodeNames();
  final panels = await Future.wait([
    api.rangeQuery(_cpuQ, range: range, relabel: names),
    api.rangeQuery(_memQ, range: range, relabel: names),
    api.rangeQuery(_diskQ, range: range, relabel: names),
    api.rangeQuery(_netQ, range: range, relabel: names),
    api.rangeQuery(_tempQ, range: range, relabel: names),
  ]);
  return ClusterMetrics(
    cpu: panels[0],
    memory: panels[1],
    disk: panels[2],
    network: panels[3],
    temps: panels[4],
  );
}

/// One guest's current load, joined with its name/node via pve_guest_info.
class GuestLoad {
  const GuestLoad({
    required this.id,
    required this.name,
    required this.node,
    required this.cpuPct,
    required this.memPct,
  });

  final String id; // e.g. lxc/104 or qemu/201
  final String name;
  final String node;
  final double cpuPct;
  final double memPct;
}

/// Watchfulness layer: exporter health, disk runway, and the guests that are
/// actually consuming the cluster — the questions the four node charts can't
/// answer.
class MetricsInsights {
  const MetricsInsights({
    required this.targetsUp,
    required this.targetsTotal,
    required this.diskRunwayDays, // node name → days until root fs is full
    required this.topGuests,
  });

  final int targetsUp;
  final int targetsTotal;
  final Map<String, double> diskRunwayDays;
  final List<GuestLoad> topGuests;
}

const _guestCpuQ =
    'pve_cpu_usage_ratio * on(id, instance) group_left(name, node) '
    'pve_guest_info';
const _guestMemQ =
    '(pve_memory_usage_bytes / pve_memory_size_bytes) '
    '* on(id, instance) group_left(name, node) pve_guest_info';
// Seconds until the root filesystem hits zero at the trailing 3-day shrink
// rate; a growing filesystem clamps to a huge value (rendered as "no risk").
// A 3-day window (was 1d) smooths daily churn — a nightly backup or a big
// temp file no longer projects a false "disk full soon".
const _runwayQ =
    'node_filesystem_avail_bytes{mountpoint="/"} '
    '/ clamp_min(-deriv(node_filesystem_avail_bytes{mountpoint="/"}[3d]), '
    '1e-9)';
const _tempQ = 'max by(instance)(node_hwmon_temp_celsius)';

@riverpod
Future<MetricsInsights> metricsInsights(Ref ref) async {
  final api = await ref.watch(prometheusApiProvider.future);
  autoRefresh(ref);
  final names = await api.nodeNames();
  final results = await Future.wait([
    api.instantQuery('up'),
    api.instantQuery(_runwayQ),
    api.instantQuery(_guestCpuQ),
    api.instantQuery(_guestMemQ),
  ]);

  final up = results[0];
  final runway = {
    for (final (m, v) in results[1])
      names['${m['instance']}'] ?? '${m['instance']}': v / 86400,
  };

  final memById = {for (final (m, v) in results[3]) '${m['id']}': v * 100};
  final guests = [
    for (final (m, v) in results[2])
      GuestLoad(
        id: '${m['id']}',
        name: '${m['name'] ?? m['id']}',
        node: '${m['node'] ?? ''}',
        cpuPct: v * 100,
        memPct: memById['${m['id']}'] ?? 0,
      ),
  ]..sort((a, b) => b.cpuPct.compareTo(a.cpuPct));

  return MetricsInsights(
    targetsUp: up.where((r) => r.$2 == 1).length,
    targetsTotal: up.length,
    diskRunwayDays: runway,
    topGuests: guests.take(5).toList(),
  );
}

/// AI backend telemetry from the ai_* exporters + Claude Code OTLP pipeline
/// (CT 105/107, built 2026-07-23): what the models cost, how hard they're
/// being driven, and whether the fallback chain is firing.
class AiMetrics {
  const AiMetrics({
    required this.tokens,
    required this.latency,
    required this.hermesCostUsd,
    required this.claudeCodeCostUsd,
    required this.codexQuotaPct,
    required this.cacheHitPct,
    required this.fallbacks,
  });

  final List<MetricSeries> tokens; // per source, trailing-1h windows
  final List<MetricSeries> latency; // Hermes API p50/p95 seconds
  final double hermesCostUsd; // metered Anthropic $, selected range
  final double claudeCodeCostUsd; // subscription quota-equivalent $
  final double? codexQuotaPct; // primary (7d) window used %
  final double? cacheHitPct; // Hermes cache-read share of input, 0–100
  final double fallbacks; // fallback activations, selected range

  /// Nothing came back at all — the ai_* exporters are down or scraped away
  /// (Prometheus itself answering is what got us here without an error).
  bool get isEmpty =>
      tokens.isEmpty &&
      latency.isEmpty &&
      codexQuotaPct == null &&
      cacheHitPct == null;
}

// AI queries validated against the live Prometheus 2026-07-23. Haiku 4.5 API
// pricing baked into the cost query: $1/M input, $0.10/M cache read, $5/M
// output — Hermes's claude-* traffic is the lab's only metered spend.
// Claude Code sessions export ephemeral per-session cumulative counters, so
// totals aggregate with max_over_time per series — increase() misses short
// sessions entirely (their first sample already carries the total).
const _aiHermesTokensQ = 'sum(increase(ai_hermes_tokens_total[1h]))';
const _aiClaudeTokensQ =
    'sum(max_over_time({__name__=~"claude_code_token_usage.*"}[1h]))';
const _aiCodexTokensQ = 'sum(increase(ai_codex_tokens_total[1h]))';
const _aiLatencyP50Q =
    'histogram_quantile(0.5, '
    'sum(rate(ai_hermes_call_latency_seconds_bucket[15m])) by (le))';
const _aiLatencyP95Q =
    'histogram_quantile(0.95, '
    'sum(rate(ai_hermes_call_latency_seconds_bucket[15m])) by (le))';

// Each component is guarded with `or vector(0)`: PromQL vector arithmetic
// with one empty operand collapses the WHOLE expression to empty — an absent
// cache-read series (fresh exporter, lazily-created counter) would otherwise
// render real spend as $0.00.
String _aiHermesCostQ(String w) =>
    '((sum(increase(ai_hermes_tokens_total'
    '{model=~"claude.*",direction="in"}[$w])) or vector(0)) '
    '- (sum(increase(ai_hermes_cache_read_tokens_total'
    '{model=~"claude.*"}[$w])) or vector(0))) * 1e-6 '
    '+ (sum(increase(ai_hermes_cache_read_tokens_total'
    '{model=~"claude.*"}[$w])) or vector(0)) * 0.10e-6 '
    '+ (sum(increase(ai_hermes_tokens_total'
    '{model=~"claude.*",direction="out"}[$w])) or vector(0)) * 5e-6';
String _aiClaudeCostQ(String w) =>
    'sum(max_over_time({__name__=~"claude_code_cost_usage.*"}[$w]))';
const _aiCodexQuotaQ =
    'max(ai_codex_rate_limit_used_percent{window="primary"})';
String _aiCacheHitQ(String w) =>
    'sum(increase(ai_hermes_cache_read_tokens_total[$w])) '
    '/ sum(increase(ai_hermes_tokens_total{direction="in"}[$w]))';
String _aiFallbacksQ(String w) =>
    'sum(increase(ai_hermes_fallbacks_total[$w]))';

@riverpod
Future<AiMetrics> aiMetrics(Ref ref) async {
  final api = await ref.watch(prometheusApiProvider.future);
  final range = ref.watch(selectedMetricsRangeProvider);
  autoRefresh(ref);
  // MetricsRange labels ('1h'…'7d') are valid PromQL durations, so the stat
  // windows follow the selected range.
  final w = range.label;

  // The chart queries aggregate across labels, so each returns at most one
  // unlabelled series — name it here.
  MetricSeries named(String label, List<MetricSeries> raw) => MetricSeries(
    label: label,
    points: raw.isEmpty ? const [] : raw.first.points,
  );

  final charts = await Future.wait([
    api.rangeQuery(_aiHermesTokensQ, range: range.duration),
    api.rangeQuery(_aiClaudeTokensQ, range: range.duration),
    api.rangeQuery(_aiCodexTokensQ, range: range.duration),
    api.rangeQuery(_aiLatencyP50Q, range: range.duration),
    api.rangeQuery(_aiLatencyP95Q, range: range.duration),
  ]);
  final stats = await Future.wait([
    api.instantQuery(_aiHermesCostQ(w)),
    api.instantQuery(_aiClaudeCostQ(w)),
    api.instantQuery(_aiCodexQuotaQ),
    api.instantQuery(_aiCacheHitQ(w)),
    api.instantQuery(_aiFallbacksQ(w)),
  ]);
  double? first(List<(Map<String, dynamic>, double)> r) =>
      r.isEmpty || r.first.$2.isNaN ? null : r.first.$2;
  final cacheHit = first(stats[3]);

  return AiMetrics(
    tokens: [
      named('Hermes', charts[0]),
      named('Claude Code', charts[1]),
      named('Codex', charts[2]),
    ].where((s) => s.points.isNotEmpty).toList(),
    latency: [
      named('p50', charts[3]),
      named('p95', charts[4]),
    ].where((s) => s.points.isNotEmpty).toList(),
    hermesCostUsd: first(stats[0]) ?? 0,
    claudeCodeCostUsd: first(stats[1]) ?? 0,
    codexQuotaPct: first(stats[2]),
    cacheHitPct: cacheHit == null ? null : cacheHit * 100,
    fallbacks: first(stats[4]) ?? 0,
  );
}

/// UPS power + energy-cost telemetry from the NUT exporter on node4
/// (:9199, built 2026-08-05): live draw off the CyberPower CP1500, battery
/// state, and a modelled electricity cost. The UPS meters the WHOLE lab —
/// cluster nodes plus whatever else shares the strip — so this is aggregate
/// draw, not a pure per-node figure.
class PowerMetrics {
  const PowerMetrics({
    required this.watts,
    required this.loadPct,
    required this.batteryPct,
    required this.runtimeSeconds,
    required this.inputVolts,
    required this.online,
    required this.onBattery,
    required this.lowBattery,
    required this.avgWatts24h,
    required this.model,
    required this.power,
    required this.rateUsdPerKwh,
  });

  final double? watts; // derived real power (load% × nominal W)
  final double? loadPct; // ups.load %
  final double? batteryPct; // battery.charge %
  final double? runtimeSeconds; // battery.runtime s
  final double? inputVolts; // input.voltage V
  final bool? online; // ups.status OL (null = no data)
  final bool onBattery; // ups.status OB
  final bool lowBattery; // ups.status LB
  final double? avgWatts24h; // 24h trailing avg — drives energy + cost
  final String? model; // device.model, for the chart legend
  final List<MetricSeries> power; // trailing watts series for the chart
  final double rateUsdPerKwh; // electricity tariff from settings

  double? get kWhPerDay =>
      avgWatts24h == null ? null : avgWatts24h! / 1000 * 24;
  double? get costPerDay =>
      avgWatts24h == null ? null : avgWatts24h! / 1000 * 24 * rateUsdPerKwh;
  // 730 h/month, 8760 h/year — mirrors the Grafana dashboard's cost math.
  double? get costPerMonth =>
      avgWatts24h == null ? null : avgWatts24h! / 1000 * 730 * rateUsdPerKwh;
  double? get costPerYear =>
      avgWatts24h == null ? null : avgWatts24h! / 1000 * 8760 * rateUsdPerKwh;

  /// Nothing came back — the NUT exporter is down or scraped away (Prometheus
  /// itself answering is what got us here without an error).
  bool get isEmpty => watts == null && batteryPct == null && power.isEmpty;
}

// NUT exporter series (see services/monitoring.md). This CP1500 reports
// ups.load % + ups.realpower.nominal but not ups.realpower, so the exporter
// derives nut_ups_load_watts = load × nominal / 100. Cost is computed client
// side from the 24h average so the tariff lives in one place (settings).
@riverpod
Future<PowerMetrics> powerMetrics(Ref ref) async {
  final api = await ref.watch(prometheusApiProvider.future);
  final settings = await ref.watch(settingsControllerProvider.future);
  final range = ref.watch(selectedMetricsRangeProvider).duration;
  autoRefresh(ref);

  final stats = await Future.wait([
    api.instantQuery('nut_ups_load_watts'),
    api.instantQuery('nut_ups_load'),
    api.instantQuery('nut_battery_charge'),
    api.instantQuery('nut_battery_runtime'),
    api.instantQuery('nut_input_voltage'),
    api.instantQuery('nut_ups_online'),
    api.instantQuery('nut_ups_on_battery'),
    api.instantQuery('nut_ups_low_battery'),
    api.instantQuery('avg_over_time(nut_ups_load_watts[24h])'),
    api.instantQuery('nut_ups_info'),
  ]);
  final rawPower = await api.rangeQuery('nut_ups_load_watts', range: range);

  double? one(List<(Map<String, dynamic>, double)> r) =>
      r.isEmpty ? null : r.first.$2;
  bool flag(List<(Map<String, dynamic>, double)> r) =>
      r.isNotEmpty && r.first.$2 == 1;

  final rawModel = stats[9].isEmpty
      ? ''
      : '${stats[9].first.$1['model'] ?? ''}'.trim();
  final model = rawModel.isEmpty ? null : rawModel;
  final power = rawPower.isEmpty
      ? const <MetricSeries>[]
      : [MetricSeries(label: model ?? 'UPS', points: rawPower.first.points)];

  return PowerMetrics(
    watts: one(stats[0]),
    loadPct: one(stats[1]),
    batteryPct: one(stats[2]),
    runtimeSeconds: one(stats[3]),
    inputVolts: one(stats[4]),
    online: stats[5].isEmpty ? null : stats[5].first.$2 == 1,
    onBattery: flag(stats[6]),
    lowBattery: flag(stats[7]),
    avgWatts24h: one(stats[8]),
    model: model,
    power: power,
    rateUsdPerKwh: settings.electricityRateUsdPerKwh,
  );
}

/// One physical disk's SMART state, joined across the smartctl exporter
/// metric family by (host, device).
class DiskHealth {
  const DiskHealth({
    required this.host,
    required this.device,
    required this.model,
    required this.passed,
    required this.tempC,
    required this.wearPct,
    required this.mediaErrors,
    required this.criticalWarning,
    required this.reallocated,
    required this.pending,
  });

  final String host; // node name, or the pushed collector's host label
  final String device; // /dev/nvme0, /dev/sda…
  final String model;
  final bool passed; // smartctl_device_smart_status == 1
  final double? tempC;
  final double? wearPct; // NVMe percentage_used
  final double? mediaErrors; // NVMe
  final double? criticalWarning; // NVMe (0 = none)
  final double? reallocated; // SATA raw attribute 5
  final double? pending; // SATA raw attribute 197

  /// Anything beyond "old and warm" worth an amber light: reallocated or
  /// pending sectors, NVMe media errors, or a critical-warning flag.
  bool get degraded =>
      (reallocated ?? 0) > 0 ||
      (pending ?? 0) > 0 ||
      (mediaErrors ?? 0) > 0 ||
      (criticalWarning ?? 0) > 0;

  String get shortDevice => device.replaceFirst('/dev/', '');
}

/// Disk-health section data: the per-disk table plus the temperature
/// history chart.
class SmartHealth {
  const SmartHealth({required this.disks, required this.temps});

  final List<DiskHealth> disks;
  final List<MetricSeries> temps; // °C per disk over the selected range

  /// Nothing came back — no smartctl exporter is scraped/pushed (Prometheus
  /// itself answering is what got us here without an error).
  bool get isEmpty => disks.isEmpty && temps.isEmpty;
}

// SMART queries validated against the live Prometheus 2026-08-18: the node
// exporters (job "smart") and the NAS relay push (job "nas_smart") share the
// smartctl_device_* family, every series carrying host/device/model_name.
// Temperature needs the temperature_type filter (current vs lifetime rows);
// SATA attributes need attribute_value_type="raw" (value/worst/thresh rows
// exist alongside). Queries are deliberately job-agnostic so any operator's
// smartctl_exporter shows up.
const _smartStatusQ = 'smartctl_device_smart_status';
const _smartTempQ =
    'smartctl_device_temperature{temperature_type="current"}';
const _smartWearQ = 'smartctl_device_percentage_used';
const _smartCritQ = 'smartctl_device_critical_warning';
const _smartMediaQ = 'smartctl_device_media_errors';
const _smartReallocQ =
    'smartctl_device_attribute{attribute_name="Reallocated_Sector_Ct",'
    'attribute_value_type="raw"}';
const _smartPendingQ =
    'smartctl_device_attribute{attribute_name="Current_Pending_Sector",'
    'attribute_value_type="raw"}';

String _diskKey(Map<String, dynamic> m) => '${m['host']}|${m['device']}';
String _diskLabel(Map<String, dynamic> m) =>
    '${m['host']} ${'${m['device']}'.replaceFirst('/dev/', '')}';

@riverpod
Future<SmartHealth> smartHealth(Ref ref) async {
  final api = await ref.watch(prometheusApiProvider.future);
  final range = ref.watch(selectedMetricsRangeProvider).duration;
  autoRefresh(ref);

  final stats = await Future.wait([
    api.instantQuery(_smartStatusQ),
    api.instantQuery(_smartTempQ),
    api.instantQuery(_smartWearQ),
    api.instantQuery(_smartCritQ),
    api.instantQuery(_smartMediaQ),
    api.instantQuery(_smartReallocQ),
    api.instantQuery(_smartPendingQ),
  ]);
  final temps = await api.rangeQuery(
    _smartTempQ,
    range: range,
    labelOf: _diskLabel,
  );

  Map<String, double> byDisk(List<(Map<String, dynamic>, double)> r) => {
        for (final (m, v) in r) _diskKey(m): v,
      };
  final temp = byDisk(stats[1]);
  final wear = byDisk(stats[2]);
  final crit = byDisk(stats[3]);
  final media = byDisk(stats[4]);
  final realloc = byDisk(stats[5]);
  final pending = byDisk(stats[6]);

  final disks = [
    for (final (m, v) in stats[0])
      DiskHealth(
        host: '${m['host'] ?? ''}',
        device: '${m['device'] ?? ''}',
        model: '${m['model_name'] ?? ''}',
        passed: v == 1,
        tempC: temp[_diskKey(m)],
        wearPct: wear[_diskKey(m)],
        mediaErrors: media[_diskKey(m)],
        criticalWarning: crit[_diskKey(m)],
        reallocated: realloc[_diskKey(m)],
        pending: pending[_diskKey(m)],
      ),
  ]..sort(
      (a, b) => a.host == b.host
          ? a.device.compareTo(b.device)
          : a.host.compareTo(b.host),
    );

  return SmartHealth(disks: disks, temps: temps);
}

/// WAN & offsite-path telemetry (personal build): both circuits' scheduled
/// speedtests, the office↔home tailnet path, the measured offsite write
/// rate, and the NAS kernel-buffer clamp state.
class WanMetrics {
  const WanMetrics({
    required this.circuits,
    required this.offsite,
    required this.siteDownBps,
    required this.siteUpBps,
    required this.pathOnline,
    required this.pathDirect,
    required this.pathRttMs,
    required this.pathLossPct,
    required this.offsiteBps,
    required this.rmemMaxBytes,
    required this.rcvbufErrDelta,
  });

  final List<MetricSeries> circuits; // bits/s, "<site> ↓"/"<site> ↑"
  final List<MetricSeries> offsite; // bytes/s
  final Map<String, double> siteDownBps; // latest per site
  final Map<String, double> siteUpBps;
  final bool? pathOnline;
  final bool? pathDirect; // false = DERP relay
  final double? pathRttMs;
  final double? pathLossPct; // over the selected range
  final double? offsiteBps;
  final double? rmemMaxBytes; // the clamp tripwire
  final double? rcvbufErrDelta; // over the selected range

  bool get isEmpty =>
      circuits.isEmpty &&
      offsite.isEmpty &&
      siteDownBps.isEmpty &&
      pathOnline == null &&
      offsiteBps == null;
}

// WAN queries validated against the live Prometheus 2026-08-18 (speedtest
// pushes label site="home"/"office"; the path exporter labels peer; the
// blackbox tailnet probe rides job="tailnet_icmp").
const _wanDownQ = 'speedtest_download_bits_per_second';
const _wanUpQ = 'speedtest_upload_bits_per_second';
const _wanOffsiteQ = 'offsite_write_bytes_per_second';
const _wanRmemQ = 'nas_rmem_max_bytes';
const _wanPathOnlineQ = 'tailscale_path_online';
const _wanPathDirectQ = 'tailscale_path_direct';
const _wanPathRttQ = 'tailscale_path_rtt_seconds';
String _wanLossQ(String w) =>
    '100 * (1 - avg_over_time(probe_success{job="tailnet_icmp"}[$w]))';
String _wanRcvbufQ(String w) => 'increase(nas_udp_rcvbuf_errors_total[$w])';

@riverpod
Future<WanMetrics> wanMetrics(Ref ref) async {
  final api = await ref.watch(prometheusApiProvider.future);
  final range = ref.watch(selectedMetricsRangeProvider);
  autoRefresh(ref);
  final w = range.label;

  final charts = await Future.wait([
    api.rangeQuery(
      _wanDownQ,
      range: range.duration,
      labelOf: (m) => '${m['site']} ↓',
    ),
    api.rangeQuery(
      _wanUpQ,
      range: range.duration,
      labelOf: (m) => '${m['site']} ↑',
    ),
    api.rangeQuery(_wanOffsiteQ, range: range.duration,
        labelOf: (_) => 'offsite write'),
  ]);
  final stats = await Future.wait([
    api.instantQuery(_wanDownQ),
    api.instantQuery(_wanUpQ),
    api.instantQuery(_wanPathOnlineQ),
    api.instantQuery(_wanPathDirectQ),
    api.instantQuery(_wanPathRttQ),
    api.instantQuery(_wanLossQ(w)),
    api.instantQuery(_wanOffsiteQ),
    api.instantQuery(_wanRmemQ),
    api.instantQuery(_wanRcvbufQ(w)),
  ]);

  Map<String, double> bySite(List<(Map<String, dynamic>, double)> r) => {
        for (final (m, v) in r)
          if (m['site'] != null) '${m['site']}': v,
      };
  double? first(List<(Map<String, dynamic>, double)> r) =>
      r.isEmpty || r.first.$2.isNaN ? null : r.first.$2;
  bool? flag(List<(Map<String, dynamic>, double)> r) =>
      r.isEmpty ? null : r.first.$2 == 1;

  final rtt = first(stats[4]);
  return WanMetrics(
    circuits: [...charts[0], ...charts[1]]
      ..sort((a, b) => a.label.compareTo(b.label)),
    offsite: charts[2],
    siteDownBps: bySite(stats[0]),
    siteUpBps: bySite(stats[1]),
    pathOnline: flag(stats[2]),
    pathDirect: flag(stats[3]),
    pathRttMs: rtt == null ? null : rtt * 1000,
    pathLossPct: first(stats[5]),
    offsiteBps: first(stats[6]),
    rmemMaxBytes: first(stats[7]),
    rcvbufErrDelta: first(stats[8]),
  );
}

/// The homelab-twin simulator lives beside Prometheus on the monitoring CT
/// (:9112), so its URL derives from the Prometheus endpoint — no extra
/// setting to seed.
@riverpod
Future<TwinApi> twinApi(Ref ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  final base = settings.prometheusEndpoint;
  if (base.isEmpty) {
    throw const PrometheusNotConfigured();
  }
  final u = Uri.parse(base);
  return TwinApi.fromBase(u.replace(port: 9112, path: '').toString());
}

@riverpod
Future<TwinData> twinData(Ref ref) async {
  final api = await ref.watch(twinApiProvider.future);
  autoRefresh(ref);
  final results = await Future.wait([api.scenarios(), api.headroom()]);
  return TwinData(
    scenarios: results[0] as List<TwinScenario>,
    headroom: results[1] as List<TwinHeadroomNode>,
  );
}
