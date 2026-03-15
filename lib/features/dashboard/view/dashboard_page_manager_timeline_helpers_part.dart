part of 'dashboard_page.dart';

extension _ManagerDashboardTimelineHelpers on _ManagerDashboardState {
  Future<void> _appendTaskEvent({
    required String taskId,
    required String eventType,
    String? note,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;
      final me = await client
          .from('users')
          .select('tenant_id')
          .eq('id', uid)
          .single();
      await client.from('employee_task_events').insert({
        'tenant_id': me['tenant_id'].toString(),
        'task_id': taskId,
        'event_type': eventType,
        'event_note': note,
        'event_payload': payload ?? const {},
        'created_by_user_id': uid,
      });
    } catch (_) {}
  }

  String _taskEventLabel(AppLocalizations t, String raw) {
    final isArabic = t.localeName.startsWith('ar');
    switch (raw) {
      case 'attachment_added':
        return t.taskEventAttachmentAdded;
      case 'time_logged':
        return isArabic ? 'تم تسجيل وقت' : 'Time logged';
      case 'timer_started':
        return isArabic ? 'تم بدء المؤقت' : 'Timer started';
      case 'timer_stopped':
        return isArabic ? 'تم إيقاف المؤقت' : 'Timer stopped';
      case 'assigned':
        return t.taskEventAssigned;
      case 'review_requested':
        return t.taskEventReviewRequested;
      case 'review_approved':
        return t.taskEventReviewApproved;
      case 'review_rejected':
        return t.taskEventReviewRejected;
      case 'qa_accepted':
        return t.taskEventQaAccepted;
      case 'qa_rework':
        return t.taskEventQaRework;
      case 'qa_rejected':
        return t.taskEventQaRejected;
      case 'status_changed':
        return t.taskEventStatusChanged;
      case 'progress_updated':
        return t.taskEventProgressUpdated;
      default:
        return raw.isEmpty ? '-' : raw;
    }
  }

  String _fmtTs(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '-';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
