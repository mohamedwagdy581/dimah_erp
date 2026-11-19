import 'dart:async';
import 'package:erp_sys/features/employees/domain/repos/employee_repo.dart';
import 'package:erp_sys/features/attendance/domain/repos/attendance_identity_repo.dart';
import 'package:erp_sys/features/employees/domain/models/employee_login_result.dart';
import 'package:erp_sys/features/employees/view/cubit/employee_wizard_cubit.dart';
import 'package:erp_sys/features/employees/view/sections/step_employee_account.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmployeesRepo implements EmployeesRepo {
  int creations = 0;
  int provisions = 0;
  bool failLink = false;
  bool failCreation = false;
  bool failReadiness = false;
  final requests = <String?>[];
  Map<Symbol, dynamic>? creationData;
  @override
  Future<void> checkEmployeeCreationReady() async {
    if (failReadiness) throw StateError('Provisioning service not installed');
  }

  Completer<String>? creationGate;
  String? lastRole;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createEmployee) {
      creations++;
      requests.add(invocation.namedArguments[#requestId] as String?);
      creationData = invocation.namedArguments;
      if (failCreation) {
        return Future<String>.error(StateError('Creation failed'));
      }
      return creationGate?.future ?? Future.value('saved-employee');
    }
    return super.noSuchMethod(invocation);
  }

  @override
  Future<EmployeeLoginResult> provisionEmployeeLogin({
    required String employeeId,
    required String role,
    required String initialPassword,
  }) async {
    provisions++;
    lastRole = role;
    if (failLink) throw StateError('Provision failed');
    return EmployeeLoginResult(
      employeeId: employeeId,
      email: 'new@example.test',
      role: role,
      accountCreated: true,
    );
  }
}

EmployeeWizardCubit _readyCubit(_EmployeesRepo repo) =>
    EmployeeWizardCubit(repo)
      ..setFullName('Test Employee')
      ..setEmail('new@example.test')
      ..setPhone('0500000000')
      ..setDepartmentId('department')
      ..setJobTitleId('job')
      ..setHireDate(DateTime(2026, 10, 4))
      ..setInitialPassword('Only-test@2042');

class _IdentityRepo implements AttendanceIdentityRepo {
  @override
  Future<List<Map<String, String>>> fetchAll() async => [];
  bool failCheck = false;
  bool failSave = false;
  int saves = 0;
  String? lastNumber;
  @override
  Future<String?> fetch(String employeeId) async => null;
  @override
  Future<void> check(String number, {String? employeeId}) async {
    if (failCheck) throw StateError('Device number in use');
  }

  @override
  Future<void> save(String employeeId, String number) async {
    saves++;
    lastNumber = number;
    if (failSave) throw StateError('Save failed');
  }
}

EmployeeWizardCubit _readyIdentityCubit(
  _EmployeesRepo repo,
  _IdentityRepo identities,
) => EmployeeWizardCubit(repo, attendanceIdentityRepo: identities)
  ..setFullName('Test Employee')
  ..setEmail('new@example.test')
  ..setPhone('0500000000')
  ..setDepartmentId('department')
  ..setJobTitleId('job')
  ..setHireDate(DateTime(2026, 10, 4))
  ..setInitialPassword('Only-test@2042');

void main() {
  test(
    'Missing login service prevents any employee or Auth creation',
    () async {
      final repo = _EmployeesRepo()..failReadiness = true;
      final cubit = _readyCubit(repo);
      await cubit.submit();
      expect(repo.creations, 0);
      expect(repo.provisions, 0);
      expect(cubit.state.success, false);
      await cubit.close();
    },
  );
  test(
    'Save retry uses the same request and retains every entered profile field',
    () async {
      final repo = _EmployeesRepo()..failCreation = true;
      final cubit = _readyCubit(repo)
        ..setNationality('Egyptian')
        ..setNationalId('1234567890')
        ..setGender('male')
        ..setDateOfBirth(DateTime(1990, 1, 2))
        ..setPassportNo('A123456')
        ..setPassportExpiry(DateTime(2030, 1, 2))
        ..setBankName('Bank')
        ..setIban('SA1234567890123456789012')
        ..setAccountNumber('12345')
        ..setContractStart(DateTime(2026, 10, 4))
        ..setContractEnd(DateTime(2027, 10, 3))
        ..setBasicSalary(6000)
        ..setHousingAllowance(1500)
        ..setTransportAllowance(500)
        ..setOtherAllowance(100)
        ..setCity('Jeddah')
        ..setCountry('Saudi Arabia')
        ..setAddress('Address')
        ..setEducationLevel('bachelor')
        ..setMajor('Accounting')
        ..setUniversity('University');
      await cubit.submit();
      repo.failCreation = false;
      await cubit.submit();
      expect(repo.requests[0], repo.requests[1]);
      expect(repo.requests[0], isNotNull);
      expect(repo.creationData, containsPair(#nationality, 'Egyptian'));
      expect(
        repo.creationData,
        containsPair(#iban, 'SA1234567890123456789012'),
      );
      expect(repo.creationData, containsPair(#passportNo, 'A123456'));
      expect(
        repo.creationData,
        containsPair(#passportExpiry, DateTime(2030, 1, 2)),
      );
      expect(repo.creationData, containsPair(#jobTitleId, 'job'));
      expect(
        repo.creationData,
        containsPair(#contractEnd, DateTime(2027, 10, 3)),
      );
      expect(repo.creationData, containsPair(#major, 'Accounting'));
      expect(cubit.state.success, true);
      await cubit.close();
    },
  );
  test(
    'Device conflict prevents employee creation and account provisioning',
    () async {
      final repo = _EmployeesRepo();
      final identities = _IdentityRepo()..failCheck = true;
      final cubit = _readyIdentityCubit(repo, identities)
        ..setAttendanceNumber('02');
      await cubit.submit();
      expect(repo.creations, 0);
      expect(repo.provisions, 0);
      expect(cubit.state.success, false);
      await cubit.close();
    },
  );
  test(
    'Device save retry keeps employee and allows correcting device number',
    () async {
      final repo = _EmployeesRepo();
      final identities = _IdentityRepo()..failSave = true;
      final cubit = _readyIdentityCubit(repo, identities)
        ..setAttendanceNumber('02');
      await cubit.submit();
      expect(cubit.state.savedEmployeeId, 'saved-employee');
      expect(repo.provisions, 0);
      cubit.setAttendanceNumber('٠٠٣');
      identities.failSave = false;
      await cubit.submit();
      expect(repo.creations, 1);
      expect(identities.lastNumber, '003');
      expect(cubit.state.success, true);
      await cubit.close();
    },
  );
  test('Login retry does not rewrite saved attendance identity', () async {
    final repo = _EmployeesRepo()..failLink = true;
    final identities = _IdentityRepo();
    final cubit = _readyIdentityCubit(repo, identities)
      ..setAttendanceNumber('02');
    await cubit.submit();
    cubit.setAttendanceNumber('04');
    expect(cubit.state.attendanceNumber, '02');
    repo.failLink = false;
    await cubit.submit();
    expect(identities.saves, 1);
    expect(repo.creations, 1);
    expect(cubit.state.success, true);
    await cubit.close();
  });
  test('Employee is saved and login is provisioned before success', () async {
    final repo = _EmployeesRepo();
    final cubit = _readyCubit(repo);
    await cubit.submit();
    expect(repo.creations, 1);
    expect(repo.provisions, 1);
    expect(cubit.state.success, true);
    expect(cubit.state.loginResult!.role, 'employee');
    expect(cubit.state.toString(), isNot(contains('Only-test@2042')));
    await cubit.close();
  });
  test('Provisioning retry never creates a second employee', () async {
    final repo = _EmployeesRepo()..failLink = true;
    final cubit = _readyCubit(repo);
    await cubit.submit();
    expect(cubit.state.success, false);
    expect(cubit.state.savedEmployeeId, 'saved-employee');
    repo.failLink = false;
    await cubit.submit();
    expect(repo.creations, 1);
    expect(repo.provisions, 2);
    expect(cubit.state.success, true);
    await cubit.close();
  });
  test('Repeated clicks cannot create concurrent employees', () async {
    final repo = _EmployeesRepo()..creationGate = Completer<String>();
    final cubit = _readyCubit(repo);
    final first = cubit.submit();
    await cubit.submit();
    expect(repo.creations, 1);
    repo.creationGate!.complete('saved-employee');
    await first;
    await cubit.submit();
    expect(repo.provisions, 1);
    await cubit.close();
  });
  test(
    'Manager role is explicit and privileged roles cannot be selected',
    () async {
      final repo = _EmployeesRepo();
      final cubit = _readyCubit(repo)..setLoginRole('admin');
      expect(cubit.state.loginRole, 'employee');
      cubit.setLoginRole('manager');
      await cubit.submit();
      expect(repo.lastRole, 'manager');
      await cubit.close();
    },
  );
  test('Invalid password saves neither employee nor account', () async {
    final repo = _EmployeesRepo();
    final cubit = _readyCubit(repo)..setInitialPassword('weak');
    await cubit.submit();
    expect(repo.creations, 0);
    expect(repo.provisions, 0);
    await cubit.close();
  });
  test('Failed employee creation never provisions an Auth account', () async {
    final repo = _EmployeesRepo()..failCreation = true;
    final cubit = _readyCubit(repo);
    await cubit.submit();
    expect(repo.provisions, 0);
    expect(cubit.state.savedEmployeeId, isNull);
    await cubit.close();
  });
  testWidgets('HR can select manager role and validate a new password', (
    tester,
  ) async {
    final cubit = _readyCubit(_EmployeesRepo());
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocProvider.value(
              value: cubit,
              child: const StepEmployeeAccount(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Direct manager').last);
    await tester.pumpAndSettle();
    expect(cubit.state.loginRole, 'manager');
    await tester.enterText(
      find.byKey(const ValueKey('employee-login-password')),
      'weak',
    );
    StepEmployeeAccount.formKey.currentState!.validate();
    await tester.pump();
    expect(find.textContaining('At least 12'), findsOneWidget);
  });
}
