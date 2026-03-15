part of 'my_tasks_repo.dart';

mixin _MyTasksRepoEventsMixin on _MyTasksRepoHelpersMixin {
  Future<void> appendTaskEvent({
    required String taskId,
    required String eventType,
    String? note,
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      final auth = await _currentUserTenant();
      if (auth == null) {
        return;
      }
      await _client.from('employee_task_events').insert({
        'tenant_id': auth['tenant_id'].toString(),
        'task_id': taskId,
        'event_type': eventType,
        'event_note': note,
        'event_payload': payload,
        'created_by_user_id': auth['user_id'].toString(),
      });
    } catch (_) {}
  }
}
