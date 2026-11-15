import 'dart:async';

import 'package:erp_sys/core/auth/auth_notifier.dart';
import 'package:erp_sys/features/employees/data/repos/employee_login_link.dart';
import 'package:erp_sys/features/auth/domain/repos/auth_repo.dart';
import 'package:erp_sys/features/profile/view/change_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _AuthRepo implements AuthRepo {
  String? changedPassword;
  @override
  Future<void> changePassword(String newPassword) async {
    changedPassword = newPassword;
  }

  @override
  bool get isSignedIn => true;
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}
  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('Both password fields can be revealed independently', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ChangePasswordPage())));
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password').first);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText, isFalse);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText, isFalse);
    await tester.tap(find.byTooltip('Hide password').first);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText, isTrue);
  });
  for (final password in ['كلمةمرورعربية١٢٣@', 'Short@1', 'onlylowercase123@', 'StrongPassword123', ' Test-only@2041 ']) {
    testWidgets('Invalid password cannot reach Auth: $password', (tester) async {
      final repo = _AuthRepo();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChangePasswordPage(authRepo: repo))));
      await tester.enterText(find.byType(TextField).at(0), password);
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.ensureVisible(find.text('Update'));
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(repo.changedPassword, isNull);
      expect(tester.widget<TextField>(find.byType(TextField).first).decoration!.errorText, isNotNull);
      expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, password);
    });
  }
  testWidgets('Mismatch blocks saving without modifying the entered password', (tester) async {
    final repo = _AuthRepo();
    tester.view.physicalSize = const Size(320, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChangePasswordPage(authRepo: repo))));
    await tester.enterText(find.byType(TextField).at(0), 'Test-only@2041');
    await tester.enterText(find.byType(TextField).at(1), 'Test-only@2042');
    await tester.ensureVisible(find.text('Update'));
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(repo.changedPassword, isNull);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final response in <Object>[
    'employee-id',
    {'employee_id': 'employee-id'},
  ]) {
    test(
      'RPC response $response links the saved employee before returning',
      () async {
        final linked = <String>[];
        final id = await linkCreatedEmployee(
          rpcResponse: response,
          linkLogin: (id) async => linked.add(id),
        );
        expect(id, 'employee-id');
        expect(linked, ['employee-id']);
      },
    );
  }
  test(
    'Login failure retains the saved ID and cannot be mistaken for creation failure',
    () async {
      final cause = StateError('Link rejected');
      await expectLater(
        linkCreatedEmployee(
          rpcResponse: 'saved-employee',
          linkLogin: (_) async => throw cause,
        ),
        throwsA(
          isA<EmployeeLoginLinkException>()
              .having((e) => e.employeeId, 'employeeId', 'saved-employee')
              .having((e) => e.cause, 'cause', same(cause)),
        ),
      );
    },
  );
  test('Invalid creation response never provisions a login', () async {
    var attempted = false;
    await expectLater(
      linkCreatedEmployee(
        rpcResponse: {},
        linkLogin: (_) async {
          attempted = true;
        },
      ),
      throwsFormatException,
    );
    expect(attempted, isFalse);
  });
  test('Recovery event and sign-out update recovery mode', () async {
    final stream = StreamController<AuthState>(sync: true);
    final notifier = AuthNotifier(
      authChanges: stream.stream,
      sessionExists: () => true,
      initialUri: Uri.parse('https://example.test/'),
    );
    expect(notifier.isPasswordRecovery, isFalse);
    stream.add(AuthState(AuthChangeEvent.passwordRecovery, null));
    expect(notifier.isPasswordRecovery, isTrue);
    stream.add(AuthState(AuthChangeEvent.signedOut, null));
    expect(notifier.isPasswordRecovery, isFalse);
    notifier.dispose();
    await stream.close();
  });
  test(
    'Initial recovery callback is recognized even before the listener subscribes',
    () async {
      final stream = StreamController<AuthState>();
      final notifier = AuthNotifier(
        authChanges: stream.stream,
        sessionExists: () => true,
        initialUri: Uri.parse(
          'https://example.test/#type=recovery&access_token=test-token',
        ),
      );
      expect(notifier.isPasswordRecovery, isTrue);
      notifier.dispose();
      await stream.close();
    },
  );
  testWidgets('Password reset saves through Auth and completes recovery', (
    tester,
  ) async {
    final repo = _AuthRepo();
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangePasswordPage(
            authRepo: repo,
            onPasswordChanged: () async {
              completed = true;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'Test-only@2041');
    await tester.enterText(find.byType(TextField).at(1), 'Test-only@2041');
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(repo.changedPassword, 'Test-only@2041');
    expect(completed, isTrue);
    expect(
      (tester.widget<TextField>(find.byType(TextField).first)).controller!.text,
      isEmpty,
    );
  });
}
