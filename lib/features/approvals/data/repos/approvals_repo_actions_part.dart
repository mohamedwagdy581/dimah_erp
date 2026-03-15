part of 'approvals_repo_impl.dart';

mixin _ApprovalsRepoActionsMixin
    on _ApprovalsRepoCountsMixin, _ApprovalsRepoLeaveHelpersMixin {
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

    if ((req['status'] ?? '').toString() == 'approved') return;

    final type = (req['request_type'] ?? '').toString();
    final payload = req['payload'] is Map
        ? Map<String, dynamic>.from(req['payload'] as Map)
        : <String, dynamic>{};
    final currentApproverRole = (req['current_approver_role'] ?? '').toString();
    if (currentApproverRole.isNotEmpty && actor.role != currentApproverRole) {
      throw Exception('This request is assigned to $currentApproverRole.');
    }

    final requestedByRole = (req['requested_by_role'] ?? 'employee').toString();
    final nextApproverRole = actor.role == 'manager'
        ? 'hr'
        : actor.role == 'hr'
            ? 'admin'
            : actor.role == 'admin'
                ? null
                : throw Exception('You do not have permission to approve requests.');
    final approvedAtColumn = actor.role == 'manager'
        ? 'approved_by_manager_at'
        : actor.role == 'hr'
            ? 'approved_by_hr_at'
            : 'approved_by_admin_at';

    if (type == 'leave' && payload['leave_id'] != null) {
      final leaveId = payload['leave_id'].toString();
      final leave = await _fetchLeaveForApproval(tenantId: tenantId, leaveId: leaveId);
      final isFinalApproval = actor.role == 'admin';

      if (isFinalApproval && leave != null && (leave['status'] ?? '').toString() != 'approved') {
        final start = DateTime.tryParse(leave['start_date'].toString());
        final end = DateTime.tryParse(leave['end_date'].toString());
        if (start != null && end != null) {
          await _applyLeaveBalanceDelta(
            tenantId: tenantId,
            employeeId: leave['employee_id'].toString(),
            leaveType: (leave['type'] ?? '').toString(),
            leaveYear: int.tryParse(leave['leave_year']?.toString() ?? '') ?? start.year,
            daysDelta: _leaveDaysInclusive(start, end),
            requestId: requestId,
            leaveId: leaveId,
            actionType: 'approve',
          );
        }
        await _updateLeaveRequestStatus(tenantId: tenantId, leaveId: leaveId, status: 'approved');
      } else if (!isFinalApproval) {
        await _updateLeaveRequestStatus(tenantId: tenantId, leaveId: leaveId, status: 'pending');
      }
    }

    if (type == 'attendance_correction' && payload['record_id'] != null) {
      final updates = <String, dynamic>{
        if (payload['proposed_check_in'] != null) 'check_in': payload['proposed_check_in'],
        if (payload['proposed_check_out'] != null) 'check_out': payload['proposed_check_out'],
      };
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

  Future<void> reject(String requestId, {String? reason}) async {
    final tenantId = await _tenantId();
    final actor = await _currentActor();
    final req = await _client
        .from('approval_requests')
        .select('request_type, payload, current_approver_role')
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
      final leaveId = payload['leave_id'].toString();
      final leave = await _fetchLeaveForApproval(tenantId: tenantId, leaveId: leaveId);
      if (leave != null && (leave['status'] ?? '').toString() == 'approved') {
        final start = DateTime.tryParse(leave['start_date'].toString());
        final end = DateTime.tryParse(leave['end_date'].toString());
        if (start != null && end != null) {
          await _applyLeaveBalanceDelta(
            tenantId: tenantId,
            employeeId: leave['employee_id'].toString(),
            leaveType: (leave['type'] ?? '').toString(),
            leaveYear: int.tryParse(leave['leave_year']?.toString() ?? '') ?? start.year,
            daysDelta: -_leaveDaysInclusive(start, end),
            requestId: requestId,
            leaveId: leaveId,
            actionType: 'rollback_on_reject',
          );
        }
      }
      await _updateLeaveRequestStatus(tenantId: tenantId, leaveId: leaveId, status: 'rejected');
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
