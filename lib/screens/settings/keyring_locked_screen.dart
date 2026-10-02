import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/brass_panel.dart';

/// Shown when settings can't be loaded because the platform keyring is locked.
///
/// The app's credentials are safe on disk — the secret store just can't be
/// read right now. This replaces the old failure mode, where a locked keyring
/// silently dropped the user onto a blank first-launch Settings screen, making
/// it look like every setting had been lost.
///
/// [onRetry] re-reads the keyring. On Linux the read itself asks the secret
/// service to unlock the default collection, so retrying is what triggers the
/// desktop unlock prompt — unlock, then retry.
class KeyringLockedScreen extends StatelessWidget {
  const KeyringLockedScreen({
    super.key,
    required this.onRetry,
    this.retrying = false,
  });

  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final brass = context.brass;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: BrassPanel(
              topRule: true,
              topRuleColor: brass.warn,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, color: brass.warn),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Keyring locked', style: text.titleLarge),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your saved settings and credentials are safe on disk, but '
                    'the system keyring is locked so they can\'t be read right '
                    'now.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unlock your login keyring (log out and back in, or unlock '
                    'it with your keyring manager), then retry. Retrying will '
                    'ask the keyring to unlock, so you may see a system unlock '
                    'prompt.',
                    style: text.bodyMedium?.copyWith(
                      color: text.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: retrying ? null : onRetry,
                      icon: retrying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_open_outlined),
                      label: Text(retrying ? 'Unlocking…' : 'Unlock & retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
