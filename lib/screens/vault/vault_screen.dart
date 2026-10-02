import 'package:flutter/material.dart';

import '../../core/build_config.dart';
import '../../core/navigation/app_tab.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/hub_scaffold.dart';
import '../ask/ask_screen.dart';
import '../webview/webview_screen.dart';

/// The Vault hub: read the vault (Wiki.js web view) and ask it (the
/// ask-homelab RAG chat). Ask depends on a private backend, so the public
/// build has only the Wiki child — [HubScaffold] then hides the strip and
/// the tab label reads plain "Wiki" (see [AppTab.vault]).
class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key, required this.railIndex});

  /// This hub's index in the shell's rail — the Wiki web view uses it to
  /// activate lazily only once the hub is opened.
  final int railIndex;

  /// Strip entries, index-aligned with [build]'s children; the shell's
  /// command palette lists them as jump targets.
  static const specs = [
    (icon: Ph.bookOpenText, label: 'Wiki'),
    if (!kPublicBuild) (icon: Ph.chatCircleText, label: 'Ask'),
  ];

  @override
  Widget build(BuildContext context) => HubScaffold(
        hub: AppTab.vault,
        tabs: [
          HubTab(
            icon: specs[0].icon,
            label: specs[0].label,
            child: WebViewScreen(service: 'Wiki', tabIndex: railIndex),
          ),
          if (!kPublicBuild)
            HubTab(
              icon: specs[1].icon,
              label: specs[1].label,
              child: const AskScreen(),
            ),
        ],
      );
}
