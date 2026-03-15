part of 'approvals_repo_impl.dart';

mixin _ApprovalsRepoHelpersMixin on _ApprovalsRepoBalanceHelpersMixin {
  Future<List<String>> _subordinateEmployeeIds({
    required String tenantId,
    required String managerEmployeeId,
  }) async {
    final directRes = await _client
        .from('employees')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final directIds = (directRes as List).map((e) => e['id'].toString()).toList();

    final managedDepartmentsRes = await _client
        .from('departments')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final managedDepartmentIds = (managedDepartmentsRes as List)
        .map((e) => e['id'].toString())
        .toList();

    if (managedDepartmentIds.isEmpty) {
      final all = {...directIds};
      all.remove(managerEmployeeId);
      return all.toList();
    }

    final deptRes = await _client
        .from('employees')
        .select('id')
        .eq('tenant_id', tenantId)
        .inFilter('department_id', managedDepartmentIds);
    final all = {
      ...directIds,
      ...(deptRes as List).map((e) => e['id'].toString()),
    };
    all.remove(managerEmployeeId);
    return all.toList();
  }
}
