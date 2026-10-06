import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/ollama_api.dart';
import '../../core/providers/ollama_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_icon_badge.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/status_light.dart';

/// Native Ollama model library (design §4): garnet screen header with a
/// "Pull model" action, garnet divider rule, and a grid of garnet-tinted
/// model cards (status pill + Params / Size / Quant stat trio) fed by the
/// daemon's `/api/tags` + `/api/ps`, auto-refreshed every 30s.
class OllamaScreen extends ConsumerWidget {
  const OllamaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brass = context.brass;
    final pal = _OllamaPalette.of(context);
    final models = ref.watch(ollamaModelsProvider);
    final running = ref.watch(ollamaRunningProvider).value ?? const <String>{};
    final modelCount = models.value?.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
          child: ScreenHeader(
            icon: Ph.robot,
            badgeField: BrassIconBadge.garnetField,
            title: 'Ollama',
            subtitle: modelCount == null
                ? 'LOCAL MODEL LIBRARY'
                : 'LOCAL MODEL LIBRARY · $modelCount '
                    'MODEL${modelCount == 1 ? '' : 'S'}',
            subtitleColor: pal.subtitle,
            trailing: [
              const SizedBox(width: 12),
              _ReachabilityPill(
                state: models,
                onRetry: () {
                  ref.invalidate(ollamaModelsProvider);
                  ref.invalidate(ollamaRunningProvider);
                },
              ),
              const SizedBox(width: 12),
              _PullButton(onPressed: () => _showPullDialog(context, ref)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SectionDivider.garnet(),
        ),
        Expanded(
          child: models.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              error: e,
              onRetry: () {
                ref.invalidate(ollamaModelsProvider);
                ref.invalidate(ollamaRunningProvider);
              },
            ),
            data: (modelList) => modelList.isEmpty
                ? Center(
                    child: Text(
                      'No models installed yet.\nPull one to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: brass.textMuted),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(ollamaModelsProvider);
                      ref.invalidate(ollamaRunningProvider);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = (constraints.maxWidth / 330)
                                .floor()
                                .clamp(1, 4);
                            final w = (constraints.maxWidth -
                                    (cols - 1) * 14) /
                                cols;
                            return Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                for (final m in modelList)
                                  SizedBox(
                                    width: w,
                                    child: _ModelCard(
                                      model: m,
                                      running: running.contains(m.name),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPullDialog(BuildContext context, WidgetRef ref) async {
    final api = await ref.read(ollamaApiProvider.future).then<OllamaApi?>(
          (a) => a,
          onError: (_) => null,
        );
    if (api == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _PullDialog(api: api),
    );
    ref.invalidate(ollamaModelsProvider);
    ref.invalidate(ollamaRunningProvider);
  }
}

/// Breathing daemon-reachability light: green when the last fetch succeeded,
/// red with a Retry affordance on error.
///
/// Renders nothing when Ollama simply isn't configured (the body already
/// shows the configure hint — a crit-red pill would be false signal), and
/// holds the previous ok/fail state while a 30s auto-refresh is in flight so
/// the pill doesn't flicker through "Checking…".
class _ReachabilityPill extends StatelessWidget {
  const _ReachabilityPill({required this.state, required this.onRetry});

  final AsyncValue<Object?> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.error is OllamaNotConfigured) return const SizedBox.shrink();
    final pal = _OllamaPalette.of(context);
    // hasValue/hasError survive a refresh (loading with a previous result),
    // so only a genuine first probe shows "Checking…".
    final failed = state.hasError;
    final up = !failed && state.hasValue;
    final health = failed
        ? Health.crit
        : up
            ? Health.ok
            : Health.offline;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: failed ? pal.pillBorderFail : pal.pillBorderUp,
        ),
        color: pal.pillBg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusLight(health: health, size: 8),
          const SizedBox(width: 8),
          Text(
            failed
                ? 'Retry'
                : up
                    ? 'Daemon up'
                    : 'Checking…',
            style: TextStyle(
              fontSize: 12,
              color: failed ? pal.pillTextFail : pal.pillTextUp,
            ),
          ),
        ],
      ),
    );
    if (!failed) return pill;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onRetry, child: pill),
    );
  }
}

/// The garnet "Pull model" gradient button.
class _PullButton extends StatelessWidget {
  const _PullButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _OllamaPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: pal.pullBtnFill,
            border: Border.all(color: const Color(0x80E09678)),
            boxShadow: brass.cardShadow,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Ph.downloadSimple, size: 15, color: Color(0xFFF6D9C4)),
              SizedBox(width: 8),
              Text(
                'Pull model',
                style: TextStyle(fontSize: 13.5, color: Color(0xFFF6D9C4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error is OllamaNotConfigured) {
      return const Center(
        child: Text(
          'Ollama is not configured yet.\n'
          'Set the daemon URL (…:11434) in Settings.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final unreachable = error is OllamaUnreachable ? error as OllamaUnreachable : null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unreachable?.message ?? 'Failed to reach Ollama:\n$error',
            textAlign: TextAlign.center,
          ),
          if (unreachable != null) ...[
            const SizedBox(height: 8),
            Text(
              unreachable.endpoint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: context.brass.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// A garnet-tinted model card: cube icon + Playfair name + Running/Idle
/// pill, then the Params / Size / Quant stat trio.
class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.model, required this.running});

  final OllamaModel model;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final pal = _OllamaPalette.of(context);
    return BrassPanel(
      fill: pal.cardFill,
      borderColor: running ? pal.borderRunning : pal.borderIdle,
      topRule: true,
      topRuleColor: running ? pal.accentRunning : pal.accentIdle,
      hoverLift: true,
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Ph.cube, size: 19, color: pal.cubeIcon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  model.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: pal.modelName,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(running: running),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: model.parameterSize.isEmpty
                      ? '—'
                      : model.parameterSize,
                  label: 'Params',
                ),
              ),
              Expanded(child: _Stat(value: model.sizeLabel, label: 'Size')),
              Expanded(
                child: _Stat(
                  value: model.quantization.isEmpty
                      ? '—'
                      : model.quantization,
                  label: 'Quant',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    final pal = _OllamaPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: running ? pal.statusBorderRunning : pal.statusBorderIdle,
        ),
        color: running ? pal.statusBgRunning : Colors.transparent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: running ? pal.statusDotRunning : pal.statusDotIdle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            running ? 'Running' : 'Idle',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.6,
              color: running ? pal.statusTextRunning : pal.statusTextIdle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pal = _OllamaPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: context.displayFont,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 1.1,
            color: pal.statValue,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 10 * 0.14,
            color: pal.statLabel,
          ),
        ),
      ],
    );
  }
}

/// Pull-model dialog: name field + live streamed progress from `/api/pull`.
class _PullDialog extends StatefulWidget {
  const _PullDialog({required this.api});

  final OllamaApi api;

  @override
  State<_PullDialog> createState() => _PullDialogState();
}

class _PullDialogState extends State<_PullDialog> {
  final _name = TextEditingController();
  bool _pulling = false;
  bool _done = false;
  String? _status;
  int? _completed;
  int? _total;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pull() async {
    final name = _name.text.trim();
    if (name.isEmpty || _pulling) return;
    setState(() {
      _pulling = true;
      _done = false;
      _error = null;
      _status = 'starting…';
      _completed = null;
      _total = null;
    });
    try {
      await widget.api.pullModel(name, (p) {
        if (!mounted) return;
        setState(() {
          _status = p.status;
          _completed = p.completed ?? _completed;
          _total = p.total ?? _total;
        });
      });
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final pal = _OllamaPalette.of(context);
    final frac = (_total ?? 0) > 0 && _completed != null
        ? (_completed! / _total!).clamp(0.0, 1.0)
        : null;
    return AlertDialog(
      title: const Text('Pull model'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              enabled: !_pulling,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Model name',
                hintText: 'e.g. llama3.1:8b',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _pull(),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(
                _done ? 'Done — $_status' : _status!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _done ? 1 : frac,
                color: pal.progressBar,
                backgroundColor: pal.progressTrack,
              ),
              if (frac != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${_gb(_completed)} / ${_gb(_total)} GB',
                  style: TextStyle(fontSize: 12, color: brass.textMuted),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _pulling ? null : () => Navigator.of(context).pop(),
          child: Text(_done ? 'Close' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _pulling ? null : _pull,
          child: const Text('Pull'),
        ),
      ],
    );
  }

  static String _gb(int? bytes) =>
      ((bytes ?? 0) / (1 << 30)).toStringAsFixed(1);
}

/// Ollama-local garnet/rosewood palette, brightness-resolved. [dark] is
/// verbatim from the dark-only era (translucent near-black garnets, cream
/// and salmon inks over the ambient backdrop); [light] turns the cards into
/// garnet-tinted paper with dark rosewood inks and collapses the pull-button
/// gradient to a solid garnet CTA (its cream label and peach rim sit on the
/// button's own fill and keep their literals in [_PullButton]).
class _OllamaPalette {
  const _OllamaPalette({
    required this.subtitle,
    required this.pillBorderFail,
    required this.pillBorderUp,
    required this.pillBg,
    required this.pillTextFail,
    required this.pillTextUp,
    required this.pullBtnFill,
    required this.cardFill,
    required this.borderRunning,
    required this.borderIdle,
    required this.accentRunning,
    required this.accentIdle,
    required this.cubeIcon,
    required this.modelName,
    required this.statusBorderRunning,
    required this.statusBorderIdle,
    required this.statusBgRunning,
    required this.statusDotRunning,
    required this.statusDotIdle,
    required this.statusTextRunning,
    required this.statusTextIdle,
    required this.statValue,
    required this.statLabel,
    required this.progressBar,
    required this.progressTrack,
  });

  final Color subtitle;
  final Color pillBorderFail;
  final Color pillBorderUp;
  final Color pillBg;
  final Color pillTextFail;
  final Color pillTextUp;
  final LinearGradient pullBtnFill;
  final LinearGradient cardFill;
  final Color borderRunning;
  final Color borderIdle;
  final Color accentRunning;
  final Color accentIdle;
  final Color cubeIcon;
  final Color modelName;
  final Color statusBorderRunning;
  final Color statusBorderIdle;
  final Color statusBgRunning;
  final Color statusDotRunning;
  final Color statusDotIdle;
  final Color statusTextRunning;
  final Color statusTextIdle;
  final Color statValue;
  final Color statLabel;
  final Color progressBar;
  final Color progressTrack;

  /// Ambient-theme resolution (registers a Theme dependency, like Brass.of).
  static _OllamaPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const dark = _OllamaPalette(
    subtitle: Color(0xFFD79F92),
    pillBorderFail: Color(0x80C8564A),
    pillBorderUp: Color(0x578C5048),
    pillBg: Color(0x66231414),
    pillTextFail: Color(0xFFECAF9F),
    pillTextUp: Color(0xFFC8A294),
    pullBtnFill: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xB3A0423C), Color(0xBF5A1F22)],
    ),
    cardFill: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xE0302121), Color(0xEB140F0F)],
    ),
    borderRunning: Color(0x737BB26A),
    borderIdle: Color(0x578C5048),
    accentRunning: Color(0xFF7BB26A),
    accentIdle: Color(0xFFC05A4E),
    cubeIcon: Color(0xFFDD9A86),
    modelName: Color(0xFFF5E2D6),
    statusBorderRunning: Color(0x807BB26A),
    statusBorderIdle: Color(0x59B48C7E),
    statusBgRunning: Color(0x802E4A30),
    statusDotRunning: Color(0xFF7BB26A),
    statusDotIdle: Color(0xFF8A6A5E),
    statusTextRunning: Color(0xFFA7E0A0),
    statusTextIdle: Color(0xFFB58C7E),
    statValue: Color(0xFFEED0C2),
    statLabel: Color(0xFFB58C7E),
    progressBar: Color(0xFFC05A4E),
    progressTrack: Color(0x33C05A4E),
  );

  static const light = _OllamaPalette(
    subtitle: Color(0xFF8F4A3C),
    pillBorderFail: Color(0x8C9E362C),
    pillBorderUp: Color(0x668F4A3C),
    pillBg: Color(0x66F2E3DA),
    pillTextFail: Color(0xFF9E362C),
    pillTextUp: Color(0xFF6E4A3E),
    pullBtnFill: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xB39C4136), Color(0xB39C4136)],
    ),
    // Parchment-family card paper (panelTop/panelBottom territory) with only
    // a whisper of the garnet warmth — the dark maroon glaze oversaturated
    // to dusty rose on the light field and drowned the status accents.
    cardFill: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xE0F4ECE0), Color(0xEBECE0D0)],
    ),
    borderRunning: Color(0x8C38702E),
    borderIdle: Color(0x668F4A3C),
    accentRunning: Color(0xFF38702E),
    accentIdle: Color(0xFF9C4136),
    cubeIcon: Color(0xFF8F4A3C),
    modelName: Color(0xFF3A241C),
    statusBorderRunning: Color(0x8C38702E),
    statusBorderIdle: Color(0x668F4A3C),
    statusBgRunning: Color(0x2E4F8A45),
    statusDotRunning: Color(0xFF38702E),
    statusDotIdle: Color(0xFF7A6558),
    statusTextRunning: Color(0xFF2C5222),
    statusTextIdle: Color(0xFF7A4438),
    statValue: Color(0xFF4A3226),
    statLabel: Color(0xFF6E4A3E),
    progressBar: Color(0xFF9C4136),
    progressTrack: Color(0x339C4136),
  );
}
