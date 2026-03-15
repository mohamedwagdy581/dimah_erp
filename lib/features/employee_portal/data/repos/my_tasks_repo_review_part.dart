part of 'my_tasks_repo.dart';

mixin _MyTasksRepoReviewMixin on _MyTasksRepoHelpersMixin, _MyTasksRepoEventsMixin {
  Future<void> requestReview({
    required String taskId,
    required String note,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('employee_tasks').update({
      'employee_review_status': 'pending',
      'employee_review_note': note,
      'employee_review_requested_at': now,
      'manager_review_note': null,
      'manager_reviewed_at': null,
      'updated_at': now,
    }).eq('id', taskId);
    await appendTaskEvent(
      taskId: taskId,
      eventType: 'review_requested',
      note: note,
    );
  }
}
