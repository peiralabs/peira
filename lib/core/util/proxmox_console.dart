import 'open_url.dart';

/// Opens a guest's Proxmox noVNC console in the system browser.
///
/// An embedded CEF console isn't viable: the Proxmox host serves a self-signed
/// cert (which CEF blocks, unlike the plain-HTTP Grafana/Wiki webviews) and the
/// noVNC page needs a cookie session the app's API-token auth can't mint. The
/// system browser handles both — a remembered cert exception and the operator's
/// existing PVE login — so we hand off to it.
///
/// [kind] is `kvm` for VMs or `lxc` for containers. Returns null on success or
/// a human error string on failure.
Future<String?> openProxmoxConsole({
  required String proxmoxUrl,
  required String node,
  required int vmid,
  required String kind,
}) async {
  final base = proxmoxUrl.trim();
  if (base.isEmpty) return 'Set the Proxmox URL in Settings first.';
  final url =
      '$base/?console=$kind&novnc=1&vmid=$vmid&node=$node&resize=scale';
  return openUrl(url);
}
