import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/pbs_api.dart';
import '../../core/providers/pbs_providers.dart';

Future<PbsApi?> requireElevated(
  BuildContext context,
  WidgetRef ref,
  PbsSlot slot,
) async {
  final elevation = ref.read(pbsElevationProvider.notifier);
  final existing = await elevation.elevatedApi(slot);
  if (existing != null || !context.mounted) return existing;
  final config = await ref.read(pbsConfigProvider(slot).future);
  if (!context.mounted) return null;
  return showDialog<PbsApi>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ElevateDialog(slot: slot, config: config),
  );
}

class _ElevateDialog extends ConsumerStatefulWidget {
  const _ElevateDialog({required this.slot, required this.config});
  final PbsSlot slot;
  final PbsServerConfig config;

  @override
  ConsumerState<_ElevateDialog> createState() => _ElevateDialogState();
}

class _ElevateDialogState extends ConsumerState<_ElevateDialog> {
  final _password = TextEditingController();
  Object? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_password.text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = await ref
          .read(pbsElevationProvider.notifier)
          .elevate(widget.slot, _password.text);
      if (mounted) Navigator.pop(context, api);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Unlock ${widget.config.name} as ${widget.config.user}'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'The password is never stored or logged. The unlocked session is kept only in memory for 30 minutes.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: true,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error == null
                  ? null
                  : _error is PbsTfaRequired
                  ? 'TFA accounts are not supported yet'
                  : 'Unlock failed: $_error',
            ),
            onSubmitted: (_) => _unlock(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : _unlock,
        child: _busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Unlock'),
      ),
    ],
  );
}
