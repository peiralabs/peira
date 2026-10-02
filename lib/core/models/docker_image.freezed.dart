// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'docker_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DockerImage {

@JsonKey(name: 'Id') String get id;@JsonKey(name: 'RepoTags') List<String> get repoTags;@JsonKey(name: 'Size') int get size;
/// Create a copy of DockerImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DockerImageCopyWith<DockerImage> get copyWith => _$DockerImageCopyWithImpl<DockerImage>(this as DockerImage, _$identity);

  /// Serializes this DockerImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DockerImage&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.repoTags, repoTags)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(repoTags),size);

@override
String toString() {
  return 'DockerImage(id: $id, repoTags: $repoTags, size: $size)';
}


}

/// @nodoc
abstract mixin class $DockerImageCopyWith<$Res>  {
  factory $DockerImageCopyWith(DockerImage value, $Res Function(DockerImage) _then) = _$DockerImageCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'RepoTags') List<String> repoTags,@JsonKey(name: 'Size') int size
});




}
/// @nodoc
class _$DockerImageCopyWithImpl<$Res>
    implements $DockerImageCopyWith<$Res> {
  _$DockerImageCopyWithImpl(this._self, this._then);

  final DockerImage _self;
  final $Res Function(DockerImage) _then;

/// Create a copy of DockerImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? repoTags = null,Object? size = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,repoTags: null == repoTags ? _self.repoTags : repoTags // ignore: cast_nullable_to_non_nullable
as List<String>,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DockerImage].
extension DockerImagePatterns on DockerImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DockerImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DockerImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DockerImage value)  $default,){
final _that = this;
switch (_that) {
case _DockerImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DockerImage value)?  $default,){
final _that = this;
switch (_that) {
case _DockerImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'RepoTags')  List<String> repoTags, @JsonKey(name: 'Size')  int size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DockerImage() when $default != null:
return $default(_that.id,_that.repoTags,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'RepoTags')  List<String> repoTags, @JsonKey(name: 'Size')  int size)  $default,) {final _that = this;
switch (_that) {
case _DockerImage():
return $default(_that.id,_that.repoTags,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'RepoTags')  List<String> repoTags, @JsonKey(name: 'Size')  int size)?  $default,) {final _that = this;
switch (_that) {
case _DockerImage() when $default != null:
return $default(_that.id,_that.repoTags,_that.size);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DockerImage implements DockerImage {
  const _DockerImage({@JsonKey(name: 'Id') this.id = '', @JsonKey(name: 'RepoTags') final  List<String> repoTags = const [], @JsonKey(name: 'Size') this.size = 0}): _repoTags = repoTags;
  factory _DockerImage.fromJson(Map<String, dynamic> json) => _$DockerImageFromJson(json);

@override@JsonKey(name: 'Id') final  String id;
 final  List<String> _repoTags;
@override@JsonKey(name: 'RepoTags') List<String> get repoTags {
  if (_repoTags is EqualUnmodifiableListView) return _repoTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_repoTags);
}

@override@JsonKey(name: 'Size') final  int size;

/// Create a copy of DockerImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DockerImageCopyWith<_DockerImage> get copyWith => __$DockerImageCopyWithImpl<_DockerImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DockerImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DockerImage&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._repoTags, _repoTags)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_repoTags),size);

@override
String toString() {
  return 'DockerImage(id: $id, repoTags: $repoTags, size: $size)';
}


}

/// @nodoc
abstract mixin class _$DockerImageCopyWith<$Res> implements $DockerImageCopyWith<$Res> {
  factory _$DockerImageCopyWith(_DockerImage value, $Res Function(_DockerImage) _then) = __$DockerImageCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'RepoTags') List<String> repoTags,@JsonKey(name: 'Size') int size
});




}
/// @nodoc
class __$DockerImageCopyWithImpl<$Res>
    implements _$DockerImageCopyWith<$Res> {
  __$DockerImageCopyWithImpl(this._self, this._then);

  final _DockerImage _self;
  final $Res Function(_DockerImage) _then;

/// Create a copy of DockerImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? repoTags = null,Object? size = null,}) {
  return _then(_DockerImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,repoTags: null == repoTags ? _self._repoTags : repoTags // ignore: cast_nullable_to_non_nullable
as List<String>,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
