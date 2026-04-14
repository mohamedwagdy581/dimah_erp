import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/app_di.dart';

class ShellNotificationsRepo {
  ShellNotificationsRepo(this._client);

  final SupabaseClient _client;

  bool showNotificationBadge(String role) {
    return role == 'admin' ||
        role == 'hr' ||
        role == 'manager' ||
        role == 'employee' ||
        role == 'finance_manager' ||
        role == 'accountant';
  }

  Future<int> fetchCount(String role, String? employeeId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    final me = await _client.from('users').select('tenant_id').eq('id', uid).single();
    final tenantId = me['tenant_id'].toString();

    if (role == 'employee' && employeeId != null) {
      return _fetchEmployeeCount(tenantId, employeeId);
    }
    if (role == 'manager' || role == 'direct_manager') {
      return _fetchManagerCount(tenantId, employeeId);
    }
    if (role == 'finance_manager') {
      return _fetchFinanceManagerCount(tenantId, employeeId);
    }
    if (role == 'accountant') {
      return _fetchAccountantCount(tenantId, employeeId);
    }
    if (role == 'admin') {
      return _fetchAdminCount(tenantId);
    }
    if (role == 'hr') {
      return _fetchHrCount(tenantId);
    }
    return 0;
  }

  Future<int> _fetchEmployeeCount(String tenantId, String employeeId) async {
    final rows = await _client
        .from('employee_tasks')
        .select('qa_status, employee_review_status, due_date, status')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .limit(100);
    final today = DateTime.now();
    var count = 0;
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final reviewStatus = (row['employee_review_status'] ?? 'none').toString();
      final qaStatus = (row['qa_status'] ?? 'pending').toString();
      if (reviewStatus == 'approved' || reviewStatus == 'rejected') count++;
      if (qaStatus == 'accepted' || qaStatus == 'rework' || qaStatus == 'rejected') {
        count++;
      }
      final dueDate = DateTime.tryParse(row['due_date']?.toString() ?? '');
      if ((row['status'] ?? '') != 'done' && dueDate != null) {
        final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (!dueOnly.isBefore(todayOnly) &&
            !dueOnly.isAfter(todayOnly.add(const Duration(days: 2)))) {
          count++;
        }
      }
    }
    return count;
  }

  Future<int> _fetchManagerCount(String tenantId, String? employeeId) async {
    final deptIdsRes = await _client
        .from('departments')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', employeeId ?? '');
    final deptIds = (deptIdsRes as List).map((e) => e['id'].toString()).toList();
    if (deptIds.isEmpty) return 0;
    final employeeRows = await _client
        .from('employees')
        .select('id')
        .eq('tenant_id', tenantId)
        .inFilter('department_id', deptIds)
        .eq('status', 'active');
    final employeeIds = (employeeRows as List).map((e) => e['id'].toString()).toList();
    if (employeeIds.isEmpty) return 0;
    final tasks = await _client
        .from('employee_tasks')
        .select('employee_review_status, status, qa_status')
        .eq('tenant_id', tenantId)
        .inFilter('employee_id', employeeIds);
    var count = 0;
    for (final row in (tasks as List).cast<Map<String, dynamic>>()) {
      if ((row['employee_review_status'] ?? 'none') == 'pending') count++;
      if ((row['status'] ?? '') == 'done' && (row['qa_status'] ?? 'pending') == 'pending') {
        count++;
      }
    }
    return count;
  }

  Future<int> _fetchFinanceManagerCount(String tenantId, String? employeeId) async {
    var count = 0;
    final payrollRows = await _client
        .from('payroll_runs')
        .select('id')
        .eq('tenant_id', tenantId)
        .or('status.eq.pending_finance_manager,and(status.eq.approved,disbursement_status.eq.assigned_to_finance_manager)');
    count += (payrollRows as List).length;

    if (employeeId != null && employeeId.isNotEmpty) {
      final taskRows = await _client
          .from('employee_tasks')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('employee_id', employeeId)
          .eq('task_type', 'payroll');
      count += (taskRows as List).length;
    }
    return count;
  }

  Future<int> _fetchAccountantCount(String tenantId, String? employeeId) async {
    if (employeeId == null || employeeId.isEmpty) return 0;
    final taskRows = await _client
        .from('employee_tasks')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .eq('task_type', 'payroll');
    return (taskRows as List).length;
  }

  Future<int> _fetchAdminCount(String tenantId) async {
    final approvalsCount = await AppDI.approvalsRepo.fetchPendingCount();
    final payrollRows = await _client
        .from('payroll_runs')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('status', 'pending_admin_approval');
    return approvalsCount + (payrollRows as List).length;
  }

  Future<int> _fetchHrCount(String tenantId) async {
    final approvalsCount = await AppDI.approvalsRepo.fetchPendingCount();
    final payrollRows = await _client
        .from('payroll_runs')
        .select('id')
        .eq('tenant_id', tenantId)
        .inFilter('status', ['rejected_by_finance_manager', 'rejected_by_admin']);
    return approvalsCount + (payrollRows as List).length;
  }
}
