import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/build_config.dart';
import 'package:peira/core/navigation/app_tab.dart';
import 'package:peira/screens/ai/ai_screen.dart';
import 'package:peira/screens/vault/vault_screen.dart';

void main() {
  // Since the 2026-08-07 hub restructure the rail is the same shape in both
  // builds (ten destinations since Home Assistant 2026-08-12, eleven since
  // the Library hub 2026-08-18, twelve since the Docker tab 2026-08-28);
  // personal-only gating lives at the sub-tab level (the Vault hub's Ask
  // sub-view).
  test('the rail is twelve destinations, identical in both builds', () {
    expect(AppTab.values.length, 12);
    for (final t in AppTab.values) {
      expect(t.railIndex, t.index, reason: t.name);
    }
  });

  test('vault hub label follows the build', () {
    expect(AppTab.vault.label, kPublicBuild ? 'Wiki' : 'Vault');
  });

  test('chat sub-tab is Hermes in the personal build, Chat in the public',
      () {
    expect(AiScreen.specs.first.label, kPublicBuild ? 'Chat' : 'Hermes');
  });

  test('Ask sub-view exists only in the personal build', () {
    expect(VaultScreen.specs.length, kPublicBuild ? 1 : 2);
    expect(VaultScreen.specs.any((s) => s.label == 'Ask'), !kPublicBuild);
  });
}
