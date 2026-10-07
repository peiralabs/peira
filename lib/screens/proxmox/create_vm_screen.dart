import 'package:flutter/material.dart';

import '../../core/api/proxmox_api.dart';
import 'create_container_screen.dart';

/// Compatibility entry point for the shared guest-create form.
class CreateVmScreen extends StatelessWidget {
  const CreateVmScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const CreateGuestScreen(kind: GuestKind.qemu);
}
