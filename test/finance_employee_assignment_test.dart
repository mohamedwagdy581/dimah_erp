import 'dart:convert';
import 'package:erp_sys/features/payroll/data/repos/payroll_repo_impl.dart';
import 'package:erp_sys/features/employees/domain/job_level.dart';
import 'package:flutter_test/flutter_test.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'Assignable staff come from the scoped RPC; senior is metadata',
    () async {
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/rpc/finance_payroll_assignees');
        return [
          {
            'id': 'employee',
            'full_name': 'Mahrous',
            'employee_number': 'EMP-0013',
            'job_level': 'senior',
          },
        ];
      }, role: 'finance_manager');
      final staff = await PayrollRepoImpl(client).fetchAssignableAccountants();
      expect(staff.single.employeeId, 'employee');
      expect(staff.single.jobLevel, 'senior');
      expect(jobLevelLabel(staff.single.jobLevel, isArabic: true), 'سينيور');
    },
  );
  test(
    'Assignment and retry use one atomic RPC with the selected employee',
    () async {
      final bodies = <Map>[];
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/rpc/finance_assign_payroll');
        bodies.add(jsonDecode(await utf8.decoder.bind(request).join()) as Map);
        return null;
      }, role: 'finance_manager');
      final repo = PayrollRepoImpl(client);
      await repo.assignDisbursementToAccountant(
        runId: 'run',
        accountantEmployeeId: 'employee',
      );
      await repo.assignDisbursementToAccountant(
        runId: 'run',
        accountantEmployeeId: 'employee',
      );
      expect(bodies, [
        {'p_run_id': 'run', 'p_employee_id': 'employee'},
        {'p_run_id': 'run', 'p_employee_id': 'employee'},
      ]);
    },
  );
  test('Rejected assignment never falls back to client table writes', () async {
    var calls = 0;
    final client = await server((request) async {
      calls++;
      expect(request.uri.path, '/rest/v1/rpc/finance_assign_payroll');
      request.response.statusCode = 403;
      return {
        'code': '42501',
        'message': 'Active employee/accountant in your team required',
      };
    }, role: 'finance_manager');
    await expectLater(
      PayrollRepoImpl(client).assignDisbursementToAccountant(
        runId: 'run',
        accountantEmployeeId: 'foreign',
      ),
      throwsA(isA<Exception>()),
    );
    expect(calls, 1);
  });
}
