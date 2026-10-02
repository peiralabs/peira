import 'package:freezed_annotation/freezed_annotation.dart';

part 'tailscale_status.freezed.dart';
part 'tailscale_status.g.dart';

/// Parsed subset of `tailscale status --json`.
@freezed
abstract class TailscaleStatus with _$TailscaleStatus {
  const TailscaleStatus._();

  const factory TailscaleStatus({
    @JsonKey(name: 'BackendState') required String backendState,
    @JsonKey(name: 'MagicDNSSuffix') @Default('') String magicDnsSuffix,
    @JsonKey(name: 'Self') required TailscaleDevice self,
    @JsonKey(name: 'Peer')
    @Default(<String, TailscaleDevice>{})
    Map<String, TailscaleDevice> peer,
  }) = _TailscaleStatus;

  factory TailscaleStatus.fromJson(Map<String, dynamic> json) =>
      _$TailscaleStatusFromJson(json);

  bool get running => backendState == 'Running';

  /// Peers sorted online-first, then by host name.
  List<TailscaleDevice> get peers {
    final list = peer.values.toList()
      ..sort((a, b) {
        if (a.online != b.online) return a.online ? -1 : 1;
        return a.hostName.toLowerCase().compareTo(b.hostName.toLowerCase());
      });
    return list;
  }
}

@freezed
abstract class TailscaleDevice with _$TailscaleDevice {
  const TailscaleDevice._();

  const factory TailscaleDevice({
    @JsonKey(name: 'HostName') required String hostName,
    @JsonKey(name: 'DNSName') @Default('') String dnsName,
    @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,
    @JsonKey(name: 'OS') @Default('') String os,
    @JsonKey(name: 'Online') @Default(false) bool online,
    @JsonKey(name: 'ExitNode') @Default(false) bool exitNode,
    @JsonKey(name: 'ExitNodeOption') @Default(false) bool exitNodeOption,
    @JsonKey(name: 'LastSeen') String? lastSeen,
  }) = _TailscaleDevice;

  factory TailscaleDevice.fromJson(Map<String, dynamic> json) =>
      _$TailscaleDeviceFromJson(json);

  /// First (IPv4) Tailscale address, or empty.
  String get ip =>
      (tailscaleIPs?.isNotEmpty ?? false) ? tailscaleIPs!.first : '';
}
