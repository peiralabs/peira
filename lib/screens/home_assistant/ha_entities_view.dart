import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/home_assistant_api.dart';
import '../../core/providers/home_assistant_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/service_frame.dart';

/// Calls `domain.service` for the tab, refreshes the entity states, and
/// reports a failure in a snackbar. Returns the service response, or null on
/// failure.
Future<Map<String, dynamic>?> haCall(
  BuildContext context,
  WidgetRef ref,
  String domain,
  String service, {
  Map<String, dynamic> data = const {},
  bool returnResponse = false,
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final api = await ref.read(homeAssistantApiProvider.future);
    final res = await api.callService(
      domain,
      service,
      data: data,
      returnResponse: returnResponse,
    );
    ref.invalidate(haStatesProvider);
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return res;
  } on Object catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('$domain.$service failed: ${describeServiceError(e)}'),
      ),
    );
    return null;
  }
}

Future<bool> haConfirm(
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

/// Domains with an on/off switch, all served by `<domain>.turn_on/turn_off`.
const _toggleDomains = {
  'light',
  'switch',
  'fan',
  'input_boolean',
  'automation',
  'siren',
  'humidifier',
  'remote',
};

/// Domain display order: things you control first, readings after.
const _domainOrder = [
  'light',
  'switch',
  'fan',
  'climate',
  'cover',
  'lock',
  'media_player',
  'vacuum',
  'scene',
  'script',
  'automation',
  'button',
  'input_boolean',
  'input_button',
  'input_select',
  'select',
  'input_number',
  'number',
  'camera',
  'alarm_control_panel',
  'update',
  'person',
  'weather',
  'binary_sensor',
  'sensor',
];

int _domainRank(String d) {
  final i = _domainOrder.indexOf(d);
  return i < 0 ? _domainOrder.length : i;
}

IconData haDomainIcon(String domain) => switch (domain) {
  'light' => Icons.lightbulb_outline,
  'switch' || 'input_boolean' => Icons.toggle_on_outlined,
  'fan' => Icons.mode_fan_off_outlined,
  'climate' => Icons.thermostat,
  'cover' => Icons.blinds,
  'lock' => Icons.lock_outline,
  'media_player' => Icons.speaker_group_outlined,
  'vacuum' => Icons.cleaning_services_outlined,
  'scene' => Icons.palette_outlined,
  'script' => Icons.description_outlined,
  'automation' => Icons.smart_toy_outlined,
  'button' || 'input_button' => Icons.radio_button_checked,
  'select' || 'input_select' => Icons.list,
  'number' || 'input_number' => Icons.pin_outlined,
  'camera' => Icons.videocam_outlined,
  'alarm_control_panel' => Icons.security,
  'update' => Icons.system_update_alt,
  'person' || 'device_tracker' => Icons.person_outline,
  'weather' => Icons.wb_sunny_outlined,
  'sun' => Icons.wb_twilight,
  'binary_sensor' => Icons.sensors,
  'sensor' => Icons.speed,
  'todo' => Icons.checklist,
  'zone' => Icons.place_outlined,
  _ => Icons.circle_outlined,
};

/// The formatted state of [e], with its unit.
String haStateText(HaEntity e) {
  if (e.domain == 'weather') {
    final t = e.attributes['temperature'];
    final u = e.attributes['temperature_unit'] ?? '';
    return t == null ? e.state : '${e.state} · $t$u';
  }
  if (e.domain == 'climate') {
    final cur = e.attributes['current_temperature'];
    return cur == null ? e.state : '${e.state} · $cur°';
  }
  final unit = e.unit;
  return unit == null ? e.state : '${e.state} $unit';
}

class HaEntitiesView extends ConsumerStatefulWidget {
  const HaEntitiesView({super.key});

  @override
  ConsumerState<HaEntitiesView> createState() => _HaEntitiesViewState();
}

class _HaEntitiesViewState extends ConsumerState<HaEntitiesView> {
  String _query = '';
  String? _domain;

  @override
  Widget build(BuildContext context) {
    final states = ref.watch(haStatesProvider);
    return states.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ServiceError(
        error: e,
        onRetry: () => ref.invalidate(haStatesProvider),
      ),
      data: (all) {
        final domains = {for (final e in all) e.domain}.toList()
          ..sort((a, b) {
            final r = _domainRank(a).compareTo(_domainRank(b));
            return r != 0 ? r : a.compareTo(b);
          });
        final q = _query.toLowerCase();
        final shown = [
          for (final e in all)
            if ((_domain == null || e.domain == _domain) &&
                (q.isEmpty ||
                    e.name.toLowerCase().contains(q) ||
                    e.entityId.contains(q)))
              e,
        ];
        final groups = <String, List<HaEntity>>{};
        for (final e in shown) {
          (groups[e.domain] ??= []).add(e);
        }
        final ordered = domains.where(groups.containsKey).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search entities',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ChoiceChip(
                    label: Text('All ${all.length}'),
                    selected: _domain == null,
                    onSelected: (_) => setState(() => _domain = null),
                  ),
                  for (final d in domains) ...[
                    const SizedBox(width: 6),
                    ChoiceChip(
                      avatar: Icon(haDomainIcon(d), size: 16),
                      label: Text(
                        '$d ${all.where((e) => e.domain == d).length}',
                      ),
                      selected: _domain == d,
                      onSelected: (_) =>
                          setState(() => _domain = _domain == d ? null : d),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(haStatesProvider);
                  await ref.read(haStatesProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  children: [
                    if (shown.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No matching entities.')),
                      ),
                    for (final d in ordered) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 6),
                        child: Text(
                          d.replaceAll('_', ' ').toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: context.brass.textMuted),
                        ),
                      ),
                      BrassPanel(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final e in groups[d]!) HaEntityTile(entity: e),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One entity row: name, state, and the quick control for its domain.
class HaEntityTile extends ConsumerWidget {
  const HaEntityTile({super.key, required this.entity});
  final HaEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = entity;
    final brass = context.brass;
    return ListTile(
      key: ValueKey('ha-${e.entityId}'),
      leading: Icon(
        haDomainIcon(e.domain),
        color: e.state == 'on' ? brass.giltBright : brass.textMuted,
      ),
      title: Text(e.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        e.entityId,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: brass.textMuted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              haStateText(e),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: e.unavailable ? brass.textMuted : null),
            ),
          ),
          const SizedBox(width: 8),
          HaQuickControl(entity: e),
        ],
      ),
      onTap: () => showHaEntityDetail(context, e),
    );
  }
}

/// The inline control for an entity's domain (switch, buttons), or nothing
/// for read-only domains.
class HaQuickControl extends ConsumerWidget {
  const HaQuickControl({super.key, required this.entity});
  final HaEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = entity;
    final id = {'entity_id': e.entityId};
    if (e.state == 'unavailable') return const SizedBox(width: 48);
    if (_toggleDomains.contains(e.domain)) {
      return Switch(
        value: e.state == 'on',
        onChanged: (on) => haCall(
          context,
          ref,
          e.domain,
          on ? 'turn_on' : 'turn_off',
          data: id,
        ),
      );
    }
    IconButton btn(IconData icon, String tip, VoidCallback onTap) =>
        IconButton(icon: Icon(icon), tooltip: tip, onPressed: onTap);
    switch (e.domain) {
      case 'scene':
      case 'script':
        return btn(
          Icons.play_arrow,
          'Run',
          () => haCall(
            context,
            ref,
            e.domain,
            'turn_on',
            data: id,
            done: '${e.name} started',
          ),
        );
      case 'button':
      case 'input_button':
        return btn(
          Icons.touch_app_outlined,
          'Press',
          () => haCall(context, ref, e.domain, 'press', data: id),
        );
      case 'lock':
        final locked = e.state == 'locked';
        return btn(
          locked ? Icons.lock_open : Icons.lock,
          locked ? 'Unlock' : 'Lock',
          () async {
            if (locked &&
                !await haConfirm(
                  context,
                  'Unlock ${e.name}?',
                  'This unlocks the physical lock.',
                  'Unlock',
                )) {
              return;
            }
            if (context.mounted) {
              await haCall(
                context,
                ref,
                'lock',
                locked ? 'unlock' : 'lock',
                data: id,
              );
            }
          },
        );
      case 'cover':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (e.supports(1))
              btn(
                Icons.arrow_upward,
                'Open',
                () => haCall(context, ref, 'cover', 'open_cover', data: id),
              ),
            if (e.supports(8))
              btn(
                Icons.stop,
                'Stop',
                () => haCall(context, ref, 'cover', 'stop_cover', data: id),
              ),
            if (e.supports(2))
              btn(
                Icons.arrow_downward,
                'Close',
                () => haCall(context, ref, 'cover', 'close_cover', data: id),
              ),
          ],
        );
      case 'media_player':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (e.state != 'off' && (e.supports(1) || e.supports(16384)))
              btn(
                e.state == 'playing' ? Icons.pause : Icons.play_arrow,
                'Play / pause',
                () => haCall(
                  context,
                  ref,
                  'media_player',
                  'media_play_pause',
                  data: id,
                ),
              ),
            if (e.supports(128) || e.supports(256))
              btn(
                Icons.power_settings_new,
                e.state == 'off' ? 'Turn on' : 'Turn off',
                () => haCall(
                  context,
                  ref,
                  'media_player',
                  e.state == 'off' ? 'turn_on' : 'turn_off',
                  data: id,
                ),
              ),
          ],
        );
      case 'vacuum':
        return btn(
          e.state == 'cleaning' ? Icons.home_outlined : Icons.play_arrow,
          e.state == 'cleaning' ? 'Return to dock' : 'Start',
          () => haCall(
            context,
            ref,
            'vacuum',
            e.state == 'cleaning' ? 'return_to_base' : 'start',
            data: id,
          ),
        );
      case 'update':
        if (e.state != 'on') return const SizedBox(width: 48);
        return btn(Icons.download, 'Install update', () async {
          if (!await haConfirm(
            context,
            'Install ${e.name}?',
            'Installs ${e.attributes['latest_version'] ?? 'the latest version'}.',
            'Install',
          )) {
            return;
          }
          if (context.mounted) {
            await haCall(
              context,
              ref,
              'update',
              'install',
              data: id,
              done: 'Update started',
            );
          }
        });
    }
    return const SizedBox(width: 48);
  }
}

/// Bottom sheet with every attribute, the 24-hour history, and the full
/// controls for [entity]'s domain.
Future<void> showHaEntityDetail(BuildContext context, HaEntity entity) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scroll) =>
            _HaEntityDetail(entityId: entity.entityId, scroll: scroll),
      ),
    );

class _HaEntityDetail extends ConsumerWidget {
  const _HaEntityDetail({required this.entityId, required this.scroll});
  final String entityId;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read from the live list so controls reflect each refresh.
    final e = ref
        .watch(haStatesProvider)
        .value
        ?.where((x) => x.entityId == entityId)
        .firstOrNull;
    if (e == null) return const Center(child: CircularProgressIndicator());
    final brass = context.brass;
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      children: [
        Row(
          children: [
            Icon(haDomainIcon(e.domain), color: brass.giltBright),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                e.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            HaQuickControl(entity: e),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(
          '${e.entityId}  ·  ${haStateText(e)}',
          style: TextStyle(color: brass.textMuted),
        ),
        const SizedBox(height: 16),
        ..._fullControls(context, ref, e),
        if (e.domain == 'camera') _CameraStill(entityId: e.entityId),
        const SizedBox(height: 12),
        Text('Last 24 hours', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _HaHistory(entity: e),
        const SizedBox(height: 16),
        Text('Attributes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final a in e.attributes.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: Text(a.key, style: TextStyle(color: brass.textMuted)),
                ),
                Expanded(child: SelectableText('${a.value}')),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _fullControls(BuildContext context, WidgetRef ref, HaEntity e) {
    final id = {'entity_id': e.entityId};
    final a = e.attributes;
    final out = <Widget>[];
    void slider(
      String label,
      double value,
      double min,
      double max,
      double? step,
      void Function(double) onEnd,
    ) {
      if (max <= min) return;
      out.add(
        _SliderRow(
          label: label,
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: step == null || step <= 0
              ? null
              : ((max - min) / step).round().clamp(1, 1000),
          onChangeEnd: onEnd,
        ),
      );
    }

    switch (e.domain) {
      case 'light':
        final modes = (a['supported_color_modes'] as List?)?.cast<String>();
        final dims = modes != null && modes.any((m) => m != 'onoff');
        if (dims) {
          final b = (a['brightness'] as num?)?.toDouble() ?? 0;
          slider(
            'Brightness',
            b / 255 * 100,
            0,
            100,
            1,
            (v) => haCall(
              context,
              ref,
              'light',
              'turn_on',
              data: {...id, 'brightness_pct': v.round()},
            ),
          );
        }
        final minK = (a['min_color_temp_kelvin'] as num?)?.toDouble();
        final maxK = (a['max_color_temp_kelvin'] as num?)?.toDouble();
        if (modes != null &&
            modes.contains('color_temp') &&
            minK != null &&
            maxK != null) {
          slider(
            'Colour temperature (K)',
            (a['color_temp_kelvin'] as num?)?.toDouble() ?? minK,
            minK,
            maxK,
            50,
            (v) => haCall(
              context,
              ref,
              'light',
              'turn_on',
              data: {...id, 'color_temp_kelvin': v.round()},
            ),
          );
        }
      case 'fan':
        if (e.supports(1)) {
          slider(
            'Speed',
            (a['percentage'] as num?)?.toDouble() ?? 0,
            0,
            100,
            (a['percentage_step'] as num?)?.toDouble(),
            (v) => haCall(
              context,
              ref,
              'fan',
              'set_percentage',
              data: {...id, 'percentage': v.round()},
            ),
          );
        }
      case 'cover':
        if (e.supports(4)) {
          slider(
            'Position',
            (a['current_position'] as num?)?.toDouble() ?? 0,
            0,
            100,
            1,
            (v) => haCall(
              context,
              ref,
              'cover',
              'set_cover_position',
              data: {...id, 'position': v.round()},
            ),
          );
        }
      case 'climate':
        final step = (a['target_temp_step'] as num?)?.toDouble() ?? 0.5;
        final t = (a['temperature'] as num?)?.toDouble();
        if (t != null) {
          slider(
            'Target temperature',
            t,
            (a['min_temp'] as num?)?.toDouble() ?? 7,
            (a['max_temp'] as num?)?.toDouble() ?? 35,
            step,
            (v) => haCall(
              context,
              ref,
              'climate',
              'set_temperature',
              data: {...id, 'temperature': v},
            ),
          );
        }
        _options(
          out,
          'Mode',
          e.state,
          (a['hvac_modes'] as List?)?.cast<Object>(),
          (v) => haCall(
            context,
            ref,
            'climate',
            'set_hvac_mode',
            data: {...id, 'hvac_mode': v},
          ),
        );
        _options(
          out,
          'Preset',
          a['preset_mode'],
          (a['preset_modes'] as List?)?.cast<Object>(),
          (v) => haCall(
            context,
            ref,
            'climate',
            'set_preset_mode',
            data: {...id, 'preset_mode': v},
          ),
        );
        _options(
          out,
          'Fan',
          a['fan_mode'],
          (a['fan_modes'] as List?)?.cast<Object>(),
          (v) => haCall(
            context,
            ref,
            'climate',
            'set_fan_mode',
            data: {...id, 'fan_mode': v},
          ),
        );
      case 'media_player':
        if (e.supports(4)) {
          slider(
            'Volume',
            ((a['volume_level'] as num?)?.toDouble() ?? 0) * 100,
            0,
            100,
            1,
            (v) => haCall(
              context,
              ref,
              'media_player',
              'volume_set',
              data: {...id, 'volume_level': v / 100},
            ),
          );
        }
        out.add(
          Wrap(
            spacing: 4,
            children: [
              if (e.supports(16))
                IconButton(
                  tooltip: 'Previous',
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () => haCall(
                    context,
                    ref,
                    'media_player',
                    'media_previous_track',
                    data: id,
                  ),
                ),
              if (e.supports(4096))
                IconButton(
                  tooltip: 'Stop',
                  icon: const Icon(Icons.stop),
                  onPressed: () => haCall(
                    context,
                    ref,
                    'media_player',
                    'media_stop',
                    data: id,
                  ),
                ),
              if (e.supports(32))
                IconButton(
                  tooltip: 'Next',
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => haCall(
                    context,
                    ref,
                    'media_player',
                    'media_next_track',
                    data: id,
                  ),
                ),
              if (e.supports(8))
                IconButton(
                  tooltip: a['is_volume_muted'] == true ? 'Unmute' : 'Mute',
                  icon: Icon(
                    a['is_volume_muted'] == true
                        ? Icons.volume_off
                        : Icons.volume_up,
                  ),
                  onPressed: () => haCall(
                    context,
                    ref,
                    'media_player',
                    'volume_mute',
                    data: {
                      ...id,
                      'is_volume_muted': a['is_volume_muted'] != true,
                    },
                  ),
                ),
            ],
          ),
        );
        _options(
          out,
          'Source',
          a['source'],
          (a['source_list'] as List?)?.cast<Object>(),
          (v) => haCall(
            context,
            ref,
            'media_player',
            'select_source',
            data: {...id, 'source': v},
          ),
        );
        if (a['media_title'] != null) {
          out.add(
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                [
                  a['media_artist'],
                  a['media_title'],
                ].whereType<String>().join(' — '),
              ),
            ),
          );
        }
      case 'select':
      case 'input_select':
        _options(
          out,
          'Option',
          e.state,
          (a['options'] as List?)?.cast<Object>(),
          (v) => haCall(
            context,
            ref,
            e.domain,
            'select_option',
            data: {...id, 'option': v},
          ),
        );
      case 'number':
      case 'input_number':
        final v = e.numericState;
        if (v != null) {
          slider(
            'Value${e.unit == null ? '' : ' (${e.unit})'}',
            v,
            (a['min'] as num?)?.toDouble() ?? 0,
            (a['max'] as num?)?.toDouble() ?? 100,
            (a['step'] as num?)?.toDouble(),
            (x) => haCall(
              context,
              ref,
              e.domain,
              'set_value',
              data: {...id, 'value': x},
            ),
          );
        }
      case 'automation':
        out.add(
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.bolt),
              label: const Text('Run actions now'),
              onPressed: () => haCall(
                context,
                ref,
                'automation',
                'trigger',
                data: id,
                done: '${e.name} triggered',
              ),
            ),
          ),
        );
      case 'alarm_control_panel':
        out.add(_AlarmControls(entity: e));
    }
    return out;
  }

  void _options(
    List<Widget> out,
    String label,
    Object? current,
    List<Object>? options,
    void Function(String) onPick,
  ) {
    if (options == null || options.isEmpty) return;
    final values = options.map((o) => '$o').toList();
    out.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: values.contains('$current') ? '$current' : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            for (final v in values) DropdownMenuItem(value: v, child: Text(v)),
          ],
          onChanged: (v) {
            if (v != null) onPick(v);
          },
        ),
      ),
    );
  }
}

class _SliderRow extends StatefulWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChangeEnd,
  });
  final String label;
  final double value, min, max;
  final int? divisions;
  final void Function(double) onChangeEnd;

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  late double _v = widget.value;

  @override
  void didUpdateWidget(_SliderRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _v = widget.value;
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 170, child: Text(widget.label)),
      Expanded(
        child: Slider(
          value: _v,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: _fmt(_v),
          onChanged: (v) => setState(() => _v = v),
          onChangeEnd: widget.onChangeEnd,
        ),
      ),
      SizedBox(width: 56, child: Text(_fmt(_v), textAlign: TextAlign.right)),
    ],
  );

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _AlarmControls extends ConsumerStatefulWidget {
  const _AlarmControls({required this.entity});
  final HaEntity entity;

  @override
  ConsumerState<_AlarmControls> createState() => _AlarmControlsState();
}

class _AlarmControlsState extends ConsumerState<_AlarmControls> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entity;
    Future<void> send(String service) => haCall(
      context,
      ref,
      'alarm_control_panel',
      service,
      data: {
        'entity_id': e.entityId,
        if (_code.text.isNotEmpty) 'code': _code.text,
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (e.attributes['code_format'] != null)
          TextField(
            controller: _code,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Code',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Bits from AlarmControlPanelEntityFeature.
            if (e.supports(1))
              OutlinedButton(
                onPressed: () => send('alarm_arm_home'),
                child: const Text('Arm home'),
              ),
            if (e.supports(2))
              OutlinedButton(
                onPressed: () => send('alarm_arm_away'),
                child: const Text('Arm away'),
              ),
            if (e.supports(4))
              OutlinedButton(
                onPressed: () => send('alarm_arm_night'),
                child: const Text('Arm night'),
              ),
            FilledButton(
              onPressed: () => send('alarm_disarm'),
              child: const Text('Disarm'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HaHistory extends ConsumerWidget {
  const _HaHistory({required this.entity});
  final HaEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(haHistoryProvider(entity.entityId));
    return history.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(describeServiceError(e)),
      data: (points) {
        if (points.isEmpty) {
          return Text(
            'No recorded changes.',
            style: TextStyle(color: context.brass.textMuted),
          );
        }
        final numeric = [
          for (final p in points)
            if (double.tryParse(p.state) != null) p,
        ];
        if (numeric.length >= 2) {
          final t0 = numeric.first.when.millisecondsSinceEpoch.toDouble();
          return SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(),
                  rightTitles: AxisTitles(),
                  bottomTitles: AxisTitles(),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final p in numeric)
                        FlSpot(
                          (p.when.millisecondsSinceEpoch - t0) / 60000,
                          double.parse(p.state),
                        ),
                    ],
                    dotData: const FlDotData(show: false),
                    color: context.brass.giltBright,
                  ),
                ],
              ),
            ),
          );
        }
        final recent = points.reversed.take(12);
        return Column(
          children: [
            for (final p in recent)
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      _hm(p.when),
                      style: TextStyle(color: context.brass.textMuted),
                    ),
                  ),
                  Expanded(child: Text(p.state)),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _CameraStill extends ConsumerWidget {
  const _CameraStill({required this.entityId});
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<List<int>>(
    future: ref
        .read(homeAssistantApiProvider.future)
        .then((api) => api.cameraImage(entityId)),
    builder: (context, snap) {
      if (snap.hasError) return Text(describeServiceError(snap.error!));
      if (!snap.hasData) return const LinearProgressIndicator();
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(Uint8List.fromList(snap.data!)),
      );
    },
  );
}

String _hm(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.month}/${l.day} ${two(l.hour)}:${two(l.minute)}';
}
