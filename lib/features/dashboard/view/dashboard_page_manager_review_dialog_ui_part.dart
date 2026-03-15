part of 'dashboard_page.dart';

extension _ManagerDashboardReviewDialogHelpers on _ManagerDashboardState {
  Future<void> _openTaskReviewDialog(
    Map<String, dynamic> task, {
    required bool approved,
  }) async {
    final t = AppLocalizations.of(context)!;
    final title = TextEditingController(text: task['title']?.toString() ?? '');
    final description = TextEditingController(text: task['description']?.toString() ?? '');
    final estimate = TextEditingController(
      text: ((task['estimate_hours'] as num?)?.toStringAsFixed(0) ?? '8'),
    );
    final note = TextEditingController();
    var priority = (task['priority'] ?? 'medium').toString();
    var taskType = (task['task_type'] ?? 'general').toString();
    DateTime? dueDate = DateTime.tryParse(task['due_date']?.toString() ?? '');

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: Text(approved ? t.approveAndUpdate : t.rejectReviewRequest),
            content: _ManagerReviewDialogContent(
              approved: approved,
              task: task,
              t: t,
              title: title,
              description: description,
              estimate: estimate,
              note: note,
              priority: priority,
              taskType: taskType,
              dueDate: dueDate,
              visibleTaskCatalog: _visibleTaskCatalog,
              taskTypeLabelBuilder: _taskTypeLabel,
              onPriorityChanged: (value) => setLocalState(() => priority = value),
              onTaskTypeChanged: (value) => setLocalState(() => taskType = value),
              onDueDateChanged: (value) => setLocalState(() => dueDate = value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(approved ? t.approveAndUpdate : t.reject),
              ),
            ],
          ),
        ),
      );

      await _submitTaskReviewDialog(
        task: task,
        approved: approved,
        t: t,
        title: title,
        description: description,
        estimate: estimate,
        note: note,
        priority: priority,
        taskType: taskType,
        dueDate: dueDate,
        saved: saved == true,
      );
    } finally {
      title.dispose();
      description.dispose();
      estimate.dispose();
      note.dispose();
    }
  }
}
