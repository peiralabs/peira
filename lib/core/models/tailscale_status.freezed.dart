// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tailscale_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TailscaleStatus {

@JsonKey(name: 'BackendState') String get backendState;@JsonKey(name: 'MagicDNSSuffix') String get magicDnsSuffix;@JsonKey(name: 'Self') TailscaleDevice get self;@JsonKey(name: 'Peer') Map<String, TailscaleDevice> get peer;
/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscaleStatusCopyWith<TailscaleStatus> get copyWith => _$TailscaleStatusCopyWithImpl<TailscaleStatus>(this as TailscaleStatus, _$identity);

  /// Serializes this TailscaleStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscaleStatus&&(identical(other.backendState, backendState) || other.backendState == backendState)&&(identical(other.magicDnsSuffix, magicDnsSuffix) || other.magicDnsSuffix == magicDnsSuffix)&&(identical(other.self, self) || other.self == self)&&const DeepCollectionEquality().equals(other.peer, peer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,backendState,magicDnsSuffix,self,const DeepCollectionEquality().hash(peer));

@override
String toString() {
  return 'TailscaleStatus(backendState: $backendState, magicDnsSuffix: $magicDnsSuffix, self: $self, peer: $peer)';
}


}

/// @nodoc
abstract mixin class $TailscaleStatusCopyWith<$Res>  {
  factory $TailscaleStatusCopyWith(TailscaleStatus value, $Res Function(TailscaleStatus) _then) = _$TailscaleStatusCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'BackendState') String backendState,@JsonKey(name: 'MagicDNSSuffix') String magicDnsSuffix,@JsonKey(name: 'Self') TailscaleDevice self,@JsonKey(name: 'Peer') Map<String, TailscaleDevice> peer
});


$TailscaleDeviceCopyWith<$Res> get self;

}
/// @nodoc
class _$TailscaleStatusCopyWithImpl<$Res>
    implements $TailscaleStatusCopyWith<$Res> {
  _$TailscaleStatusCopyWithImpl(this._self, this._then);

  final TailscaleStatus _self;
  final $Res Function(TailscaleStatus) _then;

/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backendState = null,Object? magicDnsSuffix = null,Object? self = null,Object? peer = null,}) {
  return _then(_self.copyWith(
backendState: null == backendState ? _self.backendState : backendState // ignore: cast_nullable_to_non_nullable
as String,magicDnsSuffix: null == magicDnsSuffix ? _self.magicDnsSuffix : magicDnsSuffix // ignore: cast_nullable_to_non_nullable
as String,self: null == self ? _self.self : self // ignore: cast_nullable_to_non_nullable
as TailscaleDevice,peer: null == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as Map<String, TailscaleDevice>,
  ));
}
/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TailscaleDeviceCopyWith<$Res> get self {
  
  return $TailscaleDeviceCopyWith<$Res>(_self.self, (value) {
    return _then(_self.copyWith(self: value));
  });
}
}


/// Adds pattern-matching-related methods to [TailscaleStatus].
extension TailscaleStatusPatterns on TailscaleStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailscaleStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailscaleStatus value)  $default,){
final _that = this;
switch (_that) {
case _TailscaleStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailscaleStatus value)?  $default,){
final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'BackendState')  String backendState, @JsonKey(name: 'MagicDNSSuffix')  String magicDnsSuffix, @JsonKey(name: 'Self')  TailscaleDevice self, @JsonKey(name: 'Peer')  Map<String, TailscaleDevice> peer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
return $default(_that.backendState,_that.magicDnsSuffix,_that.self,_that.peer);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'BackendState')  String backendState, @JsonKey(name: 'MagicDNSSuffix')  String magicDnsSuffix, @JsonKey(name: 'Self')  TailscaleDevice self, @JsonKey(name: 'Peer')  Map<String, TailscaleDevice> peer)  $default,) {final _that = this;
switch (_that) {
case _TailscaleStatus():
return $default(_that.backendState,_that.magicDnsSuffix,_that.self,_that.peer);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'BackendState')  String backendState, @JsonKey(name: 'MagicDNSSuffix')  String magicDnsSuffix, @JsonKey(name: 'Self')  TailscaleDevice self, @JsonKey(name: 'Peer')  Map<String, TailscaleDevice> peer)?  $default,) {final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
return $default(_that.backendState,_that.magicDnsSuffix,_that.self,_that.peer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailscaleStatus extends TailscaleStatus {
  const _TailscaleStatus({@JsonKey(name: 'BackendState') required this.backendState, @JsonKey(name: 'MagicDNSSuffix') this.magicDnsSuffix = '', @JsonKey(name: 'Self') required this.self, @JsonKey(name: 'Peer') final  Map<String, TailscaleDevice> peer = const <String, TailscaleDevice>{}}): _peer = peer,super._();
  factory _TailscaleStatus.fromJson(Map<String, dynamic> json) => _$TailscaleStatusFromJson(json);

@override@JsonKey(name: 'BackendState') final  String backendState;
@override@JsonKey(name: 'MagicDNSSuffix') final  String magicDnsSuffix;
@override@JsonKey(name: 'Self') final  TailscaleDevice self;
 final  Map<String, TailscaleDevice> _peer;
@override@JsonKey(name: 'Peer') Map<String, TailscaleDevice> get peer {
  if (_peer is EqualUnmodifiableMapView) return _peer;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_peer);
}


/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscaleStatusCopyWith<_TailscaleStatus> get copyWith => __$TailscaleStatusCopyWithImpl<_TailscaleStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailscaleStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscaleStatus&&(identical(other.backendState, backendState) || other.backendState == backendState)&&(identical(other.magicDnsSuffix, magicDnsSuffix) || other.magicDnsSuffix == magicDnsSuffix)&&(identical(other.self, self) || other.self == self)&&const DeepCollectionEquality().equals(other._peer, _peer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,backendState,magicDnsSuffix,self,const DeepCollectionEquality().hash(_peer));

@override
String toString() {
  return 'TailscaleStatus(backendState: $backendState, magicDnsSuffix: $magicDnsSuffix, self: $self, peer: $peer)';
}


}

/// @nodoc
abstract mixin class _$TailscaleStatusCopyWith<$Res> implements $TailscaleStatusCopyWith<$Res> {
  factory _$TailscaleStatusCopyWith(_TailscaleStatus value, $Res Function(_TailscaleStatus) _then) = __$TailscaleStatusCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'BackendState') String backendState,@JsonKey(name: 'MagicDNSSuffix') String magicDnsSuffix,@JsonKey(name: 'Self') TailscaleDevice self,@JsonKey(name: 'Peer') Map<String, TailscaleDevice> peer
});


@override $TailscaleDeviceCopyWith<$Res> get self;

}
/// @nodoc
class __$TailscaleStatusCopyWithImpl<$Res>
    implements _$TailscaleStatusCopyWith<$Res> {
  __$TailscaleStatusCopyWithImpl(this._self, this._then);

  final _TailscaleStatus _self;
  final $Res Function(_TailscaleStatus) _then;

/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? backendState = null,Object? magicDnsSuffix = null,Object? self = null,Object? peer = null,}) {
  return _then(_TailscaleStatus(
backendState: null == backendState ? _self.backendState : backendState // ignore: cast_nullable_to_non_nullable
as String,magicDnsSuffix: null == magicDnsSuffix ? _self.magicDnsSuffix : magicDnsSuffix // ignore: cast_nullable_to_non_nullable
as String,self: null == self ? _self.self : self // ignore: cast_nullable_to_non_nullable
as TailscaleDevice,peer: null == peer ? _self._peer : peer // ignore: cast_nullable_to_non_nullable
as Map<String, TailscaleDevice>,
  ));
}

/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TailscaleDeviceCopyWith<$Res> get self {
  
  return $TailscaleDeviceCopyWith<$Res>(_self.self, (value) {
    return _then(_self.copyWith(self: value));
  });
}
}


/// @nodoc
mixin _$TailscaleDevice {

@JsonKey(name: 'HostName') String get hostName;@JsonKey(name: 'DNSName') String get dnsName;@JsonKey(name: 'TailscaleIPs') List<String>? get tailscaleIPs;@JsonKey(name: 'OS') String get os;@JsonKey(name: 'Online') bool get online;@JsonKey(name: 'ExitNode') bool get exitNode;@JsonKey(name: 'ExitNodeOption') bool get exitNodeOption;@JsonKey(name: 'LastSeen') String? get lastSeen;
/// Create a copy of TailscaleDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscaleDeviceCopyWith<TailscaleDevice> get copyWith => _$TailscaleDeviceCopyWithImpl<TailscaleDevice>(this as TailscaleDevice, _$identity);

  /// Serializes this TailscaleDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscaleDevice&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.dnsName, dnsName) || other.dnsName == dnsName)&&const DeepCollectionEquality().equals(other.tailscaleIPs, tailscaleIPs)&&(identical(other.os, os) || other.os == os)&&(identical(other.online, online) || other.online == online)&&(identical(other.exitNode, exitNode) || other.exitNode == exitNode)&&(identical(other.exitNodeOption, exitNodeOption) || other.exitNodeOption == exitNodeOption)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hostName,dnsName,const DeepCollectionEquality().hash(tailscaleIPs),os,online,exitNode,exitNodeOption,lastSeen);

@override
String toString() {
  return 'TailscaleDevice(hostName: $hostName, dnsName: $dnsName, tailscaleIPs: $tailscaleIPs, os: $os, online: $online, exitNode: $exitNode, exitNodeOption: $exitNodeOption, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class $TailscaleDeviceCopyWith<$Res>  {
  factory $TailscaleDeviceCopyWith(TailscaleDevice value, $Res Function(TailscaleDevice) _then) = _$TailscaleDeviceCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'HostName') String hostName,@JsonKey(name: 'DNSName') String dnsName,@JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,@JsonKey(name: 'OS') String os,@JsonKey(name: 'Online') bool online,@JsonKey(name: 'ExitNode') bool exitNode,@JsonKey(name: 'ExitNodeOption') bool exitNodeOption,@JsonKey(name: 'LastSeen') String? lastSeen
});




}
/// @nodoc
class _$TailscaleDeviceCopyWithImpl<$Res>
    implements $TailscaleDeviceCopyWith<$Res> {
  _$TailscaleDeviceCopyWithImpl(this._self, this._then);

  final TailscaleDevice _self;
  final $Res Function(TailscaleDevice) _then;

/// Create a copy of TailscaleDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hostName = null,Object? dnsName = null,Object? tailscaleIPs = freezed,Object? os = null,Object? online = null,Object? exitNode = null,Object? exitNodeOption = null,Object? lastSeen = freezed,}) {
  return _then(_self.copyWith(
hostName: null == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String,dnsName: null == dnsName ? _self.dnsName : dnsName // ignore: cast_nullable_to_non_nullable
as String,tailscaleIPs: freezed == tailscaleIPs ? _self.tailscaleIPs : tailscaleIPs // ignore: cast_nullable_to_non_nullable
as List<String>?,os: null == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,exitNode: null == exitNode ? _self.exitNode : exitNode // ignore: cast_nullable_to_non_nullable
as bool,exitNodeOption: null == exitNodeOption ? _self.exitNodeOption : exitNodeOption // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TailscaleDevice].
extension TailscaleDevicePatterns on TailscaleDevice {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailscaleDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailscaleDevice() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailscaleDevice value)  $default,){
final _that = this;
switch (_that) {
case _TailscaleDevice():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailscaleDevice value)?  $default,){
final _that = this;
switch (_that) {
case _TailscaleDevice() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'HostName')  String hostName, @JsonKey(name: 'DNSName')  String dnsName, @JsonKey(name: 'TailscaleIPs')  List<String>? tailscaleIPs, @JsonKey(name: 'OS')  String os, @JsonKey(name: 'Online')  bool online, @JsonKey(name: 'ExitNode')  bool exitNode, @JsonKey(name: 'ExitNodeOption')  bool exitNodeOption, @JsonKey(name: 'LastSeen')  String? lastSeen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscaleDevice() when $default != null:
return $default(_that.hostName,_that.dnsName,_that.tailscaleIPs,_that.os,_that.online,_that.exitNode,_that.exitNodeOption,_that.lastSeen);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'HostName')  String hostName, @JsonKey(name: 'DNSName')  String dnsName, @JsonKey(name: 'TailscaleIPs')  List<String>? tailscaleIPs, @JsonKey(name: 'OS')  String os, @JsonKey(name: 'Online')  bool online, @JsonKey(name: 'ExitNode')  bool exitNode, @JsonKey(name: 'ExitNodeOption')  bool exitNodeOption, @JsonKey(name: 'LastSeen')  String? lastSeen)  $default,) {final _that = this;
switch (_that) {
case _TailscaleDevice():
return $default(_that.hostName,_that.dnsName,_that.tailscaleIPs,_that.os,_that.online,_that.exitNode,_that.exitNodeOption,_that.lastSeen);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'HostName')  String hostName, @JsonKey(name: 'DNSName')  String dnsName, @JsonKey(name: 'TailscaleIPs')  List<String>? tailscaleIPs, @JsonKey(name: 'OS')  String os, @JsonKey(name: 'Online')  bool online, @JsonKey(name: 'ExitNode')  bool exitNode, @JsonKey(name: 'ExitNodeOption')  bool exitNodeOption, @JsonKey(name: 'LastSeen')  String? lastSeen)?  $default,) {final _that = this;
switch (_that) {
case _TailscaleDevice() when $default != null:
return $default(_that.hostName,_that.dnsName,_that.tailscaleIPs,_that.os,_that.online,_that.exitNode,_that.exitNodeOption,_that.lastSeen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailscaleDevice extends TailscaleDevice {
  const _TailscaleDevice({@JsonKey(name: 'HostName') required this.hostName, @JsonKey(name: 'DNSName') this.dnsName = '', @JsonKey(name: 'TailscaleIPs') final  List<String>? tailscaleIPs, @JsonKey(name: 'OS') this.os = '', @JsonKey(name: 'Online') this.online = false, @JsonKey(name: 'ExitNode') this.exitNode = false, @JsonKey(name: 'ExitNodeOption') this.exitNodeOption = false, @JsonKey(name: 'LastSeen') this.lastSeen}): _tailscaleIPs = tailscaleIPs,super._();
  factory _TailscaleDevice.fromJson(Map<String, dynamic> json) => _$TailscaleDeviceFromJson(json);

@override@JsonKey(name: 'HostName') final  String hostName;
@override@JsonKey(name: 'DNSName') final  String dnsName;
 final  List<String>? _tailscaleIPs;
@override@JsonKey(name: 'TailscaleIPs') List<String>? get tailscaleIPs {
  final value = _tailscaleIPs;
  if (value == null) return null;
  if (_tailscaleIPs is EqualUnmodifiableListView) return _tailscaleIPs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'OS') final  String os;
@override@JsonKey(name: 'Online') final  bool online;
@override@JsonKey(name: 'ExitNode') final  bool exitNode;
@override@JsonKey(name: 'ExitNodeOption') final  bool exitNodeOption;
@override@JsonKey(name: 'LastSeen') final  String? lastSeen;

/// Create a copy of TailscaleDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscaleDeviceCopyWith<_TailscaleDevice> get copyWith => __$TailscaleDeviceCopyWithImpl<_TailscaleDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailscaleDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscaleDevice&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.dnsName, dnsName) || other.dnsName == dnsName)&&const DeepCollectionEquality().equals(other._tailscaleIPs, _tailscaleIPs)&&(identical(other.os, os) || other.os == os)&&(identical(other.online, online) || other.online == online)&&(identical(other.exitNode, exitNode) || other.exitNode == exitNode)&&(identical(other.exitNodeOption, exitNodeOption) || other.exitNodeOption == exitNodeOption)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hostName,dnsName,const DeepCollectionEquality().hash(_tailscaleIPs),os,online,exitNode,exitNodeOption,lastSeen);

@override
String toString() {
  return 'TailscaleDevice(hostName: $hostName, dnsName: $dnsName, tailscaleIPs: $tailscaleIPs, os: $os, online: $online, exitNode: $exitNode, exitNodeOption: $exitNodeOption, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class _$TailscaleDeviceCopyWith<$Res> implements $TailscaleDeviceCopyWith<$Res> {
  factory _$TailscaleDeviceCopyWith(_TailscaleDevice value, $Res Function(_TailscaleDevice) _then) = __$TailscaleDeviceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'HostName') String hostName,@JsonKey(name: 'DNSName') String dnsName,@JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,@JsonKey(name: 'OS') String os,@JsonKey(name: 'Online') bool online,@JsonKey(name: 'ExitNode') bool exitNode,@JsonKey(name: 'ExitNodeOption') bool exitNodeOption,@JsonKey(name: 'LastSeen') String? lastSeen
});




}
/// @nodoc
class __$TailscaleDeviceCopyWithImpl<$Res>
    implements _$TailscaleDeviceCopyWith<$Res> {
  __$TailscaleDeviceCopyWithImpl(this._self, this._then);

  final _TailscaleDevice _self;
  final $Res Function(_TailscaleDevice) _then;

/// Create a copy of TailscaleDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hostName = null,Object? dnsName = null,Object? tailscaleIPs = freezed,Object? os = null,Object? online = null,Object? exitNode = null,Object? exitNodeOption = null,Object? lastSeen = freezed,}) {
  return _then(_TailscaleDevice(
hostName: null == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String,dnsName: null == dnsName ? _self.dnsName : dnsName // ignore: cast_nullable_to_non_nullable
as String,tailscaleIPs: freezed == tailscaleIPs ? _self._tailscaleIPs : tailscaleIPs // ignore: cast_nullable_to_non_nullable
as List<String>?,os: null == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,exitNode: null == exitNode ? _self.exitNode : exitNode // ignore: cast_nullable_to_non_nullable
as bool,exitNodeOption: null == exitNodeOption ? _self.exitNodeOption : exitNodeOption // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
