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

    // Filter Logic
    if (employeeId == null || employeeId.trim().isEmpty) {
      // 1. If user is a Manager, show subordinates' requests
      if (actor.role == 'manager') {
        final managerEmpId = actor.employeeId;
        if (managerEmpId != null && managerEmpId.isNotEmpty) {
           final subordinates = await _subordinateEmployeeIds(
            tenantId: tenantId,
            managerEmployeeId: managerEmpId,
          );
          if (subordinates.isNotEmpty) {
            listQ = listQ.inFilter('employee_id', subordinates);
          }
        }
      }
      
      // 2. IMPORTANT: If user is Accountant or Admin, show requests assigned to their role (like Payroll)
      if (actor.role == 'accountant' ||
          actor.role == 'admin' ||
          actor.role == 'finance_manager') {
         // This allows accountant/admin to see payroll runs even if not their subordinates
         if (normalizedStatus == 'pending_assigned') {
            listQ = listQ.or('current_approver_role.eq.${actor.role},status.eq.pending');
         }
      } else if (normalizedStatus == 'pending_assigned') {
        listQ = listQ.eq('status', 'pending');
        listQ = listQ.eq('current_approver_role', actor.role);
      }
    }

    if (normalizedStatus != null && normalizedStatus.isNotEmpty && normalizedStatus != 'pending_assigned') {
      listQ = listQ.eq('status', normalizedStatus);
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

    // Re-run count with same filters (Simplified for now)
    final total = items.length; // You might want a proper count query here later

    return (items: items, total: total);
  }
}
