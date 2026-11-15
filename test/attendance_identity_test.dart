import 'package:erp_sys/features/attendance/domain/repos/attendance_identity_repo.dart';
import 'package:erp_sys/features/employees/view/widgets/employee_attendance_identity_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements AttendanceIdentityRepo {
  @override
  Future<List<Map<String, String>>> fetchAll() async => [];
  bool failLoad = false;
  bool failSave = false;
  int saves = 0;
  String? number = '0002';
  @override
  Future<String?> fetch(String employeeId) async {
    if (failLoad) throw StateError('Load failed');
    return number;
  }

  @override
  Future<void> check(String number, {String? employeeId}) async {}
  @override
  Future<void> save(String employeeId, String value) async {
    saves++;
    if (failSave) throw StateError('Duplicate device number');
    number = normalizeAttendanceNumber(value);
  }
}

Future<void> _show(WidgetTester tester, _Repo repo) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => EmployeeAttendanceIdentityDialog(
                employeeId: 'employee',
                repo: repo,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  test('Device numbers preserve leading zeros and normalize Arabic digits', () {
    expect(normalizeAttendanceNumber(' ٠٠٢ '), '002');
    expect(normalizeAttendanceNumber('۰۰۲'), '002');
    expect(normalizeAttendanceNumber('AB_02-3'), 'AB_02-3');
    expect(isValidAttendanceNumber(''), true);
    expect(isValidAttendanceNumber('2 3'), false);
    expect(isValidAttendanceNumber('x' * 33), false);
    expect(isValidAttendanceNumber('2\n3'), false);
  });
  testWidgets('Failed load cannot overwrite an unknown existing mapping', (
    tester,
  ) async {
    final repo = _Repo()..failLoad = true;
    await _show(tester, repo);
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save link'),
    );
    expect(save.onPressed, isNull);
    expect(repo.saves, 0);
    expect(find.textContaining('Load failed'), findsOneWidget);
  });
  testWidgets('Existing number is loaded and duplicate error keeps edits', (
    tester,
  ) async {
    final repo = _Repo()..failSave = true;
    await _show(tester, repo);
    expect(find.text('0002'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '0014');
    await tester.tap(find.text('Save link'));
    await tester.pumpAndSettle();
    expect(find.text('0014'), findsOneWidget);
    expect(find.textContaining('Duplicate device number'), findsOneWidget);
    expect(find.byType(EmployeeAttendanceIdentityDialog), findsOneWidget);
    repo.failSave = false;
    await tester.tap(find.text('Save link'));
    await tester.pumpAndSettle();
    expect(repo.number, '0014');
    expect(find.byType(EmployeeAttendanceIdentityDialog), findsNothing);
  });
  testWidgets('Saving blank removes only the mapping through repository', (
    tester,
  ) async {
    final repo = _Repo();
    await _show(tester, repo);
    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.text('Save link'));
    await tester.pumpAndSettle();
    expect(repo.saves, 1);
    expect(repo.number, '');
  });
}
