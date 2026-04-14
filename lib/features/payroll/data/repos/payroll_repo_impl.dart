import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/payroll_assignee_option.dart';
import '../../domain/models/payroll_item.dart';
import '../../domain/models/payroll_run.dart';
import '../../domain/repos/payroll_repo.dart';

class PayrollRepoImpl implements PayrollRepo {
  PayrollRepoImpl(this._client);
  final SupabaseClient _client;

  Future<({String tenantId, String? employeeId, String role})> _actor() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final me = await _client
        .from('users')
        .select('tenant_id, employee_id, role')
        .eq('id', uid)
        .single();

    final tenantId = me['tenant_id']?.toString();
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Missing tenant_id for current user');
    }

    return (
      tenantId: tenantId,
      employeeId: me['employee_id']?.toString(),
      role: (me['role'] ?? 'employee').toString(),
    );
  }

  Future<String> _tenantId() async => (await _actor()).tenantId;

  String _toDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  String _rejectedStatusForRole(String role) {
    if (role == 'finance_manager') return 'rejected_by_finance_manager';
    if (role == 'admin') return 'rejected_by_admin';
    return 'rejected';
  }

  Future<String> _resolveRequesterEmployeeId({
    required String tenantId,
    required String role,
    String? preferredEmployeeId,
  }) async {
    if (preferredEmployeeId != null && preferredEmployeeId.isNotEmpty) {
      return preferredEmployeeId;
    }

    final rows = await _client
        .from('users')
        .select('employee_id')
        .eq('tenant_id', tenantId)
        .eq('role', role)
        .not('employee_id', 'is', null)
        .limit(1);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      throw Exception('No employee profile linked to role "$role" in this tenant');
    }

    final employeeId = list.first['employee_id']?.toString();
    if (employeeId == null || employeeId.isEmpty) {
      throw Exception('Role "$role" is missing employee mapping');
    }
    return employeeId;
  }

  Future<String> _resolveFinanceManagerEmployeeId({
    required String tenantId,
  }) async {
    final rows = await _client
        .from('users')
        .select('employee_id')
        .eq('tenant_id', tenantId)
        .eq('role', 'finance_manager')
        .not('employee_id', 'is', null)
        .limit(1);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      throw Exception('No finance manager account found');
    }
    final employeeId = list.first['employee_id']?.toString();
    if (employeeId == null || employeeId.isEmpty) {
      throw Exception('Finance manager is missing employee mapping');
    }
    return employeeId;
  }

  Future<String> _createFinanceDisbursementTask({
    required String tenantId,
    required String financeManagerEmployeeId,
    required PayrollRun run,
    required String? assignedByEmployeeId,
  }) async {
    final inserted = await _client
        .from('employee_tasks')
        .insert({
          'tenant_id': tenantId,
          'employee_id': financeManagerEmployeeId,
          'assigned_by_employee_id': assignedByEmployeeId,
          'title': 'Payroll Disbursement ${_toDateOnly(run.periodStart)} - ${_toDateOnly(run.periodEnd)}',
          'description': 'Approved payroll run ${run.id} is ready for salary disbursement. Review the payroll and assign it to an accountant for payment processing.',
          'task_type': 'payroll',
          'estimate_hours': 8,
          'priority': 'high',
          'weight': 4,
          'status': 'todo',
          'progress': 0,
          'due_date': _toDateOnly(DateTime.now().add(const Duration(days: 2))),
        })
        .select('id')
        .single();

    return inserted['id'].toString();
  }

  @override
  Future<({List<PayrollRun> items, int total})> fetchRuns({
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String sortBy = 'period_start',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final from = page * pageSize;
    final to = from + pageSize - 1;

    dynamic listQ = _client
        .from('payroll_runs')
        .select(
          'id, tenant_id, period_start, period_end, status, total_employees, total_amount, '
          'created_at, reject_reason, disbursement_status, disbursement_task_id, '
          'disbursement_assignee_employee_id, hr_approved_at, finance_manager_approved_at, admin_approved_at',
        )
        .eq('tenant_id', tenantId);

    if (status != null && status.trim().isNotEmpty) {
      listQ = listQ.eq('status', status);
    }

    if (startDate != null) {
      listQ = listQ.gte('period_start', _toDateOnly(startDate));
    }

    if (endDate != null) {
      listQ = listQ.lte('period_end', _toDateOnly(endDate));
    }

    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => PayrollRun.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('payroll_runs')
        .select('id')
        .eq('tenant_id', tenantId);

    if (status != null && status.trim().isNotEmpty) {
      countQ = countQ.eq('status', status);
    }
    if (startDate != null) {
      countQ = countQ.gte('period_start', _toDateOnly(startDate));
    }
    if (endDate != null) {
      countQ = countQ.lte('period_end', _toDateOnly(endDate));
    }

    final countRes = await countQ;
    final total = (countRes as List).length;

    return (items: items, total: total);
  }

  @override
  Future<String> createRun({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final tenantId = await _tenantId();

    final res = await _client.rpc(
      'generate_payroll_run',
      params: {
        'p_tenant_id': tenantId,
        'p_period_start': _toDateOnly(periodStart),
        'p_period_end': _toDateOnly(periodEnd),
      },
    );

    if (res is String) return res;
    if (res is Map && res['run_id'] != null) {
      return res['run_id'].toString();
    }
    if (res != null) return res.toString();

    throw Exception('Invalid payroll RPC response');
  }

  @override
  Future<List<PayrollItem>> fetchRunItems({required String runId}) async {
    final res = await _client
        .from('payroll_items')
        .select(
          'id, run_id, employee_id, basic_salary, housing_allowance, transport_allowance, other_allowance, total_amount, '
          'employee:employees(full_name)',
        )
        .eq('run_id', runId);

    return (res as List)
        .map((e) => PayrollItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> finalizeRun({required String runId}) {
    return submitToFinanceManager(runId: runId);
  }

  @override
  Future<void> submitToFinanceManager({required String runId}) async {
    final actor = await _actor();
    final requesterEmployeeId = await _resolveRequesterEmployeeId(
      tenantId: actor.tenantId,
      role: 'hr',
      preferredEmployeeId: actor.employeeId,
    );

    await _client
        .from('payroll_runs')
        .update({
          'status': 'pending_finance_manager',
          'reject_reason': null,
          'hr_approved_at': DateTime.now().toIso8601String(),
        })
        .eq('tenant_id', actor.tenantId)
        .eq('id', runId);

    await _client.from('approval_requests').insert({
      'tenant_id': actor.tenantId,
      'request_type': 'payroll_run',
      'employee_id': requesterEmployeeId,
      'status': 'pending',
      'payload': {'run_id': runId},
      'requested_by_role': 'hr',
      'current_approver_role': 'finance_manager',
    });
  }

  @override
  Future<void> financeManagerApprove({required String runId}) async {
    final tenantId = await _tenantId();
    await _client
        .from('payroll_runs')
        .update({
          'status': 'pending_admin_approval',
          'finance_manager_approved_at': DateTime.now().toIso8601String(),
          'reject_reason': null,
        })
        .eq('tenant_id', tenantId)
        .eq('id', runId);

    await _client
        .from('approval_requests')
        .update({'current_approver_role': 'admin'})
        .eq('tenant_id', tenantId)
        .contains('payload', {'run_id': runId})
        .eq('status', 'pending');
  }

  @override
  Future<void> adminApprove({required String runId}) async {
    final actor = await _actor();
    final rows = await _client
        .from('payroll_runs')
        .select(
          'id, tenant_id, period_start, period_end, status, total_employees, total_amount, '
          'created_at, reject_reason, disbursement_status, disbursement_task_id, '
          'disbursement_assignee_employee_id, hr_approved_at, finance_manager_approved_at, admin_approved_at',
        )
        .eq('tenant_id', actor.tenantId)
        .eq('id', runId)
        .limit(1);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) throw Exception('Payroll run not found');
    final run = PayrollRun.fromMap(list.first);
    final financeManagerEmployeeId = await _resolveFinanceManagerEmployeeId(
      tenantId: actor.tenantId,
    );
    final taskId = await _createFinanceDisbursementTask(
      tenantId: actor.tenantId,
      financeManagerEmployeeId: financeManagerEmployeeId,
      run: run,
      assignedByEmployeeId: actor.employeeId,
    );

    await _client
        .from('payroll_runs')
        .update({
          'status': 'approved',
          'admin_approved_at': DateTime.now().toIso8601String(),
          'disbursement_status': 'assigned_to_finance_manager',
          'disbursement_task_id': taskId,
          'disbursement_assignee_employee_id': financeManagerEmployeeId,
        })
        .eq('tenant_id', actor.tenantId)
        .eq('id', runId);

    await _client
        .from('approval_requests')
        .update({'status': 'approved'})
        .eq('tenant_id', actor.tenantId)
        .contains('payload', {'run_id': runId})
        .eq('status', 'pending');
  }

  @override
  Future<void> rejectRun({
    required String runId,
    required String reason,
    required String rejectedByRole,
  }) async {
    final tenantId = await _tenantId();
    await _client
        .from('payroll_runs')
        .update({
          'status': _rejectedStatusForRole(rejectedByRole),
          'reject_reason': reason,
        })
        .eq('tenant_id', tenantId)
        .eq('id', runId);

    await _client
        .from('approval_requests')
        .update({'status': 'rejected', 'reject_reason': reason})
        .eq('tenant_id', tenantId)
        .contains('payload', {'run_id': runId})
        .eq('status', 'pending');
  }

  @override
  Future<List<PayrollAssigneeOption>> fetchAssignableAccountants() async {
    final actor = await _actor();
    final financeManagerEmployeeId = actor.employeeId;
    if (financeManagerEmployeeId == null || financeManagerEmployeeId.isEmpty) {
      return const [];
    }

    final rows = await _client
        .from('employees')
        .select('id, full_name')
        .eq('tenant_id', actor.tenantId)
        .eq('manager_id', financeManagerEmployeeId)
        .eq('status', 'active')
        .order('full_name');

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => PayrollAssigneeOption(
            employeeId: row['id'].toString(),
            fullName: (row['full_name'] ?? '').toString(),
          ),
        )
        .toList();
  }

  @override
  Future<void> assignDisbursementToAccountant({
    required String runId,
    required String accountantEmployeeId,
  }) async {
    final actor = await _actor();
    final managerEmployeeId = actor.employeeId;
    if (managerEmployeeId == null || managerEmployeeId.isEmpty) {
      throw Exception('Finance manager employee profile is missing');
    }

    final rows = await _client
        .from('payroll_runs')
        .select('disbursement_task_id')
        .eq('tenant_id', actor.tenantId)
        .eq('id', runId)
        .limit(1);
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) throw Exception('Payroll run not found');

    final taskId = list.first['disbursement_task_id']?.toString();
    if (taskId == null || taskId.isEmpty) {
      throw Exception('Disbursement task is missing');
    }

    await _client.from('employee_tasks').update({
      'employee_id': accountantEmployeeId,
      'assigned_by_employee_id': managerEmployeeId,
      'status': 'todo',
      'progress': 0,
      'qa_status': 'pending',
      'employee_review_status': 'none',
      'employee_review_note': null,
      'employee_review_requested_at': null,
      'manager_review_note': null,
      'manager_reviewed_at': null,
      'assignee_received_at': null,
      'assignee_started_at': null,
      'active_timer_started_at': null,
      'completed_at': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);

    await _client
        .from('payroll_runs')
        .update({
          'disbursement_status': 'assigned_to_accountant',
          'disbursement_assignee_employee_id': accountantEmployeeId,
        })
        .eq('tenant_id', actor.tenantId)
        .eq('id', runId);
  }

  @override
  Future<void> markPaymentInProgress({required String runId}) async {
    final actor = await _actor();
    final actorEmployeeId = actor.employeeId;
    if (actorEmployeeId == null || actorEmployeeId.isEmpty) {
      throw Exception('Current accountant employee profile is missing');
    }

    final rows = await _client
        .from('payroll_runs')
        .select('disbursement_task_id, disbursement_assignee_employee_id')
        .eq('tenant_id', actor.tenantId)
        .eq('id', runId)
        .limit(1);
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) throw Exception('Payroll run not found');

    final assigneeEmployeeId = list.first['disbursement_assignee_employee_id']?.toString();
    if (assigneeEmployeeId != actorEmployeeId) {
      throw Exception('This payroll is not assigned to you');
    }

    final taskId = list.first['disbursement_task_id']?.toString();
    await _client
        .from('payroll_runs')
        .update({'disbursement_status': 'payment_in_progress'})
        .eq('tenant_id', actor.tenantId)
        .eq('id', runId);

    if (taskId != null && taskId.isNotEmpty) {
      await _client.from('employee_tasks').update({
        'status': 'in_progress',
        'progress': 50,
        'assignee_started_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
    }
  }

  @override
  Future<void> markPaid({required String runId}) async {
    final actor = await _actor();
    final actorEmployeeId = actor.employeeId;
    if (actorEmployeeId == null || actorEmployeeId.isEmpty) {
      throw Exception('Current accountant employee profile is missing');
    }

    final rows = await _client
        .from('payroll_runs')
        .select('disbursement_task_id, disbursement_assignee_employee_id')
        .eq('tenant_id', actor.tenantId)
        .eq('id', runId)
        .limit(1);
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) throw Exception('Payroll run not found');

    final assigneeEmployeeId = list.first['disbursement_assignee_employee_id']?.toString();
    if (assigneeEmployeeId != actorEmployeeId) {
      throw Exception('This payroll is not assigned to you');
    }

    final taskId = list.first['disbursement_task_id']?.toString();
    await _client
        .from('payroll_runs')
        .update({'disbursement_status': 'paid'})
        .eq('tenant_id', actor.tenantId)
        .eq('id', runId);

    if (taskId != null && taskId.isNotEmpty) {
      final now = DateTime.now().toIso8601String();
      await _client.from('employee_tasks').update({
        'status': 'done',
        'progress': 100,
        'qa_status': 'accepted',
        'completed_at': now,
        'updated_at': now,
        'active_timer_started_at': null,
      }).eq('id', taskId);
    }
  }
}
