part of 'dashboard_page.dart';

extension _EmployeeDashboardDataHelpers on _EmployeeDashboard {
  Future<_EmployeeDashboardData> _loadData() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const _EmployeeDashboardData();
    final me = await client.from('users').select('tenant_id').eq('id', uid).single();
    final tenantId = me['tenant_id'].toString();

    final tasks = await client
        .from('employee_tasks')
        .select('title, status, progress, created_at, due_date, qa_status, employee_review_status')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(30);
    final rows = (tasks as List).cast<Map<String, dynamic>>();
    final total = rows.length;
    final done = rows.where((row) => row['status'] == 'done').length;
    final pending = rows.where((row) => row['status'] != 'done').length;
    final inProgress = rows.where((row) => row['status'] == 'in_progress').length;
    final reviewPending = rows.where((row) => (row['employee_review_status'] ?? 'none') == 'pending').length;
    final qaPending = rows.where((row) => row['status'] == 'done' && (row['qa_status'] ?? 'pending') == 'pending').length;

    final today = DateTime.now();
    var overdue = 0;
    var dueSoon = 0;
    for (final row in rows) {
      if ((row['status'] ?? '') == 'done') continue;
      final dueDate = DateTime.tryParse(row['due_date']?.toString() ?? '');
      if (dueDate == null) continue;
      final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final todayOnly = DateTime(today.year, today.month, today.day);
      if (dueOnly.isBefore(todayOnly)) {
        overdue++;
      } else if (!dueOnly.isAfter(todayOnly.add(const Duration(days: 3)))) {
        dueSoon++;
      }
    }

    final monthStart = DateTime(today.year, today.month, 1);
    final monthRows = rows.where((row) {
      final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
      return createdAt != null && !createdAt.isBefore(monthStart);
    }).toList();
    final monthDone = monthRows.where((row) => row['status'] == 'done').length;
    final avgProgress = total == 0
        ? 0.0
        : rows.fold<double>(0, (sum, row) => sum + ((row['progress'] as num?)?.toDouble() ?? 0)) / total;
    final notifications = _buildNotifications(rows, today);

    return _EmployeeDashboardData(
      totalTasks: total,
      doneTasks: done,
      pendingTasks: pending,
      inProgressTasks: inProgress,
      reviewPendingTasks: reviewPending,
      qaPendingTasks: qaPending,
      overdueTasks: overdue,
      dueSoonTasks: dueSoon,
      monthCompletionRate: monthRows.isEmpty ? 0 : (monthDone / monthRows.length) * 100,
      productivityPercent: avgProgress,
      recentTasks: rows.take(10).toList(),
      notifications: notifications.take(8).toList(),
    );
  }
}
