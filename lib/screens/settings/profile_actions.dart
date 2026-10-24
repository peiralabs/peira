import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_providers.dart';
import '../../core/settings/profile_store.dart';
import '../proxmox/proxmox_screen.dart' show selectedGuestProvider;

/// Where "Cancel" in the setup wizard returns to after "New from setup"
/// switched onto a blank profile. Null when the wizard is a first launch.
final setupReturnProvider = NotifierProvider<SetupReturn, SetupReturnTarget?>(
  SetupReturn.new,
);

class SetupReturnTarget {
  const SetupReturnTarget({required this.returnTo, required this.blankId});

  /// Profile to switch back to.
  final ConnectionProfile returnTo;

  /// The blank profile being set up, deleted on cancel.
  final String blankId;
}

class SetupReturn extends Notifier<SetupReturnTarget?> {
  @override
  SetupReturnTarget? build() => null;

  void set(SetupReturnTarget? target) => state = target;
}

/// Switches the live settings to profile [id] and clears per-cluster UI
/// selection (an open guest pane from the old cluster).
Future<void> switchProfile(WidgetRef ref, String id) async {
  ref.read(selectedGuestProvider.notifier).select(null);
  await ref.read(profilesControllerProvider.notifier).switchTo(id);
}

/// "New from setup": a blank profile, switched to, so the shell shows the
/// setup wizard; Cancel there comes back to the current profile.
Future<void> newProfileFromSetup(WidgetRef ref, String name) async {
  final profiles = ref.read(profilesControllerProvider.notifier);
  final current = (await ref.read(profilesControllerProvider.future)).active;
  final blank = await profiles.create(name, duplicate: false);
  ref
      .read(setupReturnProvider.notifier)
      .set(SetupReturnTarget(returnTo: current, blankId: blank.id));
  await switchProfile(ref, blank.id);
}

/// Wizard Cancel: back to the profile we came from, and drop the blank one.
Future<void> cancelNewProfile(WidgetRef ref) async {
  final target = ref.read(setupReturnProvider);
  if (target == null) return;
  await switchProfile(ref, target.returnTo.id);
  await ref.read(profilesControllerProvider.notifier).delete(target.blankId);
  ref.read(setupReturnProvider.notifier).set(null);
}

/// Asks for a profile name. Returns null on cancel or an empty name.
Future<String?> promptProfileName(
  BuildContext context, {
  required String title,
  String initial = '',
  String action = 'Save',
}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) =>
        _ProfileNameDialog(title: title, initial: initial, action: action),
  );
  final trimmed = name?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Owns its controller so it outlives the dialog's exit animation.
class _ProfileNameDialog extends StatefulWidget {
  const _ProfileNameDialog({
    required this.title,
    required this.initial,
    required this.action,
  });

  final String title;
  final String initial;
  final String action;

  @override
  State<_ProfileNameDialog> createState() => _ProfileNameDialogState();
}

class _ProfileNameDialogState extends State<_ProfileNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const ValueKey('profile-name-field'),
      controller: _controller,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Profile name'),
      onSubmitted: (v) => Navigator.of(context).pop(v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text),
        child: Text(widget.action),
      ),
    ],
  );
}

enum _FooterAction { reconnect, manage }

/// The rail footer's menu: every profile (tap to switch), then Reconnect and
/// Manage profiles. Anchored above [anchor] (the footer).
Future<void> showProfileMenu(
  BuildContext anchor,
  WidgetRef ref, {
  required VoidCallback onReconnect,
  required VoidCallback onManage,
}) async {
  final state =
      ref.read(profilesControllerProvider).value ?? ProfileState.legacy;
  final box = anchor.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(anchor).overlay!.context.findRenderObject()! as RenderBox;
  final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
  final position = RelativeRect.fromRect(
    topLeft & box.size,
    Offset.zero & overlay.size,
  );

  final picked = await showMenu<Object>(
    context: anchor,
    position: position,
    items: [
      for (final p in state.profiles)
        CheckedPopupMenuItem<Object>(
          key: ValueKey('profile-menu-${p.id}'),
          value: p,
          checked: p.id == state.activeId,
          child: Text(p.name),
        ),
      const PopupMenuDivider(),
      const PopupMenuItem<Object>(
        value: _FooterAction.reconnect,
        child: Text('Reconnect'),
      ),
      const PopupMenuItem<Object>(
        value: _FooterAction.manage,
        child: Text('Manage profiles…'),
      ),
    ],
  );
  switch (picked) {
    case final ConnectionProfile p when p.id != state.activeId:
      await switchProfile(ref, p.id);
    case _FooterAction.reconnect:
      onReconnect();
    case _FooterAction.manage:
      onManage();
    default:
      break;
  }
}
