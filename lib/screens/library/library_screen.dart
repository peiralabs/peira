import 'package:flutter/material.dart';

import '../../core/navigation/app_tab.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/hub_scaffold.dart';
import '../webview/webview_screen.dart';

/// The Library hub: Karakeep (bookmarks / read-later with local-AI tagging)
/// and Paperless-ngx (documents with OCR search) — the reading and records
/// shelf, one rail slot for both. Each service's own frontend does the work,
/// so both sub-views are embedded webviews; logins persist in the webview.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.railIndex});

  /// This hub's index in the shell's rail — the webviews use it to activate
  /// lazily only once the hub is opened.
  final int railIndex;

  /// Strip entries, index-aligned with [build]'s children; the shell's
  /// command palette lists them as jump targets.
  static const specs = [
    (icon: Ph.bookmarkSimple, label: 'Bookmarks'),
    (icon: Ph.fileText, label: 'Documents'),
  ];

  @override
  Widget build(BuildContext context) => HubScaffold(
        hub: AppTab.library,
        tabs: [
          HubTab(
            icon: specs[0].icon,
            label: specs[0].label,
            child: WebViewScreen(service: 'Karakeep', tabIndex: railIndex),
          ),
          HubTab(
            icon: specs[1].icon,
            label: specs[1].label,
            child: WebViewScreen(service: 'Paperless', tabIndex: railIndex),
          ),
        ],
      );
}
