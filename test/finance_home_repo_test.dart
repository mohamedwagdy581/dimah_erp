import 'package:erp_sys/features/finance_home/finance_home_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'Accountant reads tenant, assigned payroll and selected month; no team operation',
    () async {
      final client = await server((request) async {
        expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
        if (request.uri.path.endsWith('payroll_runs')) {
          expect(
            request.uri.queryParameters['disbursement_assignee_employee_id'],
            'eq.employee',
          );
        }
        if (request.uri.path.endsWith('journal_entries')) {
          expect(request.uri.query, contains('2026-10-01'));
          expect(request.uri.query, contains('2026-11-01'));
        }
        expect(request.uri.path.contains('/rpc/'), isFalse);
        return [];
      }, role: 'accountant');
      final data = await SupabaseFinanceHomeRepo(
        client,
      ).load(DateTime(2026, 10, 11));
      expect(data.runs.error, isNull);
      expect(data.journal.error, isNull);
      expect(data.team.value, isEmpty);
    },
  );
  test('Inactive and non-finance users never read dashboard tables', () async {
    for (final role in ['employee', 'finance_manager']) {
      final client = await server(
        (_) async {
          fail('Unauthorized read');
        },
        role: role,
        active: role != 'finance_manager',
      );
      await expectLater(
        SupabaseFinanceHomeRepo(client).load(DateTime(2026, 10)),
        throwsStateError,
      );
    }
  });
  test(
    'Team uses membership operation without accepting arbitrary manager id',
    () async {
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/rpc/finance_team_overview');
        return [];
      }, role: 'finance_manager');
      expect(await SupabaseFinanceHomeRepo(client).loadTeam(), isEmpty);
    },
  );
  test('Paging includes accounts beyond first server page', () async {
    var accountPages = 0;
    final client = await server((request) async {
      if (!request.uri.path.endsWith('accounts')) return [];
      accountPages++;
      if (accountPages == 1) {
        return List.generate(500, (i) => {'id': 'account-$i'});
      }
      return [
        {'id': 'account-500'},
      ];
    }, role: 'accountant');
    final data = await SupabaseFinanceHomeRepo(client).load(DateTime(2026, 10));
    expect(data.accounts.value!.length, 501);
    expect(accountPages, 2);
  });
}
