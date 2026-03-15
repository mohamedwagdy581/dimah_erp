part of 'employee_repo_impl.dart';

mixin _EmployeesRepoEmployeeLookupMixin on _EmployeesRepoEmployeesListMixin {
  @override
  Future<List<EmployeeLookup>> fetchEmployeeLookup({
    String? search,
    int limit = 200,
  }) async {
    final tenantId = await _tenantId();
    final actor = await _currentUserIdentity();
    final trimmedSearch = search?.trim();

    dynamic q = _client
        .from('employees')
        .select('id, full_name')
        .eq('tenant_id', tenantId)
        .order('full_name', ascending: true)
        .limit(limit);

    if (_isManagerRole(actor.role) &&
        actor.employeeId != null &&
        actor.employeeId!.trim().isNotEmpty) {
      final scopedIds = await _managerScopedEmployeeIds(
        tenantId: tenantId,
        managerEmployeeId: actor.employeeId!,
      );
      if (scopedIds.isEmpty) return const [];
      q = q.inFilter('id', scopedIds);
    }

    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      final escaped = trimmedSearch
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      q = q.or('full_name.ilike.%$escaped%');
    }

    final res = await q;
    return (res as List)
        .map((e) => EmployeeLookup.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
