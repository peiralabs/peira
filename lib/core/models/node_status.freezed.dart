// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NodeStatus {

 double? get cpu; int? get uptime; String? get kversion; String? get pveversion; List<dynamic>? get loadavg; UsageInfo? get memory; UsageInfo? get rootfs; UsageInfo? get swap;
/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeStatusCopyWith<NodeStatus> get copyWith => _$NodeStatusCopyWithImpl<NodeStatus>(this as NodeStatus, _$identity);

  /// Serializes this NodeStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeStatus&&(identical(other.cpu, cpu) || other.cpu == cpu)&&(identical(other.uptime, uptime) || other.uptime == uptime)&&(identical(other.kversion, kversion) || other.kversion == kversion)&&(identical(other.pveversion, pveversion) || other.pveversion == pveversion)&&const DeepCollectionEquality().equals(other.loadavg, loadavg)&&(identical(other.memory, memory) || other.memory == memory)&&(identical(other.rootfs, rootfs) || other.rootfs == rootfs)&&(identical(other.swap, swap) || other.swap == swap));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cpu,uptime,kversion,pveversion,const DeepCollectionEquality().hash(loadavg),memory,rootfs,swap);

@override
String toString() {
  return 'NodeStatus(cpu: $cpu, uptime: $uptime, kversion: $kversion, pveversion: $pveversion, loadavg: $loadavg, memory: $memory, rootfs: $rootfs, swap: $swap)';
}


}

/// @nodoc
abstract mixin class $NodeStatusCopyWith<$Res>  {
  factory $NodeStatusCopyWith(NodeStatus value, $Res Function(NodeStatus) _then) = _$NodeStatusCopyWithImpl;
@useResult
$Res call({
 double? cpu, int? uptime, String? kversion, String? pveversion, List<dynamic>? loadavg, UsageInfo? memory, UsageInfo? rootfs, UsageInfo? swap
});


$UsageInfoCopyWith<$Res>? get memory;$UsageInfoCopyWith<$Res>? get rootfs;$UsageInfoCopyWith<$Res>? get swap;

}
/// @nodoc
class _$NodeStatusCopyWithImpl<$Res>
    implements $NodeStatusCopyWith<$Res> {
  _$NodeStatusCopyWithImpl(this._self, this._then);

  final NodeStatus _self;
  final $Res Function(NodeStatus) _then;

/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cpu = freezed,Object? uptime = freezed,Object? kversion = freezed,Object? pveversion = freezed,Object? loadavg = freezed,Object? memory = freezed,Object? rootfs = freezed,Object? swap = freezed,}) {
  return _then(_self.copyWith(
cpu: freezed == cpu ? _self.cpu : cpu // ignore: cast_nullable_to_non_nullable
as double?,uptime: freezed == uptime ? _self.uptime : uptime // ignore: cast_nullable_to_non_nullable
as int?,kversion: freezed == kversion ? _self.kversion : kversion // ignore: cast_nullable_to_non_nullable
as String?,pveversion: freezed == pveversion ? _self.pveversion : pveversion // ignore: cast_nullable_to_non_nullable
as String?,loadavg: freezed == loadavg ? _self.loadavg : loadavg // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,memory: freezed == memory ? _self.memory : memory // ignore: cast_nullable_to_non_nullable
as UsageInfo?,rootfs: freezed == rootfs ? _self.rootfs : rootfs // ignore: cast_nullable_to_non_nullable
as UsageInfo?,swap: freezed == swap ? _self.swap : swap // ignore: cast_nullable_to_non_nullable
as UsageInfo?,
  ));
}
/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get memory {
    if (_self.memory == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.memory!, (value) {
    return _then(_self.copyWith(memory: value));
  });
}/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get rootfs {
    if (_self.rootfs == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.rootfs!, (value) {
    return _then(_self.copyWith(rootfs: value));
  });
}/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get swap {
    if (_self.swap == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.swap!, (value) {
    return _then(_self.copyWith(swap: value));
  });
}
}


/// Adds pattern-matching-related methods to [NodeStatus].
extension NodeStatusPatterns on NodeStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NodeStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NodeStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NodeStatus value)  $default,){
final _that = this;
switch (_that) {
case _NodeStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NodeStatus value)?  $default,){
final _that = this;
switch (_that) {
case _NodeStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? cpu,  int? uptime,  String? kversion,  String? pveversion,  List<dynamic>? loadavg,  UsageInfo? memory,  UsageInfo? rootfs,  UsageInfo? swap)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NodeStatus() when $default != null:
return $default(_that.cpu,_that.uptime,_that.kversion,_that.pveversion,_that.loadavg,_that.memory,_that.rootfs,_that.swap);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? cpu,  int? uptime,  String? kversion,  String? pveversion,  List<dynamic>? loadavg,  UsageInfo? memory,  UsageInfo? rootfs,  UsageInfo? swap)  $default,) {final _that = this;
switch (_that) {
case _NodeStatus():
return $default(_that.cpu,_that.uptime,_that.kversion,_that.pveversion,_that.loadavg,_that.memory,_that.rootfs,_that.swap);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? cpu,  int? uptime,  String? kversion,  String? pveversion,  List<dynamic>? loadavg,  UsageInfo? memory,  UsageInfo? rootfs,  UsageInfo? swap)?  $default,) {final _that = this;
switch (_that) {
case _NodeStatus() when $default != null:
return $default(_that.cpu,_that.uptime,_that.kversion,_that.pveversion,_that.loadavg,_that.memory,_that.rootfs,_that.swap);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NodeStatus extends NodeStatus {
  const _NodeStatus({this.cpu, this.uptime, this.kversion, this.pveversion, final  List<dynamic>? loadavg, this.memory, this.rootfs, this.swap}): _loadavg = loadavg,super._();
  factory _NodeStatus.fromJson(Map<String, dynamic> json) => _$NodeStatusFromJson(json);

@override final  double? cpu;
@override final  int? uptime;
@override final  String? kversion;
@override final  String? pveversion;
 final  List<dynamic>? _loadavg;
@override List<dynamic>? get loadavg {
  final value = _loadavg;
  if (value == null) return null;
  if (_loadavg is EqualUnmodifiableListView) return _loadavg;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  UsageInfo? memory;
@override final  UsageInfo? rootfs;
@override final  UsageInfo? swap;

/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NodeStatusCopyWith<_NodeStatus> get copyWith => __$NodeStatusCopyWithImpl<_NodeStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NodeStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NodeStatus&&(identical(other.cpu, cpu) || other.cpu == cpu)&&(identical(other.uptime, uptime) || other.uptime == uptime)&&(identical(other.kversion, kversion) || other.kversion == kversion)&&(identical(other.pveversion, pveversion) || other.pveversion == pveversion)&&const DeepCollectionEquality().equals(other._loadavg, _loadavg)&&(identical(other.memory, memory) || other.memory == memory)&&(identical(other.rootfs, rootfs) || other.rootfs == rootfs)&&(identical(other.swap, swap) || other.swap == swap));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cpu,uptime,kversion,pveversion,const DeepCollectionEquality().hash(_loadavg),memory,rootfs,swap);

@override
String toString() {
  return 'NodeStatus(cpu: $cpu, uptime: $uptime, kversion: $kversion, pveversion: $pveversion, loadavg: $loadavg, memory: $memory, rootfs: $rootfs, swap: $swap)';
}


}

/// @nodoc
abstract mixin class _$NodeStatusCopyWith<$Res> implements $NodeStatusCopyWith<$Res> {
  factory _$NodeStatusCopyWith(_NodeStatus value, $Res Function(_NodeStatus) _then) = __$NodeStatusCopyWithImpl;
@override @useResult
$Res call({
 double? cpu, int? uptime, String? kversion, String? pveversion, List<dynamic>? loadavg, UsageInfo? memory, UsageInfo? rootfs, UsageInfo? swap
});


@override $UsageInfoCopyWith<$Res>? get memory;@override $UsageInfoCopyWith<$Res>? get rootfs;@override $UsageInfoCopyWith<$Res>? get swap;

}
/// @nodoc
class __$NodeStatusCopyWithImpl<$Res>
    implements _$NodeStatusCopyWith<$Res> {
  __$NodeStatusCopyWithImpl(this._self, this._then);

  final _NodeStatus _self;
  final $Res Function(_NodeStatus) _then;

/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cpu = freezed,Object? uptime = freezed,Object? kversion = freezed,Object? pveversion = freezed,Object? loadavg = freezed,Object? memory = freezed,Object? rootfs = freezed,Object? swap = freezed,}) {
  return _then(_NodeStatus(
cpu: freezed == cpu ? _self.cpu : cpu // ignore: cast_nullable_to_non_nullable
as double?,uptime: freezed == uptime ? _self.uptime : uptime // ignore: cast_nullable_to_non_nullable
as int?,kversion: freezed == kversion ? _self.kversion : kversion // ignore: cast_nullable_to_non_nullable
as String?,pveversion: freezed == pveversion ? _self.pveversion : pveversion // ignore: cast_nullable_to_non_nullable
as String?,loadavg: freezed == loadavg ? _self._loadavg : loadavg // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,memory: freezed == memory ? _self.memory : memory // ignore: cast_nullable_to_non_nullable
as UsageInfo?,rootfs: freezed == rootfs ? _self.rootfs : rootfs // ignore: cast_nullable_to_non_nullable
as UsageInfo?,swap: freezed == swap ? _self.swap : swap // ignore: cast_nullable_to_non_nullable
as UsageInfo?,
  ));
}

/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get memory {
    if (_self.memory == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.memory!, (value) {
    return _then(_self.copyWith(memory: value));
  });
}/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get rootfs {
    if (_self.rootfs == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.rootfs!, (value) {
    return _then(_self.copyWith(rootfs: value));
  });
}/// Create a copy of NodeStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get swap {
    if (_self.swap == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.swap!, (value) {
    return _then(_self.copyWith(swap: value));
  });
}
}


/// @nodoc
mixin _$UsageInfo {

 int? get total; int? get used; int? get free; int? get avail;
/// Create a copy of UsageInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<UsageInfo> get copyWith => _$UsageInfoCopyWithImpl<UsageInfo>(this as UsageInfo, _$identity);

  /// Serializes this UsageInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsageInfo&&(identical(other.total, total) || other.total == total)&&(identical(other.used, used) || other.used == used)&&(identical(other.free, free) || other.free == free)&&(identical(other.avail, avail) || other.avail == avail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,used,free,avail);

@override
String toString() {
  return 'UsageInfo(total: $total, used: $used, free: $free, avail: $avail)';
}


}

/// @nodoc
abstract mixin class $UsageInfoCopyWith<$Res>  {
  factory $UsageInfoCopyWith(UsageInfo value, $Res Function(UsageInfo) _then) = _$UsageInfoCopyWithImpl;
@useResult
$Res call({
 int? total, int? used, int? free, int? avail
});




}
/// @nodoc
class _$UsageInfoCopyWithImpl<$Res>
    implements $UsageInfoCopyWith<$Res> {
  _$UsageInfoCopyWithImpl(this._self, this._then);

  final UsageInfo _self;
  final $Res Function(UsageInfo) _then;

/// Create a copy of UsageInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = freezed,Object? used = freezed,Object? free = freezed,Object? avail = freezed,}) {
  return _then(_self.copyWith(
total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,used: freezed == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int?,free: freezed == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as int?,avail: freezed == avail ? _self.avail : avail // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [UsageInfo].
extension UsageInfoPatterns on UsageInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsageInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsageInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsageInfo value)  $default,){
final _that = this;
switch (_that) {
case _UsageInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsageInfo value)?  $default,){
final _that = this;
switch (_that) {
case _UsageInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? total,  int? used,  int? free,  int? avail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsageInfo() when $default != null:
return $default(_that.total,_that.used,_that.free,_that.avail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? total,  int? used,  int? free,  int? avail)  $default,) {final _that = this;
switch (_that) {
case _UsageInfo():
return $default(_that.total,_that.used,_that.free,_that.avail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? total,  int? used,  int? free,  int? avail)?  $default,) {final _that = this;
switch (_that) {
case _UsageInfo() when $default != null:
return $default(_that.total,_that.used,_that.free,_that.avail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UsageInfo extends UsageInfo {
  const _UsageInfo({this.total, this.used, this.free, this.avail}): super._();
  factory _UsageInfo.fromJson(Map<String, dynamic> json) => _$UsageInfoFromJson(json);

@override final  int? total;
@override final  int? used;
@override final  int? free;
@override final  int? avail;

/// Create a copy of UsageInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsageInfoCopyWith<_UsageInfo> get copyWith => __$UsageInfoCopyWithImpl<_UsageInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsageInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsageInfo&&(identical(other.total, total) || other.total == total)&&(identical(other.used, used) || other.used == used)&&(identical(other.free, free) || other.free == free)&&(identical(other.avail, avail) || other.avail == avail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,used,free,avail);

@override
String toString() {
  return 'UsageInfo(total: $total, used: $used, free: $free, avail: $avail)';
}


}

/// @nodoc
abstract mixin class _$UsageInfoCopyWith<$Res> implements $UsageInfoCopyWith<$Res> {
  factory _$UsageInfoCopyWith(_UsageInfo value, $Res Function(_UsageInfo) _then) = __$UsageInfoCopyWithImpl;
@override @useResult
$Res call({
 int? total, int? used, int? free, int? avail
});




}
/// @nodoc
class __$UsageInfoCopyWithImpl<$Res>
    implements _$UsageInfoCopyWith<$Res> {
  __$UsageInfoCopyWithImpl(this._self, this._then);

  final _UsageInfo _self;
  final $Res Function(_UsageInfo) _then;

/// Create a copy of UsageInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = freezed,Object? used = freezed,Object? free = freezed,Object? avail = freezed,}) {
  return _then(_UsageInfo(
total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,used: freezed == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int?,free: freezed == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as int?,avail: freezed == avail ? _self.avail : avail // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
