part of 'dashboard_page.dart';

extension _EmployeeDashboardNotificationHelpers on _EmployeeDashboard {
  List<_EmployeeNotificationItem> _buildNotifications(
    List<Map<String, dynamic>> rows,
    DateTime today,
  ) {
    final notifications = <_EmployeeNotificationItem>[];
    for (final row in rows.take(20)) {
      final title = row['title']?.toString() ?? '-';
      final reviewStatus = (row['employee_review_status'] ?? 'none').toString();
      final qaStatus = (row['qa_status'] ?? 'pending').toString();
      final taskStatus = (row['status'] ?? '').toString();
      final dueDate = DateTime.tryParse(row['due_date']?.toString() ?? '');
      final createdAt = _dateOnlyFromRaw(row['created_at']?.toString());
      if (reviewStatus == 'rejected') {
        notifications.add(_EmployeeNotificationItem(type: 'review_rejected', subtitle: '$title - $createdAt', icon: Icons.reply_outlined, color: Colors.orange));
      } else if (reviewStatus == 'approved') {
        notifications.add(_EmployeeNotificationItem(type: 'review_approved', subtitle: '$title - $createdAt', icon: Icons.rule_folder_outlined, color: Colors.blue));
      }
      if (qaStatus == 'rework') {
        notifications.add(_EmployeeNotificationItem(type: 'qa_rework', subtitle: '$title - $createdAt', icon: Icons.restart_alt_outlined, color: Colors.orange));
      } else if (qaStatus == 'accepted') {
        notifications.add(_EmployeeNotificationItem(type: 'qa_accepted', subtitle: '$title - $createdAt', icon: Icons.verified_outlined, color: Colors.green));
      } else if (qaStatus == 'rejected') {
        notifications.add(_EmployeeNotificationItem(type: 'qa_rejected', subtitle: '$title - $createdAt', icon: Icons.block_outlined, color: Colors.red));
      }
      if (taskStatus != 'done' && dueDate != null) {
        final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (!dueOnly.isBefore(todayOnly) && !dueOnly.isAfter(todayOnly.add(const Duration(days: 2)))) {
          notifications.add(_EmployeeNotificationItem(type: 'task_due_soon', subtitle: '$title - ${_dateOnlyFromRaw(row['due_date']?.toString())}', icon: Icons.schedule_outlined, color: Colors.amber));
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
