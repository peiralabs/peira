// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prowlarr_release.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProwlarrRelease {

 String get title; String? get indexer; num get size; int get seeders; int get leechers; String? get protocol; String? get guid;
/// Create a copy of ProwlarrRelease
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProwlarrReleaseCopyWith<ProwlarrRelease> get copyWith => _$ProwlarrReleaseCopyWithImpl<ProwlarrRelease>(this as ProwlarrRelease, _$identity);

  /// Serializes this ProwlarrRelease to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProwlarrRelease&&(identical(other.title, title) || other.title == title)&&(identical(other.indexer, indexer) || other.indexer == indexer)&&(identical(other.size, size) || other.size == size)&&(identical(other.seeders, seeders) || other.seeders == seeders)&&(identical(other.leechers, leechers) || other.leechers == leechers)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.guid, guid) || other.guid == guid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,indexer,size,seeders,leechers,protocol,guid);

@override
String toString() {
  return 'ProwlarrRelease(title: $title, indexer: $indexer, size: $size, seeders: $seeders, leechers: $leechers, protocol: $protocol, guid: $guid)';
}


}

/// @nodoc
abstract mixin class $ProwlarrReleaseCopyWith<$Res>  {
  factory $ProwlarrReleaseCopyWith(ProwlarrRelease value, $Res Function(ProwlarrRelease) _then) = _$ProwlarrReleaseCopyWithImpl;
@useResult
$Res call({
 String title, String? indexer, num size, int seeders, int leechers, String? protocol, String? guid
});




}
/// @nodoc
class _$ProwlarrReleaseCopyWithImpl<$Res>
    implements $ProwlarrReleaseCopyWith<$Res> {
  _$ProwlarrReleaseCopyWithImpl(this._self, this._then);

  final ProwlarrRelease _self;
  final $Res Function(ProwlarrRelease) _then;

/// Create a copy of ProwlarrRelease
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? indexer = freezed,Object? size = null,Object? seeders = null,Object? leechers = null,Object? protocol = freezed,Object? guid = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,indexer: freezed == indexer ? _self.indexer : indexer // ignore: cast_nullable_to_non_nullable
as String?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as num,seeders: null == seeders ? _self.seeders : seeders // ignore: cast_nullable_to_non_nullable
as int,leechers: null == leechers ? _self.leechers : leechers // ignore: cast_nullable_to_non_nullable
as int,protocol: freezed == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as String?,guid: freezed == guid ? _self.guid : guid // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProwlarrRelease].
extension ProwlarrReleasePatterns on ProwlarrRelease {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProwlarrRelease value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProwlarrRelease() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProwlarrRelease value)  $default,){
final _that = this;
switch (_that) {
case _ProwlarrRelease():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProwlarrRelease value)?  $default,){
final _that = this;
switch (_that) {
case _ProwlarrRelease() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? indexer,  num size,  int seeders,  int leechers,  String? protocol,  String? guid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProwlarrRelease() when $default != null:
return $default(_that.title,_that.indexer,_that.size,_that.seeders,_that.leechers,_that.protocol,_that.guid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? indexer,  num size,  int seeders,  int leechers,  String? protocol,  String? guid)  $default,) {final _that = this;
switch (_that) {
case _ProwlarrRelease():
return $default(_that.title,_that.indexer,_that.size,_that.seeders,_that.leechers,_that.protocol,_that.guid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? indexer,  num size,  int seeders,  int leechers,  String? protocol,  String? guid)?  $default,) {final _that = this;
switch (_that) {
case _ProwlarrRelease() when $default != null:
return $default(_that.title,_that.indexer,_that.size,_that.seeders,_that.leechers,_that.protocol,_that.guid);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProwlarrRelease implements ProwlarrRelease {
  const _ProwlarrRelease({this.title = '', this.indexer, this.size = 0, this.seeders = 0, this.leechers = 0, this.protocol, this.guid});
  factory _ProwlarrRelease.fromJson(Map<String, dynamic> json) => _$ProwlarrReleaseFromJson(json);

@override@JsonKey() final  String title;
@override final  String? indexer;
@override@JsonKey() final  num size;
@override@JsonKey() final  int seeders;
@override@JsonKey() final  int leechers;
@override final  String? protocol;
@override final  String? guid;

/// Create a copy of ProwlarrRelease
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProwlarrReleaseCopyWith<_ProwlarrRelease> get copyWith => __$ProwlarrReleaseCopyWithImpl<_ProwlarrRelease>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProwlarrReleaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProwlarrRelease&&(identical(other.title, title) || other.title == title)&&(identical(other.indexer, indexer) || other.indexer == indexer)&&(identical(other.size, size) || other.size == size)&&(identical(other.seeders, seeders) || other.seeders == seeders)&&(identical(other.leechers, leechers) || other.leechers == leechers)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.guid, guid) || other.guid == guid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,indexer,size,seeders,leechers,protocol,guid);

@override
String toString() {
  return 'ProwlarrRelease(title: $title, indexer: $indexer, size: $size, seeders: $seeders, leechers: $leechers, protocol: $protocol, guid: $guid)';
}


}

/// @nodoc
abstract mixin class _$ProwlarrReleaseCopyWith<$Res> implements $ProwlarrReleaseCopyWith<$Res> {
  factory _$ProwlarrReleaseCopyWith(_ProwlarrRelease value, $Res Function(_ProwlarrRelease) _then) = __$ProwlarrReleaseCopyWithImpl;
@override @useResult
$Res call({
 String title, String? indexer, num size, int seeders, int leechers, String? protocol, String? guid
});




}
/// @nodoc
class __$ProwlarrReleaseCopyWithImpl<$Res>
    implements _$ProwlarrReleaseCopyWith<$Res> {
  __$ProwlarrReleaseCopyWithImpl(this._self, this._then);

  final _ProwlarrRelease _self;
  final $Res Function(_ProwlarrRelease) _then;

/// Create a copy of ProwlarrRelease
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? indexer = freezed,Object? size = null,Object? seeders = null,Object? leechers = null,Object? protocol = freezed,Object? guid = freezed,}) {
  return _then(_ProwlarrRelease(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,indexer: freezed == indexer ? _self.indexer : indexer // ignore: cast_nullable_to_non_nullable
as String?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as num,seeders: null == seeders ? _self.seeders : seeders // ignore: cast_nullable_to_non_nullable
as int,leechers: null == leechers ? _self.leechers : leechers // ignore: cast_nullable_to_non_nullable
as int,protocol: freezed == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as String?,guid: freezed == guid ? _self.guid : guid // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
