import 'package:flutter/material.dart';

import '../../core/navigation/app_tab.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/hub_scaffold.dart';
import '../karakeep/karakeep_screen.dart';
import '../paperless/paperless_screen.dart';

/// The Library hub: Karakeep (bookmarks / read-later with local-AI tagging)
/// and Paperless-ngx (documents with OCR search) — the reading and records
/// shelf, one rail slot for both. Both sub-views are native over each
/// service's API.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.railIndex});

  /// This hub's index in the shell's rail. Kept for the shell's uniform hub
  /// API; nothing here activates lazily any more.
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
            child: const KarakeepScreen(),
          ),
          HubTab(
            icon: specs[1].icon,
            label: specs[1].label,
            child: const PaperlessScreen(),
          ),
        ],
      );
}
