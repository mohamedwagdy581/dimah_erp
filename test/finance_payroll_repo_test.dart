import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/payroll/data/repos/payroll_repo_impl.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'Final admin approval uses one RPC without client account lookup or writes',
    () async {
      final bodies = <Map>[];
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/rpc/admin_approve_payroll');
        expect(request.method, 'POST');
        bodies.add(jsonDecode(await utf8.decoder.bind(request).join()) as Map);
        return null;
      }, role: 'admin');
      final repo = PayrollRepoImpl(client);
      await repo.adminApprove(runId: 'run');
      await repo.adminApprove(runId: 'run');
      expect(bodies, [
        {'p_run_id': 'run'},
        {'p_run_id': 'run'},
      ]);
    },
  );
  test(
    'Failed final approval never falls back to creating a task or updating payroll',
    () async {
      var calls = 0;
      final client = await server((request) async {
        calls++;
        expect(request.uri.path, '/rest/v1/rpc/admin_approve_payroll');
        request.response.statusCode = 400;
        return {
          'code': 'P0001',
          'message': 'PAYROLL_FINANCE_REVIEWER_NOT_LINKED',
        };
      }, role: 'admin');
      await expectLater(
        PayrollRepoImpl(client).adminApprove(runId: 'run'),
        throwsA(isA<Exception>()),
      );
      expect(calls, 1);
    },
  );
  test(
    'HR submission and finalize use one atomic RPC, including retries',
    () async {
      final bodies = <Map>[];
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/rpc/hr_submit_payroll');
        bodies.add(jsonDecode(await utf8.decoder.bind(request).join()) as Map);
        return null;
      }, role: 'hr');
      final repo = PayrollRepoImpl(client);
      await repo.submitToFinanceManager(runId: 'run');
      await repo.finalizeRun(runId: 'run');
      expect(bodies, [
        {'p_run_id': 'run'},
        {'p_run_id': 'run'},
      ]);
    },
  );
  test(
    'Failed HR submission does not fall back to partial table writes',
    () async {
      var calls = 0;
      final client = await server((request) async {
        calls++;
        expect(request.uri.path, '/rest/v1/rpc/hr_submit_payroll');
        request.response.statusCode = 403;
        return {'code': '42501', 'message': 'Active HR/admin required'};
      }, role: 'hr');
      await expectLater(
        PayrollRepoImpl(client).submitToFinanceManager(runId: 'run'),
        throwsA(isA<Exception>()),
      );
      expect(calls, 1);
    },
  );
  test(
    'All salary items load beyond 500 with tenant scope and employee identifiers',
    () async {
      final offsets = <int>[];
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/payroll_items');
        expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
        expect(request.uri.queryParameters['run_id'], 'eq.run');
        expect(
          request.uri.queryParameters['select'],
          contains('employee_number'),
        );
        final offset = int.parse(request.uri.queryParameters['offset']!);
        offsets.add(offset);
        return List.generate(
          offset == 0 ? 500 : 1,
          (i) => {
            'id': '${offset + i}',
            'run_id': 'run',
            'employee_id': 'employee-${offset + i}',
            'employee': {
              'full_name': 'Employee ${offset + i}',
              'employee_number': 'EMP-${offset + i}',
            },
            'basic_salary': 10,
            'total_amount': 10,
          },
        );
      }, role: 'finance_manager');
      final items = await PayrollRepoImpl(client).fetchRunItems(runId: 'run');
      expect(items.length, 501);
      expect(items.last.employeeNumber, 'EMP-500');
      expect(offsets, [0, 500]);
    },
  );
  test(
    'Finance approval and rejection use a single atomic operation with notes',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final client = await server((HttpRequest request) async {
        expect(request.uri.path, '/rest/v1/rpc/finance_review_payroll');
        bodies.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        return null;
      }, role: 'finance_manager');
      final repo = PayrollRepoImpl(client);
      await repo.financeManagerApprove(runId: 'run', notes: ' Reviewed ');
      await repo.rejectRun(
        runId: 'run2',
        reason: ' Incorrect allowance ',
        rejectedByRole: 'finance_manager',
      );
      expect(bodies, [
        {'p_run_id': 'run', 'p_approve': true, 'p_notes': 'Reviewed'},
        {
          'p_run_id': 'run2',
          'p_approve': false,
          'p_notes': 'Incorrect allowance',
        },
      ]);
    },
  );
  test(
    'Stored finance notes are read only from tenant payroll approval payload',
    () async {
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/approval_requests');
        expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
        expect(request.uri.queryParameters['request_type'], 'eq.payroll_run');
        expect(request.uri.queryParameters['payload'], 'cs.{"run_id":"run"}');
        return [
          {
            'payload': {'run_id': 'run', 'finance_review_notes': 'Saved notes'},
          },
        ];
      }, role: 'finance_manager');
      expect(
        await PayrollRepoImpl(client).fetchFinanceReviewNotes(runId: 'run'),
        'Saved notes',
      );
    },
  );
}
