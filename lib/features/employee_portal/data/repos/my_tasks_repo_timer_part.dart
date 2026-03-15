part of 'my_tasks_repo.dart';

mixin _MyTasksRepoTimerMixin on _MyTasksRepoHelpersMixin, _MyTasksRepoEventsMixin {
  Future<void> startTimer({
    required String taskId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await _client
        .from('employee_tasks')
        .select('status, assignee_received_at, assignee_started_at, active_timer_started_at')
        .eq('id', taskId)
        .maybeSingle();

    if ((existing?['active_timer_started_at'] ?? '').toString().isNotEmpty) {
      return;
    }

    final status = (existing?['status'] ?? 'todo').toString();
    final payload = <String, dynamic>{
      'active_timer_started_at': now,
      'updated_at': now,
    };
    if ((existing?['assignee_received_at'] ?? '').toString().isEmpty) {
      payload['assignee_received_at'] = now;
    }
    if ((existing?['assignee_started_at'] ?? '').toString().isEmpty) {
      payload['assignee_started_at'] = now;
    }
    if (status == 'todo') {
      payload['status'] = 'in_progress';
    }

    await _client.from('employee_tasks').update(payload).eq('id', taskId);
    await appendTaskEvent(taskId: taskId, eventType: 'timer_started');
  }

  Future<double> stopTimer({
    required String taskId,
    required String employeeId,
    String? note,
  }) async {
    final auth = await _currentUserTenant();
    if (auth == null) {
      throw Exception('Not authenticated');
    }

    final existing = await _client
        .from('employee_tasks')
        .select('active_timer_started_at')
        .eq('id', taskId)
        .maybeSingle();
    final startedAt = DateTime.tryParse(
      existing?['active_timer_started_at']?.toString() ?? '',
    );
    if (startedAt == null) {
      return 0;
    }

    final now = DateTime.now();
    final hours = now.difference(startedAt).inMinutes / 60.0;
    final normalizedHours = double.parse(hours.toStringAsFixed(2));
    await _client.from('employee_task_time_logs').insert({
      'tenant_id': auth['tenant_id'],
      'task_id': taskId,
      'employee_id': employeeId,
      'logged_by_user_id': auth['user_id'],
      'hours': normalizedHours <= 0 ? 0.01 : normalizedHours,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
    });
    await _client.from('employee_tasks').update({
      'active_timer_started_at': null,
      'updated_at': now.toIso8601String(),
    }).eq('id', taskId);

    await appendTaskEvent(
      taskId: taskId,
      eventType: 'timer_stopped',
      note: note,
      payload: {'hours': normalizedHours <= 0 ? 0.01 : normalizedHours},
    );
    return normalizedHours <= 0 ? 0.01 : normalizedHours;
  }
}
