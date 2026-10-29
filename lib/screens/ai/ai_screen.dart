import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_config.dart';
import '../../core/navigation/app_tab.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/ai_status_strip.dart';
import '../../core/widgets/hub_scaffold.dart';
import '../hermes/hermes_screen.dart';
import '../ollama/ollama_screen.dart';
import '../open_webui/open_webui_screen.dart';
import '../searxng/searxng_screen.dart';

/// The AI hub: Chat (the Hermes agent personally, any OpenAI-compatible
/// endpoint publicly), the native Ollama model library, Open WebUI and
/// SearXNG search — one rail slot for the whole domain instead of the three tabs
/// it used to occupy (2026-08-07 IA restructure).
class AiScreen extends StatelessWidget {
  const AiScreen({super.key, required this.railIndex});

  /// This hub's index in the shell's rail. Kept for the shell's uniform hub
  /// API; every sub-view is native, so nothing activates lazily.
  final int railIndex;

  /// Strip entries, index-aligned with [build]'s children; the shell's
  /// command palette lists them as jump targets.
  static const specs = [
    (icon: Ph.brain, label: kPublicBuild ? 'Chat' : 'Hermes'),
    (icon: Ph.cube, label: 'Models'),
    (icon: Ph.robot, label: 'Open WebUI'),
    // SearXNG — the private metasearch that also feeds Open WebUI's
    // web-search RAG, usable directly as a search page.
    (icon: Ph.magnifyingGlass, label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => HubScaffold(
        hub: AppTab.ai,
        tabs: [
          HubTab(
            icon: specs[0].icon,
            label: specs[0].label,
            child: const HermesScreen(),
          ),
          HubTab(
            icon: specs[1].icon,
            label: specs[1].label,
            child: const OllamaScreen(),
          ),
          HubTab(
            icon: specs[2].icon,
            label: specs[2].label,
            child: const AiOpenWebUiTab(),
          ),
          HubTab(
            icon: specs[3].icon,
            label: specs[3].label,
            child: const SearxngScreen(),
          ),
        ],
      );
}

/// The AI hub's Open WebUI view. The personal build adds the lab's real
/// model chain above it (Hermes runs on a hosted model that Open WebUI's
/// own model list does not show); the public build is the bare tab.
class AiOpenWebUiTab extends ConsumerWidget {
  const AiOpenWebUiTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kPublicBuild) return const OpenWebUiScreen();
    final url = ref.watch(settingsControllerProvider).value?.ollamaUrl ?? '';
    return Column(
      children: [
        if (url.isNotEmpty)
          AiStatusStrip(
            serviceName: 'Open WebUI',
            serviceUrl: url,
            accent: context.brass.moss,
          ),
        const Expanded(child: OpenWebUiScreen()),
      ],
    );
  }
}
