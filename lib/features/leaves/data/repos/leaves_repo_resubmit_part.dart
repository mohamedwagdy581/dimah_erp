part of 'leaves_repo_impl.dart';

mixin _LeavesRepoResubmitMixin on _LeavesRepoCreateMixin {
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
    final leaveYear = startDate.year;

    await _validateLeaveBalance(
      employeeId: employeeId,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );

    final leavePayload = _leavePayload(
      tenantId: tenantId,
      employeeId: employeeId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      leaveYear: leaveYear,
      fileUrl: fileUrl,
      notes: notes,
    )
      ..remove('tenant_id')
      ..remove('employee_id');

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
      'notes': _normalizeOptionalText(notes),
      'file_url': _normalizeOptionalText(fileUrl),
    };

    Map<String, dynamic>? latest;
    try {
      latest = await _client
          .from('approval_requests')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('request_type', 'leave')
          .eq('employee_id', employeeId)
          .contains('payload', {'leave_id': leaveId})
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (_) {
      latest = null;
    }

    final currentApproverRole = await _resolveLeaveApproverRole(
      tenantId: tenantId,
      requesterRole: identity.role,
      employeeId: employeeId,
    );

    if (latest != null) {
      await _client
          .from('approval_requests')
          .update({
            'status': 'pending',
            'reject_reason': null,
            'requested_by_role': identity.role,
            'current_approver_role': currentApproverRole,
            'payload': approvalPayload,
          })
          .eq('tenant_id', tenantId)
          .eq('id', latest['id'].toString());
      return;
    }

    await _client.from('approval_requests').insert({
      'tenant_id': tenantId,
      'request_type': 'leave',
      'employee_id': employeeId,
      'status': 'pending',
      'requested_by_role': identity.role,
      'current_approver_role': currentApproverRole,
      'payload': approvalPayload,
    });
  }
}
