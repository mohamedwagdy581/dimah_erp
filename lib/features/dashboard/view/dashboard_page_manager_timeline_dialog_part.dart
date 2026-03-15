part of 'dashboard_page.dart';

extension _ManagerDashboardTimelineDialogHelpers on _ManagerDashboardState {
  Future<void> _showMemberTaskTimeline({
    required String employeeId,
    required String employeeName,
  }) async {
    final t = AppLocalizations.of(context)!;
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    final me = await client.from('users').select('tenant_id').eq('id', uid).single();
    final tenantId = me['tenant_id'].toString();

    List<dynamic> tasksRes;
    try {
      tasksRes = await client
          .from('employee_tasks')
          .select(
            'id, title, status, progress, created_at, updated_at, due_date, '
            'assigned_by_employee_id, assignee_received_at, assignee_started_at, active_timer_started_at',
          )
          .eq('tenant_id', tenantId)
          .eq('employee_id', employeeId)
          .order('updated_at', ascending: false)
          .limit(20);
    } catch (_) {
      tasksRes = await client
          .from('employee_tasks')
          .select('id, title, status, progress, created_at, updated_at, due_date, assigned_by_employee_id, active_timer_started_at')
          .eq('tenant_id', tenantId)
          .eq('employee_id', employeeId)
          .order('updated_at', ascending: false)
          .limit(20);
    }
    final tasks = tasksRes.cast<Map<String, dynamic>>();
    final taskIds = tasks.map((task) => task['id'].toString()).toList();
    final eventsByTask = await _loadTimelineEventsByTask(client: client, tenantId: tenantId, taskIds: taskIds);
    final attachmentsByTask = await _loadTimelineAttachmentsByTask(client: client, tenantId: tenantId, taskIds: taskIds);
    final timeLogsByTask = await _loadTimelineTimeLogsByTask(client: client, tenantId: tenantId, taskIds: taskIds);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${t.taskTimeline}: $employeeName'),
        content: SizedBox(
          width: 780,
          height: 520,
          child: tasks.isEmpty
              ? Center(child: Text(t.noTasksAssignedYet))
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final taskId = task['id']?.toString() ?? '';
                    return _ManagerTimelineTaskCard(
                      task: task,
                      events: eventsByTask[taskId] ?? const [],
                      attachments: attachmentsByTask[taskId] ?? const [],
                      timeLogs: timeLogsByTask[taskId] ?? const [],
                      t: t,
                      onOpenExternalUrl: _openExternalUrl,
                      fmtTs: _fmtTs,
                      taskEventLabel: _taskEventLabel,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }
}

class _ManagerTimelineTaskCard extends StatelessWidget {
  const _ManagerTimelineTaskCard({
    required this.task,
    required this.events,
    required this.attachments,
    required this.timeLogs,
    required this.t,
    required this.onOpenExternalUrl,
    required this.fmtTs,
    required this.taskEventLabel,
  });

  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> timeLogs;
  final AppLocalizations t;
  final ValueChanged<String> onOpenExternalUrl;
  final String Function(dynamic raw) fmtTs;
  final String Function(AppLocalizations t, String raw) taskEventLabel;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['title']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Text('${t.created}: ${fmtTs(task['created_at'])}'),
            Text('${t.assignedToEmployeeAt}: ${fmtTs(task['created_at'])}'),
            Text('${t.employeeReceivedAt}: ${fmtTs(task['assignee_received_at'])}'),
            Text('${t.employeeStartedAt}: ${fmtTs(task['assignee_started_at'])}'),
            if ((task['active_timer_started_at'] ?? '').toString().isNotEmpty)
              Text(
                isArabic
                    ? 'المؤقت يعمل منذ: ${fmtTs(task['active_timer_started_at'])}'
                    : 'Timer running since: ${fmtTs(task['active_timer_started_at'])}',
              ),
            Text('${t.lastUpdateAt}: ${fmtTs(task['updated_at'])}'),
            if (timeLogs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                isArabic ? 'سجل الساعات' : 'Time Logs',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...timeLogs.take(8).map((log) {
                final note = (log['note'] ?? '').toString().trim();
                final hours = ((log['hours'] as num?)?.toDouble() ?? 0).toStringAsFixed(1);
                return Text(
                  '- $hours h - ${fmtTs(log['created_at'])}${note.isEmpty ? '' : ' ($note)'}',
                );
              }),
            ],
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(t.attachments, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attachments.map((attachment) {
                  return ActionChip(
                    avatar: const Icon(Icons.attach_file, size: 16),
                    label: Text(attachment['file_name']?.toString() ?? '-'),
                    onPressed: () => onOpenExternalUrl(attachment['file_url']?.toString() ?? ''),
                  );
                }).toList(),
              ),
            ],
            if (events.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(t.updatesTimeline, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...events.take(6).map((event) {
                final note = (event['event_note'] ?? '').toString().trim();
                return Text(
                  '- ${taskEventLabel(t, (event['event_type'] ?? '').toString())} - ${fmtTs(event['created_at'])}${note.isEmpty ? '' : ' ($note)'}',
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
