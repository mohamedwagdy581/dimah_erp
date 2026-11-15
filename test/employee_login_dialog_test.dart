import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/employees/domain/models/employee_login_result.dart';
import 'package:erp_sys/features/employees/domain/repos/employee_repo.dart';
import 'package:erp_sys/features/employees/view/widgets/employee_profile/employee_login_dialog.dart';

class LoginRepo implements EmployeesRepo {
  int provisions = 0;
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<void> checkEmployeeCreationReady() async {}
  @override
  Future<EmployeeLoginResult> provisionEmployeeLogin({
    required String employeeId,
    required String role,
    required String initialPassword,
  }) async {
    provisions++;
    expect(employeeId, 'existing');
    expect(initialPassword, 'Only-test@2042');
    if (gate != null) await gate!.future;
    if (fail) throw StateError('Connection failed');
    return EmployeeLoginResult(
      employeeId: employeeId,
      email: 'employee@example.test',
      role: role,
      accountCreated: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(LoginRepo repo, ValueChanged<EmployeeLoginResult?> result) =>
    MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result(
                await showDialog<EmployeeLoginResult>(
                  context: context,
                  builder: (_) => EmployeeLoginDialog(
                    repo: repo,
                    employeeId: 'existing',
                    email: 'employee@example.test',
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    'Existing employee login at small width saves once and returns actual result',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 650));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = LoginRepo()..gate = Completer<void>();
      EmployeeLoginResult? result;
      await tester.pumpWidget(app(repo, (value) => result = value));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('employee-login-password')),
        'Only-test@2042',
      );
      final save = find.text('تجهيز الحساب');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(repo.provisions, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(result!.employeeId, 'existing');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Provision failure stays open and retries for the same existing employee',
    (tester) async {
      final repo = LoginRepo()..fail = true;
      EmployeeLoginResult? result;
      await tester.pumpWidget(app(repo, (value) => result = value));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('employee-login-password')),
        'Only-test@2042',
      );
      await tester.tap(find.text('تجهيز الحساب'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(EmployeeLoginDialog), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text('تجهيز الحساب'));
      await tester.pumpAndSettle();
      expect(result!.employeeId, 'existing');
      expect(repo.provisions, 2);
    },
  );
}
