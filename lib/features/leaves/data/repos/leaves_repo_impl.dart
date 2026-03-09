import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/leave_balance.dart';
import '../../domain/models/leave_request.dart';
import '../../domain/repos/leaves_repo.dart';

class LeavesRepoImpl implements LeavesRepo {
  LeavesRepoImpl(this._client);
  final SupabaseClient _client;

  bool _isManagerRole(String role) =>
      role.trim().toLowerCase() == 'manager' ||
      role.trim().toLowerCase() == 'direct_manager';

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

  Future<({String role, String? employeeId})> _currentUserIdentity() async {
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
    final dept = await _client
        .from('departments')
        .select('manager_id')
        .eq('tenant_id', tenantId)
        .eq('id', departmentId)
        .maybeSingle();
    return dept?['manager_id']?.toString();
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

  String _toDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  int _leaveDaysInclusive(DateTime startDate, DateTime endDate) {
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return e.difference(s).inDays + 1;
  }

  @override
  Future<({List<LeaveRequest> items, int total})> fetchLeaves({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String sortBy = 'start_date',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final actor = await _currentUserIdentity();
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final s = search?.trim();

    dynamic listQ = _client
        .from('leave_requests')
        .select(
          'id, tenant_id, employee_id, type, start_date, end_date, status, file_url, notes, created_at, '
          'employee:employees(full_name)',
        )
        .eq('tenant_id', tenantId);

    if ((employeeId == null || employeeId.trim().isEmpty) &&
        _isManagerRole(actor.role) &&
        actor.employeeId != null &&
        actor.employeeId!.isNotEmpty) {
      final subordinateIds = await _subordinateEmployeeIds(
        tenantId: tenantId,
        managerEmployeeId: actor.employeeId!,
      );
      if (subordinateIds.isEmpty) {
        return (items: const <LeaveRequest>[], total: 0);
      }
      listQ = listQ.inFilter('employee_id', subordinateIds);
    }

    if (status != null && status.trim().isNotEmpty) {
      listQ = listQ.eq('status', status);
    }

    if (type != null && type.trim().isNotEmpty) {
      listQ = listQ.eq('type', type);
    }

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      listQ = listQ.eq('employee_id', employeeId);
    }

    if (startDate != null) {
      listQ = listQ.gte('start_date', _toDateOnly(startDate));
    }

    if (endDate != null) {
      listQ = listQ.lte('end_date', _toDateOnly(endDate));
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      listQ = listQ.or('employee.full_name.ilike.%$escaped%');
    }

    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => LeaveRequest.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('leave_requests')
        .select('id')
        .eq('tenant_id', tenantId);

    if ((employeeId == null || employeeId.trim().isEmpty) &&
        _isManagerRole(actor.role) &&
        actor.employeeId != null &&
        actor.employeeId!.isNotEmpty) {
      final subordinateIds = await _subordinateEmployeeIds(
        tenantId: tenantId,
        managerEmployeeId: actor.employeeId!,
      );
      if (subordinateIds.isEmpty) {
        return (items: items, total: 0);
      }
      countQ = countQ.inFilter('employee_id', subordinateIds);
    }

    if (status != null && status.trim().isNotEmpty) {
      countQ = countQ.eq('status', status);
    }

    if (type != null && type.trim().isNotEmpty) {
      countQ = countQ.eq('type', type);
    }

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      countQ = countQ.eq('employee_id', employeeId);
    }

    if (startDate != null) {
      countQ = countQ.gte('start_date', _toDateOnly(startDate));
    }

    if (endDate != null) {
      countQ = countQ.lte('end_date', _toDateOnly(endDate));
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      countQ = countQ.or('employee.full_name.ilike.%$escaped%');
    }

    final countRes = await countQ;
    final total = (countRes as List).length;

    return (items: items, total: total);
  }

  @override
  Future<void> createLeave({
    required String employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? fileUrl,
    String? notes,
  }) async {
    final tenantId = await _tenantId();
    final identity = await _currentUserIdentity();
    final requesterRole = identity.role;
    final leaveYear = startDate.year;

    if (type == 'annual' || type == 'sick' || type == 'other') {
      final balances = await fetchLeaveBalances(
        employeeId: employeeId,
        year: leaveYear,
      );
      LeaveBalance? target;
      for (final b in balances) {
        if (b.type == type) {
          target = b;
          break;
        }
      }
      if (target != null) {
        final requested = _leaveDaysInclusive(startDate, endDate).toDouble();
        if (requested > target.remaining) {
          throw Exception(
            'Insufficient leave balance. Requested: ${requested.toStringAsFixed(0)}, '
            'Remaining: ${target.remaining.toStringAsFixed(0)}',
          );
        }
      }
    }

    final leavePayload = {
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'type': type,
      'start_date': _toDateOnly(startDate),
      'end_date': _toDateOnly(endDate),
      'status': 'pending',
      'file_url': (fileUrl == null || fileUrl.trim().isEmpty)
          ? null
          : fileUrl.trim(),
      'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      'leave_year': leaveYear,
    };

    Map<String, dynamic> leave;
    try {
      leave = await _client
          .from('leave_requests')
          .insert(leavePayload)
          .select('id')
          .single();
    } catch (_) {
      leavePayload.remove('leave_year');
      leave = await _client
          .from('leave_requests')
          .insert(leavePayload)
          .select('id')
          .single();
    }

    final leaveId = leave['id'].toString();

    String currentApproverRole;
    if (requesterRole == 'hr') {
      currentApproverRole = 'admin';
    } else if (_isManagerRole(requesterRole)) {
      currentApproverRole = 'hr';
    } else {
      final managerId = await _employeeManagerId(
        tenantId: tenantId,
        employeeId: employeeId,
      );
      currentApproverRole = (managerId == null || managerId.isEmpty)
          ? 'hr'
          : 'manager';
    }

    await _client.from('approval_requests').insert({
      'tenant_id': tenantId,
      'request_type': 'leave',
      'employee_id': employeeId,
      'status': 'pending',
      'requested_by_role': requesterRole,
      'current_approver_role': currentApproverRole,
      'payload': {
        'leave_id': leaveId,
        'type': type,
        'start_date': _toDateOnly(startDate),
        'end_date': _toDateOnly(endDate),
        'leave_year': leaveYear,
        'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
        'file_url': (fileUrl == null || fileUrl.trim().isEmpty)
            ? null
            : fileUrl.trim(),
      },
    });
  }

  @override
  Future<void> resubmitLeave({
    required String leaveId,
    required String employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? fileUrl,
    String? notes,
  }) async {
    final tenantId = await _tenantId();
    final identity = await _currentUserIdentity();
    final requesterRole = identity.role;
    final leaveYear = startDate.year;

    if (type == 'annual' || type == 'sick' || type == 'other') {
      final balances = await fetchLeaveBalances(
        employeeId: employeeId,
        year: leaveYear,
      );
      LeaveBalance? target;
      for (final b in balances) {
        if (b.type == type) {
          target = b;
          break;
        }
      }
      if (target != null) {
        final requested = _leaveDaysInclusive(startDate, endDate).toDouble();
        if (requested > target.remaining) {
          throw Exception(
            'Insufficient leave balance. Requested: ${requested.toStringAsFixed(0)}, '
            'Remaining: ${target.remaining.toStringAsFixed(0)}',
          );
        }
      }
    }

    final leavePayload = {
      'type': type,
      'start_date': _toDateOnly(startDate),
      'end_date': _toDateOnly(endDate),
      'status': 'pending',
      'file_url': (fileUrl == null || fileUrl.trim().isEmpty)
          ? null
          : fileUrl.trim(),
      'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      'leave_year': leaveYear,
    };

    try {
      await _client
          .from('leave_requests')
          .update(leavePayload)
          .eq('tenant_id', tenantId)
          .eq('id', leaveId)
          .eq('employee_id', employeeId);
    } catch (_) {
      leavePayload.remove('leave_year');
      await _client
          .from('leave_requests')
          .update(leavePayload)
          .eq('tenant_id', tenantId)
          .eq('id', leaveId)
          .eq('employee_id', employeeId);
    }

    final approvalPayload = {
      'leave_id': leaveId,
      'type': type,
      'start_date': _toDateOnly(startDate),
      'end_date': _toDateOnly(endDate),
      'leave_year': leaveYear,
      'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      'file_url': (fileUrl == null || fileUrl.trim().isEmpty)
          ? null
          : fileUrl.trim(),
    };

    dynamic latestQ = _client
        .from('approval_requests')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('request_type', 'leave')
        .eq('employee_id', employeeId)
        .contains('payload', {'leave_id': leaveId})
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    Map<String, dynamic>? latest;
    try {
      latest = await latestQ;
    } catch (_) {
      latest = null;
    }

    if (latest != null) {
      String currentApproverRole;
      if (requesterRole == 'hr') {
        currentApproverRole = 'admin';
      } else if (_isManagerRole(requesterRole)) {
        currentApproverRole = 'hr';
      } else {
        final managerId = await _employeeManagerId(
          tenantId: tenantId,
          employeeId: employeeId,
        );
        currentApproverRole = (managerId == null || managerId.isEmpty)
            ? 'hr'
            : 'manager';
      }

      await _client
          .from('approval_requests')
          .update({
            'status': 'pending',
            'reject_reason': null,
            'requested_by_role': requesterRole,
            'current_approver_role': currentApproverRole,
            'payload': approvalPayload,
          })
          .eq('tenant_id', tenantId)
          .eq('id', latest['id'].toString());
    } else {
      String currentApproverRole;
      if (requesterRole == 'hr') {
        currentApproverRole = 'admin';
      } else if (_isManagerRole(requesterRole)) {
        currentApproverRole = 'hr';
      } else {
        final managerId = await _employeeManagerId(
          tenantId: tenantId,
          employeeId: employeeId,
        );
        currentApproverRole = (managerId == null || managerId.isEmpty)
            ? 'hr'
            : 'manager';
      }

      await _client.from('approval_requests').insert({
        'tenant_id': tenantId,
        'request_type': 'leave',
        'employee_id': employeeId,
        'status': 'pending',
        'requested_by_role': requesterRole,
        'current_approver_role': currentApproverRole,
        'payload': approvalPayload,
      });
    }
  }

  @override
  Future<List<LeaveBalance>> fetchLeaveBalances({
    required String employeeId,
    int? year,
  }) async {
    final tenantId = await _tenantId();
    final targetYear = year ?? DateTime.now().year;

    final row = await _client
        .from('employee_leave_balances')
        .select(
          'annual_entitlement, sick_entitlement, other_entitlement, '
          'annual_used, sick_used, other_used',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .eq('leave_year', targetYear)
        .maybeSingle();

    if (row == null) {
      return const [
        LeaveBalance(type: 'annual', entitlement: 0, used: 0),
        LeaveBalance(type: 'sick', entitlement: 0, used: 0),
        LeaveBalance(type: 'other', entitlement: 0, used: 0),
      ];
    }

    double toNum(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '0') ?? 0;
    }

    return [
      LeaveBalance(
        type: 'annual',
        entitlement: toNum(row['annual_entitlement']),
        used: toNum(row['annual_used']),
      ),
      LeaveBalance(
        type: 'sick',
        entitlement: toNum(row['sick_entitlement']),
        used: toNum(row['sick_used']),
      ),
      LeaveBalance(
        type: 'other',
        entitlement: toNum(row['other_entitlement']),
        used: toNum(row['other_used']),
      ),
    ];
  }
}
