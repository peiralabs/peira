import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/grafana_providers.dart';
import '../providers/proxmox_providers.dart';
import '../providers/sweep_providers.dart';
import '../providers/tailscale_providers.dart';
import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';
import 'astrolabe.dart';
import 'brass_ornament.dart';

/// The boot/reconnect controller. The rail footer calls [request] to re-run the
/// boot splash and re-fetch the full live-data set; [SplashGate] watches the
/// epoch to drive the splash UI. Owning the refresh set here (rather than
/// inline in the widget) keeps the one authoritative list of "everything the
/// dashboard shows" in one place.
class ReconnectRequest extends Notifier<int> {
  @override
  int build() => 0;

  void request() {
    state++;
    refresh();
  }

  /// Invalidate every live cluster/service provider the shell surfaces, so a
  /// reconnect re-fetches all of it — not just the nodes the splash waits on.
  void refresh() {
    ref.invalidate(nodesProvider);
    ref.invalidate(allContainersProvider);
    ref.invalidate(allVmsProvider);
    ref.invalidate(activeAlertsProvider);
    ref.invalidate(recentTasksProvider);
    ref.invalidate(tailscaleStatusProvider);
  }
}

final reconnectRequestProvider = NotifierProvider<ReconnectRequest, int>(
  ReconnectRequest.new,
);

/// Shows the boot/reconnect splash over [child] until the first nodes fetch
/// resolves (success or error), with a minimum display so the astrolabe and
/// the gauge sweep read. Never shown when [enabled] is false (first-launch /
/// keyring-gate flows) or under FLUTTER_TEST.
class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate> {
  // Not just an animation gate: the splash is never *shown* under test, so
  // this keys off the shared "in tests" flag (same env check).
  static final bool _test = kUnderTest;

  late bool _visible = widget.enabled && !_test;
  bool _shown = false;
  bool _minDone = false;
  bool _loaded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_visible) {
      _shown = true;
      _startMinTimer();
    }
  }

  @override
  void didUpdateWidget(SplashGate old) {
    super.didUpdateWidget(old);
    // On a real cold start settings resolve asynchronously, so the gate first
    // mounts with enabled=false and flips true a frame later — latch the boot
    // splash then (once), or it would never show outside tests.
    if (!old.enabled && widget.enabled && !_test && !_shown) {
      _shown = true;
      setState(() => _visible = true);
      _startMinTimer();
    }
  }

  void _startMinTimer() {
    _minDone = false;
    _loaded = false;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      _minDone = true;
      _maybeFinish();
    });
  }

  void _maybeFinish() {
    if (!mounted || !_visible || !_minDone || !_loaded) return;
    setState(() => _visible = false);
    ref.read(sweepEpochProvider.notifier).bump();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_test && widget.enabled) {
      ref.listen(reconnectRequestProvider, (prev, next) {
        // The controller already re-fetched the data set; the widget only
        // re-shows the splash until the nodes fetch it waits on resolves.
        if (prev == null || next == prev) return;
        setState(() => _visible = true);
        _startMinTimer();
      });
      final nodes = ref.watch(nodesProvider);
      if (_visible && !_loaded && !nodes.isLoading) {
        _loaded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFinish());
      }
    }
    return Stack(
      fit: StackFit.expand,
      children: [widget.child, if (_visible) const _SplashBody()],
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final palette = brass.isDark ? _Palette.dark : _Palette.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.16),
          radius: 1.1,
          colors: [palette.backdropCenter, palette.backdropEdge],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Astrolabe(size: 156),
          const SizedBox(height: 20),
          const GiltWordmark(fontSize: 22),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Brass.emerald.cabochon,
                  boxShadow: brass.jewelHalo(Brass.emerald),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Contacting cluster…',
                style: TextStyle(fontSize: 15, color: brass.sage),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ShimmerBar(),
        ],
      ),
    );
  }
}

class _ShimmerBar extends StatefulWidget {
  const _ShimmerBar();

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  );

  @override
  void initState() {
    super.initState();
    if (kMolAnimationsEnabled) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brass.isDark ? _Palette.dark : _Palette.light;
    return SizedBox(
      width: 210,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: ColoredBox(
          color: palette.shimmerTrack,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Align(
              // Sweep the 38%-wide highlight from off-left to off-right.
              alignment: Alignment(-2.2 + _c.value * 5.4, 0),
              child: FractionallySizedBox(
                widthFactor: 0.38,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: palette.shimmerSweep),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Splash-local inks, resolved per brightness: dark values verbatim from the
/// dark-only era; light is a parchment scrim whose sweep inverts to dense
/// bronze (a pale-gold highlight is invisible on the pale track).
class _Palette {
  const _Palette({
    required this.backdropCenter,
    required this.backdropEdge,
    required this.shimmerTrack,
    required this.shimmerSweep,
  });

  final Color backdropCenter;
  final Color backdropEdge;
  final Color shimmerTrack;
  final List<Color> shimmerSweep;

  static const dark = _Palette(
    backdropCenter: Color(0xEB1E2E20),
    backdropEdge: Color(0xFA090F0A),
    shimmerTrack: Color(0x24C9AA58),
    shimmerSweep: [Color(0x00F2DD94), Color(0xFFF2DD94), Color(0x00F2DD94)],
  );

  static const light = _Palette(
    backdropCenter: Color(0xEBF3EBDA),
    backdropEdge: Color(0xFAE0D4BC),
    shimmerTrack: Color(0x338A6A2A),
    shimmerSweep: [Color(0x008A6A2A), Color(0xFF8A6A2A), Color(0x008A6A2A)],
  );
}
