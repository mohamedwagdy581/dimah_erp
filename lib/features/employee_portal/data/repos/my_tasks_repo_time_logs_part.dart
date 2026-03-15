part of 'my_tasks_repo.dart';

mixin _MyTasksRepoTimeLogsMixin on _MyTasksRepoHelpersMixin, _MyTasksRepoEventsMixin {
  Future<void> logHours({
    required String taskId,
    required String employeeId,
    required double hours,
    String? note,
  }) async {
    final auth = await _currentUserTenant();
    if (auth == null) {
      throw Exception('Not authenticated');
    }

    final normalizedHours = double.parse(hours.toStringAsFixed(2));
    final now = DateTime.now().toIso8601String();
    await _client.from('employee_task_time_logs').insert({
      'tenant_id': auth['tenant_id'],
      'task_id': taskId,
      'employee_id': employeeId,
      'logged_by_user_id': auth['user_id'],
      'hours': normalizedHours,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
    });

    final existing = await _client
        .from('employee_tasks')
        .select('status, assignee_received_at, assignee_started_at')
        .eq('id', taskId)
        .maybeSingle();
    final status = (existing?['status'] ?? 'todo').toString();
    final payload = <String, dynamic>{
      'updated_at': now,
    };
    if ((existing?['assignee_received_at'] ?? '').toString().isEmpty) {
      payload['assignee_received_at'] = now;
    }
    if ((existing?['assignee_started_at'] ?? '').toString().isEmpty &&
        status != 'done') {
      payload['assignee_started_at'] = now;
    }
    if (status == 'todo') {
      payload['status'] = 'in_progress';
    }
    await _client.from('employee_tasks').update(payload).eq('id', taskId);

    await appendTaskEvent(
      taskId: taskId,
      eventType: 'time_logged',
      note: note,
      payload: {'hours': normalizedHours},
    );
  }
}
