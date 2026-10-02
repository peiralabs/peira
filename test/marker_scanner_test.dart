import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The public-marker scanner gates the public repo; a gate nobody tests passes
// everything, so its self-test (positive AND negative fixtures, plus the
// binary attestation checks) runs as part of the ordinary test suite.
void main() {
  test('public-marker scanner self-test passes', () async {
    final result = await Process.run(
        'dart', ['tool/check_public_markers.dart', '--self-test']);
    expect(result.exitCode, 0,
        reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
  });
}
