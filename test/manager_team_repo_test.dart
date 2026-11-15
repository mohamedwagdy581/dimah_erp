import 'package:erp_sys/features/manager_team/data/manager_team_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'Repository scopes every query to company and verifies team IDs',
    () async {
      final client = await server((request) async {
        final query = request.uri.queryParameters;
        expect(query['tenant_id'], 'eq.tenant');
        expect(query['limit'], '500');
        expect(query['offset'], '0');
        switch (request.uri.path) {
          case '/rest/v1/departments':
            expect(query['manager_id'], 'eq.employee');
            return [
              {'id': 'department'},
            ];
          case '/rest/v1/employees':
            expect(query['status'], 'eq.active');
            if (query.containsKey('department_id')) {
              expect(
                query['department_id']?.replaceAll('"', ''),
                'in.(department)',
              );
              return [
                {'id': 'employee', 'full_name': 'Manager'},
                {'id': 'e1', 'full_name': 'Actual name'},
                {'id': 'e2', 'full_name': 'Other member'},
              ];
            }
            expect(query['manager_id'], 'eq.employee');
            return [
              {'id': 'e1', 'full_name': 'Actual name'},
            ];
          case '/rest/v1/employee_tasks':
            expect(query['select']!.split(','), contains('progress'));
            expect(query['employee_id']?.replaceAll('"', ''), 'in.(e1,e2)');
            return [
              {'id': 'task', 'employee_id': 'e1', 'status': 'done'},
              {
                'id': 'task-2',
                'employee_id': 'e2',
                'status': 'in_progress',
                'progress': 20,
              },
            ];
          case '/rest/v1/approval_requests':
            expect(query['employee_id']?.replaceAll('"', ''), 'in.(e1,e2)');
            expect(query['status'], 'eq.pending');
            expect(query['current_approver_role'], 'eq.manager');
            return [
              {'id': 'request'},
            ];
          default:
            fail('Unexpected query ${request.uri}');
        }
      }, role: 'manager');
      final data = await SupabaseManagerTeamRepo(client).load();
      expect(data.members.map((m) => m.id), ['e1', 'e2']);
      expect(data.pendingRequests, 1);
      expect(data.completion('e1'), 1);
      expect(data.tasks.last.progress, 20);
      expect(data.averageProgress('e2'), .2);
    },
  );
  test('Non-manager sessions cannot read team records', () async {
    final client = await server((request) async {
      fail('Unexpected team read');
    });
    await expectLater(SupabaseManagerTeamRepo(client).load(), throwsStateError);
  });
}
