import 'package:flutter/material.dart';

import '../../core/api/proxmox_api.dart';
import '../../core/models/proxmox_vm.dart';
import 'ct_detail_screen.dart';

/// Compatibility entry point for the shared guest-detail screen.
class VmDetailScreen extends StatelessWidget {
  const VmDetailScreen({super.key, required this.vm, this.embedded = false});

  final ProxmoxVm vm;
  final bool embedded;

  @override
  Widget build(BuildContext context) => GuestDetailScreen(
    kind: GuestKind.qemu,
    node: vm.node ?? '',
    vmid: vm.vmid,
    name: vm.name,
    embedded: embedded,
  );
}
