import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/employees/view/widgets/employee_status_dialog.dart';
import 'package:erp_sys/l10n/app_localizations.dart';

void main() {
  testWidgets('Status confirmation guards repeat requests and waits for save', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    bool? result;
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => EmployeeStatusDialog(
                    name: 'Employee',
                    inactive: false,
                    save: () {
                      calls++;
                      return pending.future;
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate employee'));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Saving...'), findsOneWidget);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
    pending.complete();
    await tester.pumpAndSettle();
    expect(result, true);
  });

  testWidgets('Failed status save keeps confirmation open for retry', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeStatusDialog(
            name: 'Employee',
            inactive: true,
            save: () async {
              calls++;
              throw Exception('offline');
            },
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Reactivate employee'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.textContaining('Could not change status.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reactivate employee'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}
