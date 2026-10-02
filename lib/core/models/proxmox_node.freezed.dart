// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proxmox_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProxmoxNode {

 String get node; String get status; double? get cpu; int? get maxcpu; int? get mem; int? get maxmem; int? get disk; int? get maxdisk; int? get uptime;
/// Create a copy of ProxmoxNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProxmoxNodeCopyWith<ProxmoxNode> get copyWith => _$ProxmoxNodeCopyWithImpl<ProxmoxNode>(this as ProxmoxNode, _$identity);

  /// Serializes this ProxmoxNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProxmoxNode&&(identical(other.node, node) || other.node == node)&&(identical(other.status, status) || other.status == status)&&(identical(other.cpu, cpu) || other.cpu == cpu)&&(identical(other.maxcpu, maxcpu) || other.maxcpu == maxcpu)&&(identical(other.mem, mem) || other.mem == mem)&&(identical(other.maxmem, maxmem) || other.maxmem == maxmem)&&(identical(other.disk, disk) || other.disk == disk)&&(identical(other.maxdisk, maxdisk) || other.maxdisk == maxdisk)&&(identical(other.uptime, uptime) || other.uptime == uptime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,node,status,cpu,maxcpu,mem,maxmem,disk,maxdisk,uptime);

@override
String toString() {
  return 'ProxmoxNode(node: $node, status: $status, cpu: $cpu, maxcpu: $maxcpu, mem: $mem, maxmem: $maxmem, disk: $disk, maxdisk: $maxdisk, uptime: $uptime)';
}


}

/// @nodoc
abstract mixin class $ProxmoxNodeCopyWith<$Res>  {
  factory $ProxmoxNodeCopyWith(ProxmoxNode value, $Res Function(ProxmoxNode) _then) = _$ProxmoxNodeCopyWithImpl;
@useResult
$Res call({
 String node, String status, double? cpu, int? maxcpu, int? mem, int? maxmem, int? disk, int? maxdisk, int? uptime
});




}
/// @nodoc
class _$ProxmoxNodeCopyWithImpl<$Res>
    implements $ProxmoxNodeCopyWith<$Res> {
  _$ProxmoxNodeCopyWithImpl(this._self, this._then);

  final ProxmoxNode _self;
  final $Res Function(ProxmoxNode) _then;

/// Create a copy of ProxmoxNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? node = null,Object? status = null,Object? cpu = freezed,Object? maxcpu = freezed,Object? mem = freezed,Object? maxmem = freezed,Object? disk = freezed,Object? maxdisk = freezed,Object? uptime = freezed,}) {
  return _then(_self.copyWith(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,cpu: freezed == cpu ? _self.cpu : cpu // ignore: cast_nullable_to_non_nullable
as double?,maxcpu: freezed == maxcpu ? _self.maxcpu : maxcpu // ignore: cast_nullable_to_non_nullable
as int?,mem: freezed == mem ? _self.mem : mem // ignore: cast_nullable_to_non_nullable
as int?,maxmem: freezed == maxmem ? _self.maxmem : maxmem // ignore: cast_nullable_to_non_nullable
as int?,disk: freezed == disk ? _self.disk : disk // ignore: cast_nullable_to_non_nullable
as int?,maxdisk: freezed == maxdisk ? _self.maxdisk : maxdisk // ignore: cast_nullable_to_non_nullable
as int?,uptime: freezed == uptime ? _self.uptime : uptime // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProxmoxNode].
extension ProxmoxNodePatterns on ProxmoxNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProxmoxNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProxmoxNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProxmoxNode value)  $default,){
final _that = this;
switch (_that) {
case _ProxmoxNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProxmoxNode value)?  $default,){
final _that = this;
switch (_that) {
case _ProxmoxNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String node,  String status,  double? cpu,  int? maxcpu,  int? mem,  int? maxmem,  int? disk,  int? maxdisk,  int? uptime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProxmoxNode() when $default != null:
return $default(_that.node,_that.status,_that.cpu,_that.maxcpu,_that.mem,_that.maxmem,_that.disk,_that.maxdisk,_that.uptime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String node,  String status,  double? cpu,  int? maxcpu,  int? mem,  int? maxmem,  int? disk,  int? maxdisk,  int? uptime)  $default,) {final _that = this;
switch (_that) {
case _ProxmoxNode():
return $default(_that.node,_that.status,_that.cpu,_that.maxcpu,_that.mem,_that.maxmem,_that.disk,_that.maxdisk,_that.uptime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String node,  String status,  double? cpu,  int? maxcpu,  int? mem,  int? maxmem,  int? disk,  int? maxdisk,  int? uptime)?  $default,) {final _that = this;
switch (_that) {
case _ProxmoxNode() when $default != null:
return $default(_that.node,_that.status,_that.cpu,_that.maxcpu,_that.mem,_that.maxmem,_that.disk,_that.maxdisk,_that.uptime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProxmoxNode implements ProxmoxNode {
  const _ProxmoxNode({required this.node, required this.status, this.cpu, this.maxcpu, this.mem, this.maxmem, this.disk, this.maxdisk, this.uptime});
  factory _ProxmoxNode.fromJson(Map<String, dynamic> json) => _$ProxmoxNodeFromJson(json);

@override final  String node;
@override final  String status;
@override final  double? cpu;
@override final  int? maxcpu;
@override final  int? mem;
@override final  int? maxmem;
@override final  int? disk;
@override final  int? maxdisk;
@override final  int? uptime;

/// Create a copy of ProxmoxNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProxmoxNodeCopyWith<_ProxmoxNode> get copyWith => __$ProxmoxNodeCopyWithImpl<_ProxmoxNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProxmoxNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProxmoxNode&&(identical(other.node, node) || other.node == node)&&(identical(other.status, status) || other.status == status)&&(identical(other.cpu, cpu) || other.cpu == cpu)&&(identical(other.maxcpu, maxcpu) || other.maxcpu == maxcpu)&&(identical(other.mem, mem) || other.mem == mem)&&(identical(other.maxmem, maxmem) || other.maxmem == maxmem)&&(identical(other.disk, disk) || other.disk == disk)&&(identical(other.maxdisk, maxdisk) || other.maxdisk == maxdisk)&&(identical(other.uptime, uptime) || other.uptime == uptime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,node,status,cpu,maxcpu,mem,maxmem,disk,maxdisk,uptime);

@override
String toString() {
  return 'ProxmoxNode(node: $node, status: $status, cpu: $cpu, maxcpu: $maxcpu, mem: $mem, maxmem: $maxmem, disk: $disk, maxdisk: $maxdisk, uptime: $uptime)';
}


}

/// @nodoc
abstract mixin class _$ProxmoxNodeCopyWith<$Res> implements $ProxmoxNodeCopyWith<$Res> {
  factory _$ProxmoxNodeCopyWith(_ProxmoxNode value, $Res Function(_ProxmoxNode) _then) = __$ProxmoxNodeCopyWithImpl;
@override @useResult
$Res call({
 String node, String status, double? cpu, int? maxcpu, int? mem, int? maxmem, int? disk, int? maxdisk, int? uptime
});




}
/// @nodoc
class __$ProxmoxNodeCopyWithImpl<$Res>
    implements _$ProxmoxNodeCopyWith<$Res> {
  __$ProxmoxNodeCopyWithImpl(this._self, this._then);

  final _ProxmoxNode _self;
  final $Res Function(_ProxmoxNode) _then;

/// Create a copy of ProxmoxNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? node = null,Object? status = null,Object? cpu = freezed,Object? maxcpu = freezed,Object? mem = freezed,Object? maxmem = freezed,Object? disk = freezed,Object? maxdisk = freezed,Object? uptime = freezed,}) {
  return _then(_ProxmoxNode(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,cpu: freezed == cpu ? _self.cpu : cpu // ignore: cast_nullable_to_non_nullable
as double?,maxcpu: freezed == maxcpu ? _self.maxcpu : maxcpu // ignore: cast_nullable_to_non_nullable
as int?,mem: freezed == mem ? _self.mem : mem // ignore: cast_nullable_to_non_nullable
as int?,maxmem: freezed == maxmem ? _self.maxmem : maxmem // ignore: cast_nullable_to_non_nullable
as int?,disk: freezed == disk ? _self.disk : disk // ignore: cast_nullable_to_non_nullable
as int?,maxdisk: freezed == maxdisk ? _self.maxdisk : maxdisk // ignore: cast_nullable_to_non_nullable
as int?,uptime: freezed == uptime ? _self.uptime : uptime // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
