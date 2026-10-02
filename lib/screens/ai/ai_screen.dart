import 'package:flutter/material.dart';

import '../../core/build_config.dart';
import '../../core/navigation/app_tab.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/hub_scaffold.dart';
import '../hermes/hermes_screen.dart';
import '../ollama/ollama_screen.dart';
import '../webview/webview_screen.dart';

/// The AI hub: Chat (the Hermes agent personally, any OpenAI-compatible
/// endpoint publicly), the native Ollama model library, and the Open WebUI
/// web view — one rail slot for the whole domain instead of the three tabs
/// it used to occupy (2026-08-07 IA restructure).
class AiScreen extends StatelessWidget {
  const AiScreen({super.key, required this.railIndex});

  /// This hub's index in the shell's rail — the Open WebUI web view uses it
  /// to activate lazily only once the hub is opened.
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
            child: WebViewScreen(service: 'Open WebUI', tabIndex: railIndex),
          ),
          HubTab(
            icon: specs[3].icon,
            label: specs[3].label,
            child: WebViewScreen(service: 'SearXNG', tabIndex: railIndex),
          ),
        ],
      );
}
