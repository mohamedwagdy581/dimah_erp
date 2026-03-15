part of 'dashboard_page.dart';

extension _ManagerDashboardReviewDialogSubmitHelpers on _ManagerDashboardState {
  Future<void> _submitTaskReviewDialog({
    required Map<String, dynamic> task,
    required bool approved,
    required AppLocalizations t,
    required TextEditingController title,
    required TextEditingController description,
    required TextEditingController estimate,
    required TextEditingController note,
    required String priority,
    required String taskType,
    required DateTime? dueDate,
    required bool saved,
  }) async {
    if (!saved) return;
    if (note.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.reviewNoteRequired)),
      );
      return;
    }

    final payload = <String, dynamic>{
      'employee_review_status': approved ? 'approved' : 'rejected',
      'manager_review_note': note.text.trim(),
      'manager_reviewed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (approved) {
      final parsedEstimate = double.tryParse(estimate.text.trim());
      if (parsedEstimate == null || parsedEstimate <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.invalidEstimateHours)),
        );
        return;
      }
      payload.addAll({
        'title': title.text.trim().isEmpty ? task['title'] : title.text.trim(),
        'description': description.text.trim().isEmpty ? null : description.text.trim(),
        'estimate_hours': parsedEstimate,
        'priority': priority,
        'task_type': taskType,
        'due_date': dueDate == null
            ? null
            : '${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
      });
    }

    await Supabase.instance.client.from('employee_tasks').update(payload).eq('id', task['id']);
    await _appendTaskEvent(
      taskId: task['id'].toString(),
      eventType: approved ? 'review_approved' : 'review_rejected',
      note: note.text.trim(),
      payload: approved ? {'task_type': taskType, 'priority': priority} : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved ? t.reviewApprovedAndTaskUpdated : t.reviewRejectedAndReturned,
        ),
      ),
    );
    setState(() {
      _future = _loadData();
    });
  }
}
