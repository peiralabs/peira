import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/app_tab.dart';
import '../providers/navigation_providers.dart';
import '../theme/app_theme.dart';
import '../theme/phosphor.dart';
import '../util/open_url.dart';
import 'screen_header.dart';

/// Opens [url] in the system browser, reporting a failure in a snackbar.
Future<void> openInBrowser(BuildContext context, String url) async {
  final error = await openUrl(url);
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

/// The "Open in browser" button every native service tab carries, for what
/// the service's API (or its key's rights) cannot do from the app.
class OpenInBrowserButton extends StatelessWidget {
  const OpenInBrowserButton({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: url.isEmpty ? null : () => openInBrowser(context, url),
    icon: const Icon(Icons.open_in_new, size: 16),
    label: const Text('Open in browser'),
  );
}

/// Shell of a native service tab: a header with the browser button, then
/// [child]. Until the service has a URL and its API credential, it shows
/// what is missing and links to Settings instead.
class ServiceFrame extends ConsumerWidget {
  const ServiceFrame({
    super.key,
    required this.service,
    required this.icon,
    required this.subtitle,
    required this.url,
    required this.configured,
    required this.credentialName,
    required this.child,
    this.trailing = const [],
  });

  final String service;
  final IconData icon;
  final String subtitle;
  final String url;

  /// True once the URL and the API credential are both saved.
  final bool configured;

  /// What Settings calls the missing credential, e.g. "long-lived access
  /// token".
  final String credentialName;
  final Widget child;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      child: ScreenHeader(
        icon: icon,
        title: service,
        subtitle: subtitle,
        trailing: [
          ...trailing,
          if (trailing.isNotEmpty) const SizedBox(width: 8),
          OpenInBrowserButton(url: url),
        ],
      ),
    );
    if (configured) {
      return Column(
        children: [
          header,
          Expanded(child: child),
        ],
      );
    }
    final brass = context.brass;
    return Column(
      children: [
        header,
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Ph.lockSimple, size: 40, color: brass.textMuted),
                  const SizedBox(height: 14),
                  Text(
                    url.isEmpty
                        ? '$service has no URL yet.'
                        : '$service needs its $credentialName.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add it in Settings to control $service from here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: brass.textMuted),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => ref
                        .read(selectedTabProvider.notifier)
                        .select(AppTab.settings.railIndex),
                    icon: const Icon(Ph.gearSix),
                    label: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A one-line error with a retry, for a failed service read.
class ServiceError extends StatelessWidget {
  const ServiceError({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            describeServiceError(error),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.brass.crit),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

/// A short human message for an API failure; never echoes request headers.
String describeServiceError(Object error) {
  final text = error.toString();
  final status = RegExp(r'status code of (\d{3})').firstMatch(text)?.group(1);
  return switch (status) {
    '401' || '403' => 'The service rejected the API key (HTTP $status).',
    '404' => 'Not found on this server (HTTP 404).',
    final s? => 'The service answered HTTP $s.',
    null when text.contains('SocketException') || text.contains('connection') =>
      'Could not reach the service.',
    null => text.length > 200 ? '${text.substring(0, 200)}…' : text,
  };
}
