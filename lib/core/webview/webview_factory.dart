import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'cef_webview.dart';
import 'ios_webview.dart';

part 'webview_factory.g.dart';

/// Builds a platform-appropriate embedded web view for a URL. The returned
/// widget owns its controller lifecycle. Tests override the provider with a
/// fake so no platform channels are touched.
abstract class WebViewFactory {
  /// [maskScript] is optional JavaScript injected on load to restyle the page
  /// so it blends into the app (see WebMasks).
  ///
  /// [controls] adds the brass browser-chrome bar above the page
  /// (back/forward/reload/home + live address readout + service pill) — used
  /// for the Wiki tab and for SPAs like Jellyseerr that have no in-page back
  /// affordance. [controlsLabel] is the pill text (e.g. `Embedded · Wiki.js`).
  Widget build(
    String url, {
    String? maskScript,
    bool controls = false,
    String? controlsLabel,
  });
}

@Riverpod(keepAlive: true)
WebViewFactory webViewFactory(Ref ref) =>
    Platform.isIOS ? IosWebViewFactory() : CefWebViewFactory();
