part of 'dashboard_page.dart';

extension _EmployeeDashboardNotificationHelpers on _EmployeeDashboard {
  List<EmployeeDashboardNotification> _buildNotifications(
    List<Map<String, dynamic>> rows,
    DateTime today,
  ) {
    final notifications = <EmployeeDashboardNotification>[];
    final recent = List<Map<String, dynamic>>.of(rows)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(
          (a['updated_at'] ?? a['created_at'])?.toString() ?? '',
        );
        final bDate = DateTime.tryParse(
          (b['updated_at'] ?? b['created_at'])?.toString() ?? '',
        );
        if (aDate == null) return bDate == null ? 0 : 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    for (final row in recent.take(30)) {
      final title = row['title']?.toString() ?? '-';
      final reviewStatus = (row['employee_review_status'] ?? 'none').toString();
      final qaStatus = (row['qa_status'] ?? 'pending').toString();
      final taskStatus = (row['status'] ?? '').toString();
      final dueDate = DateTime.tryParse(row['due_date']?.toString() ?? '');
      final createdAt = _dateOnlyFromRaw(
        (row['updated_at'] ?? row['created_at'])?.toString(),
      );
      if (reviewStatus == 'rejected') {
        notifications.add(
          EmployeeDashboardNotification(
            type: 'review_rejected',
            subtitle: '$title - $createdAt',
            icon: Icons.reply_outlined,
            color: Colors.orange,
          ),
        );
      } else if (reviewStatus == 'approved') {
        notifications.add(
          EmployeeDashboardNotification(
            type: 'review_approved',
            subtitle: '$title - $createdAt',
            icon: Icons.rule_folder_outlined,
            color: Colors.blue,
          ),
        );
      }
      if (qaStatus == 'rework') {
        notifications.add(
          EmployeeDashboardNotification(
            type: 'qa_rework',
            subtitle: '$title - $createdAt',
            icon: Icons.restart_alt_outlined,
            color: Colors.orange,
          ),
        );
      } else if (qaStatus == 'accepted') {
        notifications.add(
          EmployeeDashboardNotification(
            type: 'qa_accepted',
            subtitle: '$title - $createdAt',
            icon: Icons.verified_outlined,
            color: Colors.green,
          ),
        );
      } else if (qaStatus == 'rejected') {
        notifications.add(
          EmployeeDashboardNotification(
            type: 'qa_rejected',
            subtitle: '$title - $createdAt',
            icon: Icons.block_outlined,
            color: Colors.red,
          ),
        );
      }
      if (taskStatus != 'done' && dueDate != null) {
        final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (!dueOnly.isBefore(todayOnly) &&
            !dueOnly.isAfter(todayOnly.add(const Duration(days: 2)))) {
          notifications.add(
            EmployeeDashboardNotification(
              type: 'task_due_soon',
              subtitle:
                  '$title - ${_dateOnlyFromRaw(row['due_date']?.toString())}',
              icon: Icons.schedule_outlined,
              color: Colors.amber,
            ),
          );
        }
      }
    }
    return notifications;
  }
}

String _employeeNotificationTitle(AppLocalizations t, String type) {
  switch (type) {
    case 'review_rejected':
      return t.reviewRejected;
    case 'review_approved':
      return t.reviewApproved;
    case 'qa_rework':
      return t.qaRework;
    case 'qa_accepted':
      return t.qaAccepted;
    case 'qa_rejected':
      return t.qaRejected;
    case 'task_due_soon':
      return t.taskDueSoon;
    default:
      return '-';
  }
}

String _dateOnlyFromRaw(String? raw) {
  final dt = DateTime.tryParse(raw ?? '');
  if (dt == null) return '-';
  return '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
