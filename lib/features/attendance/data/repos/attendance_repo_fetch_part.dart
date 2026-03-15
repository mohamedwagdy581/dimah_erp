part of 'attendance_repo_impl.dart';

mixin _AttendanceRepoFetchMixin on _AttendanceRepoHelpersMixin {
  Future<({List<AttendanceRecord> items, int total})> fetchAttendance({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    DateTime? date,
    String? employeeId,
    String sortBy = 'date',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final actor = await _currentUserIdentity();
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final trimmedSearch = search?.trim();

    dynamic listQ = _client
        .from('attendance_records')
        .select(
          'id, tenant_id, employee_id, date, status, check_in, check_out, notes, created_at, '
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
        return (items: const <AttendanceRecord>[], total: 0);
      }
      listQ = listQ.inFilter('employee_id', subordinateIds);
    }

    if (status != null && status.trim().isNotEmpty) listQ = listQ.eq('status', status);
    if (date != null) listQ = listQ.eq('date', _toDateOnly(date));
    if (employeeId != null && employeeId.trim().isNotEmpty) {
      listQ = listQ.eq('employee_id', employeeId);
    }
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      final escaped = trimmedSearch.replaceAll('%', r'\%').replaceAll('_', r'\_');
      listQ = listQ.or('employee.full_name.ilike.%$escaped%');
    }

    final listRes = await listQ.order(sortBy, ascending: ascending).range(from, to);
    final items = (listRes as List)
        .map((e) => AttendanceRecord.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('attendance_records')
        .select('id')
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
        return (items: items, total: 0);
      }
      countQ = countQ.inFilter('employee_id', subordinateIds);
    }

    if (status != null && status.trim().isNotEmpty) countQ = countQ.eq('status', status);
    if (date != null) countQ = countQ.eq('date', _toDateOnly(date));
    if (employeeId != null && employeeId.trim().isNotEmpty) {
      countQ = countQ.eq('employee_id', employeeId);
    }
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      final escaped = trimmedSearch.replaceAll('%', r'\%').replaceAll('_', r'\_');
      countQ = countQ.or('employee.full_name.ilike.%$escaped%');
    }

    final total = (await countQ as List).length;
    return (items: items, total: total);
  }
}
