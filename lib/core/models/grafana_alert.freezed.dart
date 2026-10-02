// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grafana_alert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GrafanaAlert {

 Map<String, String> get labels; Map<String, String> get annotations; DateTime get startsAt; String? get fingerprint; Map<String, dynamic>? get status;@JsonKey(name: 'generatorURL') String get generatorUrl;
/// Create a copy of GrafanaAlert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrafanaAlertCopyWith<GrafanaAlert> get copyWith => _$GrafanaAlertCopyWithImpl<GrafanaAlert>(this as GrafanaAlert, _$identity);

  /// Serializes this GrafanaAlert to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrafanaAlert&&const DeepCollectionEquality().equals(other.labels, labels)&&const DeepCollectionEquality().equals(other.annotations, annotations)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&const DeepCollectionEquality().equals(other.status, status)&&(identical(other.generatorUrl, generatorUrl) || other.generatorUrl == generatorUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(labels),const DeepCollectionEquality().hash(annotations),startsAt,fingerprint,const DeepCollectionEquality().hash(status),generatorUrl);

@override
String toString() {
  return 'GrafanaAlert(labels: $labels, annotations: $annotations, startsAt: $startsAt, fingerprint: $fingerprint, status: $status, generatorUrl: $generatorUrl)';
}


}

/// @nodoc
abstract mixin class $GrafanaAlertCopyWith<$Res>  {
  factory $GrafanaAlertCopyWith(GrafanaAlert value, $Res Function(GrafanaAlert) _then) = _$GrafanaAlertCopyWithImpl;
@useResult
$Res call({
 Map<String, String> labels, Map<String, String> annotations, DateTime startsAt, String? fingerprint, Map<String, dynamic>? status,@JsonKey(name: 'generatorURL') String generatorUrl
});




}
/// @nodoc
class _$GrafanaAlertCopyWithImpl<$Res>
    implements $GrafanaAlertCopyWith<$Res> {
  _$GrafanaAlertCopyWithImpl(this._self, this._then);

  final GrafanaAlert _self;
  final $Res Function(GrafanaAlert) _then;

/// Create a copy of GrafanaAlert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? labels = null,Object? annotations = null,Object? startsAt = null,Object? fingerprint = freezed,Object? status = freezed,Object? generatorUrl = null,}) {
  return _then(_self.copyWith(
labels: null == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as Map<String, String>,annotations: null == annotations ? _self.annotations : annotations // ignore: cast_nullable_to_non_nullable
as Map<String, String>,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,fingerprint: freezed == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,generatorUrl: null == generatorUrl ? _self.generatorUrl : generatorUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GrafanaAlert].
extension GrafanaAlertPatterns on GrafanaAlert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrafanaAlert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrafanaAlert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrafanaAlert value)  $default,){
final _that = this;
switch (_that) {
case _GrafanaAlert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrafanaAlert value)?  $default,){
final _that = this;
switch (_that) {
case _GrafanaAlert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, String> labels,  Map<String, String> annotations,  DateTime startsAt,  String? fingerprint,  Map<String, dynamic>? status, @JsonKey(name: 'generatorURL')  String generatorUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrafanaAlert() when $default != null:
return $default(_that.labels,_that.annotations,_that.startsAt,_that.fingerprint,_that.status,_that.generatorUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, String> labels,  Map<String, String> annotations,  DateTime startsAt,  String? fingerprint,  Map<String, dynamic>? status, @JsonKey(name: 'generatorURL')  String generatorUrl)  $default,) {final _that = this;
switch (_that) {
case _GrafanaAlert():
return $default(_that.labels,_that.annotations,_that.startsAt,_that.fingerprint,_that.status,_that.generatorUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, String> labels,  Map<String, String> annotations,  DateTime startsAt,  String? fingerprint,  Map<String, dynamic>? status, @JsonKey(name: 'generatorURL')  String generatorUrl)?  $default,) {final _that = this;
switch (_that) {
case _GrafanaAlert() when $default != null:
return $default(_that.labels,_that.annotations,_that.startsAt,_that.fingerprint,_that.status,_that.generatorUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GrafanaAlert extends GrafanaAlert {
  const _GrafanaAlert({final  Map<String, String> labels = const <String, String>{}, final  Map<String, String> annotations = const <String, String>{}, required this.startsAt, this.fingerprint, final  Map<String, dynamic>? status, @JsonKey(name: 'generatorURL') this.generatorUrl = ''}): _labels = labels,_annotations = annotations,_status = status,super._();
  factory _GrafanaAlert.fromJson(Map<String, dynamic> json) => _$GrafanaAlertFromJson(json);

 final  Map<String, String> _labels;
@override@JsonKey() Map<String, String> get labels {
  if (_labels is EqualUnmodifiableMapView) return _labels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_labels);
}

 final  Map<String, String> _annotations;
@override@JsonKey() Map<String, String> get annotations {
  if (_annotations is EqualUnmodifiableMapView) return _annotations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_annotations);
}

@override final  DateTime startsAt;
@override final  String? fingerprint;
 final  Map<String, dynamic>? _status;
@override Map<String, dynamic>? get status {
  final value = _status;
  if (value == null) return null;
  if (_status is EqualUnmodifiableMapView) return _status;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'generatorURL') final  String generatorUrl;

/// Create a copy of GrafanaAlert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrafanaAlertCopyWith<_GrafanaAlert> get copyWith => __$GrafanaAlertCopyWithImpl<_GrafanaAlert>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrafanaAlertToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrafanaAlert&&const DeepCollectionEquality().equals(other._labels, _labels)&&const DeepCollectionEquality().equals(other._annotations, _annotations)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&const DeepCollectionEquality().equals(other._status, _status)&&(identical(other.generatorUrl, generatorUrl) || other.generatorUrl == generatorUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_labels),const DeepCollectionEquality().hash(_annotations),startsAt,fingerprint,const DeepCollectionEquality().hash(_status),generatorUrl);

@override
String toString() {
  return 'GrafanaAlert(labels: $labels, annotations: $annotations, startsAt: $startsAt, fingerprint: $fingerprint, status: $status, generatorUrl: $generatorUrl)';
}


}

/// @nodoc
abstract mixin class _$GrafanaAlertCopyWith<$Res> implements $GrafanaAlertCopyWith<$Res> {
  factory _$GrafanaAlertCopyWith(_GrafanaAlert value, $Res Function(_GrafanaAlert) _then) = __$GrafanaAlertCopyWithImpl;
@override @useResult
$Res call({
 Map<String, String> labels, Map<String, String> annotations, DateTime startsAt, String? fingerprint, Map<String, dynamic>? status,@JsonKey(name: 'generatorURL') String generatorUrl
});




}
/// @nodoc
class __$GrafanaAlertCopyWithImpl<$Res>
    implements _$GrafanaAlertCopyWith<$Res> {
  __$GrafanaAlertCopyWithImpl(this._self, this._then);

  final _GrafanaAlert _self;
  final $Res Function(_GrafanaAlert) _then;

/// Create a copy of GrafanaAlert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? labels = null,Object? annotations = null,Object? startsAt = null,Object? fingerprint = freezed,Object? status = freezed,Object? generatorUrl = null,}) {
  return _then(_GrafanaAlert(
labels: null == labels ? _self._labels : labels // ignore: cast_nullable_to_non_nullable
as Map<String, String>,annotations: null == annotations ? _self._annotations : annotations // ignore: cast_nullable_to_non_nullable
as Map<String, String>,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,fingerprint: freezed == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self._status : status // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,generatorUrl: null == generatorUrl ? _self.generatorUrl : generatorUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
