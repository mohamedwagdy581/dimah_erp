part of 'leaves_repo_impl.dart';

mixin _LeavesRepoFetchMixin on _LeavesRepoHelpersMixin {
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
    final trimmedSearch = search?.trim();

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

    if (status != null && status.trim().isNotEmpty) listQ = listQ.eq('status', status);
    if (type != null && type.trim().isNotEmpty) listQ = listQ.eq('type', type);
    if (employeeId != null && employeeId.trim().isNotEmpty) {
      listQ = listQ.eq('employee_id', employeeId);
    }
    if (startDate != null) listQ = listQ.gte('start_date', _toDateOnly(startDate));
    if (endDate != null) listQ = listQ.lte('end_date', _toDateOnly(endDate));
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      final escaped = trimmedSearch.replaceAll('%', r'\%').replaceAll('_', r'\_');
      listQ = listQ.or('employee.full_name.ilike.%$escaped%');
    }

    final listRes = await listQ.order(sortBy, ascending: ascending).range(from, to);
    final items = (listRes as List)
        .map((e) => LeaveRequest.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client.from('leave_requests').select('id').eq('tenant_id', tenantId);

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

    if (status != null && status.trim().isNotEmpty) countQ = countQ.eq('status', status);
    if (type != null && type.trim().isNotEmpty) countQ = countQ.eq('type', type);
    if (employeeId != null && employeeId.trim().isNotEmpty) {
      countQ = countQ.eq('employee_id', employeeId);
    }
    if (startDate != null) countQ = countQ.gte('start_date', _toDateOnly(startDate));
    if (endDate != null) countQ = countQ.lte('end_date', _toDateOnly(endDate));
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      final escaped = trimmedSearch.replaceAll('%', r'\%').replaceAll('_', r'\_');
      countQ = countQ.or('employee.full_name.ilike.%$escaped%');
    }

    final total = (await countQ as List).length;
    return (items: items, total: total);
  }
}
