// Demo mode boots the real app with lib/core/demo/demo.dart's overrides —
// the same ProviderScope wiring `--demo` uses — and must land on a fully
// populated dashboard with the banner, no wizard, and no real values.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/app.dart';
import 'package:peira/core/demo/demo.dart';

void main() {
  testWidgets('demo overrides land on a populated dashboard with the banner',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: demoOverrides,
      child: const HomeLabApp(),
    ));
    await tester.pumpAndSettle();

    // No first-run wizard: the demo settings read as configured.
    expect(find.text('Connect your Proxmox'), findsNothing);
    // The persistent banner is on screen.
    expect(
      find.textContaining('DEMO DATA'),
      findsOneWidget,
    );
    // Fake inventory rendered on the dashboard.
    expect(find.text('node1'), findsWidgets);
  });

  test('isDemoRequested triggers on the flag, not by default', () {
    expect(isDemoRequested(['--demo']), isTrue);
    expect(isDemoRequested([]), isFalse);
  });
}
