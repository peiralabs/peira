// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proxmox_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProxmoxTask {

 String get upid; String get node; String get type; int get starttime; int? get endtime; String? get status; String? get user; String? get id;
/// Create a copy of ProxmoxTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProxmoxTaskCopyWith<ProxmoxTask> get copyWith => _$ProxmoxTaskCopyWithImpl<ProxmoxTask>(this as ProxmoxTask, _$identity);

  /// Serializes this ProxmoxTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProxmoxTask&&(identical(other.upid, upid) || other.upid == upid)&&(identical(other.node, node) || other.node == node)&&(identical(other.type, type) || other.type == type)&&(identical(other.starttime, starttime) || other.starttime == starttime)&&(identical(other.endtime, endtime) || other.endtime == endtime)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,upid,node,type,starttime,endtime,status,user,id);

@override
String toString() {
  return 'ProxmoxTask(upid: $upid, node: $node, type: $type, starttime: $starttime, endtime: $endtime, status: $status, user: $user, id: $id)';
}


}

/// @nodoc
abstract mixin class $ProxmoxTaskCopyWith<$Res>  {
  factory $ProxmoxTaskCopyWith(ProxmoxTask value, $Res Function(ProxmoxTask) _then) = _$ProxmoxTaskCopyWithImpl;
@useResult
$Res call({
 String upid, String node, String type, int starttime, int? endtime, String? status, String? user, String? id
});




}
/// @nodoc
class _$ProxmoxTaskCopyWithImpl<$Res>
    implements $ProxmoxTaskCopyWith<$Res> {
  _$ProxmoxTaskCopyWithImpl(this._self, this._then);

  final ProxmoxTask _self;
  final $Res Function(ProxmoxTask) _then;

/// Create a copy of ProxmoxTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? upid = null,Object? node = null,Object? type = null,Object? starttime = null,Object? endtime = freezed,Object? status = freezed,Object? user = freezed,Object? id = freezed,}) {
  return _then(_self.copyWith(
upid: null == upid ? _self.upid : upid // ignore: cast_nullable_to_non_nullable
as String,node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,starttime: null == starttime ? _self.starttime : starttime // ignore: cast_nullable_to_non_nullable
as int,endtime: freezed == endtime ? _self.endtime : endtime // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProxmoxTask].
extension ProxmoxTaskPatterns on ProxmoxTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProxmoxTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProxmoxTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProxmoxTask value)  $default,){
final _that = this;
switch (_that) {
case _ProxmoxTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProxmoxTask value)?  $default,){
final _that = this;
switch (_that) {
case _ProxmoxTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String upid,  String node,  String type,  int starttime,  int? endtime,  String? status,  String? user,  String? id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProxmoxTask() when $default != null:
return $default(_that.upid,_that.node,_that.type,_that.starttime,_that.endtime,_that.status,_that.user,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String upid,  String node,  String type,  int starttime,  int? endtime,  String? status,  String? user,  String? id)  $default,) {final _that = this;
switch (_that) {
case _ProxmoxTask():
return $default(_that.upid,_that.node,_that.type,_that.starttime,_that.endtime,_that.status,_that.user,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String upid,  String node,  String type,  int starttime,  int? endtime,  String? status,  String? user,  String? id)?  $default,) {final _that = this;
switch (_that) {
case _ProxmoxTask() when $default != null:
return $default(_that.upid,_that.node,_that.type,_that.starttime,_that.endtime,_that.status,_that.user,_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProxmoxTask extends ProxmoxTask {
  const _ProxmoxTask({required this.upid, required this.node, required this.type, required this.starttime, this.endtime, this.status, this.user, this.id}): super._();
  factory _ProxmoxTask.fromJson(Map<String, dynamic> json) => _$ProxmoxTaskFromJson(json);

@override final  String upid;
@override final  String node;
@override final  String type;
@override final  int starttime;
@override final  int? endtime;
@override final  String? status;
@override final  String? user;
@override final  String? id;

/// Create a copy of ProxmoxTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProxmoxTaskCopyWith<_ProxmoxTask> get copyWith => __$ProxmoxTaskCopyWithImpl<_ProxmoxTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProxmoxTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProxmoxTask&&(identical(other.upid, upid) || other.upid == upid)&&(identical(other.node, node) || other.node == node)&&(identical(other.type, type) || other.type == type)&&(identical(other.starttime, starttime) || other.starttime == starttime)&&(identical(other.endtime, endtime) || other.endtime == endtime)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,upid,node,type,starttime,endtime,status,user,id);

@override
String toString() {
  return 'ProxmoxTask(upid: $upid, node: $node, type: $type, starttime: $starttime, endtime: $endtime, status: $status, user: $user, id: $id)';
}


}

/// @nodoc
abstract mixin class _$ProxmoxTaskCopyWith<$Res> implements $ProxmoxTaskCopyWith<$Res> {
  factory _$ProxmoxTaskCopyWith(_ProxmoxTask value, $Res Function(_ProxmoxTask) _then) = __$ProxmoxTaskCopyWithImpl;
@override @useResult
$Res call({
 String upid, String node, String type, int starttime, int? endtime, String? status, String? user, String? id
});




}
/// @nodoc
class __$ProxmoxTaskCopyWithImpl<$Res>
    implements _$ProxmoxTaskCopyWith<$Res> {
  __$ProxmoxTaskCopyWithImpl(this._self, this._then);

  final _ProxmoxTask _self;
  final $Res Function(_ProxmoxTask) _then;

/// Create a copy of ProxmoxTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? upid = null,Object? node = null,Object? type = null,Object? starttime = null,Object? endtime = freezed,Object? status = freezed,Object? user = freezed,Object? id = freezed,}) {
  return _then(_ProxmoxTask(
upid: null == upid ? _self.upid : upid // ignore: cast_nullable_to_non_nullable
as String,node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,starttime: null == starttime ? _self.starttime : starttime // ignore: cast_nullable_to_non_nullable
as int,endtime: freezed == endtime ? _self.endtime : endtime // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
