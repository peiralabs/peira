import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_config.dart';
import '../../core/providers/navigation_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/webview/web_logins.dart';
import '../../core/webview/web_masks.dart';
import '../../core/webview/webview_factory.dart';
import '../../core/widgets/ai_status_strip.dart';

/// Shared wrapper for the embedded service web views (Open WebUI, Wiki,
/// Jellyseerr). The service URL comes from settings — never hardcoded.
///
/// The web view is created lazily the first time this tab is selected, so
/// the app doesn't spawn four CEF browsers at startup; once created it stays
/// alive across tab switches (the shell's IndexedStack keeps state).
class WebViewScreen extends ConsumerStatefulWidget {
  const WebViewScreen({
    super.key,
    required this.service,
    required this.tabIndex,
  });

  final String service;
  final int tabIndex;

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen>
    with AutomaticKeepAliveClientMixin {
  bool _activated = false;

  // Keep the (CEF) web view alive when it lives inside a TabBarView (the Media
  // tab's Discover sub-tab) so switching sub-tabs doesn't tear down and respawn
  // the browser. Harmless under the shell's IndexedStack, which already keeps
  // state.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final brass = context.brass;
    final settings = ref.watch(settingsControllerProvider).value;
    if (ref.watch(selectedTabProvider) == widget.tabIndex) _activated = true;

    final url =
        switch (widget.service) {
          // The Open WebUI chat front-end still lives at the Ollama URL —
          // the "Ollama" tab itself is now the native model library.
          'Open WebUI' => settings?.ollamaUrl,
          'Wiki' => settings?.wikiUrl,
          'Jellyseerr' => settings?.jellyseerrUrl,
          'Home Assistant' => settings?.homeAssistantUrl,
          'SearXNG' => settings?.searxngUrl,
          'Karakeep' => settings?.karakeepUrl,
          'Paperless' => settings?.paperlessUrl,
          'Immich' => settings?.immichUrl,
          'changedetection.io' => settings?.changedetectionUrl,
          _ => null,
        } ??
        '';

    if (url.isEmpty) {
      return Center(
        child: Text(
          '${widget.service} has no URL yet.\nEnter it in Settings.',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!_activated) return const SizedBox.shrink();

    // Wiki gets the full browser chrome per the design (§6); Jellyseerr
    // (Discover) is a deep SPA with no in-page back button, so it keeps the
    // same bar so drilling into a title isn't a dead end. SearXNG and
    // Karakeep navigate to EXTERNAL result/bookmark pages — without
    // back/home those tabs are one-way doors — and Paperless, Immich, and
    // changedetection.io all have drill-in views, so every embedded service
    // added with the 2026-08-18 expansion carries the same bar.
    final chromeLabel = switch (widget.service) {
      'Wiki' => 'Embedded · Wiki.js',
      'Jellyseerr' => 'Embedded · Jellyseerr',
      'SearXNG' => 'Embedded · SearXNG',
      'Karakeep' => 'Embedded · Karakeep',
      'Paperless' => 'Embedded · Paperless-ngx',
      'Immich' => 'Embedded · Immich',
      'changedetection.io' => 'Embedded · changedetection.io',
      _ => null,
    };
    // The mask palette follows the effective brightness live: context.brass is
    // Theme-resolved, so a System/Light/Dark flip (or an OS brightness change
    // under System) rebuilds this screen with a new maskScript, and the
    // platform webviews re-inject it into already-open pages
    // (didUpdateWidget → executeJavaScript / runJavaScript).
    // Combine the cosmetic mask with an autofill script for the service's own
    // login form (when a credential is stored), so both are injected on load
    // and re-run together on a theme flip.
    final mask = WebMasks.scriptFor(widget.service, isDark: brass.isDark);
    final login = WebLogins.scriptFor(
      widget.service,
      login: settings?.webLoginFor(widget.service),
      autoSubmit: settings?.webAutoLogin ?? true,
    );
    final script = [
      mask,
      login,
    ].where((s) => s != null).join('\n');

    final webView = ref
        .watch(webViewFactoryProvider)
        .build(
          url,
          maskScript: script.isEmpty ? null : script,
          controls: chromeLabel != null,
          controlsLabel: chromeLabel,
        );

    // Personal build only: a native header showing the real model chain
    // (Hermes runs on Claude Haiku; Open WebUI only lists local models, so
    // without this the tab misrepresents what actually answers). The chain
    // is this lab's private routing — a public user's Open WebUI lists
    // their own models correctly, so the strip would only mislead there.
    if (!kPublicBuild && widget.service == 'Open WebUI') {
      return Column(
        children: [
          AiStatusStrip(
            serviceName: 'Open WebUI',
            serviceUrl: url,
            accent: brass.moss,
          ),
          const SizedBox(height: 12),
          Expanded(child: webView),
        ],
      );
    }
    return webView;
  }
}
