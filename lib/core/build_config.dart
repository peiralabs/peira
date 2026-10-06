/// Compile-time build variant.
///
/// The default build is the public open-source **Peira** app. The personal
/// HomeLab build is compiled with
/// `flutter build ... --dart-define=PEIRA_PUBLIC=false`, which re-enables
/// features that depend on private backends no external user has: the
/// ask-homelab RAG service (Ask tab), the homelab-twin simulator (Metrics
/// What-if planner), and the `ai_*` Prometheus exporters (Metrics
/// AI-telemetry panel).
///
/// Because this is a `const`, the disabled branches are tree-shaken out of the
/// public build entirely.
const bool kPublicBuild = bool.fromEnvironment('PEIRA_PUBLIC', defaultValue: true);

/// User-facing application name. The public open-source build ships as
/// **Peira** (the Peira Labs product name); the personal build keeps its
/// **HomeLab** identity. Display string only — it does not affect the Linux
/// APPLICATION_ID, the Dart package name, or the keyring schema.
const String kAppName = kPublicBuild ? 'Peira' : 'HomeLab';
