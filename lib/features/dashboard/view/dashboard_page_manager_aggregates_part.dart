part of 'dashboard_page.dart';

extension _ManagerDashboardAggregateHelpers on _ManagerDashboardState {
  _ManagerDashboardData _buildManagerDashboardData({
    required List<Map<String, dynamic>> taskRows,
    required List<_MemberProductivity> metrics,
    required List<String> managedDepartmentNames,
    required Map<String, String> memberNameById,
    required DateTime monthStart,
  }) {
    final now = DateTime.now();
    final monthTaskRows = taskRows.where((task) {
      final createdAt = DateTime.tryParse(task['created_at']?.toString() ?? '');
      return createdAt != null && !createdAt.isBefore(monthStart);
    }).toList();
    final monthCompletedRows = taskRows.where((task) {
      final completedAt = DateTime.tryParse(task['completed_at']?.toString() ?? '');
      return completedAt != null && !completedAt.isBefore(monthStart);
    }).toList();

    final dueSoonTasks = <Map<String, dynamic>>[];
    final overdueTasks = _collectDueTasks(taskRows, memberNameById, dueSoonTasks, now);
    final pendingReviewRequests = _pendingReviewRequests(taskRows, memberNameById);
    final pendingQaTasks = _pendingQaTasks(taskRows, memberNameById);
    final taskTypeDistribution = _taskTypeDistribution(monthTaskRows);
    final employeeWorkloadSeries = _employeeWorkload(monthTaskRows, memberNameById);
    final sortedMetrics = [...metrics]..sort((a, b) => b.productivityPercent.compareTo(a.productivityPercent));
    final attentionMetrics = [...metrics]..sort((a, b) => a.productivityPercent.compareTo(b.productivityPercent));

    return _ManagerDashboardData(
      members: metrics,
      managedDepartmentNames: managedDepartmentNames,
      teamTotalTasks: taskRows.length,
      teamDoneTasks: taskRows.where((task) => task['status'] == 'done').length,
      teamPendingTasks: taskRows.where((task) => task['status'] != 'done').length,
      monthCreatedTasks: monthTaskRows.length,
      monthCompletedTasks: monthCompletedRows.length,
      monthOnTimeTasks: _monthOnTimeTasks(monthCompletedRows),
      monthProductivityPercent: metrics.isEmpty
          ? 0
          : metrics.fold<double>(0, (sum, item) => sum + item.productivityPercent) / metrics.length,
      overdueTasks: overdueTasks,
      dueSoonTasks: dueSoonTasks.take(8).toList(),
      pendingReviewRequests: pendingReviewRequests,
      pendingQaTasks: pendingQaTasks,
      monthlyCompletionSeries: _buildMonthlyCompletionSeries(taskRows),
      monthlyDeliverySeries: _buildMonthlyDeliverySeries(taskRows),
      taskTypeDistribution: taskTypeDistribution,
      employeeWorkloadSeries: employeeWorkloadSeries.take(6).toList(),
      completionTrendPercent: _trendPercent(taskRows: taskRows, done: true, now: now),
      pendingTrendPercent: _trendPercent(taskRows: taskRows, done: false, now: now),
      topPerformers: sortedMetrics.take(5).toList(),
      needsAttention: attentionMetrics.take(5).toList(),
    );
  }

  int _collectDueTasks(
    List<Map<String, dynamic>> taskRows,
    Map<String, String> memberNameById,
    List<Map<String, dynamic>> dueSoonTasks,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final dueSoonEnd = today.add(const Duration(days: 7));
    var overdueTasks = 0;
    for (final task in taskRows) {
      if (task['status'] == 'done') continue;
      final due = DateTime.tryParse(task['due_date']?.toString() ?? '');
      if (due == null) continue;
      final dueDate = DateTime(due.year, due.month, due.day);
      if (dueDate.isBefore(today)) overdueTasks++;
      if (!dueDate.isBefore(today) && !dueDate.isAfter(dueSoonEnd)) {
        final employeeId = task['employee_id']?.toString() ?? '';
        dueSoonTasks.add({
          'title': task['title']?.toString() ?? '-',
          'due_date': task['due_date']?.toString() ?? '',
          'employee_name': memberNameById[employeeId] ?? '-',
        });
      }
    }
    dueSoonTasks.sort((a, b) => (a['due_date'] as String).compareTo(b['due_date'] as String));
    return overdueTasks;
  }

  List<Map<String, dynamic>> _pendingReviewRequests(
    List<Map<String, dynamic>> taskRows,
    Map<String, String> memberNameById,
  ) {
    return taskRows
        .where((task) => (task['employee_review_status'] ?? 'none').toString().toLowerCase() == 'pending')
        .map((task) => {...task, 'employee_name': memberNameById[task['employee_id']?.toString() ?? ''] ?? '-'})
        .toList()
      ..sort((a, b) => (b['employee_review_requested_at']?.toString() ?? '')
          .compareTo(a['employee_review_requested_at']?.toString() ?? ''));
  }

  List<Map<String, dynamic>> _pendingQaTasks(
    List<Map<String, dynamic>> taskRows,
    Map<String, String> memberNameById,
  ) {
    return taskRows
        .where((task) => (task['status'] ?? '').toString() == 'done' && (task['qa_status'] ?? 'pending').toString() == 'pending')
        .map((task) => {...task, 'employee_name': memberNameById[task['employee_id']?.toString() ?? ''] ?? '-'})
        .toList()
      ..sort((a, b) => (b['completed_at']?.toString() ?? '').compareTo(a['completed_at']?.toString() ?? ''));
  }

  List<_TaskTypeDistributionPoint> _taskTypeDistribution(List<Map<String, dynamic>> rows) {
    final counts = <String, int>{};
    for (final row in rows) {
      final taskType = (row['task_type'] ?? 'general').toString();
      counts[taskType] = (counts[taskType] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((entry) => _TaskTypeDistributionPoint(taskType: entry.key, count: entry.value)).toList();
  }

  List<_EmployeeWorkloadPoint> _employeeWorkload(
    List<Map<String, dynamic>> rows,
    Map<String, String> memberNameById,
  ) {
    final counts = <String, int>{};
    for (final row in rows) {
      final employeeId = row['employee_id']?.toString() ?? '';
      if (employeeId.isEmpty) continue;
      counts[employeeId] = (counts[employeeId] ?? 0) + 1;
    }
    final series = counts.entries
        .map((entry) => _EmployeeWorkloadPoint(employeeName: memberNameById[entry.key] ?? '-', tasks: entry.value))
        .toList()
      ..sort((a, b) => b.tasks.compareTo(a.tasks));
    return series;
  }
}
