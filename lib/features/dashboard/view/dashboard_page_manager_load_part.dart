part of 'dashboard_page.dart';

extension _ManagerDashboardLoadHelpers on _ManagerDashboardState {
  Future<_ManagerDashboardData> _loadData() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const _ManagerDashboardData();
    final me = await client.from('users').select('tenant_id').eq('id', uid).single();
    final tenantId = me['tenant_id'].toString();

    final managedDepartmentsRes = await client
        .from('departments')
        .select('id, name')
        .eq('tenant_id', tenantId)
        .eq('manager_id', widget.managerEmployeeId);
    final managedDepartments = (managedDepartmentsRes as List).cast<Map<String, dynamic>>();
    final managedDepartmentNames = managedDepartments
        .map((e) => (e['name'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();

    final members = await _loadManagedMembers(
      client: client,
      tenantId: tenantId,
      managedDepartmentIds: managedDepartments.map((e) => e['id'].toString()).toList(),
    );
    if (members.isEmpty) return const _ManagerDashboardData();

    final taskRows = await _loadManagerTasks(
      client: client,
      tenantId: tenantId,
      employeeIds: members.map((e) => e['id'].toString()).toList(),
    );
    await _attachTaskFiles(client: client, tenantId: tenantId, taskRows: taskRows);

    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final metrics = _buildMemberMetrics(members, taskRows, monthStart);
    final memberNameById = <String, String>{
      for (final member in members) member['id'].toString(): member['full_name']?.toString() ?? '-',
    };

    return _buildManagerDashboardData(
      taskRows: taskRows,
      metrics: metrics,
      managedDepartmentNames: managedDepartmentNames,
      memberNameById: memberNameById,
      monthStart: monthStart,
    );
  }

  Future<List<Map<String, dynamic>>> _loadManagedMembers({
    required SupabaseClient client,
    required String tenantId,
    required List<String> managedDepartmentIds,
  }) async {
    final directReportsRes = await client
        .from('employees')
        .select('id, full_name')
        .eq('tenant_id', tenantId)
        .eq('manager_id', widget.managerEmployeeId)
        .eq('status', 'active');
    final directReports = (directReportsRes as List).cast<Map<String, dynamic>>();

    final departmentReports = <Map<String, dynamic>>[];
    if (managedDepartmentIds.isNotEmpty) {
      final deptRes = await client
          .from('employees')
          .select('id, full_name')
          .eq('tenant_id', tenantId)
          .inFilter('department_id', managedDepartmentIds)
          .eq('status', 'active');
      departmentReports.addAll((deptRes as List).cast<Map<String, dynamic>>());
    }

    final byId = <String, Map<String, dynamic>>{};
    for (final employee in [...directReports, ...departmentReports]) {
      final id = employee['id'].toString();
      if (id == widget.managerEmployeeId) continue;
      byId[id] = employee;
    }

    final members = byId.values.toList()
      ..sort((a, b) => (a['full_name']?.toString() ?? '').compareTo(b['full_name']?.toString() ?? ''));
    return members;
  }

  Future<List<Map<String, dynamic>>> _loadManagerTasks({
    required SupabaseClient client,
    required String tenantId,
    required List<String> employeeIds,
  }) async {
    final rows = await client
        .from('employee_tasks')
        .select(
          'id, employee_id, status, progress, due_date, title, created_at, updated_at, '
          'completed_at, qa_status, weight, description, task_type, priority, estimate_hours, '
          'employee_review_status, employee_review_note, employee_review_requested_at, '
          'assignee_received_at, assignee_started_at, active_timer_started_at, '
          'manager_review_note, manager_reviewed_at',
        )
        .eq('tenant_id', tenantId)
        .inFilter('employee_id', employeeIds);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> _attachTaskFiles({
    required SupabaseClient client,
    required String tenantId,
    required List<Map<String, dynamic>> taskRows,
  }) async {
    final taskIds = taskRows.map((task) => task['id'].toString()).toList();
    final attachmentsByTask = <String, List<Map<String, dynamic>>>{};
    final loggedHoursByTask = <String, double>{};
    final logCountByTask = <String, int>{};
    if (taskIds.isNotEmpty) {
      try {
        final attachmentsRes = await client
            .from('employee_task_attachments')
            .select('task_id, file_name, file_url, mime_type, created_at')
            .eq('tenant_id', tenantId)
            .inFilter('task_id', taskIds)
            .order('created_at', ascending: false);
        for (final attachment in (attachmentsRes as List).cast<Map<String, dynamic>>()) {
          final taskId = attachment['task_id']?.toString() ?? '';
          if (taskId.isEmpty) continue;
          attachmentsByTask.putIfAbsent(taskId, () => []).add(attachment);
        }

        final timeLogsRes = await client
            .from('employee_task_time_logs')
            .select('task_id, hours')
            .eq('tenant_id', tenantId)
            .inFilter('task_id', taskIds)
            .order('created_at', ascending: false);
        for (final row in (timeLogsRes as List).cast<Map<String, dynamic>>()) {
          final taskId = row['task_id']?.toString() ?? '';
          if (taskId.isEmpty) continue;
          loggedHoursByTask[taskId] =
              (loggedHoursByTask[taskId] ?? 0) +
              ((row['hours'] as num?)?.toDouble() ?? 0);
          logCountByTask[taskId] = (logCountByTask[taskId] ?? 0) + 1;
        }
      } catch (_) {}
    }
    for (final task in taskRows) {
      final taskId = task['id']?.toString() ?? '';
      task['attachments'] = attachmentsByTask[taskId] ?? const [];
      task['logged_hours'] = loggedHoursByTask[taskId] ?? 0.0;
      task['time_log_count'] = logCountByTask[taskId] ?? 0;
    }
  }
}
