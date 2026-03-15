part of 'dashboard_page.dart';

extension _ManagerDashboardTimelineDataHelpers on _ManagerDashboardState {
  Future<Map<String, List<Map<String, dynamic>>>> _loadTimelineEventsByTask({
    required SupabaseClient client,
    required String tenantId,
    required List<String> taskIds,
  }) async {
    final eventsByTask = <String, List<Map<String, dynamic>>>{};
    if (taskIds.isEmpty) return eventsByTask;
    try {
      final eventsRes = await client
          .from('employee_task_events')
          .select('task_id, event_type, event_note, created_at, event_payload')
          .eq('tenant_id', tenantId)
          .inFilter('task_id', taskIds)
          .order('created_at', ascending: false);
      for (final event in (eventsRes as List).cast<Map<String, dynamic>>()) {
        final taskId = event['task_id']?.toString() ?? '';
        if (taskId.isEmpty) continue;
        eventsByTask.putIfAbsent(taskId, () => []).add(event);
      }
    } catch (_) {}
    return eventsByTask;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadTimelineAttachmentsByTask({
    required SupabaseClient client,
    required String tenantId,
    required List<String> taskIds,
  }) async {
    final attachmentsByTask = <String, List<Map<String, dynamic>>>{};
    if (taskIds.isEmpty) return attachmentsByTask;
    try {
      final attachmentsRes = await client
          .from('employee_task_attachments')
          .select('task_id, file_name, file_url')
          .eq('tenant_id', tenantId)
          .inFilter('task_id', taskIds)
          .order('created_at', ascending: false);
      for (final row in (attachmentsRes as List).cast<Map<String, dynamic>>()) {
        final taskId = row['task_id']?.toString() ?? '';
        if (taskId.isEmpty) continue;
        attachmentsByTask.putIfAbsent(taskId, () => []).add(row);
      }
    } catch (_) {}
    return attachmentsByTask;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadTimelineTimeLogsByTask({
    required SupabaseClient client,
    required String tenantId,
    required List<String> taskIds,
  }) async {
    final logsByTask = <String, List<Map<String, dynamic>>>{};
    if (taskIds.isEmpty) return logsByTask;
    try {
      final logsRes = await client
          .from('employee_task_time_logs')
          .select('task_id, hours, note, created_at')
          .eq('tenant_id', tenantId)
          .inFilter('task_id', taskIds)
          .order('created_at', ascending: false);
      for (final row in (logsRes as List).cast<Map<String, dynamic>>()) {
        final taskId = row['task_id']?.toString() ?? '';
        if (taskId.isEmpty) continue;
        logsByTask.putIfAbsent(taskId, () => []).add(row);
      }
    } catch (_) {}
    return logsByTask;
  }
}
