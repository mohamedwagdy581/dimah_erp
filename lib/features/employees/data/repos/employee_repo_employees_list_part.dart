part of 'employee_repo_impl.dart';

mixin _EmployeesRepoEmployeesListMixin on _EmployeesRepoAuthMixin {
  @override
  Future<({List<Employee> items, int total})> fetchEmployees({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? actorRole,
    String? actorEmployeeId,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final trimmedSearch = search?.trim();

    dynamic listQ = _client
        .from('employees')
        .select(
          'id, tenant_id, full_name, email, phone, status, hire_date, created_at, '
          'department_id, job_title_id, '
          'department:departments!employees_department_id_fkey(name), '
          'job_title:job_titles(name)',
        )
        .eq('tenant_id', tenantId);

    if (actorRole == 'manager' &&
        actorEmployeeId != null &&
        actorEmployeeId.trim().isNotEmpty) {
      final scopedIds = await _managerScopedEmployeeIds(
        tenantId: tenantId,
        managerEmployeeId: actorEmployeeId,
      );
      if (scopedIds.isEmpty) {
        return (items: const <Employee>[], total: 0);
      }
      listQ = listQ.inFilter('id', scopedIds);
    }

    if (status != null && status.trim().isNotEmpty) {
      listQ = listQ.eq('status', status);
    }

    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      final escaped = trimmedSearch
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      listQ = listQ.or(
        'full_name.ilike.%$escaped%,email.ilike.%$escaped%,phone.ilike.%$escaped%',
      );
    }

    final listRes = await listQ.order(sortBy, ascending: ascending).range(from, to);
    final items = (listRes as List)
        .map((e) => Employee.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client.from('employees').select('id').eq('tenant_id', tenantId);

    if (actorRole == 'manager' &&
        actorEmployeeId != null &&
        actorEmployeeId.trim().isNotEmpty) {
      final scopedIds = await _managerScopedEmployeeIds(
        tenantId: tenantId,
        managerEmployeeId: actorEmployeeId,
      );
      if (scopedIds.isEmpty) {
        return (items: items, total: 0);
      }
      countQ = countQ.inFilter('id', scopedIds);
    }

    if (status != null && status.trim().isNotEmpty) {
      countQ = countQ.eq('status', status);
    }

    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      final escaped = trimmedSearch
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      countQ = countQ.or(
        'full_name.ilike.%$escaped%,email.ilike.%$escaped%,phone.ilike.%$escaped%',
      );
    }

    final total = (await countQ as List).length;
    return (items: items, total: total);
  }

  Future<List<String>> _managerScopedEmployeeIds({
    required String tenantId,
    required String managerEmployeeId,
  }) async {
    final managedDepartmentsRes = await _client
        .from('departments')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final managedDepartmentIds = (managedDepartmentsRes as List)
        .map((e) => e['id'].toString())
        .toList();

    final directReportsRes = await _client
        .from('employees')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final directReportIds = (directReportsRes as List)
        .map((e) => e['id'].toString())
        .toList();

    final deptEmployeesIds = <String>[];
    if (managedDepartmentIds.isNotEmpty) {
      final deptEmployeesRes = await _client
          .from('employees')
          .select('id')
          .eq('tenant_id', tenantId)
          .inFilter('department_id', managedDepartmentIds);
      deptEmployeesIds.addAll(
        (deptEmployeesRes as List).map((e) => e['id'].toString()),
      );
    }

    final unique = {...directReportIds, ...deptEmployeesIds};
    unique.remove(managerEmployeeId);
    return unique.toList();
  }
}
