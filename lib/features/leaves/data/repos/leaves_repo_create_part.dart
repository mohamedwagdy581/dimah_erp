part of 'leaves_repo_impl.dart';

mixin _LeavesRepoCreateMixin on _LeavesRepoFetchMixin {
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
    );

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
    final currentApproverRole = await _resolveLeaveApproverRole(
      tenantId: tenantId,
      requesterRole: identity.role,
      employeeId: employeeId,
    );

    await _client.from('approval_requests').insert({
      'tenant_id': tenantId,
      'request_type': 'leave',
      'employee_id': employeeId,
      'status': 'pending',
      'requested_by_role': identity.role,
      'current_approver_role': currentApproverRole,
      'payload': {
        'leave_id': leaveId,
        'type': type,
        'start_date': _toDateOnly(startDate),
        'end_date': _toDateOnly(endDate),
        'leave_year': leaveYear,
        'notes': _normalizeOptionalText(notes),
        'file_url': _normalizeOptionalText(fileUrl),
      },
    });
  }
}
