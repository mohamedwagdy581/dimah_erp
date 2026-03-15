part of 'leaves_repo_impl.dart';

mixin _LeavesRepoHelpersMixin on _LeavesRepoSessionMixin, _LeavesRepoBalancesMixin {
  Future<String?> _employeeManagerId({
    required String tenantId,
    required String employeeId,
  }) async {
    final row = await _client
        .from('employees')
        .select('manager_id, department_id')
        .eq('tenant_id', tenantId)
        .eq('id', employeeId)
        .maybeSingle();

    final directManager = row?['manager_id']?.toString();
    if (directManager != null && directManager.isNotEmpty) return directManager;

    final departmentId = row?['department_id']?.toString();
    if (departmentId == null || departmentId.isEmpty) return null;

    final department = await _client
        .from('departments')
        .select('manager_id')
        .eq('tenant_id', tenantId)
        .eq('id', departmentId)
        .maybeSingle();
    return department?['manager_id']?.toString();
  }

  Future<List<String>> _subordinateEmployeeIds({
    required String tenantId,
    required String managerEmployeeId,
  }) async {
    final directRes = await _client
        .from('employees')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final directIds = (directRes as List).map((e) => e['id'].toString()).toList();

    final managedDepartmentsRes = await _client
        .from('departments')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final managedDepartmentIds = (managedDepartmentsRes as List)
        .map((e) => e['id'].toString())
        .toList();

    final departmentIds = <String>[];
    if (managedDepartmentIds.isNotEmpty) {
      final deptRes = await _client
          .from('employees')
          .select('id')
          .eq('tenant_id', tenantId)
          .inFilter('department_id', managedDepartmentIds);
      departmentIds.addAll((deptRes as List).map((e) => e['id'].toString()));
    }

    final all = {...directIds, ...departmentIds};
    all.remove(managerEmployeeId);
    return all.toList();
  }

  int _leaveDaysInclusive(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  Future<void> _validateLeaveBalance({
    required String employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (type != 'annual' && type != 'sick' && type != 'other') return;

    final balances = await fetchLeaveBalances(
      employeeId: employeeId,
      year: startDate.year,
    );
    LeaveBalance? target;
    for (final balance in balances) {
      if (balance.type == type) {
        target = balance;
        break;
      }
    }
    if (target == null) return;

    final requested = _leaveDaysInclusive(startDate, endDate).toDouble();
    if (requested > target.remaining) {
      throw Exception(
        'Insufficient leave balance. Requested: ${requested.toStringAsFixed(0)}, '
        'Remaining: ${target.remaining.toStringAsFixed(0)}',
      );
    }
  }

  String? _normalizeOptionalText(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  Map<String, dynamic> _leavePayload({
    required String tenantId,
    required String employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required int leaveYear,
    String? fileUrl,
    String? notes,
  }) {
    return {
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'type': type,
      'start_date': _toDateOnly(startDate),
      'end_date': _toDateOnly(endDate),
      'status': 'pending',
      'file_url': _normalizeOptionalText(fileUrl),
      'notes': _normalizeOptionalText(notes),
      'leave_year': leaveYear,
    };
  }

  Future<String> _resolveLeaveApproverRole({
    required String tenantId,
    required String requesterRole,
    required String employeeId,
  }) async {
    if (requesterRole == 'hr') return 'admin';
    if (_isManagerRole(requesterRole)) return 'hr';
    final managerId = await _employeeManagerId(
      tenantId: tenantId,
      employeeId: employeeId,
    );
    return (managerId == null || managerId.isEmpty) ? 'hr' : 'manager';
  }
}
