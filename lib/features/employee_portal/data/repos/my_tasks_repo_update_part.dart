part of 'my_tasks_repo.dart';

mixin _MyTasksRepoUpdateMixin on _MyTasksRepoHelpersMixin, _MyTasksRepoEventsMixin {
  Future<void> updateTask({
    required String id,
    required String status,
    required int progress,
  }) async {
    final existing = await _client
        .from('employee_tasks')
        .select('status, progress, employee_id, active_timer_started_at')
        .eq('id', id)
        .maybeSingle();
    final oldStatus = (existing?['status'] ?? 'todo').toString();
    final oldProgress = (existing?['progress'] as num?)?.toInt() ?? 0;
    final clamped = progress.clamp(0, 100).toInt();
    final adjustedStatus = clamped >= 100 ? 'done' : status;
    final payload = <String, dynamic>{
      'status': adjustedStatus,
      'progress': clamped,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (oldStatus != 'done' && adjustedStatus == 'done') {
      final activeTimerStartedAt = DateTime.tryParse(
        existing?['active_timer_started_at']?.toString() ?? '',
      );
      if (activeTimerStartedAt != null) {
        final auth = await _currentUserTenant();
        if (auth != null) {
          final now = DateTime.now();
          final hours = (now.difference(activeTimerStartedAt).inMinutes / 60.0)
              .clamp(0.01, 24.0);
          await _client.from('employee_task_time_logs').insert({
            'tenant_id': auth['tenant_id'],
            'task_id': id,
            'employee_id': existing?['employee_id']?.toString() ?? '',
            'logged_by_user_id': auth['user_id'],
            'hours': double.parse(hours.toStringAsFixed(2)),
            'note': 'Auto logged from active timer on task completion',
          });
          await appendTaskEvent(
            taskId: id,
            eventType: 'timer_stopped',
            payload: {'hours': double.parse(hours.toStringAsFixed(2))},
          );
        }
      }
      payload['completed_at'] = DateTime.now().toIso8601String();
      payload['qa_status'] = 'pending';
      payload['active_timer_started_at'] = null;
    } else if (oldStatus == 'done' && adjustedStatus != 'done') {
      payload['completed_at'] = null;
    }
    if (oldStatus == 'todo' && adjustedStatus != 'todo') {
      payload['assignee_received_at'] = DateTime.now().toIso8601String();
    }
    if (oldStatus != 'in_progress' && adjustedStatus == 'in_progress') {
      payload['assignee_started_at'] = DateTime.now().toIso8601String();
    }
    await _client.from('employee_tasks').update(payload).eq('id', id);
    await appendTaskEvent(
      taskId: id,
      eventType: oldStatus != adjustedStatus ? 'status_changed' : 'progress_updated',
      payload: {
        'old_status': oldStatus,
        'new_status': adjustedStatus,
        'old_progress': oldProgress,
        'new_progress': clamped,
      },
    );
  }
}
