// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'docker_container.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DockerContainer {

@JsonKey(name: 'Id') String get id;@JsonKey(name: 'Names', fromJson: _dockerContainerName) String get name;@JsonKey(name: 'Image') String get image;@JsonKey(name: 'State') String get state;@JsonKey(name: 'Status') String get status;@JsonKey(name: 'Ports') List<Map<String, dynamic>> get ports;
/// Create a copy of DockerContainer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DockerContainerCopyWith<DockerContainer> get copyWith => _$DockerContainerCopyWithImpl<DockerContainer>(this as DockerContainer, _$identity);

  /// Serializes this DockerContainer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DockerContainer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image)&&(identical(other.state, state) || other.state == state)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.ports, ports));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,image,state,status,const DeepCollectionEquality().hash(ports));

@override
String toString() {
  return 'DockerContainer(id: $id, name: $name, image: $image, state: $state, status: $status, ports: $ports)';
}


}

/// @nodoc
abstract mixin class $DockerContainerCopyWith<$Res>  {
  factory $DockerContainerCopyWith(DockerContainer value, $Res Function(DockerContainer) _then) = _$DockerContainerCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Names', fromJson: _dockerContainerName) String name,@JsonKey(name: 'Image') String image,@JsonKey(name: 'State') String state,@JsonKey(name: 'Status') String status,@JsonKey(name: 'Ports') List<Map<String, dynamic>> ports
});




}
/// @nodoc
class _$DockerContainerCopyWithImpl<$Res>
    implements $DockerContainerCopyWith<$Res> {
  _$DockerContainerCopyWithImpl(this._self, this._then);

  final DockerContainer _self;
  final $Res Function(DockerContainer) _then;

/// Create a copy of DockerContainer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? image = null,Object? state = null,Object? status = null,Object? ports = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ports: null == ports ? _self.ports : ports // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}

}


/// Adds pattern-matching-related methods to [DockerContainer].
extension DockerContainerPatterns on DockerContainer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DockerContainer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DockerContainer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DockerContainer value)  $default,){
final _that = this;
switch (_that) {
case _DockerContainer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DockerContainer value)?  $default,){
final _that = this;
switch (_that) {
case _DockerContainer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Names', fromJson: _dockerContainerName)  String name, @JsonKey(name: 'Image')  String image, @JsonKey(name: 'State')  String state, @JsonKey(name: 'Status')  String status, @JsonKey(name: 'Ports')  List<Map<String, dynamic>> ports)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DockerContainer() when $default != null:
return $default(_that.id,_that.name,_that.image,_that.state,_that.status,_that.ports);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Names', fromJson: _dockerContainerName)  String name, @JsonKey(name: 'Image')  String image, @JsonKey(name: 'State')  String state, @JsonKey(name: 'Status')  String status, @JsonKey(name: 'Ports')  List<Map<String, dynamic>> ports)  $default,) {final _that = this;
switch (_that) {
case _DockerContainer():
return $default(_that.id,_that.name,_that.image,_that.state,_that.status,_that.ports);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Names', fromJson: _dockerContainerName)  String name, @JsonKey(name: 'Image')  String image, @JsonKey(name: 'State')  String state, @JsonKey(name: 'Status')  String status, @JsonKey(name: 'Ports')  List<Map<String, dynamic>> ports)?  $default,) {final _that = this;
switch (_that) {
case _DockerContainer() when $default != null:
return $default(_that.id,_that.name,_that.image,_that.state,_that.status,_that.ports);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DockerContainer implements DockerContainer {
  const _DockerContainer({@JsonKey(name: 'Id') this.id = '', @JsonKey(name: 'Names', fromJson: _dockerContainerName) this.name = '', @JsonKey(name: 'Image') this.image = '', @JsonKey(name: 'State') this.state = '', @JsonKey(name: 'Status') this.status = '', @JsonKey(name: 'Ports') final  List<Map<String, dynamic>> ports = const []}): _ports = ports;
  factory _DockerContainer.fromJson(Map<String, dynamic> json) => _$DockerContainerFromJson(json);

@override@JsonKey(name: 'Id') final  String id;
@override@JsonKey(name: 'Names', fromJson: _dockerContainerName) final  String name;
@override@JsonKey(name: 'Image') final  String image;
@override@JsonKey(name: 'State') final  String state;
@override@JsonKey(name: 'Status') final  String status;
 final  List<Map<String, dynamic>> _ports;
@override@JsonKey(name: 'Ports') List<Map<String, dynamic>> get ports {
  if (_ports is EqualUnmodifiableListView) return _ports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ports);
}


/// Create a copy of DockerContainer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DockerContainerCopyWith<_DockerContainer> get copyWith => __$DockerContainerCopyWithImpl<_DockerContainer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DockerContainerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DockerContainer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image)&&(identical(other.state, state) || other.state == state)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._ports, _ports));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,image,state,status,const DeepCollectionEquality().hash(_ports));

@override
String toString() {
  return 'DockerContainer(id: $id, name: $name, image: $image, state: $state, status: $status, ports: $ports)';
}


}

/// @nodoc
abstract mixin class _$DockerContainerCopyWith<$Res> implements $DockerContainerCopyWith<$Res> {
  factory _$DockerContainerCopyWith(_DockerContainer value, $Res Function(_DockerContainer) _then) = __$DockerContainerCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Names', fromJson: _dockerContainerName) String name,@JsonKey(name: 'Image') String image,@JsonKey(name: 'State') String state,@JsonKey(name: 'Status') String status,@JsonKey(name: 'Ports') List<Map<String, dynamic>> ports
});




}
/// @nodoc
class __$DockerContainerCopyWithImpl<$Res>
    implements _$DockerContainerCopyWith<$Res> {
  __$DockerContainerCopyWithImpl(this._self, this._then);

  final _DockerContainer _self;
  final $Res Function(_DockerContainer) _then;

/// Create a copy of DockerContainer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? image = null,Object? state = null,Object? status = null,Object? ports = null,}) {
  return _then(_DockerContainer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ports: null == ports ? _self._ports : ports // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

// dart format on
