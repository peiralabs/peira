// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sonarr_series.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SonarrSeriesStatistics {

 int get episodeCount; int get episodeFileCount; int get totalEpisodeCount; int get sizeOnDisk;
/// Create a copy of SonarrSeriesStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SonarrSeriesStatisticsCopyWith<SonarrSeriesStatistics> get copyWith => _$SonarrSeriesStatisticsCopyWithImpl<SonarrSeriesStatistics>(this as SonarrSeriesStatistics, _$identity);

  /// Serializes this SonarrSeriesStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SonarrSeriesStatistics&&(identical(other.episodeCount, episodeCount) || other.episodeCount == episodeCount)&&(identical(other.episodeFileCount, episodeFileCount) || other.episodeFileCount == episodeFileCount)&&(identical(other.totalEpisodeCount, totalEpisodeCount) || other.totalEpisodeCount == totalEpisodeCount)&&(identical(other.sizeOnDisk, sizeOnDisk) || other.sizeOnDisk == sizeOnDisk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,episodeCount,episodeFileCount,totalEpisodeCount,sizeOnDisk);

@override
String toString() {
  return 'SonarrSeriesStatistics(episodeCount: $episodeCount, episodeFileCount: $episodeFileCount, totalEpisodeCount: $totalEpisodeCount, sizeOnDisk: $sizeOnDisk)';
}


}

/// @nodoc
abstract mixin class $SonarrSeriesStatisticsCopyWith<$Res>  {
  factory $SonarrSeriesStatisticsCopyWith(SonarrSeriesStatistics value, $Res Function(SonarrSeriesStatistics) _then) = _$SonarrSeriesStatisticsCopyWithImpl;
@useResult
$Res call({
 int episodeCount, int episodeFileCount, int totalEpisodeCount, int sizeOnDisk
});




}
/// @nodoc
class _$SonarrSeriesStatisticsCopyWithImpl<$Res>
    implements $SonarrSeriesStatisticsCopyWith<$Res> {
  _$SonarrSeriesStatisticsCopyWithImpl(this._self, this._then);

  final SonarrSeriesStatistics _self;
  final $Res Function(SonarrSeriesStatistics) _then;

/// Create a copy of SonarrSeriesStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? episodeCount = null,Object? episodeFileCount = null,Object? totalEpisodeCount = null,Object? sizeOnDisk = null,}) {
  return _then(_self.copyWith(
episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,episodeFileCount: null == episodeFileCount ? _self.episodeFileCount : episodeFileCount // ignore: cast_nullable_to_non_nullable
as int,totalEpisodeCount: null == totalEpisodeCount ? _self.totalEpisodeCount : totalEpisodeCount // ignore: cast_nullable_to_non_nullable
as int,sizeOnDisk: null == sizeOnDisk ? _self.sizeOnDisk : sizeOnDisk // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SonarrSeriesStatistics].
extension SonarrSeriesStatisticsPatterns on SonarrSeriesStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SonarrSeriesStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SonarrSeriesStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SonarrSeriesStatistics value)  $default,){
final _that = this;
switch (_that) {
case _SonarrSeriesStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SonarrSeriesStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _SonarrSeriesStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int episodeCount,  int episodeFileCount,  int totalEpisodeCount,  int sizeOnDisk)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SonarrSeriesStatistics() when $default != null:
return $default(_that.episodeCount,_that.episodeFileCount,_that.totalEpisodeCount,_that.sizeOnDisk);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int episodeCount,  int episodeFileCount,  int totalEpisodeCount,  int sizeOnDisk)  $default,) {final _that = this;
switch (_that) {
case _SonarrSeriesStatistics():
return $default(_that.episodeCount,_that.episodeFileCount,_that.totalEpisodeCount,_that.sizeOnDisk);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int episodeCount,  int episodeFileCount,  int totalEpisodeCount,  int sizeOnDisk)?  $default,) {final _that = this;
switch (_that) {
case _SonarrSeriesStatistics() when $default != null:
return $default(_that.episodeCount,_that.episodeFileCount,_that.totalEpisodeCount,_that.sizeOnDisk);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SonarrSeriesStatistics implements SonarrSeriesStatistics {
  const _SonarrSeriesStatistics({this.episodeCount = 0, this.episodeFileCount = 0, this.totalEpisodeCount = 0, this.sizeOnDisk = 0});
  factory _SonarrSeriesStatistics.fromJson(Map<String, dynamic> json) => _$SonarrSeriesStatisticsFromJson(json);

@override@JsonKey() final  int episodeCount;
@override@JsonKey() final  int episodeFileCount;
@override@JsonKey() final  int totalEpisodeCount;
@override@JsonKey() final  int sizeOnDisk;

/// Create a copy of SonarrSeriesStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SonarrSeriesStatisticsCopyWith<_SonarrSeriesStatistics> get copyWith => __$SonarrSeriesStatisticsCopyWithImpl<_SonarrSeriesStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SonarrSeriesStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SonarrSeriesStatistics&&(identical(other.episodeCount, episodeCount) || other.episodeCount == episodeCount)&&(identical(other.episodeFileCount, episodeFileCount) || other.episodeFileCount == episodeFileCount)&&(identical(other.totalEpisodeCount, totalEpisodeCount) || other.totalEpisodeCount == totalEpisodeCount)&&(identical(other.sizeOnDisk, sizeOnDisk) || other.sizeOnDisk == sizeOnDisk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,episodeCount,episodeFileCount,totalEpisodeCount,sizeOnDisk);

@override
String toString() {
  return 'SonarrSeriesStatistics(episodeCount: $episodeCount, episodeFileCount: $episodeFileCount, totalEpisodeCount: $totalEpisodeCount, sizeOnDisk: $sizeOnDisk)';
}


}

/// @nodoc
abstract mixin class _$SonarrSeriesStatisticsCopyWith<$Res> implements $SonarrSeriesStatisticsCopyWith<$Res> {
  factory _$SonarrSeriesStatisticsCopyWith(_SonarrSeriesStatistics value, $Res Function(_SonarrSeriesStatistics) _then) = __$SonarrSeriesStatisticsCopyWithImpl;
@override @useResult
$Res call({
 int episodeCount, int episodeFileCount, int totalEpisodeCount, int sizeOnDisk
});




}
/// @nodoc
class __$SonarrSeriesStatisticsCopyWithImpl<$Res>
    implements _$SonarrSeriesStatisticsCopyWith<$Res> {
  __$SonarrSeriesStatisticsCopyWithImpl(this._self, this._then);

  final _SonarrSeriesStatistics _self;
  final $Res Function(_SonarrSeriesStatistics) _then;

/// Create a copy of SonarrSeriesStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? episodeCount = null,Object? episodeFileCount = null,Object? totalEpisodeCount = null,Object? sizeOnDisk = null,}) {
  return _then(_SonarrSeriesStatistics(
episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,episodeFileCount: null == episodeFileCount ? _self.episodeFileCount : episodeFileCount // ignore: cast_nullable_to_non_nullable
as int,totalEpisodeCount: null == totalEpisodeCount ? _self.totalEpisodeCount : totalEpisodeCount // ignore: cast_nullable_to_non_nullable
as int,sizeOnDisk: null == sizeOnDisk ? _self.sizeOnDisk : sizeOnDisk // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SonarrSeries {

 int get id; String get title; int? get year; bool get monitored; String? get status; String? get network; String? get seriesType; int? get tvdbId; String? get overview; SonarrSeriesStatistics? get statistics;
/// Create a copy of SonarrSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SonarrSeriesCopyWith<SonarrSeries> get copyWith => _$SonarrSeriesCopyWithImpl<SonarrSeries>(this as SonarrSeries, _$identity);

  /// Serializes this SonarrSeries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SonarrSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.monitored, monitored) || other.monitored == monitored)&&(identical(other.status, status) || other.status == status)&&(identical(other.network, network) || other.network == network)&&(identical(other.seriesType, seriesType) || other.seriesType == seriesType)&&(identical(other.tvdbId, tvdbId) || other.tvdbId == tvdbId)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.statistics, statistics) || other.statistics == statistics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,year,monitored,status,network,seriesType,tvdbId,overview,statistics);

@override
String toString() {
  return 'SonarrSeries(id: $id, title: $title, year: $year, monitored: $monitored, status: $status, network: $network, seriesType: $seriesType, tvdbId: $tvdbId, overview: $overview, statistics: $statistics)';
}


}

/// @nodoc
abstract mixin class $SonarrSeriesCopyWith<$Res>  {
  factory $SonarrSeriesCopyWith(SonarrSeries value, $Res Function(SonarrSeries) _then) = _$SonarrSeriesCopyWithImpl;
@useResult
$Res call({
 int id, String title, int? year, bool monitored, String? status, String? network, String? seriesType, int? tvdbId, String? overview, SonarrSeriesStatistics? statistics
});


$SonarrSeriesStatisticsCopyWith<$Res>? get statistics;

}
/// @nodoc
class _$SonarrSeriesCopyWithImpl<$Res>
    implements $SonarrSeriesCopyWith<$Res> {
  _$SonarrSeriesCopyWithImpl(this._self, this._then);

  final SonarrSeries _self;
  final $Res Function(SonarrSeries) _then;

/// Create a copy of SonarrSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? year = freezed,Object? monitored = null,Object? status = freezed,Object? network = freezed,Object? seriesType = freezed,Object? tvdbId = freezed,Object? overview = freezed,Object? statistics = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,monitored: null == monitored ? _self.monitored : monitored // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,network: freezed == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String?,seriesType: freezed == seriesType ? _self.seriesType : seriesType // ignore: cast_nullable_to_non_nullable
as String?,tvdbId: freezed == tvdbId ? _self.tvdbId : tvdbId // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,statistics: freezed == statistics ? _self.statistics : statistics // ignore: cast_nullable_to_non_nullable
as SonarrSeriesStatistics?,
  ));
}
/// Create a copy of SonarrSeries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SonarrSeriesStatisticsCopyWith<$Res>? get statistics {
    if (_self.statistics == null) {
    return null;
  }

  return $SonarrSeriesStatisticsCopyWith<$Res>(_self.statistics!, (value) {
    return _then(_self.copyWith(statistics: value));
  });
}
}


/// Adds pattern-matching-related methods to [SonarrSeries].
extension SonarrSeriesPatterns on SonarrSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SonarrSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SonarrSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SonarrSeries value)  $default,){
final _that = this;
switch (_that) {
case _SonarrSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SonarrSeries value)?  $default,){
final _that = this;
switch (_that) {
case _SonarrSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  int? year,  bool monitored,  String? status,  String? network,  String? seriesType,  int? tvdbId,  String? overview,  SonarrSeriesStatistics? statistics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SonarrSeries() when $default != null:
return $default(_that.id,_that.title,_that.year,_that.monitored,_that.status,_that.network,_that.seriesType,_that.tvdbId,_that.overview,_that.statistics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  int? year,  bool monitored,  String? status,  String? network,  String? seriesType,  int? tvdbId,  String? overview,  SonarrSeriesStatistics? statistics)  $default,) {final _that = this;
switch (_that) {
case _SonarrSeries():
return $default(_that.id,_that.title,_that.year,_that.monitored,_that.status,_that.network,_that.seriesType,_that.tvdbId,_that.overview,_that.statistics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  int? year,  bool monitored,  String? status,  String? network,  String? seriesType,  int? tvdbId,  String? overview,  SonarrSeriesStatistics? statistics)?  $default,) {final _that = this;
switch (_that) {
case _SonarrSeries() when $default != null:
return $default(_that.id,_that.title,_that.year,_that.monitored,_that.status,_that.network,_that.seriesType,_that.tvdbId,_that.overview,_that.statistics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SonarrSeries implements SonarrSeries {
  const _SonarrSeries({this.id = 0, this.title = '', this.year, this.monitored = false, this.status, this.network, this.seriesType, this.tvdbId, this.overview, this.statistics});
  factory _SonarrSeries.fromJson(Map<String, dynamic> json) => _$SonarrSeriesFromJson(json);

@override@JsonKey() final  int id;
@override@JsonKey() final  String title;
@override final  int? year;
@override@JsonKey() final  bool monitored;
@override final  String? status;
@override final  String? network;
@override final  String? seriesType;
@override final  int? tvdbId;
@override final  String? overview;
@override final  SonarrSeriesStatistics? statistics;

/// Create a copy of SonarrSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SonarrSeriesCopyWith<_SonarrSeries> get copyWith => __$SonarrSeriesCopyWithImpl<_SonarrSeries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SonarrSeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SonarrSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.monitored, monitored) || other.monitored == monitored)&&(identical(other.status, status) || other.status == status)&&(identical(other.network, network) || other.network == network)&&(identical(other.seriesType, seriesType) || other.seriesType == seriesType)&&(identical(other.tvdbId, tvdbId) || other.tvdbId == tvdbId)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.statistics, statistics) || other.statistics == statistics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,year,monitored,status,network,seriesType,tvdbId,overview,statistics);

@override
String toString() {
  return 'SonarrSeries(id: $id, title: $title, year: $year, monitored: $monitored, status: $status, network: $network, seriesType: $seriesType, tvdbId: $tvdbId, overview: $overview, statistics: $statistics)';
}


}

/// @nodoc
abstract mixin class _$SonarrSeriesCopyWith<$Res> implements $SonarrSeriesCopyWith<$Res> {
  factory _$SonarrSeriesCopyWith(_SonarrSeries value, $Res Function(_SonarrSeries) _then) = __$SonarrSeriesCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, int? year, bool monitored, String? status, String? network, String? seriesType, int? tvdbId, String? overview, SonarrSeriesStatistics? statistics
});


@override $SonarrSeriesStatisticsCopyWith<$Res>? get statistics;

}
/// @nodoc
class __$SonarrSeriesCopyWithImpl<$Res>
    implements _$SonarrSeriesCopyWith<$Res> {
  __$SonarrSeriesCopyWithImpl(this._self, this._then);

  final _SonarrSeries _self;
  final $Res Function(_SonarrSeries) _then;

/// Create a copy of SonarrSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? year = freezed,Object? monitored = null,Object? status = freezed,Object? network = freezed,Object? seriesType = freezed,Object? tvdbId = freezed,Object? overview = freezed,Object? statistics = freezed,}) {
  return _then(_SonarrSeries(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,monitored: null == monitored ? _self.monitored : monitored // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,network: freezed == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String?,seriesType: freezed == seriesType ? _self.seriesType : seriesType // ignore: cast_nullable_to_non_nullable
as String?,tvdbId: freezed == tvdbId ? _self.tvdbId : tvdbId // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,statistics: freezed == statistics ? _self.statistics : statistics // ignore: cast_nullable_to_non_nullable
as SonarrSeriesStatistics?,
  ));
}

/// Create a copy of SonarrSeries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SonarrSeriesStatisticsCopyWith<$Res>? get statistics {
    if (_self.statistics == null) {
    return null;
  }

  return $SonarrSeriesStatisticsCopyWith<$Res>(_self.statistics!, (value) {
    return _then(_self.copyWith(statistics: value));
  });
}
}

// dart format on
