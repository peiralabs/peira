import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/api/pbs_api.dart';
import 'package:peira/screens/pbs/pbs_actions.dart';

void main() {
  const snapshot = PbsSnapshot(
    type: 'vm',
    id: '204',
    time: 1787911200,
    size: 4096,
    protected: false,
    comment: '',
    owner: 'root@pam',
    verification: null,
    files: [],
    fingerprint: '',
    namespace: null,
  );

  test('pbsRestoreVolid formats the PBS archive timestamp as RFC3339 UTC', () {
    expect(
      pbsRestoreVolid('pbs-office', snapshot),
      'pbs-office:backup/vm/204/2026-08-28T10:00:00Z',
    );
  });

  test('pbsJobEditPayload separates changed and cleared optional fields', () {
    final payload = pbsJobEditPayload(
      const {
        'schedule': 'daily',
        'comment': 'old',
        'keep-last': 3,
        'disable': false,
      },
      const {
        'schedule': 'daily',
        'comment': '',
        'keep-last': '5',
        'disable': true,
      },
    );

    expect(payload.changes, {'keep-last': '5', 'disable': true});
    expect(payload.delete, ['comment']);
  });

  testWidgets('typed confirm enables Delete only on the exact text', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await pbsTypedConfirm(context, 'Delete?', 'ct/105'),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    FilledButton delete() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete'),
    );
    expect(delete().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'ct/10');
    await tester.pump();
    expect(delete().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'ct/105');
    await tester.pump();
    expect(delete().onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
