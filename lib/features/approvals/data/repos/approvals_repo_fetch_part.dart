part of 'approvals_repo_impl.dart';

mixin _ApprovalsRepoFetchMixin on _ApprovalsRepoHelpersMixin {
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
    final normalizedStatus = status?.trim();

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
      if (normalizedStatus == 'pending_assigned') {
        listQ = listQ.eq('status', 'pending');
        listQ = listQ.eq('current_approver_role', actor.role);
      }
    }

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

    final listRes = await listQ
        .order(sortBy, ascending: ascending)
        .range(from, to);
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
      if (normalizedStatus == 'pending_assigned') {
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

    final total = (await countQ as List).length;
    return (items: items, total: total);
  }
}
