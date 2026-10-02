// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'container_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContainerStatus {

 String get status; int? get vmid; String? get name; double? get cpu; int? get cpus; int? get mem; int? get maxmem; int? get swap; int? get maxswap; int? get disk; int? get maxdisk; int? get uptime; int? get netin; int? get netout; int? get diskread; int? get diskwrite;
/// Create a copy of ContainerStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContainerStatusCopyWith<ContainerStatus> get copyWith => _$ContainerStatusCopyWithImpl<ContainerStatus>(this as ContainerStatus, _$identity);

  /// Serializes this ContainerStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContainerStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.vmid, vmid) || other.vmid == vmid)&&(identical(other.name, name) || other.name == name)&&(identical(other.cpu, cpu) || other.cpu == cpu)&&(identical(other.cpus, cpus) || other.cpus == cpus)&&(identical(other.mem, mem) || other.mem == mem)&&(identical(other.maxmem, maxmem) || other.maxmem == maxmem)&&(identical(other.swap, swap) || other.swap == swap)&&(identical(other.maxswap, maxswap) || other.maxswap == maxswap)&&(identical(other.disk, disk) || other.disk == disk)&&(identical(other.maxdisk, maxdisk) || other.maxdisk == maxdisk)&&(identical(other.uptime, uptime) || other.uptime == uptime)&&(identical(other.netin, netin) || other.netin == netin)&&(identical(other.netout, netout) || other.netout == netout)&&(identical(other.diskread, diskread) || other.diskread == diskread)&&(identical(other.diskwrite, diskwrite) || other.diskwrite == diskwrite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,vmid,name,cpu,cpus,mem,maxmem,swap,maxswap,disk,maxdisk,uptime,netin,netout,diskread,diskwrite);

@override
String toString() {
  return 'ContainerStatus(status: $status, vmid: $vmid, name: $name, cpu: $cpu, cpus: $cpus, mem: $mem, maxmem: $maxmem, swap: $swap, maxswap: $maxswap, disk: $disk, maxdisk: $maxdisk, uptime: $uptime, netin: $netin, netout: $netout, diskread: $diskread, diskwrite: $diskwrite)';
}


}

/// @nodoc
abstract mixin class $ContainerStatusCopyWith<$Res>  {
  factory $ContainerStatusCopyWith(ContainerStatus value, $Res Function(ContainerStatus) _then) = _$ContainerStatusCopyWithImpl;
@useResult
$Res call({
 String status, int? vmid, String? name, double? cpu, int? cpus, int? mem, int? maxmem, int? swap, int? maxswap, int? disk, int? maxdisk, int? uptime, int? netin, int? netout, int? diskread, int? diskwrite
});




}
/// @nodoc
class _$ContainerStatusCopyWithImpl<$Res>
    implements $ContainerStatusCopyWith<$Res> {
  _$ContainerStatusCopyWithImpl(this._self, this._then);

  final ContainerStatus _self;
  final $Res Function(ContainerStatus) _then;

/// Create a copy of ContainerStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? vmid = freezed,Object? name = freezed,Object? cpu = freezed,Object? cpus = freezed,Object? mem = freezed,Object? maxmem = freezed,Object? swap = freezed,Object? maxswap = freezed,Object? disk = freezed,Object? maxdisk = freezed,Object? uptime = freezed,Object? netin = freezed,Object? netout = freezed,Object? diskread = freezed,Object? diskwrite = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,vmid: freezed == vmid ? _self.vmid : vmid // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [ContainerStatus].
extension ContainerStatusPatterns on ContainerStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContainerStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContainerStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContainerStatus value)  $default,){
final _that = this;
switch (_that) {
case _ContainerStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContainerStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ContainerStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  int? vmid,  String? name,  double? cpu,  int? cpus,  int? mem,  int? maxmem,  int? swap,  int? maxswap,  int? disk,  int? maxdisk,  int? uptime,  int? netin,  int? netout,  int? diskread,  int? diskwrite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContainerStatus() when $default != null:
return $default(_that.status,_that.vmid,_that.name,_that.cpu,_that.cpus,_that.mem,_that.maxmem,_that.swap,_that.maxswap,_that.disk,_that.maxdisk,_that.uptime,_that.netin,_that.netout,_that.diskread,_that.diskwrite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  int? vmid,  String? name,  double? cpu,  int? cpus,  int? mem,  int? maxmem,  int? swap,  int? maxswap,  int? disk,  int? maxdisk,  int? uptime,  int? netin,  int? netout,  int? diskread,  int? diskwrite)  $default,) {final _that = this;
switch (_that) {
case _ContainerStatus():
return $default(_that.status,_that.vmid,_that.name,_that.cpu,_that.cpus,_that.mem,_that.maxmem,_that.swap,_that.maxswap,_that.disk,_that.maxdisk,_that.uptime,_that.netin,_that.netout,_that.diskread,_that.diskwrite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  int? vmid,  String? name,  double? cpu,  int? cpus,  int? mem,  int? maxmem,  int? swap,  int? maxswap,  int? disk,  int? maxdisk,  int? uptime,  int? netin,  int? netout,  int? diskread,  int? diskwrite)?  $default,) {final _that = this;
switch (_that) {
case _ContainerStatus() when $default != null:
return $default(_that.status,_that.vmid,_that.name,_that.cpu,_that.cpus,_that.mem,_that.maxmem,_that.swap,_that.maxswap,_that.disk,_that.maxdisk,_that.uptime,_that.netin,_that.netout,_that.diskread,_that.diskwrite);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContainerStatus implements ContainerStatus {
  const _ContainerStatus({required this.status, this.vmid, this.name, this.cpu, this.cpus, this.mem, this.maxmem, this.swap, this.maxswap, this.disk, this.maxdisk, this.uptime, this.netin, this.netout, this.diskread, this.diskwrite});
  factory _ContainerStatus.fromJson(Map<String, dynamic> json) => _$ContainerStatusFromJson(json);

@override final  String status;
@override final  int? vmid;
@override final  String? name;
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

/// Create a copy of ContainerStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContainerStatusCopyWith<_ContainerStatus> get copyWith => __$ContainerStatusCopyWithImpl<_ContainerStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContainerStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContainerStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.vmid, vmid) || other.vmid == vmid)&&(identical(other.name, name) || other.name == name)&&(identical(other.cpu, cpu) || other.cpu == cpu)&&(identical(other.cpus, cpus) || other.cpus == cpus)&&(identical(other.mem, mem) || other.mem == mem)&&(identical(other.maxmem, maxmem) || other.maxmem == maxmem)&&(identical(other.swap, swap) || other.swap == swap)&&(identical(other.maxswap, maxswap) || other.maxswap == maxswap)&&(identical(other.disk, disk) || other.disk == disk)&&(identical(other.maxdisk, maxdisk) || other.maxdisk == maxdisk)&&(identical(other.uptime, uptime) || other.uptime == uptime)&&(identical(other.netin, netin) || other.netin == netin)&&(identical(other.netout, netout) || other.netout == netout)&&(identical(other.diskread, diskread) || other.diskread == diskread)&&(identical(other.diskwrite, diskwrite) || other.diskwrite == diskwrite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,vmid,name,cpu,cpus,mem,maxmem,swap,maxswap,disk,maxdisk,uptime,netin,netout,diskread,diskwrite);

@override
String toString() {
  return 'ContainerStatus(status: $status, vmid: $vmid, name: $name, cpu: $cpu, cpus: $cpus, mem: $mem, maxmem: $maxmem, swap: $swap, maxswap: $maxswap, disk: $disk, maxdisk: $maxdisk, uptime: $uptime, netin: $netin, netout: $netout, diskread: $diskread, diskwrite: $diskwrite)';
}


}

/// @nodoc
abstract mixin class _$ContainerStatusCopyWith<$Res> implements $ContainerStatusCopyWith<$Res> {
  factory _$ContainerStatusCopyWith(_ContainerStatus value, $Res Function(_ContainerStatus) _then) = __$ContainerStatusCopyWithImpl;
@override @useResult
$Res call({
 String status, int? vmid, String? name, double? cpu, int? cpus, int? mem, int? maxmem, int? swap, int? maxswap, int? disk, int? maxdisk, int? uptime, int? netin, int? netout, int? diskread, int? diskwrite
});




}
/// @nodoc
class __$ContainerStatusCopyWithImpl<$Res>
    implements _$ContainerStatusCopyWith<$Res> {
  __$ContainerStatusCopyWithImpl(this._self, this._then);

  final _ContainerStatus _self;
  final $Res Function(_ContainerStatus) _then;

/// Create a copy of ContainerStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? vmid = freezed,Object? name = freezed,Object? cpu = freezed,Object? cpus = freezed,Object? mem = freezed,Object? maxmem = freezed,Object? swap = freezed,Object? maxswap = freezed,Object? disk = freezed,Object? maxdisk = freezed,Object? uptime = freezed,Object? netin = freezed,Object? netout = freezed,Object? diskread = freezed,Object? diskwrite = freezed,}) {
  return _then(_ContainerStatus(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,vmid: freezed == vmid ? _self.vmid : vmid // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
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
