part of 'attendance_repo_impl.dart';

mixin _AttendanceRepoHelpersMixin on _AttendanceRepoSessionMixin {
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

    final departmentIds = <String>[];
    if (managedDepartmentIds.isNotEmpty) {
      final deptRes = await _client
          .from('employees')
          .select('id')
          .eq('tenant_id', tenantId)
          .inFilter('department_id', managedDepartmentIds);
      departmentIds.addAll((deptRes as List).map((e) => e['id'].toString()));
    }

    final all = {...directIds, ...departmentIds};
    all.remove(managerEmployeeId);
    return all.toList();
  }

  String? _normalizeOptionalText(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
