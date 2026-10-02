// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tailscale_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TailscaleStatus _$TailscaleStatusFromJson(Map<String, dynamic> json) =>
    _TailscaleStatus(
      backendState: json['BackendState'] as String,
      magicDnsSuffix: json['MagicDNSSuffix'] as String? ?? '',
      self: TailscaleDevice.fromJson(json['Self'] as Map<String, dynamic>),
      peer:
          (json['Peer'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              TailscaleDevice.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const <String, TailscaleDevice>{},
    );

Map<String, dynamic> _$TailscaleStatusToJson(_TailscaleStatus instance) =>
    <String, dynamic>{
      'BackendState': instance.backendState,
      'MagicDNSSuffix': instance.magicDnsSuffix,
      'Self': instance.self,
      'Peer': instance.peer,
    };

_TailscaleDevice _$TailscaleDeviceFromJson(Map<String, dynamic> json) =>
    _TailscaleDevice(
      hostName: json['HostName'] as String,
      dnsName: json['DNSName'] as String? ?? '',
      tailscaleIPs: (json['TailscaleIPs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      os: json['OS'] as String? ?? '',
      online: json['Online'] as bool? ?? false,
      exitNode: json['ExitNode'] as bool? ?? false,
      exitNodeOption: json['ExitNodeOption'] as bool? ?? false,
      lastSeen: json['LastSeen'] as String?,
    );

Map<String, dynamic> _$TailscaleDeviceToJson(_TailscaleDevice instance) =>
    <String, dynamic>{
      'HostName': instance.hostName,
      'DNSName': instance.dnsName,
      'TailscaleIPs': instance.tailscaleIPs,
      'OS': instance.os,
      'Online': instance.online,
      'ExitNode': instance.exitNode,
      'ExitNodeOption': instance.exitNodeOption,
      'LastSeen': instance.lastSeen,
    };
