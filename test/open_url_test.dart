import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/util/open_url.dart';

/// `openUrl` hands its argument to `xdg-open`. Some callers pass data that
/// originates off-device (alert triage URLs from Grafana/Prometheus
/// annotations), so anything that isn't an http(s) web URL must be refused
/// before it can reach the desktop's URL handler. These cases all return
/// before any process is spawned, so the test never launches a browser.
void main() {
  group('openUrl refuses non-web URLs', () {
    const refusal = 'Refusing to open a non-web URL.';

    for (final bad in const [
      'file:///etc/passwd',
      'javascript:alert(1)',
      'smb://attacker/share',
      'ftp://host/file',
      '-oProxyCommand=evil', // option-like, no scheme
      '10.0.0.5:8006/?console=1', // scheme-less → not http(s)
    ]) {
      test('refuses: $bad', () async {
        expect(await openUrl(bad), refusal);
      });
    }

    test('empty input keeps the distinct empty-URL message', () async {
      expect(await openUrl('   '), 'No URL to open.');
    });
  });
}
