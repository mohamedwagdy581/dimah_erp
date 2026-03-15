part of 'approvals_repo_impl.dart';

mixin _ApprovalsRepoLeaveHelpersMixin on _ApprovalsRepoHelpersMixin {
  Future<Map<String, dynamic>?> _fetchLeaveForApproval({
    required String tenantId,
    required String leaveId,
  }) async {
    try {
      return await _client
          .from('leave_requests')
          .select('employee_id, type, start_date, end_date, leave_year, status')
          .eq('tenant_id', tenantId)
          .eq('id', leaveId)
          .maybeSingle();
    } catch (_) {
      return _client
          .from('leave_requests')
          .select('employee_id, type, start_date, end_date, status')
          .eq('tenant_id', tenantId)
          .eq('id', leaveId)
          .maybeSingle();
    }
  }

  Future<void> _updateLeaveRequestStatus({
    required String tenantId,
    required String leaveId,
    required String status,
  }) {
    return _client
        .from('leave_requests')
        .update({'status': status})
        .eq('tenant_id', tenantId)
        .eq('id', leaveId);
  }
}
