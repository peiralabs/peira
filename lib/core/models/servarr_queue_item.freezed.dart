// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'servarr_queue_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServarrQueueItem {

 int get id; String get title; String? get status; String? get trackedDownloadState; String? get trackedDownloadStatus; num get size; num get sizeleft; String? get timeleft; String? get indexer;
/// Create a copy of ServarrQueueItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServarrQueueItemCopyWith<ServarrQueueItem> get copyWith => _$ServarrQueueItemCopyWithImpl<ServarrQueueItem>(this as ServarrQueueItem, _$identity);

  /// Serializes this ServarrQueueItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServarrQueueItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.trackedDownloadState, trackedDownloadState) || other.trackedDownloadState == trackedDownloadState)&&(identical(other.trackedDownloadStatus, trackedDownloadStatus) || other.trackedDownloadStatus == trackedDownloadStatus)&&(identical(other.size, size) || other.size == size)&&(identical(other.sizeleft, sizeleft) || other.sizeleft == sizeleft)&&(identical(other.timeleft, timeleft) || other.timeleft == timeleft)&&(identical(other.indexer, indexer) || other.indexer == indexer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,trackedDownloadState,trackedDownloadStatus,size,sizeleft,timeleft,indexer);

@override
String toString() {
  return 'ServarrQueueItem(id: $id, title: $title, status: $status, trackedDownloadState: $trackedDownloadState, trackedDownloadStatus: $trackedDownloadStatus, size: $size, sizeleft: $sizeleft, timeleft: $timeleft, indexer: $indexer)';
}


}

/// @nodoc
abstract mixin class $ServarrQueueItemCopyWith<$Res>  {
  factory $ServarrQueueItemCopyWith(ServarrQueueItem value, $Res Function(ServarrQueueItem) _then) = _$ServarrQueueItemCopyWithImpl;
@useResult
$Res call({
 int id, String title, String? status, String? trackedDownloadState, String? trackedDownloadStatus, num size, num sizeleft, String? timeleft, String? indexer
});




}
/// @nodoc
class _$ServarrQueueItemCopyWithImpl<$Res>
    implements $ServarrQueueItemCopyWith<$Res> {
  _$ServarrQueueItemCopyWithImpl(this._self, this._then);

  final ServarrQueueItem _self;
  final $Res Function(ServarrQueueItem) _then;

/// Create a copy of ServarrQueueItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? status = freezed,Object? trackedDownloadState = freezed,Object? trackedDownloadStatus = freezed,Object? size = null,Object? sizeleft = null,Object? timeleft = freezed,Object? indexer = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,trackedDownloadState: freezed == trackedDownloadState ? _self.trackedDownloadState : trackedDownloadState // ignore: cast_nullable_to_non_nullable
as String?,trackedDownloadStatus: freezed == trackedDownloadStatus ? _self.trackedDownloadStatus : trackedDownloadStatus // ignore: cast_nullable_to_non_nullable
as String?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as num,sizeleft: null == sizeleft ? _self.sizeleft : sizeleft // ignore: cast_nullable_to_non_nullable
as num,timeleft: freezed == timeleft ? _self.timeleft : timeleft // ignore: cast_nullable_to_non_nullable
as String?,indexer: freezed == indexer ? _self.indexer : indexer // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServarrQueueItem].
extension ServarrQueueItemPatterns on ServarrQueueItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServarrQueueItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServarrQueueItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServarrQueueItem value)  $default,){
final _that = this;
switch (_that) {
case _ServarrQueueItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServarrQueueItem value)?  $default,){
final _that = this;
switch (_that) {
case _ServarrQueueItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String? status,  String? trackedDownloadState,  String? trackedDownloadStatus,  num size,  num sizeleft,  String? timeleft,  String? indexer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServarrQueueItem() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.trackedDownloadState,_that.trackedDownloadStatus,_that.size,_that.sizeleft,_that.timeleft,_that.indexer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String? status,  String? trackedDownloadState,  String? trackedDownloadStatus,  num size,  num sizeleft,  String? timeleft,  String? indexer)  $default,) {final _that = this;
switch (_that) {
case _ServarrQueueItem():
return $default(_that.id,_that.title,_that.status,_that.trackedDownloadState,_that.trackedDownloadStatus,_that.size,_that.sizeleft,_that.timeleft,_that.indexer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String? status,  String? trackedDownloadState,  String? trackedDownloadStatus,  num size,  num sizeleft,  String? timeleft,  String? indexer)?  $default,) {final _that = this;
switch (_that) {
case _ServarrQueueItem() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.trackedDownloadState,_that.trackedDownloadStatus,_that.size,_that.sizeleft,_that.timeleft,_that.indexer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServarrQueueItem extends ServarrQueueItem {
  const _ServarrQueueItem({this.id = 0, this.title = '', this.status, this.trackedDownloadState, this.trackedDownloadStatus, this.size = 0, this.sizeleft = 0, this.timeleft, this.indexer}): super._();
  factory _ServarrQueueItem.fromJson(Map<String, dynamic> json) => _$ServarrQueueItemFromJson(json);

@override@JsonKey() final  int id;
@override@JsonKey() final  String title;
@override final  String? status;
@override final  String? trackedDownloadState;
@override final  String? trackedDownloadStatus;
@override@JsonKey() final  num size;
@override@JsonKey() final  num sizeleft;
@override final  String? timeleft;
@override final  String? indexer;

/// Create a copy of ServarrQueueItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServarrQueueItemCopyWith<_ServarrQueueItem> get copyWith => __$ServarrQueueItemCopyWithImpl<_ServarrQueueItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServarrQueueItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServarrQueueItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.trackedDownloadState, trackedDownloadState) || other.trackedDownloadState == trackedDownloadState)&&(identical(other.trackedDownloadStatus, trackedDownloadStatus) || other.trackedDownloadStatus == trackedDownloadStatus)&&(identical(other.size, size) || other.size == size)&&(identical(other.sizeleft, sizeleft) || other.sizeleft == sizeleft)&&(identical(other.timeleft, timeleft) || other.timeleft == timeleft)&&(identical(other.indexer, indexer) || other.indexer == indexer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,trackedDownloadState,trackedDownloadStatus,size,sizeleft,timeleft,indexer);

@override
String toString() {
  return 'ServarrQueueItem(id: $id, title: $title, status: $status, trackedDownloadState: $trackedDownloadState, trackedDownloadStatus: $trackedDownloadStatus, size: $size, sizeleft: $sizeleft, timeleft: $timeleft, indexer: $indexer)';
}


}

/// @nodoc
abstract mixin class _$ServarrQueueItemCopyWith<$Res> implements $ServarrQueueItemCopyWith<$Res> {
  factory _$ServarrQueueItemCopyWith(_ServarrQueueItem value, $Res Function(_ServarrQueueItem) _then) = __$ServarrQueueItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String? status, String? trackedDownloadState, String? trackedDownloadStatus, num size, num sizeleft, String? timeleft, String? indexer
});




}
/// @nodoc
class __$ServarrQueueItemCopyWithImpl<$Res>
    implements _$ServarrQueueItemCopyWith<$Res> {
  __$ServarrQueueItemCopyWithImpl(this._self, this._then);

  final _ServarrQueueItem _self;
  final $Res Function(_ServarrQueueItem) _then;

/// Create a copy of ServarrQueueItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? status = freezed,Object? trackedDownloadState = freezed,Object? trackedDownloadStatus = freezed,Object? size = null,Object? sizeleft = null,Object? timeleft = freezed,Object? indexer = freezed,}) {
  return _then(_ServarrQueueItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,trackedDownloadState: freezed == trackedDownloadState ? _self.trackedDownloadState : trackedDownloadState // ignore: cast_nullable_to_non_nullable
as String?,trackedDownloadStatus: freezed == trackedDownloadStatus ? _self.trackedDownloadStatus : trackedDownloadStatus // ignore: cast_nullable_to_non_nullable
as String?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as num,sizeleft: null == sizeleft ? _self.sizeleft : sizeleft // ignore: cast_nullable_to_non_nullable
as num,timeleft: freezed == timeleft ? _self.timeleft : timeleft // ignore: cast_nullable_to_non_nullable
as String?,indexer: freezed == indexer ? _self.indexer : indexer // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
