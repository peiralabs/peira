import 'package:freezed_annotation/freezed_annotation.dart';

part 'grafana_alert.freezed.dart';
part 'grafana_alert.g.dart';

/// One entry from Grafana's Alertmanager-compatible API
/// (GET /api/alertmanager/grafana/api/v2/alerts).
@freezed
abstract class GrafanaAlert with _$GrafanaAlert {
  const GrafanaAlert._();

  const factory GrafanaAlert({
    @Default(<String, String>{}) Map<String, String> labels,
    @Default(<String, String>{}) Map<String, String> annotations,
    required DateTime startsAt,
    String? fingerprint,
    Map<String, dynamic>? status,
    // Alertmanager's link to the source query/rule — the triage target.
    @JsonKey(name: 'generatorURL') @Default('') String generatorUrl,
  }) = _GrafanaAlert;

  factory GrafanaAlert.fromJson(Map<String, dynamic> json) =>
      _$GrafanaAlertFromJson(json);

  String get name => labels['alertname'] ?? 'unknown';

  /// critical / warning / info — defaults to info when unlabeled.
  String get severity => labels['severity'] ?? 'info';

  bool get isSuppressed => status?['state'] == 'suppressed';

  /// A runbook link (annotation) or the generator URL — where a human goes to
  /// triage this alert. Empty when neither is present.
  String get triageUrl {
    final runbook = annotations['runbook_url'] ?? annotations['runbook'] ?? '';
    return runbook.isNotEmpty ? runbook : generatorUrl;
  }
}
