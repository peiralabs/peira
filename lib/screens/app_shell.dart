import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/demo/demo.dart';
import '../core/navigation/app_tab.dart';
import '../core/notifications/alert_notifier.dart';
import '../core/providers/navigation_providers.dart';
import '../core/providers/proxmox_providers.dart';
import '../core/providers/settings_providers.dart';
import '../core/settings/settings_repository.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/mol_motion.dart';
import '../core/widgets/ambient_background.dart';
import '../core/widgets/boot_splash.dart';
import '../core/widgets/command_palette.dart';
import '../core/widgets/glass_nav_rail.dart';
import '../core/widgets/masthead.dart';
import 'ai/ai_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'docker/docker_screen.dart';
import 'library/library_screen.dart';
import 'media/media_screen.dart';
import 'metrics/metrics_hub_screen.dart';
import 'proxmox/proxmox_screen.dart';
import 'settings/keyring_locked_screen.dart';
import 'settings/settings_screen.dart';
import 'setup/setup_wizard_screen.dart';
import 'tailscale/tailscale_screen.dart';
import 'terminal/terminal_screen.dart';
import 'vault/vault_screen.dart';
import 'webview/webview_screen.dart';

/// Top-level navigation shell.
///
/// Linux desktop gets the Brass masthead (the real CSD titlebar) over the
/// brass nav rail; iOS gets a [NavigationBar] at the bottom. On first launch
/// (no Proxmox credentials stored yet) the shell opens on the Settings tab.
/// Tab state lives in [SelectedTab] so dashboard tiles can jump to other
/// tabs. Tailscale and Terminal are desktop-only — iOS has no CLI or process
/// spawning.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static final _desktop = !Platform.isIOS;

  /// The active tabs in canonical order — all of them on desktop, minus the
  /// desktop-only ones (Tailscale/Terminal) on iOS. Everything downstream
  /// (rail, page stack, palette, accents) is derived from this.
  static final _tabs =
      AppTab.values.where((t) => _desktop || !t.desktopOnly).toList();

  static Widget _screenFor(AppTab t) => switch (t) {
        AppTab.dashboard => const DashboardScreen(),
        AppTab.proxmox => const ProxmoxScreen(),
        AppTab.docker => const DockerScreen(),
        // Domain hubs (left-top-top IA): each keys its web-view children's
        // lazy activation off its own rail index.
        AppTab.metrics =>
          MetricsHubScreen(railIndex: AppTab.metrics.railIndex),
        AppTab.ai => AiScreen(railIndex: AppTab.ai.railIndex),
        AppTab.media => MediaScreen(railIndex: AppTab.media.railIndex),
        AppTab.homeAssistant => WebViewScreen(
            service: 'Home Assistant',
            tabIndex: AppTab.homeAssistant.railIndex,
          ),
        AppTab.vault => VaultScreen(railIndex: AppTab.vault.railIndex),
        AppTab.library => LibraryScreen(railIndex: AppTab.library.railIndex),
        AppTab.tailscale => const TailscaleScreen(),
        AppTab.terminal => TerminalScreen(tabIndex: AppTab.terminal.railIndex),
        AppTab.settings => const SettingsScreen(),
      };

  static final _screens = [for (final t in _tabs) _screenFor(t)];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If the keyring is locked, the settings load fails with a typed error.
    // Show an unlock-and-retry gate instead of silently dropping the user onto
    // a blank first-launch Settings screen (their data is safe on disk).
    final settingsAsync = ref.watch(settingsControllerProvider);
    if (settingsAsync.error is KeyringLockedException) {
      return AmbientBackground(
        child: KeyringLockedScreen(
          retrying: settingsAsync.isLoading,
          onRetry: () => ref.invalidate(settingsControllerProvider),
        ),
      );
    }

    // First launch: a guided setup with a real connection test, instead of
    // the old blank Settings screen (card t_abe366ce).
    final settings = settingsAsync.value;
    if (settings != null && !settings.isConfigured) {
      return const AmbientBackground(child: SetupWizardScreen());
    }
    final selectedIndex = ref.watch(selectedTabProvider) ?? 0;

    // Keep the background alert→desktop-notification watcher alive for the
    // life of the shell (configured, non-demo desktop only).
    if (_desktop && !ref.watch(demoModeProvider)) {
      ref.watch(alertWatcherProvider);
    }

    final stoppedCount =
        ref
            .watch(allContainersProvider)
            .value
            ?.where((c) => c.status != 'running')
            .length ??
        0;

    Widget iconFor(int index) {
      final icon = Icon(_tabs[index].icon);
      if (_tabs[index] != AppTab.proxmox || stoppedCount == 0) return icon;
      return Badge(label: Text('$stoppedCount'), child: icon);
    }

    Widget body = _TabFade(
      index: selectedIndex,
      child: IndexedStack(index: selectedIndex, children: _screens),
    );
    // Demo mode keeps a persistent "everything is fake" strip above the
    // content so no screenshot or walkthrough can pass as a real lab.
    if (ref.watch(demoModeProvider)) {
      body = Column(
        children: [
          const DemoBanner(),
          Expanded(child: body),
        ],
      );
    }

    // The active section's accent tints the ambient backdrop (content-aware
    // accent), so the whole app shifts hue with the current tab.
    final brass = context.brass;
    final activeAccent = brass.sectionAccent(_tabs[selectedIndex].section);

    final paletteDests = [
      for (var i = 0; i < _tabs.length; i++)
        PaletteDest(
          index: i,
          label: _tabs[i].label,
          icon: _tabs[i].icon,
          accent: brass.sectionAccent(_tabs[i].section),
        ),
      // Hub sub-views as first-class palette targets ("plex" lands on
      // Media › Plex). A single-child hub already IS its child — skip it.
      for (final (hub, specs) in [
        (AppTab.metrics, MetricsHubScreen.specs),
        (AppTab.ai, AiScreen.specs),
        (AppTab.media, MediaScreen.specs),
        (AppTab.vault, VaultScreen.specs),
        (AppTab.library, LibraryScreen.specs),
      ])
        if (specs.length > 1 && _tabs.contains(hub))
          for (var s = 0; s < specs.length; s++)
            PaletteDest(
              index: _tabs.indexOf(hub),
              label: specs[s].label,
              icon: specs[s].icon,
              accent: brass.sectionAccent(hub.section),
              hub: hub,
              subIndex: s,
            ),
    ];
    void openPalette() => CommandPalette.show(context, paletteDests);

    void onSelect(int i) => ref.read(selectedTabProvider.notifier).select(i);

    if (_desktop) {
      final navDests = [
        for (final t in _tabs)
          NavDest(
            icon: t.icon,
            label: t.label,
            accent: brass.sectionAccent(t.section),
            section: t.section,
            pinnedBottom: t == AppTab.settings,
          ),
      ];
      final collapsed = settings?.railCollapsed ?? false;
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
              openPalette,
          const SingleActivator(LogicalKeyboardKey.keyK, control: true):
              openPalette,
        },
        child: Focus(
          autofocus: true,
          child: _BevelFrame(
            child: SplashGate(
              enabled: settings != null,
              child: AmbientBackground(
                accent: activeAccent,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Column(
                    children: [
                      const Masthead(),
                      Expanded(
                        child: Row(
                          children: [
                            GlassNavRail(
                              destinations: navDests,
                              selectedIndex: selectedIndex,
                              onSelect: onSelect,
                              badges: {
                                if (stoppedCount > 0)
                                  AppTab.proxmox.railIndex: stoppedCount,
                              },
                              onSearch: openPalette,
                              collapsed: collapsed,
                              onToggleCollapse: () async {
                                final s = ref
                                    .read(settingsControllerProvider)
                                    .value;
                                if (s == null) return;
                                await ref
                                    .read(settingsControllerProvider.notifier)
                                    .save(s.copyWith(
                                        railCollapsed: !s.railCollapsed));
                              },
                              onReconnect: () => ref
                                  .read(reconnectRequestProvider.notifier)
                                  .request(),
                            ),
                            Expanded(child: body),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SplashGate(
      enabled: settings != null,
      child: AmbientBackground(
        accent: activeAccent,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            destinations: [
              for (var i = 0; i < _tabs.length; i++)
                NavigationDestination(
                  icon: iconFor(i),
                  label: _tabs[i].label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The gilded window bevel (design §Window frame, border-only per the
/// approved plan — no desk margin so content keeps its full size).
class _BevelFrame extends StatelessWidget {
  const _BevelFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bevel =
        context.brass.isDark ? _BevelPalette.dark : _BevelPalette.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: bevel.outer),
      ),
      position: DecorationPosition.foreground,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Dark-bronze middle stroke — reads on both fields.
          border: Border.all(color: const Color(0x6B785C28), width: 3),
        ),
        position: DecorationPosition.foreground,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border:
                Border(top: BorderSide(color: bevel.topHighlight)),
          ),
          position: DecorationPosition.foreground,
          child: child,
        ),
      ),
    );
  }
}

/// Window-bevel gilding: brass gold with a cream catch-light over the dark
/// shell; engraved bronze ink with a warm paper sheen on parchment.
class _BevelPalette {
  const _BevelPalette({required this.outer, required this.topHighlight});

  final Color outer;
  final Color topHighlight;

  static const dark = _BevelPalette(
    outer: Color(0x80C9AA58),
    topHighlight: Color(0x3DFFF4C8),
  );
  static const light = _BevelPalette(
    outer: Color(0x808A6A2A),
    topHighlight: Color(0x66FFFBEE),
  );
}

/// Fades + slides the screen in on tab change (design: om-fade .45s,
/// translateY 9px → 0). Wraps the IndexedStack so keep-alive state survives.
///
/// The IndexedStack sits behind a [RepaintBoundary] with the fade/slide
/// applied outside it, so transition frames re-composite the screens' cached
/// layer instead of repainting every screen (software-rendered desktop).
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && kMolAnimationsEnabled) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _fade,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 9 * (1 - _fade.value)),
          child: child,
        ),
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

