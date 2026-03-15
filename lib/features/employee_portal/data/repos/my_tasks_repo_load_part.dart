part of 'my_tasks_repo.dart';

mixin _MyTasksRepoLoadMixin on _MyTasksRepoHelpersMixin {
  Future<List<Map<String, dynamic>>> loadTasks(String employeeId) async {
    final auth = await _currentUserTenant();
    if (auth == null) {
      return const [];
    }
    final tenantId = auth['tenant_id'].toString();
    final res = await _client
        .from('employee_tasks')
        .select(
          'id, title, description, task_type, priority, estimate_hours, status, progress, due_date, '
          'created_at, updated_at, assignee_received_at, assignee_started_at, completed_at, '
          'active_timer_started_at, '
          'employee_review_status, employee_review_note, employee_review_requested_at, '
          'manager_review_note, manager_reviewed_at, qa_status',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(60);
    final tasks = (res as List).cast<Map<String, dynamic>>();
    final taskIds = tasks.map((task) => task['id'].toString()).toList();
    if (taskIds.isEmpty) {
      return tasks;
    }

    final attachmentsRes = await _client
        .from('employee_task_attachments')
        .select('id, task_id, file_name, file_url, mime_type, created_at')
        .eq('tenant_id', tenantId)
        .inFilter('task_id', taskIds)
        .order('created_at', ascending: false);
    final timeLogsRes = await _client
        .from('employee_task_time_logs')
        .select('task_id, hours')
        .eq('tenant_id', tenantId)
        .inFilter('task_id', taskIds)
        .order('created_at', ascending: false);
    final grouped = <String, List<Map<String, dynamic>>>{};
    final loggedHoursByTask = <String, double>{};
    final logCountByTask = <String, int>{};
    for (final row in (attachmentsRes as List).cast<Map<String, dynamic>>()) {
      final taskId = row['task_id']?.toString() ?? '';
      if (taskId.isEmpty) {
        continue;
      }
      grouped.putIfAbsent(taskId, () => []).add(row);
    }
    for (final row in (timeLogsRes as List).cast<Map<String, dynamic>>()) {
      final taskId = row['task_id']?.toString() ?? '';
      if (taskId.isEmpty) {
        continue;
      }
      loggedHoursByTask[taskId] =
          (loggedHoursByTask[taskId] ?? 0) +
          ((row['hours'] as num?)?.toDouble() ?? 0);
      logCountByTask[taskId] = (logCountByTask[taskId] ?? 0) + 1;
    }
    for (final task in tasks) {
      final taskId = task['id']?.toString() ?? '';
      task['attachments'] = grouped[taskId] ?? const [];
      task['logged_hours'] = loggedHoursByTask[taskId] ?? 0.0;
      task['time_log_count'] = logCountByTask[taskId] ?? 0;
    }
    return tasks;
  }
}
