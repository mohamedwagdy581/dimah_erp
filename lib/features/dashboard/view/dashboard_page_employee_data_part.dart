part of 'dashboard_page.dart';

extension _EmployeeDashboardDataHelpers on _EmployeeDashboard {
  Future<EmployeeDashboardData> _loadData() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Session missing');
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    final tenantId = me['tenant_id'].toString();

    final rows = <Map<String, dynamic>>[];
    // Read every page so the summary is not limited to the latest 30 tasks.
    const pageSize = 500;
    for (var offset = 0; ; offset += pageSize) {
      final tasks = await client
          .from('employee_tasks')
          .select(
            'id, title, priority, status, progress, created_at, updated_at, due_date, qa_status, employee_review_status',
          )
          .eq('tenant_id', tenantId)
          .eq('employee_id', employeeId)
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + pageSize - 1);
      final page = (tasks as List).cast<Map<String, dynamic>>();
      rows.addAll(page);
      if (page.length < pageSize) break;
    }
    final extras = await Future.wait<Object?>([
      client
          .from('employees')
          .select('full_name')
          .eq('tenant_id', tenantId)
          .eq('id', employeeId)
          .maybeSingle(),
      AppDI.leavesRepo.fetchLeaveBalances(employeeId: employeeId),
      AppDI.approvalsRepo.fetchPendingCount(employeeId: employeeId),
    ]);
    final employee = extras[0] as Map<String, dynamic>?;
    final balances = extras[1] as List<LeaveBalance>;
    final total = rows.length;
    final done = rows.where((row) => row['status'] == 'done').length;
    final pending = rows.where((row) => row['status'] != 'done').length;
    final inProgress = rows
        .where((row) => row['status'] == 'in_progress')
        .length;
    final reviewPending = rows
        .where((row) => (row['employee_review_status'] ?? 'none') == 'pending')
        .length;
    final qaPending = rows
        .where(
          (row) =>
              row['status'] == 'done' &&
              (row['qa_status'] ?? 'pending') == 'pending',
        )
        .length;

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
        : rows.fold<double>(
                0,
                (sum, row) =>
                    sum + ((row['progress'] as num?)?.toDouble() ?? 0),
              ) /
              total;
    final notifications = _buildNotifications(rows, today);

    return EmployeeDashboardData(
      employeeName: employee?['full_name']?.toString() ?? '',
      annualBalance: balances.where((b) => b.type == 'annual').firstOrNull,
      pendingRequests: extras[2] as int,
      todayTasks: rows.where((row) {
        final due = DateTime.tryParse(row['due_date']?.toString() ?? '');
        return row['status'] != 'done' &&
            due != null &&
            due.year == today.year &&
            due.month == today.month &&
            due.day == today.day;
      }).length,
      totalTasks: total,
      doneTasks: done,
      pendingTasks: pending,
      inProgressTasks: inProgress,
      reviewPendingTasks: reviewPending,
      qaPendingTasks: qaPending,
      overdueTasks: overdue,
      dueSoonTasks: dueSoon,
      monthCompletionRate: monthRows.isEmpty
          ? 0
          : (monthDone / monthRows.length) * 100,
      productivityPercent: avgProgress,
      recentTasks:
          (rows.where((row) => row['status'] != 'done').toList()..sort((a, b) {
                final aDue = DateTime.tryParse(a['due_date']?.toString() ?? '');
                final bDue = DateTime.tryParse(b['due_date']?.toString() ?? '');
                if (aDue == null) return bDue == null ? 0 : 1;
                if (bDue == null) return -1;
                return aDue.compareTo(bDue);
              }))
              .take(4)
              .toList(),
      notifications: notifications.take(8).toList(),
    );
  }
}
