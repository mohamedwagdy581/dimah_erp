import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/approval_request.dart';
import '../../domain/repos/approvals_repo.dart';

class ApprovalsRepoImpl implements ApprovalsRepo {
  ApprovalsRepoImpl(this._client);
  final SupabaseClient _client;

  Future<String> _tenantId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final me = await _client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();

    final t = me['tenant_id'];
    if (t == null) throw Exception('Missing tenant_id for current user');
    return t.toString();
  }

  Future<({String role, String? employeeId})> _currentActor() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final me = await _client
        .from('users')
        .select('role, employee_id')
        .eq('id', uid)
        .single();
    return (
      role: (me['role'] ?? 'employee').toString(),
      employeeId: me['employee_id']?.toString(),
    );
  }

  int _leaveDaysInclusive(DateTime startDate, DateTime endDate) {
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return e.difference(s).inDays + 1;
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '0') ?? 0;
  }

  Future<void> _logLeaveBalanceHistory({
    required String tenantId,
    required String employeeId,
    required int leaveYear,
    required String leaveType,
    required int days,
    required String actionType,
    required String requestId,
    String? leaveId,
    String? note,
  }) async {
    final actorUserId = _client.auth.currentUser?.id;
    try {
      await _client.from('employee_leave_balance_history').insert({
        'tenant_id': tenantId,
        'employee_id': employeeId,
        'leave_year': leaveYear,
        'leave_type': leaveType,
        'days': days,
        'action_type': actionType,
        'request_id': requestId,
        'leave_id': leaveId,
        'actor_user_id': actorUserId,
        'note': note,
      });
    } catch (_) {
      // Backward compatible if migration not applied yet.
    }
  }

  Future<void> _applyLeaveBalanceDelta({
    required String tenantId,
    required String employeeId,
    required String leaveType,
    required int leaveYear,
    required int daysDelta,
    required String requestId,
    String? leaveId,
    required String actionType,
  }) async {
    if (daysDelta == 0) return;
    if (leaveType != 'annual' && leaveType != 'sick' && leaveType != 'other') {
      return;
    }

    final row = await _client
        .from('employee_leave_balances')
        .select(
          'id, annual_entitlement, sick_entitlement, other_entitlement, '
          'annual_used, sick_used, other_used',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .eq('leave_year', leaveYear)
        .maybeSingle();

    if (row == null) {
      if (daysDelta < 0) {
        throw Exception(
          'Cannot rollback leave balance: leave balance record is missing.',
        );
      }
      final payload = <String, dynamic>{
        'tenant_id': tenantId,
        'employee_id': employeeId,
        'leave_year': leaveYear,
        'annual_entitlement': 21,
        'sick_entitlement': 10,
        'other_entitlement': 5,
        'annual_used': 0,
        'sick_used': 0,
        'other_used': 0,
      };
      if (leaveType == 'annual') payload['annual_used'] = daysDelta;
      if (leaveType == 'sick') payload['sick_used'] = daysDelta;
      if (leaveType == 'other') payload['other_used'] = daysDelta;
      await _client.from('employee_leave_balances').insert(payload);
      await _logLeaveBalanceHistory(
        tenantId: tenantId,
        employeeId: employeeId,
        leaveYear: leaveYear,
        leaveType: leaveType,
        days: daysDelta,
        actionType: actionType,
        requestId: requestId,
        leaveId: leaveId,
      );
      return;
    }

    final updates = <String, dynamic>{};
    if (leaveType == 'annual') {
      final entitlement = _toDouble(row['annual_entitlement']);
      final used = _toDouble(row['annual_used']);
      final next = used + daysDelta;
      if (next < 0) {
        throw Exception('Cannot rollback annual leave: used balance is too low.');
      }
      if (daysDelta > 0 && next > entitlement) {
        throw Exception('Insufficient annual leave balance for approval.');
      }
      updates['annual_used'] = next;
    } else if (leaveType == 'sick') {
      final entitlement = _toDouble(row['sick_entitlement']);
      final used = _toDouble(row['sick_used']);
      final next = used + daysDelta;
      if (next < 0) {
        throw Exception('Cannot rollback sick leave: used balance is too low.');
      }
      if (daysDelta > 0 && next > entitlement) {
        throw Exception('Insufficient sick leave balance for approval.');
      }
      updates['sick_used'] = next;
    } else if (leaveType == 'other') {
      final entitlement = _toDouble(row['other_entitlement']);
      final used = _toDouble(row['other_used']);
      final next = used + daysDelta;
      if (next < 0) {
        throw Exception('Cannot rollback other leave: used balance is too low.');
      }
      if (daysDelta > 0 && next > entitlement) {
        throw Exception('Insufficient other leave balance for approval.');
      }
      updates['other_used'] = next;
    }

    await _client
        .from('employee_leave_balances')
        .update(updates)
        .eq('tenant_id', tenantId)
        .eq('id', row['id'].toString());

    await _logLeaveBalanceHistory(
      tenantId: tenantId,
      employeeId: employeeId,
      leaveYear: leaveYear,
      leaveType: leaveType,
      days: daysDelta,
      actionType: actionType,
      requestId: requestId,
      leaveId: leaveId,
    );
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

    final deptIds = <String>[];
    if (managedDepartmentIds.isNotEmpty) {
      final deptRes = await _client
          .from('employees')
          .select('id')
          .eq('tenant_id', tenantId)
          .inFilter('department_id', managedDepartmentIds);
      deptIds.addAll((deptRes as List).map((e) => e['id'].toString()));
    }

    final all = {...directIds, ...deptIds};
    all.remove(managerEmployeeId);
    return all.toList();
  }

  @override
  Future<({List<ApprovalRequest> items, int total})> fetchApprovals({
    required int page,
    required int pageSize,
    String? status,
    String? requestType,
    String? employeeId,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final actor = await _currentActor();
    final from = page * pageSize;
    final to = from + pageSize - 1;

    dynamic listQ = _client
        .from('approval_requests')
        .select(
          'id, tenant_id, request_type, employee_id, status, reject_reason, payload, '
          'requested_by_role, current_approver_role, created_at, '
          'employee:employees(full_name)',
        )
        .eq('tenant_id', tenantId);

    if (employeeId == null || employeeId.trim().isEmpty) {
      if (actor.role == 'manager') {
        final managerEmpId = actor.employeeId;
        if (managerEmpId == null || managerEmpId.isEmpty) {
          return (items: const <ApprovalRequest>[], total: 0);
        }
        final subordinates = await _subordinateEmployeeIds(
          tenantId: tenantId,
          managerEmployeeId: managerEmpId,
        );
        if (subordinates.isEmpty) {
          return (items: const <ApprovalRequest>[], total: 0);
        }
        listQ = listQ.inFilter('employee_id', subordinates);
      }
      if (status != null && status.trim() == 'pending_assigned') {
        listQ = listQ.eq('status', 'pending');
        listQ = listQ.eq('current_approver_role', actor.role);
      }
    }

    final normalizedStatus = status?.trim();
    if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
      listQ = listQ.eq(
        'status',
        normalizedStatus == 'pending_assigned' ? 'pending' : normalizedStatus,
      );
    }

    if (requestType != null && requestType.trim().isNotEmpty) {
      listQ = listQ.eq('request_type', requestType);
    }

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      listQ = listQ.eq('employee_id', employeeId);
    }

    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => ApprovalRequest.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('approval_requests')
        .select('id')
        .eq('tenant_id', tenantId);

    if (employeeId == null || employeeId.trim().isEmpty) {
      if (actor.role == 'manager') {
        final managerEmpId = actor.employeeId;
        if (managerEmpId == null || managerEmpId.isEmpty) {
          return (items: items, total: 0);
        }
        final subordinates = await _subordinateEmployeeIds(
          tenantId: tenantId,
          managerEmployeeId: managerEmpId,
        );
        if (subordinates.isEmpty) {
          return (items: items, total: 0);
        }
        countQ = countQ.inFilter('employee_id', subordinates);
      }
      if (status != null && status.trim() == 'pending_assigned') {
        countQ = countQ.eq('status', 'pending');
        countQ = countQ.eq('current_approver_role', actor.role);
      }
    }

    if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
      countQ = countQ.eq(
        'status',
        normalizedStatus == 'pending_assigned' ? 'pending' : normalizedStatus,
      );
    }

    if (requestType != null && requestType.trim().isNotEmpty) {
      countQ = countQ.eq('request_type', requestType);
    }

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      countQ = countQ.eq('employee_id', employeeId);
    }

    final countRes = await countQ;
    final total = (countRes as List).length;

    return (items: items, total: total);
  }

  @override
  Future<int> fetchPendingCount({String? employeeId}) async {
    final tenantId = await _tenantId();
    final actor = await _currentActor();
    dynamic q = _client
        .from('approval_requests')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('status', 'pending');

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      q = q.eq('employee_id', employeeId);
    } else {
      q = q.eq('current_approver_role', actor.role);
      if (actor.role == 'manager' &&
          actor.employeeId != null &&
          actor.employeeId!.isNotEmpty) {
        final subordinateIds = await _subordinateEmployeeIds(
          tenantId: tenantId,
          managerEmployeeId: actor.employeeId!,
        );
        if (subordinateIds.isEmpty) return 0;
        q = q.inFilter('employee_id', subordinateIds);
      }
    }

    final res = await q;
    return (res as List).length;
  }

  @override
  Future<int> fetchProcessedCount({required String employeeId}) async {
    final tenantId = await _tenantId();
    final res = await _client
        .from('approval_requests')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .neq('status', 'pending');
    return (res as List).length;
  }

  @override
  Future<void> approve(String requestId) async {
    final tenantId = await _tenantId();
    final actor = await _currentActor();
    final req = await _client
        .from('approval_requests')
        .select(
          'request_type, payload, status, requested_by_role, current_approver_role',
        )
        .eq('tenant_id', tenantId)
        .eq('id', requestId)
        .single();

    if ((req['status'] ?? '').toString() == 'approved') {
      return;
    }

    final type = (req['request_type'] ?? '').toString();
    final payload = req['payload'] is Map
        ? Map<String, dynamic>.from(req['payload'] as Map)
        : <String, dynamic>{};
    final requestedByRole = (req['requested_by_role'] ?? 'employee').toString();
    final currentApproverRole = (req['current_approver_role'] ?? '').toString();

    if (currentApproverRole.isNotEmpty && actor.role != currentApproverRole) {
      throw Exception('This request is assigned to $currentApproverRole.');
    }

    String? nextApproverRole;
    String approvedAtColumn;
    if (actor.role == 'manager') {
      nextApproverRole = 'hr';
      approvedAtColumn = 'approved_by_manager_at';
    } else if (actor.role == 'hr') {
      nextApproverRole = 'admin';
      approvedAtColumn = 'approved_by_hr_at';
    } else if (actor.role == 'admin') {
      nextApproverRole = null;
      approvedAtColumn = 'approved_by_admin_at';
    } else {
      throw Exception('You do not have permission to approve requests.');
    }

    if (type == 'leave' && payload['leave_id'] != null) {
      Map<String, dynamic>? leave;
      try {
        leave = await _client
            .from('leave_requests')
            .select('employee_id, type, start_date, end_date, leave_year, status')
            .eq('tenant_id', tenantId)
            .eq('id', payload['leave_id'].toString())
            .maybeSingle();
      } catch (_) {
        leave = await _client
            .from('leave_requests')
            .select('employee_id, type, start_date, end_date, status')
            .eq('tenant_id', tenantId)
            .eq('id', payload['leave_id'].toString())
            .maybeSingle();
      }

      final isFinalApproval = actor.role == 'admin';
      if (isFinalApproval &&
          leave != null &&
          (leave['status'] ?? '').toString() != 'approved') {
        final start = DateTime.tryParse(leave['start_date'].toString());
        final end = DateTime.tryParse(leave['end_date'].toString());
        if (start != null && end != null) {
          final days = _leaveDaysInclusive(start, end);
          final leaveYear =
              int.tryParse(leave['leave_year']?.toString() ?? '') ?? start.year;
          await _applyLeaveBalanceDelta(
            tenantId: tenantId,
            employeeId: leave['employee_id'].toString(),
            leaveType: (leave['type'] ?? '').toString(),
            leaveYear: leaveYear,
            daysDelta: days,
            requestId: requestId,
            leaveId: payload['leave_id']?.toString(),
            actionType: 'approve',
          );
        }

        await _client
            .from('leave_requests')
            .update({'status': 'approved'})
            .eq('tenant_id', tenantId)
            .eq('id', payload['leave_id'].toString());
      } else if (!isFinalApproval) {
        await _client
            .from('leave_requests')
            .update({'status': 'pending'})
            .eq('tenant_id', tenantId)
            .eq('id', payload['leave_id'].toString());
      }
    }

    if (type == 'attendance_correction' && payload['record_id'] != null) {
      final updates = <String, dynamic>{};
      if (payload['proposed_check_in'] != null) {
        updates['check_in'] = payload['proposed_check_in'];
      }
      if (payload['proposed_check_out'] != null) {
        updates['check_out'] = payload['proposed_check_out'];
      }
      if (updates.isNotEmpty) {
        await _client
            .from('attendance_records')
            .update(updates)
            .eq('tenant_id', tenantId)
            .eq('id', payload['record_id'].toString());
      }
    }

    await _client
        .from('approval_requests')
        .update({
          approvedAtColumn: DateTime.now().toIso8601String(),
          'current_approver_role': nextApproverRole,
          'status': nextApproverRole == null ? 'approved' : 'pending',
          'reject_reason': null,
          'requested_by_role': requestedByRole,
        })
        .eq('tenant_id', tenantId)
        .eq('id', requestId);
  }

  @override
  Future<void> reject(String requestId, {String? reason}) async {
    final tenantId = await _tenantId();
    final actor = await _currentActor();
    final req = await _client
        .from('approval_requests')
        .select('request_type, payload, status, current_approver_role')
        .eq('tenant_id', tenantId)
        .eq('id', requestId)
        .single();

    final currentApproverRole = (req['current_approver_role'] ?? '').toString();
    if (currentApproverRole.isNotEmpty && actor.role != currentApproverRole) {
      throw Exception('This request is assigned to $currentApproverRole.');
    }

    final type = (req['request_type'] ?? '').toString();
    final payload = req['payload'] is Map
        ? Map<String, dynamic>.from(req['payload'] as Map)
        : <String, dynamic>{};

    if (type == 'leave' && payload['leave_id'] != null) {
      Map<String, dynamic>? leave;
      try {
        leave = await _client
            .from('leave_requests')
            .select('employee_id, type, start_date, end_date, leave_year, status')
            .eq('tenant_id', tenantId)
            .eq('id', payload['leave_id'].toString())
            .maybeSingle();
      } catch (_) {
        leave = await _client
            .from('leave_requests')
            .select('employee_id, type, start_date, end_date, status')
            .eq('tenant_id', tenantId)
            .eq('id', payload['leave_id'].toString())
            .maybeSingle();
      }

      if (leave != null && (leave['status'] ?? '').toString() == 'approved') {
        final start = DateTime.tryParse(leave['start_date'].toString());
        final end = DateTime.tryParse(leave['end_date'].toString());
        if (start != null && end != null) {
          final days = _leaveDaysInclusive(start, end);
          final leaveYear =
              int.tryParse(leave['leave_year']?.toString() ?? '') ?? start.year;
          await _applyLeaveBalanceDelta(
            tenantId: tenantId,
            employeeId: leave['employee_id'].toString(),
            leaveType: (leave['type'] ?? '').toString(),
            leaveYear: leaveYear,
            daysDelta: -days,
            requestId: requestId,
            leaveId: payload['leave_id']?.toString(),
            actionType: 'rollback_on_reject',
          );
        }
      }

      await _client
          .from('leave_requests')
          .update({'status': 'rejected'})
          .eq('tenant_id', tenantId)
          .eq('id', payload['leave_id'].toString());
    }

    await _client
        .from('approval_requests')
        .update({
          'status': 'rejected',
          'reject_reason': reason,
          'current_approver_role': null,
        })
        .eq('tenant_id', tenantId)
        .eq('id', requestId);
  }
}
