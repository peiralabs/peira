import 'package:dio/dio.dart';

/// GitHub repository the public build checks for releases. The pre-push
/// rename pass owns this value; the personal build never calls the check.
const kReleaseRepo = 'peiralabs/homelab-app';

/// Version baked into this build. `test/update_check_test.dart` asserts it
/// matches pubspec.yaml, and the release workflow refuses a tag that doesn't
/// match pubspec — so all three move together or CI goes red.
const kAppVersion = '1.1.0';

/// Outcome of an update check. Check-only by design: an AppImage cannot
/// replace itself in place, so "update" means pointing the operator at the
/// releases page — never downloading anything, and no telemetry beyond the
/// single releases-API GET the operator explicitly asked for.
sealed class UpdateCheckResult {
  const UpdateCheckResult();
}

class UpdateAvailable extends UpdateCheckResult {
  const UpdateAvailable(this.latestTag);
  final String latestTag;
}

class UpToDate extends UpdateCheckResult {
  const UpToDate(this.latestTag);
  final String latestTag;
}

class UpdateCheckFailed extends UpdateCheckResult {
  const UpdateCheckFailed(this.message);
  final String message;
}

/// True when [candidate] (a `vX.Y.Z` tag or bare version) is numerically
/// newer than [current]. Pre-release/build suffixes are ignored — releases
/// are tagged as plain semver.
bool isNewerVersion(String candidate, String current) {
  List<int> parse(String v) => v
      .replaceFirst(RegExp('^v'), '')
      .split(RegExp('[-+]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final a = parse(candidate);
  final b = parse(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// Asks the GitHub Releases API for the latest release tag and compares it
/// with [kAppVersion]. [dio] is injectable for tests.
Future<UpdateCheckResult> checkForUpdate({Dio? dio}) async {
  final d = dio ??
      Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
  try {
    final r = await d.get<Map<String, dynamic>>(
      'https://api.github.com/repos/$kReleaseRepo/releases/latest',
      options: Options(headers: {'Accept': 'application/vnd.github+json'}),
    );
    final tag = (r.data?['tag_name'] as String?)?.trim() ?? '';
    if (tag.isEmpty) return const UpdateCheckFailed('No releases found.');
    return isNewerVersion(tag, kAppVersion)
        ? UpdateAvailable(tag)
        : UpToDate(tag);
  } on DioException {
    return const UpdateCheckFailed(
      'Could not reach the releases API — check your connection.',
    );
  }
}
