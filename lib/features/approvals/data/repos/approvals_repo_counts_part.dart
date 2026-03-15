part of 'approvals_repo_impl.dart';

mixin _ApprovalsRepoCountsMixin on _ApprovalsRepoFetchMixin {
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

    return (await q as List).length;
  }

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
}
