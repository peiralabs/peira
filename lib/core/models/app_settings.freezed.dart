// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 String get proxmoxUrl; String get proxmoxTokenId; String get proxmoxTokenSecret; String get dockerUrl; bool get dockerTlsVerify; String get grafanaUrl; String get grafanaApiKey; String get prometheusUrl; String get hermesUrl; String get wikiUrl; String get ollamaUrl; String get ollamaApiUrl; String get hermesApiUrl; String get hermesApiKey; String get aiChatModel; String get askUrl; String get homeAssistantUrl; String get searxngUrl; String get karakeepUrl; String get paperlessUrl; String get immichUrl; String get changedetectionUrl; String get lokiUrl; String get pdmUrl; String get pdmTokenId; String get pdmTokenSecret; String get pdmFingerprint; String get jellyseerrUrl; String get jellyfinUrl; String get jellyfinApiKey; String get plexUrl; String get plexToken; String get radarrUrl; String get radarrApiKey; String get sonarrUrl; String get sonarrApiKey; String get prowlarrUrl; String get prowlarrApiKey; String get qbittorrentUrl; String get qbittorrentUser; String get qbittorrentPass; bool get trustSelfSigned; String get themeMode; bool get railCollapsed; String get sshTargets; String get sshUsername; double get electricityRateUsdPerKwh; String get webLoginsJson; bool get webAutoLogin; bool get notifyAlerts;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.proxmoxUrl, proxmoxUrl) || other.proxmoxUrl == proxmoxUrl)&&(identical(other.proxmoxTokenId, proxmoxTokenId) || other.proxmoxTokenId == proxmoxTokenId)&&(identical(other.proxmoxTokenSecret, proxmoxTokenSecret) || other.proxmoxTokenSecret == proxmoxTokenSecret)&&(identical(other.dockerUrl, dockerUrl) || other.dockerUrl == dockerUrl)&&(identical(other.dockerTlsVerify, dockerTlsVerify) || other.dockerTlsVerify == dockerTlsVerify)&&(identical(other.grafanaUrl, grafanaUrl) || other.grafanaUrl == grafanaUrl)&&(identical(other.grafanaApiKey, grafanaApiKey) || other.grafanaApiKey == grafanaApiKey)&&(identical(other.prometheusUrl, prometheusUrl) || other.prometheusUrl == prometheusUrl)&&(identical(other.hermesUrl, hermesUrl) || other.hermesUrl == hermesUrl)&&(identical(other.wikiUrl, wikiUrl) || other.wikiUrl == wikiUrl)&&(identical(other.ollamaUrl, ollamaUrl) || other.ollamaUrl == ollamaUrl)&&(identical(other.ollamaApiUrl, ollamaApiUrl) || other.ollamaApiUrl == ollamaApiUrl)&&(identical(other.hermesApiUrl, hermesApiUrl) || other.hermesApiUrl == hermesApiUrl)&&(identical(other.hermesApiKey, hermesApiKey) || other.hermesApiKey == hermesApiKey)&&(identical(other.aiChatModel, aiChatModel) || other.aiChatModel == aiChatModel)&&(identical(other.askUrl, askUrl) || other.askUrl == askUrl)&&(identical(other.homeAssistantUrl, homeAssistantUrl) || other.homeAssistantUrl == homeAssistantUrl)&&(identical(other.searxngUrl, searxngUrl) || other.searxngUrl == searxngUrl)&&(identical(other.karakeepUrl, karakeepUrl) || other.karakeepUrl == karakeepUrl)&&(identical(other.paperlessUrl, paperlessUrl) || other.paperlessUrl == paperlessUrl)&&(identical(other.immichUrl, immichUrl) || other.immichUrl == immichUrl)&&(identical(other.changedetectionUrl, changedetectionUrl) || other.changedetectionUrl == changedetectionUrl)&&(identical(other.lokiUrl, lokiUrl) || other.lokiUrl == lokiUrl)&&(identical(other.pdmUrl, pdmUrl) || other.pdmUrl == pdmUrl)&&(identical(other.pdmTokenId, pdmTokenId) || other.pdmTokenId == pdmTokenId)&&(identical(other.pdmTokenSecret, pdmTokenSecret) || other.pdmTokenSecret == pdmTokenSecret)&&(identical(other.pdmFingerprint, pdmFingerprint) || other.pdmFingerprint == pdmFingerprint)&&(identical(other.jellyseerrUrl, jellyseerrUrl) || other.jellyseerrUrl == jellyseerrUrl)&&(identical(other.jellyfinUrl, jellyfinUrl) || other.jellyfinUrl == jellyfinUrl)&&(identical(other.jellyfinApiKey, jellyfinApiKey) || other.jellyfinApiKey == jellyfinApiKey)&&(identical(other.plexUrl, plexUrl) || other.plexUrl == plexUrl)&&(identical(other.plexToken, plexToken) || other.plexToken == plexToken)&&(identical(other.radarrUrl, radarrUrl) || other.radarrUrl == radarrUrl)&&(identical(other.radarrApiKey, radarrApiKey) || other.radarrApiKey == radarrApiKey)&&(identical(other.sonarrUrl, sonarrUrl) || other.sonarrUrl == sonarrUrl)&&(identical(other.sonarrApiKey, sonarrApiKey) || other.sonarrApiKey == sonarrApiKey)&&(identical(other.prowlarrUrl, prowlarrUrl) || other.prowlarrUrl == prowlarrUrl)&&(identical(other.prowlarrApiKey, prowlarrApiKey) || other.prowlarrApiKey == prowlarrApiKey)&&(identical(other.qbittorrentUrl, qbittorrentUrl) || other.qbittorrentUrl == qbittorrentUrl)&&(identical(other.qbittorrentUser, qbittorrentUser) || other.qbittorrentUser == qbittorrentUser)&&(identical(other.qbittorrentPass, qbittorrentPass) || other.qbittorrentPass == qbittorrentPass)&&(identical(other.trustSelfSigned, trustSelfSigned) || other.trustSelfSigned == trustSelfSigned)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.railCollapsed, railCollapsed) || other.railCollapsed == railCollapsed)&&(identical(other.sshTargets, sshTargets) || other.sshTargets == sshTargets)&&(identical(other.sshUsername, sshUsername) || other.sshUsername == sshUsername)&&(identical(other.electricityRateUsdPerKwh, electricityRateUsdPerKwh) || other.electricityRateUsdPerKwh == electricityRateUsdPerKwh)&&(identical(other.webLoginsJson, webLoginsJson) || other.webLoginsJson == webLoginsJson)&&(identical(other.webAutoLogin, webAutoLogin) || other.webAutoLogin == webAutoLogin)&&(identical(other.notifyAlerts, notifyAlerts) || other.notifyAlerts == notifyAlerts));
}


@override
int get hashCode => Object.hashAll([runtimeType,proxmoxUrl,proxmoxTokenId,proxmoxTokenSecret,dockerUrl,dockerTlsVerify,grafanaUrl,grafanaApiKey,prometheusUrl,hermesUrl,wikiUrl,ollamaUrl,ollamaApiUrl,hermesApiUrl,hermesApiKey,aiChatModel,askUrl,homeAssistantUrl,searxngUrl,karakeepUrl,paperlessUrl,immichUrl,changedetectionUrl,lokiUrl,pdmUrl,pdmTokenId,pdmTokenSecret,pdmFingerprint,jellyseerrUrl,jellyfinUrl,jellyfinApiKey,plexUrl,plexToken,radarrUrl,radarrApiKey,sonarrUrl,sonarrApiKey,prowlarrUrl,prowlarrApiKey,qbittorrentUrl,qbittorrentUser,qbittorrentPass,trustSelfSigned,themeMode,railCollapsed,sshTargets,sshUsername,electricityRateUsdPerKwh,webLoginsJson,webAutoLogin,notifyAlerts]);

@override
String toString() {
  return 'AppSettings(proxmoxUrl: $proxmoxUrl, proxmoxTokenId: $proxmoxTokenId, proxmoxTokenSecret: $proxmoxTokenSecret, dockerUrl: $dockerUrl, dockerTlsVerify: $dockerTlsVerify, grafanaUrl: $grafanaUrl, grafanaApiKey: $grafanaApiKey, prometheusUrl: $prometheusUrl, hermesUrl: $hermesUrl, wikiUrl: $wikiUrl, ollamaUrl: $ollamaUrl, ollamaApiUrl: $ollamaApiUrl, hermesApiUrl: $hermesApiUrl, hermesApiKey: $hermesApiKey, aiChatModel: $aiChatModel, askUrl: $askUrl, homeAssistantUrl: $homeAssistantUrl, searxngUrl: $searxngUrl, karakeepUrl: $karakeepUrl, paperlessUrl: $paperlessUrl, immichUrl: $immichUrl, changedetectionUrl: $changedetectionUrl, lokiUrl: $lokiUrl, pdmUrl: $pdmUrl, pdmTokenId: $pdmTokenId, pdmTokenSecret: $pdmTokenSecret, pdmFingerprint: $pdmFingerprint, jellyseerrUrl: $jellyseerrUrl, jellyfinUrl: $jellyfinUrl, jellyfinApiKey: $jellyfinApiKey, plexUrl: $plexUrl, plexToken: $plexToken, radarrUrl: $radarrUrl, radarrApiKey: $radarrApiKey, sonarrUrl: $sonarrUrl, sonarrApiKey: $sonarrApiKey, prowlarrUrl: $prowlarrUrl, prowlarrApiKey: $prowlarrApiKey, qbittorrentUrl: $qbittorrentUrl, qbittorrentUser: $qbittorrentUser, qbittorrentPass: $qbittorrentPass, trustSelfSigned: $trustSelfSigned, themeMode: $themeMode, railCollapsed: $railCollapsed, sshTargets: $sshTargets, sshUsername: $sshUsername, electricityRateUsdPerKwh: $electricityRateUsdPerKwh, webLoginsJson: $webLoginsJson, webAutoLogin: $webAutoLogin, notifyAlerts: $notifyAlerts)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 String proxmoxUrl, String proxmoxTokenId, String proxmoxTokenSecret, String dockerUrl, bool dockerTlsVerify, String grafanaUrl, String grafanaApiKey, String prometheusUrl, String hermesUrl, String wikiUrl, String ollamaUrl, String ollamaApiUrl, String hermesApiUrl, String hermesApiKey, String aiChatModel, String askUrl, String homeAssistantUrl, String searxngUrl, String karakeepUrl, String paperlessUrl, String immichUrl, String changedetectionUrl, String lokiUrl, String pdmUrl, String pdmTokenId, String pdmTokenSecret, String pdmFingerprint, String jellyseerrUrl, String jellyfinUrl, String jellyfinApiKey, String plexUrl, String plexToken, String radarrUrl, String radarrApiKey, String sonarrUrl, String sonarrApiKey, String prowlarrUrl, String prowlarrApiKey, String qbittorrentUrl, String qbittorrentUser, String qbittorrentPass, bool trustSelfSigned, String themeMode, bool railCollapsed, String sshTargets, String sshUsername, double electricityRateUsdPerKwh, String webLoginsJson, bool webAutoLogin, bool notifyAlerts
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? proxmoxUrl = null,Object? proxmoxTokenId = null,Object? proxmoxTokenSecret = null,Object? dockerUrl = null,Object? dockerTlsVerify = null,Object? grafanaUrl = null,Object? grafanaApiKey = null,Object? prometheusUrl = null,Object? hermesUrl = null,Object? wikiUrl = null,Object? ollamaUrl = null,Object? ollamaApiUrl = null,Object? hermesApiUrl = null,Object? hermesApiKey = null,Object? aiChatModel = null,Object? askUrl = null,Object? homeAssistantUrl = null,Object? searxngUrl = null,Object? karakeepUrl = null,Object? paperlessUrl = null,Object? immichUrl = null,Object? changedetectionUrl = null,Object? lokiUrl = null,Object? pdmUrl = null,Object? pdmTokenId = null,Object? pdmTokenSecret = null,Object? pdmFingerprint = null,Object? jellyseerrUrl = null,Object? jellyfinUrl = null,Object? jellyfinApiKey = null,Object? plexUrl = null,Object? plexToken = null,Object? radarrUrl = null,Object? radarrApiKey = null,Object? sonarrUrl = null,Object? sonarrApiKey = null,Object? prowlarrUrl = null,Object? prowlarrApiKey = null,Object? qbittorrentUrl = null,Object? qbittorrentUser = null,Object? qbittorrentPass = null,Object? trustSelfSigned = null,Object? themeMode = null,Object? railCollapsed = null,Object? sshTargets = null,Object? sshUsername = null,Object? electricityRateUsdPerKwh = null,Object? webLoginsJson = null,Object? webAutoLogin = null,Object? notifyAlerts = null,}) {
  return _then(_self.copyWith(
proxmoxUrl: null == proxmoxUrl ? _self.proxmoxUrl : proxmoxUrl // ignore: cast_nullable_to_non_nullable
as String,proxmoxTokenId: null == proxmoxTokenId ? _self.proxmoxTokenId : proxmoxTokenId // ignore: cast_nullable_to_non_nullable
as String,proxmoxTokenSecret: null == proxmoxTokenSecret ? _self.proxmoxTokenSecret : proxmoxTokenSecret // ignore: cast_nullable_to_non_nullable
as String,dockerUrl: null == dockerUrl ? _self.dockerUrl : dockerUrl // ignore: cast_nullable_to_non_nullable
as String,dockerTlsVerify: null == dockerTlsVerify ? _self.dockerTlsVerify : dockerTlsVerify // ignore: cast_nullable_to_non_nullable
as bool,grafanaUrl: null == grafanaUrl ? _self.grafanaUrl : grafanaUrl // ignore: cast_nullable_to_non_nullable
as String,grafanaApiKey: null == grafanaApiKey ? _self.grafanaApiKey : grafanaApiKey // ignore: cast_nullable_to_non_nullable
as String,prometheusUrl: null == prometheusUrl ? _self.prometheusUrl : prometheusUrl // ignore: cast_nullable_to_non_nullable
as String,hermesUrl: null == hermesUrl ? _self.hermesUrl : hermesUrl // ignore: cast_nullable_to_non_nullable
as String,wikiUrl: null == wikiUrl ? _self.wikiUrl : wikiUrl // ignore: cast_nullable_to_non_nullable
as String,ollamaUrl: null == ollamaUrl ? _self.ollamaUrl : ollamaUrl // ignore: cast_nullable_to_non_nullable
as String,ollamaApiUrl: null == ollamaApiUrl ? _self.ollamaApiUrl : ollamaApiUrl // ignore: cast_nullable_to_non_nullable
as String,hermesApiUrl: null == hermesApiUrl ? _self.hermesApiUrl : hermesApiUrl // ignore: cast_nullable_to_non_nullable
as String,hermesApiKey: null == hermesApiKey ? _self.hermesApiKey : hermesApiKey // ignore: cast_nullable_to_non_nullable
as String,aiChatModel: null == aiChatModel ? _self.aiChatModel : aiChatModel // ignore: cast_nullable_to_non_nullable
as String,askUrl: null == askUrl ? _self.askUrl : askUrl // ignore: cast_nullable_to_non_nullable
as String,homeAssistantUrl: null == homeAssistantUrl ? _self.homeAssistantUrl : homeAssistantUrl // ignore: cast_nullable_to_non_nullable
as String,searxngUrl: null == searxngUrl ? _self.searxngUrl : searxngUrl // ignore: cast_nullable_to_non_nullable
as String,karakeepUrl: null == karakeepUrl ? _self.karakeepUrl : karakeepUrl // ignore: cast_nullable_to_non_nullable
as String,paperlessUrl: null == paperlessUrl ? _self.paperlessUrl : paperlessUrl // ignore: cast_nullable_to_non_nullable
as String,immichUrl: null == immichUrl ? _self.immichUrl : immichUrl // ignore: cast_nullable_to_non_nullable
as String,changedetectionUrl: null == changedetectionUrl ? _self.changedetectionUrl : changedetectionUrl // ignore: cast_nullable_to_non_nullable
as String,lokiUrl: null == lokiUrl ? _self.lokiUrl : lokiUrl // ignore: cast_nullable_to_non_nullable
as String,pdmUrl: null == pdmUrl ? _self.pdmUrl : pdmUrl // ignore: cast_nullable_to_non_nullable
as String,pdmTokenId: null == pdmTokenId ? _self.pdmTokenId : pdmTokenId // ignore: cast_nullable_to_non_nullable
as String,pdmTokenSecret: null == pdmTokenSecret ? _self.pdmTokenSecret : pdmTokenSecret // ignore: cast_nullable_to_non_nullable
as String,pdmFingerprint: null == pdmFingerprint ? _self.pdmFingerprint : pdmFingerprint // ignore: cast_nullable_to_non_nullable
as String,jellyseerrUrl: null == jellyseerrUrl ? _self.jellyseerrUrl : jellyseerrUrl // ignore: cast_nullable_to_non_nullable
as String,jellyfinUrl: null == jellyfinUrl ? _self.jellyfinUrl : jellyfinUrl // ignore: cast_nullable_to_non_nullable
as String,jellyfinApiKey: null == jellyfinApiKey ? _self.jellyfinApiKey : jellyfinApiKey // ignore: cast_nullable_to_non_nullable
as String,plexUrl: null == plexUrl ? _self.plexUrl : plexUrl // ignore: cast_nullable_to_non_nullable
as String,plexToken: null == plexToken ? _self.plexToken : plexToken // ignore: cast_nullable_to_non_nullable
as String,radarrUrl: null == radarrUrl ? _self.radarrUrl : radarrUrl // ignore: cast_nullable_to_non_nullable
as String,radarrApiKey: null == radarrApiKey ? _self.radarrApiKey : radarrApiKey // ignore: cast_nullable_to_non_nullable
as String,sonarrUrl: null == sonarrUrl ? _self.sonarrUrl : sonarrUrl // ignore: cast_nullable_to_non_nullable
as String,sonarrApiKey: null == sonarrApiKey ? _self.sonarrApiKey : sonarrApiKey // ignore: cast_nullable_to_non_nullable
as String,prowlarrUrl: null == prowlarrUrl ? _self.prowlarrUrl : prowlarrUrl // ignore: cast_nullable_to_non_nullable
as String,prowlarrApiKey: null == prowlarrApiKey ? _self.prowlarrApiKey : prowlarrApiKey // ignore: cast_nullable_to_non_nullable
as String,qbittorrentUrl: null == qbittorrentUrl ? _self.qbittorrentUrl : qbittorrentUrl // ignore: cast_nullable_to_non_nullable
as String,qbittorrentUser: null == qbittorrentUser ? _self.qbittorrentUser : qbittorrentUser // ignore: cast_nullable_to_non_nullable
as String,qbittorrentPass: null == qbittorrentPass ? _self.qbittorrentPass : qbittorrentPass // ignore: cast_nullable_to_non_nullable
as String,trustSelfSigned: null == trustSelfSigned ? _self.trustSelfSigned : trustSelfSigned // ignore: cast_nullable_to_non_nullable
as bool,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,railCollapsed: null == railCollapsed ? _self.railCollapsed : railCollapsed // ignore: cast_nullable_to_non_nullable
as bool,sshTargets: null == sshTargets ? _self.sshTargets : sshTargets // ignore: cast_nullable_to_non_nullable
as String,sshUsername: null == sshUsername ? _self.sshUsername : sshUsername // ignore: cast_nullable_to_non_nullable
as String,electricityRateUsdPerKwh: null == electricityRateUsdPerKwh ? _self.electricityRateUsdPerKwh : electricityRateUsdPerKwh // ignore: cast_nullable_to_non_nullable
as double,webLoginsJson: null == webLoginsJson ? _self.webLoginsJson : webLoginsJson // ignore: cast_nullable_to_non_nullable
as String,webAutoLogin: null == webAutoLogin ? _self.webAutoLogin : webAutoLogin // ignore: cast_nullable_to_non_nullable
as bool,notifyAlerts: null == notifyAlerts ? _self.notifyAlerts : notifyAlerts // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String proxmoxUrl,  String proxmoxTokenId,  String proxmoxTokenSecret,  String dockerUrl,  bool dockerTlsVerify,  String grafanaUrl,  String grafanaApiKey,  String prometheusUrl,  String hermesUrl,  String wikiUrl,  String ollamaUrl,  String ollamaApiUrl,  String hermesApiUrl,  String hermesApiKey,  String aiChatModel,  String askUrl,  String homeAssistantUrl,  String searxngUrl,  String karakeepUrl,  String paperlessUrl,  String immichUrl,  String changedetectionUrl,  String lokiUrl,  String pdmUrl,  String pdmTokenId,  String pdmTokenSecret,  String pdmFingerprint,  String jellyseerrUrl,  String jellyfinUrl,  String jellyfinApiKey,  String plexUrl,  String plexToken,  String radarrUrl,  String radarrApiKey,  String sonarrUrl,  String sonarrApiKey,  String prowlarrUrl,  String prowlarrApiKey,  String qbittorrentUrl,  String qbittorrentUser,  String qbittorrentPass,  bool trustSelfSigned,  String themeMode,  bool railCollapsed,  String sshTargets,  String sshUsername,  double electricityRateUsdPerKwh,  String webLoginsJson,  bool webAutoLogin,  bool notifyAlerts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.proxmoxUrl,_that.proxmoxTokenId,_that.proxmoxTokenSecret,_that.dockerUrl,_that.dockerTlsVerify,_that.grafanaUrl,_that.grafanaApiKey,_that.prometheusUrl,_that.hermesUrl,_that.wikiUrl,_that.ollamaUrl,_that.ollamaApiUrl,_that.hermesApiUrl,_that.hermesApiKey,_that.aiChatModel,_that.askUrl,_that.homeAssistantUrl,_that.searxngUrl,_that.karakeepUrl,_that.paperlessUrl,_that.immichUrl,_that.changedetectionUrl,_that.lokiUrl,_that.pdmUrl,_that.pdmTokenId,_that.pdmTokenSecret,_that.pdmFingerprint,_that.jellyseerrUrl,_that.jellyfinUrl,_that.jellyfinApiKey,_that.plexUrl,_that.plexToken,_that.radarrUrl,_that.radarrApiKey,_that.sonarrUrl,_that.sonarrApiKey,_that.prowlarrUrl,_that.prowlarrApiKey,_that.qbittorrentUrl,_that.qbittorrentUser,_that.qbittorrentPass,_that.trustSelfSigned,_that.themeMode,_that.railCollapsed,_that.sshTargets,_that.sshUsername,_that.electricityRateUsdPerKwh,_that.webLoginsJson,_that.webAutoLogin,_that.notifyAlerts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String proxmoxUrl,  String proxmoxTokenId,  String proxmoxTokenSecret,  String dockerUrl,  bool dockerTlsVerify,  String grafanaUrl,  String grafanaApiKey,  String prometheusUrl,  String hermesUrl,  String wikiUrl,  String ollamaUrl,  String ollamaApiUrl,  String hermesApiUrl,  String hermesApiKey,  String aiChatModel,  String askUrl,  String homeAssistantUrl,  String searxngUrl,  String karakeepUrl,  String paperlessUrl,  String immichUrl,  String changedetectionUrl,  String lokiUrl,  String pdmUrl,  String pdmTokenId,  String pdmTokenSecret,  String pdmFingerprint,  String jellyseerrUrl,  String jellyfinUrl,  String jellyfinApiKey,  String plexUrl,  String plexToken,  String radarrUrl,  String radarrApiKey,  String sonarrUrl,  String sonarrApiKey,  String prowlarrUrl,  String prowlarrApiKey,  String qbittorrentUrl,  String qbittorrentUser,  String qbittorrentPass,  bool trustSelfSigned,  String themeMode,  bool railCollapsed,  String sshTargets,  String sshUsername,  double electricityRateUsdPerKwh,  String webLoginsJson,  bool webAutoLogin,  bool notifyAlerts)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.proxmoxUrl,_that.proxmoxTokenId,_that.proxmoxTokenSecret,_that.dockerUrl,_that.dockerTlsVerify,_that.grafanaUrl,_that.grafanaApiKey,_that.prometheusUrl,_that.hermesUrl,_that.wikiUrl,_that.ollamaUrl,_that.ollamaApiUrl,_that.hermesApiUrl,_that.hermesApiKey,_that.aiChatModel,_that.askUrl,_that.homeAssistantUrl,_that.searxngUrl,_that.karakeepUrl,_that.paperlessUrl,_that.immichUrl,_that.changedetectionUrl,_that.lokiUrl,_that.pdmUrl,_that.pdmTokenId,_that.pdmTokenSecret,_that.pdmFingerprint,_that.jellyseerrUrl,_that.jellyfinUrl,_that.jellyfinApiKey,_that.plexUrl,_that.plexToken,_that.radarrUrl,_that.radarrApiKey,_that.sonarrUrl,_that.sonarrApiKey,_that.prowlarrUrl,_that.prowlarrApiKey,_that.qbittorrentUrl,_that.qbittorrentUser,_that.qbittorrentPass,_that.trustSelfSigned,_that.themeMode,_that.railCollapsed,_that.sshTargets,_that.sshUsername,_that.electricityRateUsdPerKwh,_that.webLoginsJson,_that.webAutoLogin,_that.notifyAlerts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String proxmoxUrl,  String proxmoxTokenId,  String proxmoxTokenSecret,  String dockerUrl,  bool dockerTlsVerify,  String grafanaUrl,  String grafanaApiKey,  String prometheusUrl,  String hermesUrl,  String wikiUrl,  String ollamaUrl,  String ollamaApiUrl,  String hermesApiUrl,  String hermesApiKey,  String aiChatModel,  String askUrl,  String homeAssistantUrl,  String searxngUrl,  String karakeepUrl,  String paperlessUrl,  String immichUrl,  String changedetectionUrl,  String lokiUrl,  String pdmUrl,  String pdmTokenId,  String pdmTokenSecret,  String pdmFingerprint,  String jellyseerrUrl,  String jellyfinUrl,  String jellyfinApiKey,  String plexUrl,  String plexToken,  String radarrUrl,  String radarrApiKey,  String sonarrUrl,  String sonarrApiKey,  String prowlarrUrl,  String prowlarrApiKey,  String qbittorrentUrl,  String qbittorrentUser,  String qbittorrentPass,  bool trustSelfSigned,  String themeMode,  bool railCollapsed,  String sshTargets,  String sshUsername,  double electricityRateUsdPerKwh,  String webLoginsJson,  bool webAutoLogin,  bool notifyAlerts)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.proxmoxUrl,_that.proxmoxTokenId,_that.proxmoxTokenSecret,_that.dockerUrl,_that.dockerTlsVerify,_that.grafanaUrl,_that.grafanaApiKey,_that.prometheusUrl,_that.hermesUrl,_that.wikiUrl,_that.ollamaUrl,_that.ollamaApiUrl,_that.hermesApiUrl,_that.hermesApiKey,_that.aiChatModel,_that.askUrl,_that.homeAssistantUrl,_that.searxngUrl,_that.karakeepUrl,_that.paperlessUrl,_that.immichUrl,_that.changedetectionUrl,_that.lokiUrl,_that.pdmUrl,_that.pdmTokenId,_that.pdmTokenSecret,_that.pdmFingerprint,_that.jellyseerrUrl,_that.jellyfinUrl,_that.jellyfinApiKey,_that.plexUrl,_that.plexToken,_that.radarrUrl,_that.radarrApiKey,_that.sonarrUrl,_that.sonarrApiKey,_that.prowlarrUrl,_that.prowlarrApiKey,_that.qbittorrentUrl,_that.qbittorrentUser,_that.qbittorrentPass,_that.trustSelfSigned,_that.themeMode,_that.railCollapsed,_that.sshTargets,_that.sshUsername,_that.electricityRateUsdPerKwh,_that.webLoginsJson,_that.webAutoLogin,_that.notifyAlerts);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings extends AppSettings {
  const _AppSettings({this.proxmoxUrl = '', this.proxmoxTokenId = '', this.proxmoxTokenSecret = '', this.dockerUrl = '', this.dockerTlsVerify = true, this.grafanaUrl = '', this.grafanaApiKey = '', this.prometheusUrl = '', this.hermesUrl = '', this.wikiUrl = '', this.ollamaUrl = '', this.ollamaApiUrl = '', this.hermesApiUrl = '', this.hermesApiKey = '', this.aiChatModel = '', this.askUrl = '', this.homeAssistantUrl = '', this.searxngUrl = '', this.karakeepUrl = '', this.paperlessUrl = '', this.immichUrl = '', this.changedetectionUrl = '', this.lokiUrl = '', this.pdmUrl = '', this.pdmTokenId = '', this.pdmTokenSecret = '', this.pdmFingerprint = '', this.jellyseerrUrl = '', this.jellyfinUrl = '', this.jellyfinApiKey = '', this.plexUrl = '', this.plexToken = '', this.radarrUrl = '', this.radarrApiKey = '', this.sonarrUrl = '', this.sonarrApiKey = '', this.prowlarrUrl = '', this.prowlarrApiKey = '', this.qbittorrentUrl = '', this.qbittorrentUser = '', this.qbittorrentPass = '', this.trustSelfSigned = true, this.themeMode = 'system', this.railCollapsed = false, this.sshTargets = '', this.sshUsername = 'root', this.electricityRateUsdPerKwh = 0.30, this.webLoginsJson = '', this.webAutoLogin = true, this.notifyAlerts = true}): super._();
  

@override@JsonKey() final  String proxmoxUrl;
@override@JsonKey() final  String proxmoxTokenId;
@override@JsonKey() final  String proxmoxTokenSecret;
@override@JsonKey() final  String dockerUrl;
@override@JsonKey() final  bool dockerTlsVerify;
@override@JsonKey() final  String grafanaUrl;
@override@JsonKey() final  String grafanaApiKey;
@override@JsonKey() final  String prometheusUrl;
@override@JsonKey() final  String hermesUrl;
@override@JsonKey() final  String wikiUrl;
@override@JsonKey() final  String ollamaUrl;
@override@JsonKey() final  String ollamaApiUrl;
@override@JsonKey() final  String hermesApiUrl;
@override@JsonKey() final  String hermesApiKey;
@override@JsonKey() final  String aiChatModel;
@override@JsonKey() final  String askUrl;
@override@JsonKey() final  String homeAssistantUrl;
@override@JsonKey() final  String searxngUrl;
@override@JsonKey() final  String karakeepUrl;
@override@JsonKey() final  String paperlessUrl;
@override@JsonKey() final  String immichUrl;
@override@JsonKey() final  String changedetectionUrl;
@override@JsonKey() final  String lokiUrl;
@override@JsonKey() final  String pdmUrl;
@override@JsonKey() final  String pdmTokenId;
@override@JsonKey() final  String pdmTokenSecret;
@override@JsonKey() final  String pdmFingerprint;
@override@JsonKey() final  String jellyseerrUrl;
@override@JsonKey() final  String jellyfinUrl;
@override@JsonKey() final  String jellyfinApiKey;
@override@JsonKey() final  String plexUrl;
@override@JsonKey() final  String plexToken;
@override@JsonKey() final  String radarrUrl;
@override@JsonKey() final  String radarrApiKey;
@override@JsonKey() final  String sonarrUrl;
@override@JsonKey() final  String sonarrApiKey;
@override@JsonKey() final  String prowlarrUrl;
@override@JsonKey() final  String prowlarrApiKey;
@override@JsonKey() final  String qbittorrentUrl;
@override@JsonKey() final  String qbittorrentUser;
@override@JsonKey() final  String qbittorrentPass;
@override@JsonKey() final  bool trustSelfSigned;
@override@JsonKey() final  String themeMode;
@override@JsonKey() final  bool railCollapsed;
@override@JsonKey() final  String sshTargets;
@override@JsonKey() final  String sshUsername;
@override@JsonKey() final  double electricityRateUsdPerKwh;
@override@JsonKey() final  String webLoginsJson;
@override@JsonKey() final  bool webAutoLogin;
@override@JsonKey() final  bool notifyAlerts;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.proxmoxUrl, proxmoxUrl) || other.proxmoxUrl == proxmoxUrl)&&(identical(other.proxmoxTokenId, proxmoxTokenId) || other.proxmoxTokenId == proxmoxTokenId)&&(identical(other.proxmoxTokenSecret, proxmoxTokenSecret) || other.proxmoxTokenSecret == proxmoxTokenSecret)&&(identical(other.dockerUrl, dockerUrl) || other.dockerUrl == dockerUrl)&&(identical(other.dockerTlsVerify, dockerTlsVerify) || other.dockerTlsVerify == dockerTlsVerify)&&(identical(other.grafanaUrl, grafanaUrl) || other.grafanaUrl == grafanaUrl)&&(identical(other.grafanaApiKey, grafanaApiKey) || other.grafanaApiKey == grafanaApiKey)&&(identical(other.prometheusUrl, prometheusUrl) || other.prometheusUrl == prometheusUrl)&&(identical(other.hermesUrl, hermesUrl) || other.hermesUrl == hermesUrl)&&(identical(other.wikiUrl, wikiUrl) || other.wikiUrl == wikiUrl)&&(identical(other.ollamaUrl, ollamaUrl) || other.ollamaUrl == ollamaUrl)&&(identical(other.ollamaApiUrl, ollamaApiUrl) || other.ollamaApiUrl == ollamaApiUrl)&&(identical(other.hermesApiUrl, hermesApiUrl) || other.hermesApiUrl == hermesApiUrl)&&(identical(other.hermesApiKey, hermesApiKey) || other.hermesApiKey == hermesApiKey)&&(identical(other.aiChatModel, aiChatModel) || other.aiChatModel == aiChatModel)&&(identical(other.askUrl, askUrl) || other.askUrl == askUrl)&&(identical(other.homeAssistantUrl, homeAssistantUrl) || other.homeAssistantUrl == homeAssistantUrl)&&(identical(other.searxngUrl, searxngUrl) || other.searxngUrl == searxngUrl)&&(identical(other.karakeepUrl, karakeepUrl) || other.karakeepUrl == karakeepUrl)&&(identical(other.paperlessUrl, paperlessUrl) || other.paperlessUrl == paperlessUrl)&&(identical(other.immichUrl, immichUrl) || other.immichUrl == immichUrl)&&(identical(other.changedetectionUrl, changedetectionUrl) || other.changedetectionUrl == changedetectionUrl)&&(identical(other.lokiUrl, lokiUrl) || other.lokiUrl == lokiUrl)&&(identical(other.pdmUrl, pdmUrl) || other.pdmUrl == pdmUrl)&&(identical(other.pdmTokenId, pdmTokenId) || other.pdmTokenId == pdmTokenId)&&(identical(other.pdmTokenSecret, pdmTokenSecret) || other.pdmTokenSecret == pdmTokenSecret)&&(identical(other.pdmFingerprint, pdmFingerprint) || other.pdmFingerprint == pdmFingerprint)&&(identical(other.jellyseerrUrl, jellyseerrUrl) || other.jellyseerrUrl == jellyseerrUrl)&&(identical(other.jellyfinUrl, jellyfinUrl) || other.jellyfinUrl == jellyfinUrl)&&(identical(other.jellyfinApiKey, jellyfinApiKey) || other.jellyfinApiKey == jellyfinApiKey)&&(identical(other.plexUrl, plexUrl) || other.plexUrl == plexUrl)&&(identical(other.plexToken, plexToken) || other.plexToken == plexToken)&&(identical(other.radarrUrl, radarrUrl) || other.radarrUrl == radarrUrl)&&(identical(other.radarrApiKey, radarrApiKey) || other.radarrApiKey == radarrApiKey)&&(identical(other.sonarrUrl, sonarrUrl) || other.sonarrUrl == sonarrUrl)&&(identical(other.sonarrApiKey, sonarrApiKey) || other.sonarrApiKey == sonarrApiKey)&&(identical(other.prowlarrUrl, prowlarrUrl) || other.prowlarrUrl == prowlarrUrl)&&(identical(other.prowlarrApiKey, prowlarrApiKey) || other.prowlarrApiKey == prowlarrApiKey)&&(identical(other.qbittorrentUrl, qbittorrentUrl) || other.qbittorrentUrl == qbittorrentUrl)&&(identical(other.qbittorrentUser, qbittorrentUser) || other.qbittorrentUser == qbittorrentUser)&&(identical(other.qbittorrentPass, qbittorrentPass) || other.qbittorrentPass == qbittorrentPass)&&(identical(other.trustSelfSigned, trustSelfSigned) || other.trustSelfSigned == trustSelfSigned)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.railCollapsed, railCollapsed) || other.railCollapsed == railCollapsed)&&(identical(other.sshTargets, sshTargets) || other.sshTargets == sshTargets)&&(identical(other.sshUsername, sshUsername) || other.sshUsername == sshUsername)&&(identical(other.electricityRateUsdPerKwh, electricityRateUsdPerKwh) || other.electricityRateUsdPerKwh == electricityRateUsdPerKwh)&&(identical(other.webLoginsJson, webLoginsJson) || other.webLoginsJson == webLoginsJson)&&(identical(other.webAutoLogin, webAutoLogin) || other.webAutoLogin == webAutoLogin)&&(identical(other.notifyAlerts, notifyAlerts) || other.notifyAlerts == notifyAlerts));
}


@override
int get hashCode => Object.hashAll([runtimeType,proxmoxUrl,proxmoxTokenId,proxmoxTokenSecret,dockerUrl,dockerTlsVerify,grafanaUrl,grafanaApiKey,prometheusUrl,hermesUrl,wikiUrl,ollamaUrl,ollamaApiUrl,hermesApiUrl,hermesApiKey,aiChatModel,askUrl,homeAssistantUrl,searxngUrl,karakeepUrl,paperlessUrl,immichUrl,changedetectionUrl,lokiUrl,pdmUrl,pdmTokenId,pdmTokenSecret,pdmFingerprint,jellyseerrUrl,jellyfinUrl,jellyfinApiKey,plexUrl,plexToken,radarrUrl,radarrApiKey,sonarrUrl,sonarrApiKey,prowlarrUrl,prowlarrApiKey,qbittorrentUrl,qbittorrentUser,qbittorrentPass,trustSelfSigned,themeMode,railCollapsed,sshTargets,sshUsername,electricityRateUsdPerKwh,webLoginsJson,webAutoLogin,notifyAlerts]);

@override
String toString() {
  return 'AppSettings(proxmoxUrl: $proxmoxUrl, proxmoxTokenId: $proxmoxTokenId, proxmoxTokenSecret: $proxmoxTokenSecret, dockerUrl: $dockerUrl, dockerTlsVerify: $dockerTlsVerify, grafanaUrl: $grafanaUrl, grafanaApiKey: $grafanaApiKey, prometheusUrl: $prometheusUrl, hermesUrl: $hermesUrl, wikiUrl: $wikiUrl, ollamaUrl: $ollamaUrl, ollamaApiUrl: $ollamaApiUrl, hermesApiUrl: $hermesApiUrl, hermesApiKey: $hermesApiKey, aiChatModel: $aiChatModel, askUrl: $askUrl, homeAssistantUrl: $homeAssistantUrl, searxngUrl: $searxngUrl, karakeepUrl: $karakeepUrl, paperlessUrl: $paperlessUrl, immichUrl: $immichUrl, changedetectionUrl: $changedetectionUrl, lokiUrl: $lokiUrl, pdmUrl: $pdmUrl, pdmTokenId: $pdmTokenId, pdmTokenSecret: $pdmTokenSecret, pdmFingerprint: $pdmFingerprint, jellyseerrUrl: $jellyseerrUrl, jellyfinUrl: $jellyfinUrl, jellyfinApiKey: $jellyfinApiKey, plexUrl: $plexUrl, plexToken: $plexToken, radarrUrl: $radarrUrl, radarrApiKey: $radarrApiKey, sonarrUrl: $sonarrUrl, sonarrApiKey: $sonarrApiKey, prowlarrUrl: $prowlarrUrl, prowlarrApiKey: $prowlarrApiKey, qbittorrentUrl: $qbittorrentUrl, qbittorrentUser: $qbittorrentUser, qbittorrentPass: $qbittorrentPass, trustSelfSigned: $trustSelfSigned, themeMode: $themeMode, railCollapsed: $railCollapsed, sshTargets: $sshTargets, sshUsername: $sshUsername, electricityRateUsdPerKwh: $electricityRateUsdPerKwh, webLoginsJson: $webLoginsJson, webAutoLogin: $webAutoLogin, notifyAlerts: $notifyAlerts)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 String proxmoxUrl, String proxmoxTokenId, String proxmoxTokenSecret, String dockerUrl, bool dockerTlsVerify, String grafanaUrl, String grafanaApiKey, String prometheusUrl, String hermesUrl, String wikiUrl, String ollamaUrl, String ollamaApiUrl, String hermesApiUrl, String hermesApiKey, String aiChatModel, String askUrl, String homeAssistantUrl, String searxngUrl, String karakeepUrl, String paperlessUrl, String immichUrl, String changedetectionUrl, String lokiUrl, String pdmUrl, String pdmTokenId, String pdmTokenSecret, String pdmFingerprint, String jellyseerrUrl, String jellyfinUrl, String jellyfinApiKey, String plexUrl, String plexToken, String radarrUrl, String radarrApiKey, String sonarrUrl, String sonarrApiKey, String prowlarrUrl, String prowlarrApiKey, String qbittorrentUrl, String qbittorrentUser, String qbittorrentPass, bool trustSelfSigned, String themeMode, bool railCollapsed, String sshTargets, String sshUsername, double electricityRateUsdPerKwh, String webLoginsJson, bool webAutoLogin, bool notifyAlerts
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? proxmoxUrl = null,Object? proxmoxTokenId = null,Object? proxmoxTokenSecret = null,Object? dockerUrl = null,Object? dockerTlsVerify = null,Object? grafanaUrl = null,Object? grafanaApiKey = null,Object? prometheusUrl = null,Object? hermesUrl = null,Object? wikiUrl = null,Object? ollamaUrl = null,Object? ollamaApiUrl = null,Object? hermesApiUrl = null,Object? hermesApiKey = null,Object? aiChatModel = null,Object? askUrl = null,Object? homeAssistantUrl = null,Object? searxngUrl = null,Object? karakeepUrl = null,Object? paperlessUrl = null,Object? immichUrl = null,Object? changedetectionUrl = null,Object? lokiUrl = null,Object? pdmUrl = null,Object? pdmTokenId = null,Object? pdmTokenSecret = null,Object? pdmFingerprint = null,Object? jellyseerrUrl = null,Object? jellyfinUrl = null,Object? jellyfinApiKey = null,Object? plexUrl = null,Object? plexToken = null,Object? radarrUrl = null,Object? radarrApiKey = null,Object? sonarrUrl = null,Object? sonarrApiKey = null,Object? prowlarrUrl = null,Object? prowlarrApiKey = null,Object? qbittorrentUrl = null,Object? qbittorrentUser = null,Object? qbittorrentPass = null,Object? trustSelfSigned = null,Object? themeMode = null,Object? railCollapsed = null,Object? sshTargets = null,Object? sshUsername = null,Object? electricityRateUsdPerKwh = null,Object? webLoginsJson = null,Object? webAutoLogin = null,Object? notifyAlerts = null,}) {
  return _then(_AppSettings(
proxmoxUrl: null == proxmoxUrl ? _self.proxmoxUrl : proxmoxUrl // ignore: cast_nullable_to_non_nullable
as String,proxmoxTokenId: null == proxmoxTokenId ? _self.proxmoxTokenId : proxmoxTokenId // ignore: cast_nullable_to_non_nullable
as String,proxmoxTokenSecret: null == proxmoxTokenSecret ? _self.proxmoxTokenSecret : proxmoxTokenSecret // ignore: cast_nullable_to_non_nullable
as String,dockerUrl: null == dockerUrl ? _self.dockerUrl : dockerUrl // ignore: cast_nullable_to_non_nullable
as String,dockerTlsVerify: null == dockerTlsVerify ? _self.dockerTlsVerify : dockerTlsVerify // ignore: cast_nullable_to_non_nullable
as bool,grafanaUrl: null == grafanaUrl ? _self.grafanaUrl : grafanaUrl // ignore: cast_nullable_to_non_nullable
as String,grafanaApiKey: null == grafanaApiKey ? _self.grafanaApiKey : grafanaApiKey // ignore: cast_nullable_to_non_nullable
as String,prometheusUrl: null == prometheusUrl ? _self.prometheusUrl : prometheusUrl // ignore: cast_nullable_to_non_nullable
as String,hermesUrl: null == hermesUrl ? _self.hermesUrl : hermesUrl // ignore: cast_nullable_to_non_nullable
as String,wikiUrl: null == wikiUrl ? _self.wikiUrl : wikiUrl // ignore: cast_nullable_to_non_nullable
as String,ollamaUrl: null == ollamaUrl ? _self.ollamaUrl : ollamaUrl // ignore: cast_nullable_to_non_nullable
as String,ollamaApiUrl: null == ollamaApiUrl ? _self.ollamaApiUrl : ollamaApiUrl // ignore: cast_nullable_to_non_nullable
as String,hermesApiUrl: null == hermesApiUrl ? _self.hermesApiUrl : hermesApiUrl // ignore: cast_nullable_to_non_nullable
as String,hermesApiKey: null == hermesApiKey ? _self.hermesApiKey : hermesApiKey // ignore: cast_nullable_to_non_nullable
as String,aiChatModel: null == aiChatModel ? _self.aiChatModel : aiChatModel // ignore: cast_nullable_to_non_nullable
as String,askUrl: null == askUrl ? _self.askUrl : askUrl // ignore: cast_nullable_to_non_nullable
as String,homeAssistantUrl: null == homeAssistantUrl ? _self.homeAssistantUrl : homeAssistantUrl // ignore: cast_nullable_to_non_nullable
as String,searxngUrl: null == searxngUrl ? _self.searxngUrl : searxngUrl // ignore: cast_nullable_to_non_nullable
as String,karakeepUrl: null == karakeepUrl ? _self.karakeepUrl : karakeepUrl // ignore: cast_nullable_to_non_nullable
as String,paperlessUrl: null == paperlessUrl ? _self.paperlessUrl : paperlessUrl // ignore: cast_nullable_to_non_nullable
as String,immichUrl: null == immichUrl ? _self.immichUrl : immichUrl // ignore: cast_nullable_to_non_nullable
as String,changedetectionUrl: null == changedetectionUrl ? _self.changedetectionUrl : changedetectionUrl // ignore: cast_nullable_to_non_nullable
as String,lokiUrl: null == lokiUrl ? _self.lokiUrl : lokiUrl // ignore: cast_nullable_to_non_nullable
as String,pdmUrl: null == pdmUrl ? _self.pdmUrl : pdmUrl // ignore: cast_nullable_to_non_nullable
as String,pdmTokenId: null == pdmTokenId ? _self.pdmTokenId : pdmTokenId // ignore: cast_nullable_to_non_nullable
as String,pdmTokenSecret: null == pdmTokenSecret ? _self.pdmTokenSecret : pdmTokenSecret // ignore: cast_nullable_to_non_nullable
as String,pdmFingerprint: null == pdmFingerprint ? _self.pdmFingerprint : pdmFingerprint // ignore: cast_nullable_to_non_nullable
as String,jellyseerrUrl: null == jellyseerrUrl ? _self.jellyseerrUrl : jellyseerrUrl // ignore: cast_nullable_to_non_nullable
as String,jellyfinUrl: null == jellyfinUrl ? _self.jellyfinUrl : jellyfinUrl // ignore: cast_nullable_to_non_nullable
as String,jellyfinApiKey: null == jellyfinApiKey ? _self.jellyfinApiKey : jellyfinApiKey // ignore: cast_nullable_to_non_nullable
as String,plexUrl: null == plexUrl ? _self.plexUrl : plexUrl // ignore: cast_nullable_to_non_nullable
as String,plexToken: null == plexToken ? _self.plexToken : plexToken // ignore: cast_nullable_to_non_nullable
as String,radarrUrl: null == radarrUrl ? _self.radarrUrl : radarrUrl // ignore: cast_nullable_to_non_nullable
as String,radarrApiKey: null == radarrApiKey ? _self.radarrApiKey : radarrApiKey // ignore: cast_nullable_to_non_nullable
as String,sonarrUrl: null == sonarrUrl ? _self.sonarrUrl : sonarrUrl // ignore: cast_nullable_to_non_nullable
as String,sonarrApiKey: null == sonarrApiKey ? _self.sonarrApiKey : sonarrApiKey // ignore: cast_nullable_to_non_nullable
as String,prowlarrUrl: null == prowlarrUrl ? _self.prowlarrUrl : prowlarrUrl // ignore: cast_nullable_to_non_nullable
as String,prowlarrApiKey: null == prowlarrApiKey ? _self.prowlarrApiKey : prowlarrApiKey // ignore: cast_nullable_to_non_nullable
as String,qbittorrentUrl: null == qbittorrentUrl ? _self.qbittorrentUrl : qbittorrentUrl // ignore: cast_nullable_to_non_nullable
as String,qbittorrentUser: null == qbittorrentUser ? _self.qbittorrentUser : qbittorrentUser // ignore: cast_nullable_to_non_nullable
as String,qbittorrentPass: null == qbittorrentPass ? _self.qbittorrentPass : qbittorrentPass // ignore: cast_nullable_to_non_nullable
as String,trustSelfSigned: null == trustSelfSigned ? _self.trustSelfSigned : trustSelfSigned // ignore: cast_nullable_to_non_nullable
as bool,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,railCollapsed: null == railCollapsed ? _self.railCollapsed : railCollapsed // ignore: cast_nullable_to_non_nullable
as bool,sshTargets: null == sshTargets ? _self.sshTargets : sshTargets // ignore: cast_nullable_to_non_nullable
as String,sshUsername: null == sshUsername ? _self.sshUsername : sshUsername // ignore: cast_nullable_to_non_nullable
as String,electricityRateUsdPerKwh: null == electricityRateUsdPerKwh ? _self.electricityRateUsdPerKwh : electricityRateUsdPerKwh // ignore: cast_nullable_to_non_nullable
as double,webLoginsJson: null == webLoginsJson ? _self.webLoginsJson : webLoginsJson // ignore: cast_nullable_to_non_nullable
as String,webAutoLogin: null == webAutoLogin ? _self.webAutoLogin : webAutoLogin // ignore: cast_nullable_to_non_nullable
as bool,notifyAlerts: null == notifyAlerts ? _self.notifyAlerts : notifyAlerts // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
