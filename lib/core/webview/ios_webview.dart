import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'browser_chrome.dart';
import 'webview_factory.dart';

/// iOS web views backed by WKWebView via webview_flutter.
class IosWebViewFactory implements WebViewFactory {
  @override
  Widget build(
    String url, {
    String? maskScript,
    bool controls = false,
    String? controlsLabel,
  }) =>
      IosWebView(
        url: url,
        maskScript: maskScript,
        controls: controls,
        controlsLabel: controlsLabel,
      );
}

class IosWebView extends StatefulWidget {
  const IosWebView({
    super.key,
    required this.url,
    this.maskScript,
    this.controls = false,
    this.controlsLabel,
  });

  final String url;
  final String? maskScript;
  final bool controls;
  final String? controlsLabel;

  @override
  State<IosWebView> createState() => _IosWebViewState();
}

class _IosWebViewState extends State<IosWebView> {
  late final ValueNotifier<String> _url = ValueNotifier(widget.url);

  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          final mask = widget.maskScript;
          if (mask != null) _controller.runJavaScript(mask);
        },
        // Live address readout for the chrome bar.
        onUrlChange: (change) {
          final url = change.url;
          if (mounted && url != null) _url.value = url;
        },
      ),
    )
    ..loadRequest(Uri.parse(widget.url));

  @override
  void didUpdateWidget(IosWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final mask = widget.maskScript;
    if (mask != null && mask != oldWidget.maskScript) {
      // A brightness flip rebuilt us with a new mask; re-run it in the live
      // page (WebMasks scripts replace their prior style node). Future loads
      // pick it up via onPageFinished, which reads the current widget.
      _controller.runJavaScript(mask);
    }
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = WebViewWidget(controller: _controller);
    if (!widget.controls) return page;
    return Column(
      children: [
        BrowserChromeBar(
          url: _url,
          pillLabel: widget.controlsLabel ?? 'Embedded',
          onBack: () => _controller.goBack(),
          onForward: () => _controller.goForward(),
          onReload: () => _controller.reload(),
          onHome: () => _controller.loadRequest(Uri.parse(widget.url)),
        ),
        Expanded(child: page),
      ],
    );
  }
}
