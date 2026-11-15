import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/payroll_assignee_option.dart';
import '../../domain/models/payroll_item.dart';
import '../../domain/models/payroll_run.dart';
import '../../domain/repos/payroll_repo.dart';

class PayrollRepoImpl implements PayrollRepo {
  PayrollRepoImpl(this._client);
  final SupabaseClient _client;

  @override
  Future<List<PayrollItem>> fetchPreparationItems() async {
    final actor = await _actor();
    if (actor.role != 'hr' && actor.role != 'admin') {
      throw StateError('Payroll preparation requires HR or admin');
    }
    final employees = <Map<String, dynamic>>[];
    final compensation = <String, Map<String, dynamic>>{};
    for (var page = 0; ; page++) {
      final rows = await _client
          .from('employees')
          .select('id, full_name, photo_url, job_title:job_titles(name)')
          .eq('tenant_id', actor.tenantId)
          .eq('status', 'active')
          .order('id')
          .range(page * 500, page * 500 + 499);
      employees.addAll(rows);
      if (rows.length < 500) break;
    }
    for (var page = 0; ; page++) {
      final rows = await _client
          .from('employee_compensation')
          .select(
            'employee_id, basic_salary, housing_allowance, transport_allowance, other_allowance',
          )
          .eq('tenant_id', actor.tenantId)
          .order('employee_id')
          .range(page * 500, page * 500 + 499);
      for (final row in rows) {
        compensation[row['employee_id'].toString()] = row;
      }
      if (rows.length < 500) break;
    }
    return employees.map((employee) {
      final c = compensation[employee['id'].toString()] ?? <String, dynamic>{};
      num amount(String key) => (c[key] ?? 0) as num;
      return PayrollItem.fromMap({
        ...c,
        'id': employee['id'],
        'run_id': '',
        'employee_id': employee['id'],
        'employee': employee,
        'total_amount':
            amount('basic_salary') +
            amount('housing_allowance') +
            amount('transport_allowance') +
            amount('other_allowance'),
      });
    }).toList()..sort((a, b) => a.employeeName.compareTo(b.employeeName));
  }

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
    final tenantId = await _tenantId();
    final items = <PayrollItem>[];
    for (var page = 0; ; page++) {
      final res = await _client
          .from('payroll_items')
          .select(
            'id, run_id, employee_id, basic_salary, housing_allowance, transport_allowance, other_allowance, total_amount, '
            'employee:employees(full_name, employee_number, photo_url, job_title:job_titles(name))',
          )
          .eq('tenant_id', tenantId)
          .eq('run_id', runId)
          .order('id')
          .range(page * 500, page * 500 + 499);
      items.addAll(
        (res as List)
            .map((e) => PayrollItem.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
      if (res.length < 500) break;
    }
    return items;
  }

  @override
  Future<void> finalizeRun({required String runId}) {
    return submitToFinanceManager(runId: runId);
  }

  @override
  Future<void> submitToFinanceManager({required String runId}) async {
    await _client.rpc('hr_submit_payroll', params: {'p_run_id': runId});
  }

  @override
  Future<void> financeManagerApprove({
    required String runId,
    String? notes,
  }) async {
    await _client.rpc(
      'finance_review_payroll',
      params: {'p_run_id': runId, 'p_approve': true, 'p_notes': notes?.trim()},
    );
  }

  @override
  Future<String?> fetchFinanceReviewNotes({required String runId}) async {
    final tenantId = await _tenantId();
    final rows = await _client
        .from('approval_requests')
        .select('payload')
        .eq('tenant_id', tenantId)
        .eq('request_type', 'payroll_run')
        .contains('payload', {'run_id': runId})
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final payload = rows.first['payload'];
    return payload is Map ? payload['finance_review_notes']?.toString() : null;
  }

  @override
  Future<void> adminApprove({required String runId}) async {
    await _client.rpc('admin_approve_payroll', params: {'p_run_id': runId});
  }

  @override
  Future<void> rejectRun({
    required String runId,
    required String reason,
    required String rejectedByRole,
  }) async {
    if (rejectedByRole == 'finance_manager') {
      await _client.rpc(
        'finance_review_payroll',
        params: {
          'p_run_id': runId,
          'p_approve': false,
          'p_notes': reason.trim(),
        },
      );
      return;
    }
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
    final rows = await _client.rpc('finance_payroll_assignees') as List;
    return rows
        .cast<Map<String, dynamic>>()
        .map(
          (row) => PayrollAssigneeOption(
            employeeId: row['id'].toString(),
            fullName: (row['full_name'] ?? '').toString(),
            employeeNumber: row['employee_number']?.toString(),
            jobLevel: row['job_level']?.toString(),
          ),
        )
        .toList();
  }

  @override
  Future<void> assignDisbursementToAccountant({
    required String runId,
    required String accountantEmployeeId,
  }) async {
    await _client.rpc(
      'finance_assign_payroll',
      params: {'p_run_id': runId, 'p_employee_id': accountantEmployeeId},
    );
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

    final assigneeEmployeeId = list.first['disbursement_assignee_employee_id']
        ?.toString();
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
      await _client
          .from('employee_tasks')
          .update({
            'status': 'in_progress',
            'progress': 50,
            'assignee_started_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId);
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

    final assigneeEmployeeId = list.first['disbursement_assignee_employee_id']
        ?.toString();
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
      await _client
          .from('employee_tasks')
          .update({
            'status': 'done',
            'progress': 100,
            'qa_status': 'accepted',
            'completed_at': now,
            'updated_at': now,
            'active_timer_started_at': null,
          })
          .eq('id', taskId);
    }
  }
}
