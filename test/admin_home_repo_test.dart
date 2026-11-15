import 'package:erp_sys/features/admin_home/admin_home_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'Active admin scopes each read and selected month; users use authorized service',
    () async {
      final client = await server((request) async {
        if (request.uri.path.endsWith('/rpc/list_company_users')) {
          return {'actor_id': 'auth-fixture', 'can_edit': true, 'users': []};
        }
        expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
        if (request.uri.path.endsWith('approval_requests')) {
          expect(request.uri.queryParameters['status'], 'eq.pending');
          expect(
            request.uri.queryParameters['current_approver_role'],
            'eq.admin',
          );
        }
        if (request.uri.path.endsWith('journal_entries')) {
          expect(request.uri.query, contains('2026-10-01'));
          expect(request.uri.query, contains('2026-11-01'));
        }
        return [];
      }, role: 'admin');
      final data = await SupabaseAdminHomeRepo(
        client,
      ).load(DateTime(2026, 10, 11));
      expect(data.users.error, isNull);
      expect(data.employees.error, isNull);
      expect(data.journal.error, isNull);
    },
  );
  test(
    'Inactive admin and other roles never read company dashboard tables',
    () async {
      for (final role in ['admin', 'hr', 'employee']) {
        final client = await server(
          (_) async {
            fail('Unauthorized read');
          },
          role: role,
          active: role != 'admin',
        );
        await expectLater(
          SupabaseAdminHomeRepo(client).load(DateTime(2026, 10)),
          throwsStateError,
        );
      }
    },
  );
  test(
    'User operation identity mismatch is a section failure with no direct fallback',
    () async {
      final client = await server((request) async {
        if (request.uri.path.endsWith('/rpc/list_company_users')) {
          return {'actor_id': 'other', 'can_edit': true, 'users': []};
        }
        return [];
      }, role: 'admin');
      final data = await SupabaseAdminHomeRepo(client).load(DateTime(2026, 10));
      expect(data.users.error, isStateError);
      expect(data.users.value, isNull);
      expect(data.employees.error, isNull);
    },
  );
  test('Employee counts include records beyond first page', () async {
    var pages = 0;
    final client = await server((request) async {
      if (request.uri.path.endsWith('/rpc/list_company_users')) {
        return {'actor_id': 'auth-fixture', 'can_edit': true, 'users': []};
      }
      if (!request.uri.path.endsWith('employees')) return [];
      pages++;
      if (pages == 1) {
        return List.generate(
          500,
          (i) => {'id': 'employee-$i', 'status': 'active'},
        );
      }
      return [
        {'id': 'employee-500', 'status': 'active'},
      ];
    }, role: 'admin');
    final data = await SupabaseAdminHomeRepo(client).load(DateTime(2026, 10));
    expect(data.activeEmployees, 501);
    expect(pages, 2);
  });
}
