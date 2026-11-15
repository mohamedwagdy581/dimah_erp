import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/employees/data/repos/employee_status_repo.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'Status changes use the scoped RPC and accept only active/inactive',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final client = await server((req) async {
        expect(req.uri.path, '/rest/v1/rpc/hr_set_employee_status');
        expect(req.method, 'POST');
        bodies.add(
          jsonDecode(await utf8.decoder.bind(req).join())
              as Map<String, dynamic>,
        );
        return null;
      });
      final repo = EmployeeStatusRepo(client);
      await repo.setStatus('employee-id', 'inactive');
      await repo.setStatus('employee-id', 'active');
      await expectLater(
        repo.setStatus('employee-id', 'deleted'),
        throwsArgumentError,
      );
      expect(bodies, [
        {'p_employee_id': 'employee-id', 'p_status': 'inactive'},
        {'p_employee_id': 'employee-id', 'p_status': 'active'},
      ]);
    },
  );
}
