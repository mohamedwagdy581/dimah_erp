import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/approvals/data/repos/approvals_repo_impl.dart';
import 'package:erp_sys/features/manager_requests/data/manager_requests_repo.dart';
import 'employee_attendance_repo_test.dart' show server;
import 'manager_requests_test.dart' show request;

void main() {
  test(
    'Missing payload attachment is restored only from the matching tenant and employee leave',
    () {
      final row = {
        ...request('r', 'leave'),
        'payload': {'leave_id': 'l', 'file_url': '  '},
      };
      final leaf = {
        'id': 'l',
        'tenant_id': 'tenant',
        'employee_id': 'e1',
        'file_url': 'https://example.test/medical.pdf',
      };
      expect(
        (mergeManagerLeaveAttachments([row], [leaf]).single['payload']
            as Map)['file_url'],
        leaf['file_url'],
      );
      expect(
        mergeManagerLeaveAttachments(
          [row],
          [
            {...leaf, 'employee_id': 'another'},
          ],
        ).single['attachment_unavailable'],
        true,
      );
      expect(
        mergeManagerLeaveAttachments(
          [row],
          [
            {...leaf, 'tenant_id': 'another'},
          ],
        ).single['attachment_unavailable'],
        true,
      );
      final existing = {
        ...row,
        'payload': {
          'leave_id': 'l',
          'file_url': 'https://example.test/current.pdf',
        },
      };
      expect(
        (mergeManagerLeaveAttachments([existing], [leaf]).single['payload']
            as Map)['file_url'],
        'https://example.test/current.pdf',
      );
    },
  );
  test('Non-manager sessions cannot read team requests', () async {
    final client = await server((_) async => fail('Unexpected team query'));
    await expectLater(
      SupabaseManagerRequestsRepo(client, ApprovalsRepoImpl(client)).load(),
      throwsStateError,
    );
  });
  for (final invalid in ['foreign', 'hr', 'rejected']) {
    test('Decision rejects $invalid request without writes', () async {
      final client = await server((req) async {
        if (req.method != 'GET') fail('Unexpected write ${req.uri}');
        switch (req.uri.path) {
          case '/rest/v1/employees':
            return [
              {'id': 'e1'},
            ];
          case '/rest/v1/departments':
            return [];
          case '/rest/v1/approval_requests':
            return {
              ...request('r', 'attendance_correction'),
              if (invalid == 'foreign') 'employee_id': 'foreign',
              if (invalid == 'hr') 'current_approver_role': 'hr',
              if (invalid == 'rejected') 'status': 'rejected',
            };
          default:
            fail('Unexpected query ${req.uri}');
        }
      }, role: 'manager');
      await expectLater(
        ApprovalsRepoImpl(client).approve('r'),
        throwsStateError,
      );
      await expectLater(
        ApprovalsRepoImpl(client).reject('r', reason: 'reason'),
        invalid == 'hr' ? throwsException : throwsStateError,
      );
    });
  }
  test(
    'Repository reads only verified company/team requests including processed statuses',
    () async {
      final client = await server((req) async {
        final q = req.uri.queryParameters;
        expect(q['tenant_id'], 'eq.tenant');
        switch (req.uri.path) {
          case '/rest/v1/departments':
            return [];
          case '/rest/v1/employees':
            if (q['select'] == 'id,job_title_id') {
              return [
                {'id': 'e1', 'job_title_id': 'job'},
              ];
            }
            return [
              {'id': 'e1', 'full_name': 'Real name'},
            ];
          case '/rest/v1/job_titles':
            return [
              {'id': 'job', 'name': 'Real job'},
            ];
          case '/rest/v1/employee_tasks':
            return [];
          case '/rest/v1/approval_requests':
            expect(q['employee_id']?.replaceAll('"', ''), 'in.(e1)');
            if (q['select'] == 'id') return [];
            expect(q.containsKey('status'), false);
            final row = request('r', 'leave', status: 'approved');
            return [
              {
                ...row,
                'payload': {
                  ...(row['payload'] as Map),
                  'leave_id': 'l1',
                  'file_url': null,
                },
              },
            ];
          case '/rest/v1/leave_requests':
            expect(q['employee_id']?.replaceAll('"', ''), 'in.(e1)');
            expect(q['id']?.replaceAll('"', ''), 'in.(l1)');
            return [
              {
                'id': 'l1',
                'tenant_id': 'tenant',
                'employee_id': 'e1',
                'file_url': 'https://example.test/medical.pdf',
              },
            ];
          default:
            fail('Unexpected request ${req.uri}');
        }
      }, role: 'manager');
      final data = await SupabaseManagerRequestsRepo(
        client,
        ApprovalsRepoImpl(client),
      ).load();
      expect(data.rows.single['job_title'], 'Real job');
      expect((data.rows.single['employee'] as Map)['full_name'], 'Real name');
      expect(data.rows.single['status'], 'approved');
      expect(
        (data.rows.single['payload'] as Map)['file_url'],
        'https://example.test/medical.pdf',
      );
      await expectLater(
        SupabaseManagerRequestsRepo(
          client,
          ApprovalsRepoImpl(client),
        ).decide('r', true, ''),
        throwsStateError,
      );
    },
  );
  test('Empty team does not issue an unscoped request query', () async {
    final client = await server((req) async {
      expect([
        '/rest/v1/departments',
        '/rest/v1/employees',
      ], contains(req.uri.path));
      return [];
    }, role: 'manager');
    expect(
      (await SupabaseManagerRequestsRepo(
        client,
        ApprovalsRepoImpl(client),
      ).load()).rows,
      isEmpty,
    );
  });
  test(
    'Direct-manager approval uses manager stage and does not grant final approval',
    () async {
      Map? update;
      final client = await server((req) async {
        switch (req.uri.path) {
          case '/rest/v1/departments':
            return [];
          case '/rest/v1/employees':
            return [
              {'id': 'e1'},
            ];
          case '/rest/v1/approval_requests':
            if (req.method == 'PATCH') {
              update = jsonDecode(await utf8.decoder.bind(req).join()) as Map;
              return [];
            }
            return {
              ...request('r', 'attendance_correction'),
              'payload': {
                'record_id': 'record',
                'proposed_check_in': '2026-10-05T07:00:00Z',
              },
            };
          default:
            fail('Unexpected write ${req.uri}');
        }
      }, role: 'direct_manager');
      await ApprovalsRepoImpl(client).approve('r');
      expect(update?['current_approver_role'], 'hr');
      expect(update?['status'], 'pending');
      expect(update?['approved_by_manager_at'], isNotNull);
    },
  );
}
