part of 'dashboard_page.dart';

extension _ManagerDashboardDialogHelpers on _ManagerDashboardState {
  Future<void> _openQaDecisionDialog(
    Map<String, dynamic> task, {
    required String decision,
  }) async {
    final t = AppLocalizations.of(context)!;
    final note = TextEditingController();
    try {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            switch (decision) {
              'accepted' => t.qaApprove,
              'rework' => t.qaSendRework,
              _ => t.qaReject,
            },
          ),
          content: TextField(
            controller: note,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: t.managerResponseNote,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.save),
            ),
          ],
        ),
      );
      if (shouldProceed != true) return;
      if (decision != 'accepted' && note.text.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.reviewNoteRequired)));
        return;
      }
      final payload = <String, dynamic>{
        'qa_status': decision,
        'manager_review_note': note.text.trim().isEmpty ? null : note.text.trim(),
        'manager_reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (decision != 'accepted') {
        payload.addAll({
          'status': 'in_progress',
          'completed_at': null,
          'progress': decision == 'rejected'
              ? 0
              : (((task['progress'] as num?)?.toInt() ?? 100).clamp(0, 95)),
        });
      }
      final client = Supabase.instance.client;
      await client.from('employee_tasks').update(payload).eq('id', task['id']);
      await _appendTaskEvent(
        taskId: task['id'].toString(),
        eventType: switch (decision) {
          'accepted' => 'qa_accepted',
          'rework' => 'qa_rework',
          _ => 'qa_rejected',
        },
        note: note.text.trim().isEmpty ? null : note.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switch (decision) {
              'accepted' => t.qaApprovedMessage,
              'rework' => t.qaReworkMessage,
              _ => t.qaRejectedMessage,
            },
          ),
        ),
      );
      setState(() {
        _future = _loadData();
      });
    } finally {
      note.dispose();
    }
  }
}
