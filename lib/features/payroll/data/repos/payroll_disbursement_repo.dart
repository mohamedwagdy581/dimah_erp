import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/payroll_run.dart';
import '../../domain/models/payroll_assignee_option.dart';
import '../../domain/repos/payroll_repo.dart';

class PayrollDisbursementData {
  const PayrollDisbursementData({
    required this.run,
    this.accountants = const [],
    this.taskTitle,
    this.taskCreatedAt,
  });
  final PayrollRun run;
  final List<PayrollAssigneeOption> accountants;
  final String? taskTitle;
  final DateTime? taskCreatedAt;
}

abstract class PayrollDisbursementRepo {
  Future<PayrollDisbursementData> load(String runId);
  Future<void> assign(String runId, String employeeId);
}

class SupabasePayrollDisbursementRepo implements PayrollDisbursementRepo {
  SupabasePayrollDisbursementRepo(this.payroll, this.client);
  final PayrollRepo payroll;
  final SupabaseClient client;
  @override
  Future<PayrollDisbursementData> load(String runId) async {
    PayrollRun? run;
    for (var page = 0; run == null; page++) {
      final result = await payroll.fetchRuns(
        page: page,
        pageSize: 100,
        sortBy: 'created_at',
      );
      for (final item in result.items) {
        if (item.id == runId) run = item;
      }
      if (result.items.isEmpty || (page + 1) * 100 >= result.total) break;
    }
    if (run == null) throw StateError('Payroll not found');
    Map<String, dynamic>? task;
    if ((run.disbursementTaskId ?? '').isNotEmpty) {
      task = await client
          .from('employee_tasks')
          .select('title, created_at')
          .eq('id', run.disbursementTaskId!)
          .eq('tenant_id', run.tenantId)
          .maybeSingle();
    }
    final eligible =
        run.status == 'approved' &&
        [
          'not_started',
          'assigned_to_finance_manager',
        ].contains(run.disbursementStatus ?? 'not_started');
    return PayrollDisbursementData(
      run: run,
      accountants: eligible
          ? await payroll.fetchAssignableAccountants()
          : const [],
      taskTitle: task?['title']?.toString(),
      taskCreatedAt: DateTime.tryParse(task?['created_at']?.toString() ?? ''),
    );
  }

  @override
  Future<void> assign(String runId, String employeeId) =>
      payroll.assignDisbursementToAccountant(
        runId: runId,
        accountantEmployeeId: employeeId,
      );
}
