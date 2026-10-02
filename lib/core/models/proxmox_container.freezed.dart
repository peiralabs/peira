// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proxmox_container.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProxmoxContainer {

 int get vmid; String get status; String? get name; String? get node; double? get cpu; int? get cpus; int? get mem; int? get maxmem; int? get swap; int? get maxswap; int? get disk; int? get maxdisk; int? get uptime; int? get netin; int? get netout; int? get diskread; int? get diskwrite;
/// Create a copy of ProxmoxContainer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProxmoxContainerCopyWith<ProxmoxContainer> get copyWith => _$ProxmoxContainerCopyWithImpl<ProxmoxContainer>(this as ProxmoxContainer, _$identity);

  /// Serializes this ProxmoxContainer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProxmoxContainer&&(identical(other.vmid, vmid) || other.vmid == vmid)&&(identical(other.status, status) || other.status == status)&&(identical(other.name, name) || other.name == name)&&(identical(other.node, node) || other.node == node)&&(identical(other.cpu, cpu) || other.cpu == cpu)&&(identical(other.cpus, cpus) || other.cpus == cpus)&&(identical(other.mem, mem) || other.mem == mem)&&(identical(other.maxmem, maxmem) || other.maxmem == maxmem)&&(identical(other.swap, swap) || other.swap == swap)&&(identical(other.maxswap, maxswap) || other.maxswap == maxswap)&&(identical(other.disk, disk) || other.disk == disk)&&(identical(other.maxdisk, maxdisk) || other.maxdisk == maxdisk)&&(identical(other.uptime, uptime) || other.uptime == uptime)&&(identical(other.netin, netin) || other.netin == netin)&&(identical(other.netout, netout) || other.netout == netout)&&(identical(other.diskread, diskread) || other.diskread == diskread)&&(identical(other.diskwrite, diskwrite) || other.diskwrite == diskwrite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vmid,status,name,node,cpu,cpus,mem,maxmem,swap,maxswap,disk,maxdisk,uptime,netin,netout,diskread,diskwrite);

@override
String toString() {
  return 'ProxmoxContainer(vmid: $vmid, status: $status, name: $name, node: $node, cpu: $cpu, cpus: $cpus, mem: $mem, maxmem: $maxmem, swap: $swap, maxswap: $maxswap, disk: $disk, maxdisk: $maxdisk, uptime: $uptime, netin: $netin, netout: $netout, diskread: $diskread, diskwrite: $diskwrite)';
}


}

/// @nodoc
abstract mixin class $ProxmoxContainerCopyWith<$Res>  {
  factory $ProxmoxContainerCopyWith(ProxmoxContainer value, $Res Function(ProxmoxContainer) _then) = _$ProxmoxContainerCopyWithImpl;
@useResult
$Res call({
 int vmid, String status, String? name, String? node, double? cpu, int? cpus, int? mem, int? maxmem, int? swap, int? maxswap, int? disk, int? maxdisk, int? uptime, int? netin, int? netout, int? diskread, int? diskwrite
});




}
/// @nodoc
class _$ProxmoxContainerCopyWithImpl<$Res>
    implements $ProxmoxContainerCopyWith<$Res> {
  _$ProxmoxContainerCopyWithImpl(this._self, this._then);

  final ProxmoxContainer _self;
  final $Res Function(ProxmoxContainer) _then;

/// Create a copy of ProxmoxContainer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vmid = null,Object? status = null,Object? name = freezed,Object? node = freezed,Object? cpu = freezed,Object? cpus = freezed,Object? mem = freezed,Object? maxmem = freezed,Object? swap = freezed,Object? maxswap = freezed,Object? disk = freezed,Object? maxdisk = freezed,Object? uptime = freezed,Object? netin = freezed,Object? netout = freezed,Object? diskread = freezed,Object? diskwrite = freezed,}) {
  return _then(_self.copyWith(
vmid: null == vmid ? _self.vmid : vmid // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,node: freezed == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String?,cpu: freezed == cpu ? _self.cpu : cpu // ignore: cast_nullable_to_non_nullable
as double?,cpus: freezed == cpus ? _self.cpus : cpus // ignore: cast_nullable_to_non_nullable
as int?,mem: freezed == mem ? _self.mem : mem // ignore: cast_nullable_to_non_nullable
as int?,maxmem: freezed == maxmem ? _self.maxmem : maxmem // ignore: cast_nullable_to_non_nullable
as int?,swap: freezed == swap ? _self.swap : swap // ignore: cast_nullable_to_non_nullable
as int?,maxswap: freezed == maxswap ? _self.maxswap : maxswap // ignore: cast_nullable_to_non_nullable
as int?,disk: freezed == disk ? _self.disk : disk // ignore: cast_nullable_to_non_nullable
as int?,maxdisk: freezed == maxdisk ? _self.maxdisk : maxdisk // ignore: cast_nullable_to_non_nullable
as int?,uptime: freezed == uptime ? _self.uptime : uptime // ignore: cast_nullable_to_non_nullable
as int?,netin: freezed == netin ? _self.netin : netin // ignore: cast_nullable_to_non_nullable
as int?,netout: freezed == netout ? _self.netout : netout // ignore: cast_nullable_to_non_nullable
as int?,diskread: freezed == diskread ? _self.diskread : diskread // ignore: cast_nullable_to_non_nullable
as int?,diskwrite: freezed == diskwrite ? _self.diskwrite : diskwrite // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProxmoxContainer].
extension ProxmoxContainerPatterns on ProxmoxContainer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProxmoxContainer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProxmoxContainer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProxmoxContainer value)  $default,){
final _that = this;
switch (_that) {
case _ProxmoxContainer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProxmoxContainer value)?  $default,){
final _that = this;
switch (_that) {
case _ProxmoxContainer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int vmid,  String status,  String? name,  String? node,  double? cpu,  int? cpus,  int? mem,  int? maxmem,  int? swap,  int? maxswap,  int? disk,  int? maxdisk,  int? uptime,  int? netin,  int? netout,  int? diskread,  int? diskwrite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProxmoxContainer() when $default != null:
return $default(_that.vmid,_that.status,_that.name,_that.node,_that.cpu,_that.cpus,_that.mem,_that.maxmem,_that.swap,_that.maxswap,_that.disk,_that.maxdisk,_that.uptime,_that.netin,_that.netout,_that.diskread,_that.diskwrite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int vmid,  String status,  String? name,  String? node,  double? cpu,  int? cpus,  int? mem,  int? maxmem,  int? swap,  int? maxswap,  int? disk,  int? maxdisk,  int? uptime,  int? netin,  int? netout,  int? diskread,  int? diskwrite)  $default,) {final _that = this;
switch (_that) {
case _ProxmoxContainer():
return $default(_that.vmid,_that.status,_that.name,_that.node,_that.cpu,_that.cpus,_that.mem,_that.maxmem,_that.swap,_that.maxswap,_that.disk,_that.maxdisk,_that.uptime,_that.netin,_that.netout,_that.diskread,_that.diskwrite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int vmid,  String status,  String? name,  String? node,  double? cpu,  int? cpus,  int? mem,  int? maxmem,  int? swap,  int? maxswap,  int? disk,  int? maxdisk,  int? uptime,  int? netin,  int? netout,  int? diskread,  int? diskwrite)?  $default,) {final _that = this;
switch (_that) {
case _ProxmoxContainer() when $default != null:
return $default(_that.vmid,_that.status,_that.name,_that.node,_that.cpu,_that.cpus,_that.mem,_that.maxmem,_that.swap,_that.maxswap,_that.disk,_that.maxdisk,_that.uptime,_that.netin,_that.netout,_that.diskread,_that.diskwrite);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProxmoxContainer implements ProxmoxContainer {
  const _ProxmoxContainer({required this.vmid, required this.status, this.name, this.node, this.cpu, this.cpus, this.mem, this.maxmem, this.swap, this.maxswap, this.disk, this.maxdisk, this.uptime, this.netin, this.netout, this.diskread, this.diskwrite});
  factory _ProxmoxContainer.fromJson(Map<String, dynamic> json) => _$ProxmoxContainerFromJson(json);

@override final  int vmid;
@override final  String status;
@override final  String? name;
@override final  String? node;
@override final  double? cpu;
@override final  int? cpus;
@override final  int? mem;
@override final  int? maxmem;
@override final  int? swap;
@override final  int? maxswap;
@override final  int? disk;
@override final  int? maxdisk;
@override final  int? uptime;
@override final  int? netin;
@override final  int? netout;
@override final  int? diskread;
@override final  int? diskwrite;

/// Create a copy of ProxmoxContainer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProxmoxContainerCopyWith<_ProxmoxContainer> get copyWith => __$ProxmoxContainerCopyWithImpl<_ProxmoxContainer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProxmoxContainerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProxmoxContainer&&(identical(other.vmid, vmid) || other.vmid == vmid)&&(identical(other.status, status) || other.status == status)&&(identical(other.name, name) || other.name == name)&&(identical(other.node, node) || other.node == node)&&(identical(other.cpu, cpu) || other.cpu == cpu)&&(identical(other.cpus, cpus) || other.cpus == cpus)&&(identical(other.mem, mem) || other.mem == mem)&&(identical(other.maxmem, maxmem) || other.maxmem == maxmem)&&(identical(other.swap, swap) || other.swap == swap)&&(identical(other.maxswap, maxswap) || other.maxswap == maxswap)&&(identical(other.disk, disk) || other.disk == disk)&&(identical(other.maxdisk, maxdisk) || other.maxdisk == maxdisk)&&(identical(other.uptime, uptime) || other.uptime == uptime)&&(identical(other.netin, netin) || other.netin == netin)&&(identical(other.netout, netout) || other.netout == netout)&&(identical(other.diskread, diskread) || other.diskread == diskread)&&(identical(other.diskwrite, diskwrite) || other.diskwrite == diskwrite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vmid,status,name,node,cpu,cpus,mem,maxmem,swap,maxswap,disk,maxdisk,uptime,netin,netout,diskread,diskwrite);

@override
String toString() {
  return 'ProxmoxContainer(vmid: $vmid, status: $status, name: $name, node: $node, cpu: $cpu, cpus: $cpus, mem: $mem, maxmem: $maxmem, swap: $swap, maxswap: $maxswap, disk: $disk, maxdisk: $maxdisk, uptime: $uptime, netin: $netin, netout: $netout, diskread: $diskread, diskwrite: $diskwrite)';
}


}

/// @nodoc
abstract mixin class _$ProxmoxContainerCopyWith<$Res> implements $ProxmoxContainerCopyWith<$Res> {
  factory _$ProxmoxContainerCopyWith(_ProxmoxContainer value, $Res Function(_ProxmoxContainer) _then) = __$ProxmoxContainerCopyWithImpl;
@override @useResult
$Res call({
 int vmid, String status, String? name, String? node, double? cpu, int? cpus, int? mem, int? maxmem, int? swap, int? maxswap, int? disk, int? maxdisk, int? uptime, int? netin, int? netout, int? diskread, int? diskwrite
});




}
/// @nodoc
class __$ProxmoxContainerCopyWithImpl<$Res>
    implements _$ProxmoxContainerCopyWith<$Res> {
  __$ProxmoxContainerCopyWithImpl(this._self, this._then);

  final _ProxmoxContainer _self;
  final $Res Function(_ProxmoxContainer) _then;

/// Create a copy of ProxmoxContainer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vmid = null,Object? status = null,Object? name = freezed,Object? node = freezed,Object? cpu = freezed,Object? cpus = freezed,Object? mem = freezed,Object? maxmem = freezed,Object? swap = freezed,Object? maxswap = freezed,Object? disk = freezed,Object? maxdisk = freezed,Object? uptime = freezed,Object? netin = freezed,Object? netout = freezed,Object? diskread = freezed,Object? diskwrite = freezed,}) {
  return _then(_ProxmoxContainer(
vmid: null == vmid ? _self.vmid : vmid // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,node: freezed == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String?,cpu: freezed == cpu ? _self.cpu : cpu // ignore: cast_nullable_to_non_nullable
as double?,cpus: freezed == cpus ? _self.cpus : cpus // ignore: cast_nullable_to_non_nullable
as int?,mem: freezed == mem ? _self.mem : mem // ignore: cast_nullable_to_non_nullable
as int?,maxmem: freezed == maxmem ? _self.maxmem : maxmem // ignore: cast_nullable_to_non_nullable
as int?,swap: freezed == swap ? _self.swap : swap // ignore: cast_nullable_to_non_nullable
as int?,maxswap: freezed == maxswap ? _self.maxswap : maxswap // ignore: cast_nullable_to_non_nullable
as int?,disk: freezed == disk ? _self.disk : disk // ignore: cast_nullable_to_non_nullable
as int?,maxdisk: freezed == maxdisk ? _self.maxdisk : maxdisk // ignore: cast_nullable_to_non_nullable
as int?,uptime: freezed == uptime ? _self.uptime : uptime // ignore: cast_nullable_to_non_nullable
as int?,netin: freezed == netin ? _self.netin : netin // ignore: cast_nullable_to_non_nullable
as int?,netout: freezed == netout ? _self.netout : netout // ignore: cast_nullable_to_non_nullable
as int?,diskread: freezed == diskread ? _self.diskread : diskread // ignore: cast_nullable_to_non_nullable
as int?,diskwrite: freezed == diskwrite ? _self.diskwrite : diskwrite // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
