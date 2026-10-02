import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peira/core/theme/app_theme.dart';
import 'package:peira/core/widgets/ai_status_strip.dart';

void main() {
  testWidgets('AI status strip shows the Haiku primary chain', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // No network in widget tests — pin reachability to healthy.
          serviceReachableProvider.overrideWith((ref, url) async => true),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: AiStatusStrip(serviceName: 'Hermes', serviceUrl: 'http://x'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('claude-haiku-4-5'), findsOneWidget);
    expect(find.textContaining('runs Hermes'), findsOneWidget);
    expect(find.text('gpt-oss-120b'), findsOneWidget);
    expect(find.text('qwen2.5-coder:7b'), findsOneWidget);
    expect(find.text('nomic-embed-text'), findsOneWidget);
  });
}
