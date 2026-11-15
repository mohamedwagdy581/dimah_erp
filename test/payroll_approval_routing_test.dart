import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/approvals/data/repos/approvals_repo_impl.dart';
import 'package:erp_sys/features/payroll/domain/repos/payroll_repo.dart';
import 'employee_attendance_repo_test.dart' show server;

class PayrollDecisions implements PayrollRepo {
  final calls = <String>[];
  @override
  Future<void> financeManagerApprove({
    required String runId,
    String? notes,
  }) async => calls.add('finance:$runId');
  @override
  Future<void> adminApprove({required String runId}) async =>
      calls.add('admin:$runId');
  @override
  Future<void> rejectRun({
    required String runId,
    required String reason,
    required String rejectedByRole,
  }) async => calls.add('reject:$runId:$rejectedByRole:$reason');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final role in ['finance_manager', 'admin']) {
    for (final approve in [true, false]) {
      test(
        '$role payroll ${approve ? 'approval' : 'rejection'} delegates to payroll workflow',
        () async {
          final payroll = PayrollDecisions();
          final client = await server((request) async {
            expect(request.method, 'GET');
            expect(request.uri.path, '/rest/v1/approval_requests');
            expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
            return {
              'request_type': 'payroll_run',
              'status': 'pending',
              'current_approver_role': role,
              'payload': {'run_id': 'run'},
            };
          }, role: role);
          final repo = ApprovalsRepoImpl(client, payroll: payroll);
          if (approve) {
            await repo.approve('approval');
          } else {
            await repo.reject('approval', reason: ' Needs correction ');
          }
          expect(payroll.calls, [
            approve
                ? '${role == 'admin' ? 'admin' : 'finance'}:run'
                : 'reject:run:$role:Needs correction',
          ]);
        },
      );
    }
  }
  for (final scenario in [
    'other_role',
    'missing_run',
    'rejected',
    'missing_reason',
  ]) {
    test('Cannot reject payroll with $scenario', () async {
      final payroll = PayrollDecisions();
      final client = await server(
        (request) async => {
          'request_type': 'payroll_run',
          'status': scenario == 'rejected' ? 'rejected' : 'pending',
          'current_approver_role': scenario == 'other_role'
              ? 'admin'
              : 'finance_manager',
          'payload': scenario == 'missing_run' ? {} : {'run_id': 'run'},
        },
        role: 'finance_manager',
      );
      await expectLater(
        ApprovalsRepoImpl(client, payroll: payroll).reject(
          'approval',
          reason: scenario == 'missing_reason' ? ' ' : 'Fix totals',
        ),
        throwsA(anyOf(isA<StateError>(), isA<Exception>())),
      );
      expect(payroll.calls, isEmpty);
    });
  }
}
