// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qbittorrent_torrent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QbittorrentTorrent {

 String get hash; String get name; String get state; double get progress; int get dlspeed; int get upspeed; int get size; int get eta; String get category;@JsonKey(name: 'num_seeds') int get numSeeds;@JsonKey(name: 'num_leechs') int get numLeechs; double get ratio;
/// Create a copy of QbittorrentTorrent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QbittorrentTorrentCopyWith<QbittorrentTorrent> get copyWith => _$QbittorrentTorrentCopyWithImpl<QbittorrentTorrent>(this as QbittorrentTorrent, _$identity);

  /// Serializes this QbittorrentTorrent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QbittorrentTorrent&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.name, name) || other.name == name)&&(identical(other.state, state) || other.state == state)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.dlspeed, dlspeed) || other.dlspeed == dlspeed)&&(identical(other.upspeed, upspeed) || other.upspeed == upspeed)&&(identical(other.size, size) || other.size == size)&&(identical(other.eta, eta) || other.eta == eta)&&(identical(other.category, category) || other.category == category)&&(identical(other.numSeeds, numSeeds) || other.numSeeds == numSeeds)&&(identical(other.numLeechs, numLeechs) || other.numLeechs == numLeechs)&&(identical(other.ratio, ratio) || other.ratio == ratio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hash,name,state,progress,dlspeed,upspeed,size,eta,category,numSeeds,numLeechs,ratio);

@override
String toString() {
  return 'QbittorrentTorrent(hash: $hash, name: $name, state: $state, progress: $progress, dlspeed: $dlspeed, upspeed: $upspeed, size: $size, eta: $eta, category: $category, numSeeds: $numSeeds, numLeechs: $numLeechs, ratio: $ratio)';
}


}

/// @nodoc
abstract mixin class $QbittorrentTorrentCopyWith<$Res>  {
  factory $QbittorrentTorrentCopyWith(QbittorrentTorrent value, $Res Function(QbittorrentTorrent) _then) = _$QbittorrentTorrentCopyWithImpl;
@useResult
$Res call({
 String hash, String name, String state, double progress, int dlspeed, int upspeed, int size, int eta, String category,@JsonKey(name: 'num_seeds') int numSeeds,@JsonKey(name: 'num_leechs') int numLeechs, double ratio
});




}
/// @nodoc
class _$QbittorrentTorrentCopyWithImpl<$Res>
    implements $QbittorrentTorrentCopyWith<$Res> {
  _$QbittorrentTorrentCopyWithImpl(this._self, this._then);

  final QbittorrentTorrent _self;
  final $Res Function(QbittorrentTorrent) _then;

/// Create a copy of QbittorrentTorrent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hash = null,Object? name = null,Object? state = null,Object? progress = null,Object? dlspeed = null,Object? upspeed = null,Object? size = null,Object? eta = null,Object? category = null,Object? numSeeds = null,Object? numLeechs = null,Object? ratio = null,}) {
  return _then(_self.copyWith(
hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,dlspeed: null == dlspeed ? _self.dlspeed : dlspeed // ignore: cast_nullable_to_non_nullable
as int,upspeed: null == upspeed ? _self.upspeed : upspeed // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,eta: null == eta ? _self.eta : eta // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,numSeeds: null == numSeeds ? _self.numSeeds : numSeeds // ignore: cast_nullable_to_non_nullable
as int,numLeechs: null == numLeechs ? _self.numLeechs : numLeechs // ignore: cast_nullable_to_non_nullable
as int,ratio: null == ratio ? _self.ratio : ratio // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [QbittorrentTorrent].
extension QbittorrentTorrentPatterns on QbittorrentTorrent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QbittorrentTorrent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QbittorrentTorrent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QbittorrentTorrent value)  $default,){
final _that = this;
switch (_that) {
case _QbittorrentTorrent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QbittorrentTorrent value)?  $default,){
final _that = this;
switch (_that) {
case _QbittorrentTorrent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String hash,  String name,  String state,  double progress,  int dlspeed,  int upspeed,  int size,  int eta,  String category, @JsonKey(name: 'num_seeds')  int numSeeds, @JsonKey(name: 'num_leechs')  int numLeechs,  double ratio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QbittorrentTorrent() when $default != null:
return $default(_that.hash,_that.name,_that.state,_that.progress,_that.dlspeed,_that.upspeed,_that.size,_that.eta,_that.category,_that.numSeeds,_that.numLeechs,_that.ratio);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String hash,  String name,  String state,  double progress,  int dlspeed,  int upspeed,  int size,  int eta,  String category, @JsonKey(name: 'num_seeds')  int numSeeds, @JsonKey(name: 'num_leechs')  int numLeechs,  double ratio)  $default,) {final _that = this;
switch (_that) {
case _QbittorrentTorrent():
return $default(_that.hash,_that.name,_that.state,_that.progress,_that.dlspeed,_that.upspeed,_that.size,_that.eta,_that.category,_that.numSeeds,_that.numLeechs,_that.ratio);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String hash,  String name,  String state,  double progress,  int dlspeed,  int upspeed,  int size,  int eta,  String category, @JsonKey(name: 'num_seeds')  int numSeeds, @JsonKey(name: 'num_leechs')  int numLeechs,  double ratio)?  $default,) {final _that = this;
switch (_that) {
case _QbittorrentTorrent() when $default != null:
return $default(_that.hash,_that.name,_that.state,_that.progress,_that.dlspeed,_that.upspeed,_that.size,_that.eta,_that.category,_that.numSeeds,_that.numLeechs,_that.ratio);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QbittorrentTorrent implements QbittorrentTorrent {
  const _QbittorrentTorrent({this.hash = '', this.name = '', this.state = '', this.progress = 0, this.dlspeed = 0, this.upspeed = 0, this.size = 0, this.eta = 0, this.category = '', @JsonKey(name: 'num_seeds') this.numSeeds = 0, @JsonKey(name: 'num_leechs') this.numLeechs = 0, this.ratio = 0});
  factory _QbittorrentTorrent.fromJson(Map<String, dynamic> json) => _$QbittorrentTorrentFromJson(json);

@override@JsonKey() final  String hash;
@override@JsonKey() final  String name;
@override@JsonKey() final  String state;
@override@JsonKey() final  double progress;
@override@JsonKey() final  int dlspeed;
@override@JsonKey() final  int upspeed;
@override@JsonKey() final  int size;
@override@JsonKey() final  int eta;
@override@JsonKey() final  String category;
@override@JsonKey(name: 'num_seeds') final  int numSeeds;
@override@JsonKey(name: 'num_leechs') final  int numLeechs;
@override@JsonKey() final  double ratio;

/// Create a copy of QbittorrentTorrent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QbittorrentTorrentCopyWith<_QbittorrentTorrent> get copyWith => __$QbittorrentTorrentCopyWithImpl<_QbittorrentTorrent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QbittorrentTorrentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QbittorrentTorrent&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.name, name) || other.name == name)&&(identical(other.state, state) || other.state == state)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.dlspeed, dlspeed) || other.dlspeed == dlspeed)&&(identical(other.upspeed, upspeed) || other.upspeed == upspeed)&&(identical(other.size, size) || other.size == size)&&(identical(other.eta, eta) || other.eta == eta)&&(identical(other.category, category) || other.category == category)&&(identical(other.numSeeds, numSeeds) || other.numSeeds == numSeeds)&&(identical(other.numLeechs, numLeechs) || other.numLeechs == numLeechs)&&(identical(other.ratio, ratio) || other.ratio == ratio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hash,name,state,progress,dlspeed,upspeed,size,eta,category,numSeeds,numLeechs,ratio);

@override
String toString() {
  return 'QbittorrentTorrent(hash: $hash, name: $name, state: $state, progress: $progress, dlspeed: $dlspeed, upspeed: $upspeed, size: $size, eta: $eta, category: $category, numSeeds: $numSeeds, numLeechs: $numLeechs, ratio: $ratio)';
}


}

/// @nodoc
abstract mixin class _$QbittorrentTorrentCopyWith<$Res> implements $QbittorrentTorrentCopyWith<$Res> {
  factory _$QbittorrentTorrentCopyWith(_QbittorrentTorrent value, $Res Function(_QbittorrentTorrent) _then) = __$QbittorrentTorrentCopyWithImpl;
@override @useResult
$Res call({
 String hash, String name, String state, double progress, int dlspeed, int upspeed, int size, int eta, String category,@JsonKey(name: 'num_seeds') int numSeeds,@JsonKey(name: 'num_leechs') int numLeechs, double ratio
});




}
/// @nodoc
class __$QbittorrentTorrentCopyWithImpl<$Res>
    implements _$QbittorrentTorrentCopyWith<$Res> {
  __$QbittorrentTorrentCopyWithImpl(this._self, this._then);

  final _QbittorrentTorrent _self;
  final $Res Function(_QbittorrentTorrent) _then;

/// Create a copy of QbittorrentTorrent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hash = null,Object? name = null,Object? state = null,Object? progress = null,Object? dlspeed = null,Object? upspeed = null,Object? size = null,Object? eta = null,Object? category = null,Object? numSeeds = null,Object? numLeechs = null,Object? ratio = null,}) {
  return _then(_QbittorrentTorrent(
hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,dlspeed: null == dlspeed ? _self.dlspeed : dlspeed // ignore: cast_nullable_to_non_nullable
as int,upspeed: null == upspeed ? _self.upspeed : upspeed // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,eta: null == eta ? _self.eta : eta // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,numSeeds: null == numSeeds ? _self.numSeeds : numSeeds // ignore: cast_nullable_to_non_nullable
as int,numLeechs: null == numLeechs ? _self.numLeechs : numLeechs // ignore: cast_nullable_to_non_nullable
as int,ratio: null == ratio ? _self.ratio : ratio // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
