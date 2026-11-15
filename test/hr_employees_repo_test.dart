import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/employees/data/repos/hr_employees_repo.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'HR loads all company employees and all filter options across pages',
    () async {
      final offsets = <String>[];
      final client = await server((req) async {
        final q = req.uri.queryParameters;
        expect(q['tenant_id'], 'eq.tenant');
        if (req.uri.path == '/rest/v1/employees') {
          expect(q.containsKey('manager_id'), isFalse);
          expect(q.containsKey('status'), isFalse);
          offsets.add(q['offset']!);
          if (q['offset'] == '0') {
            return List.generate(
              500,
              (i) => {
                'id': '$i',
                'tenant_id': 'tenant',
                'full_name': 'Member $i',
                'status': 'active',
              },
            );
          }
          return [
            {
              'id': '500',
              'tenant_id': 'tenant',
              'full_name': 'Inactive member',
              'status': 'inactive',
            },
          ];
        }
        if (req.uri.path == '/rest/v1/departments') {
          return [
            {'id': 'd', 'name': 'Department'},
          ];
        }
        if (req.uri.path == '/rest/v1/job_titles') {
          return [
            {'id': 'j', 'name': 'Job'},
          ];
        }
        fail('Unexpected query');
      }, role: 'hr');
      final data = await SupabaseHrEmployeesRepo(client).load();
      expect(data.employees.length, 501);
      expect(data.employees.last.status, 'inactive');
      expect(offsets, ['0', '500']);
      expect(data.departments['d'], 'Department');
      expect(data.jobTitles['j'], 'Job');
    },
  );
  test('Non-HR cannot read the HR directory', () async {
    final client = await server(
      (_) async => fail('Unauthorized query'),
      role: 'manager',
    );
    await expectLater(SupabaseHrEmployeesRepo(client).load(), throwsStateError);
  });
}
