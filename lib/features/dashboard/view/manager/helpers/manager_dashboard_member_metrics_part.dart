part of '../../dashboard_page.dart';

extension _ManagerDashboardMetricsHelpers on _ManagerDashboardState {
  List<_MemberProductivity> _buildMemberMetrics(
    List<Map<String, dynamic>> members,
    List<Map<String, dynamic>> taskRows,
    DateTime monthStart,
  ) {
    return members.map((member) {
      final employeeId = member['id'].toString();
      final ownTasks = taskRows
          .where((task) => task['employee_id'].toString() == employeeId)
          .toList();
      final totalTasks = ownTasks.length;
      final doneTasks = ownTasks.where((task) => task['status'] == 'done').length;
      final completionPercent = totalTasks == 0 ? 0.0 : (doneTasks / totalTasks) * 100;
      final monthTasks = ownTasks.where((task) {
        final createdAt = DateTime.tryParse(task['created_at']?.toString() ?? '');
        return createdAt != null && !createdAt.isBefore(monthStart);
      }).toList();
      final monthDoneTasks = monthTasks.where((task) => task['status'] == 'done').length;
      final loggedHours = ownTasks.fold<double>(
        0,
        (sum, task) => sum + ((task['logged_hours'] as num?)?.toDouble() ?? 0),
      );
      final estimatedHours = ownTasks.fold<double>(
        0,
        (sum, task) => sum + ((task['estimate_hours'] as num?)?.toDouble() ?? 0),
      );
      final averageProgressPercent = totalTasks == 0
          ? 0.0
          : ownTasks.fold<double>(
                0,
                (sum, task) => sum + ((task['progress'] as num?)?.toDouble() ?? 0),
              ) /
              totalTasks;

      final executionHealthPercent = _buildExecutionHealthPercent(ownTasks);
      final productivityPercent = totalTasks == 0
          ? 0.0
          : ((completionPercent * 0.25) +
                  (averageProgressPercent * 0.30) +
                  (executionHealthPercent * 0.45))
              .clamp(0.0, 100.0);

      return _MemberProductivity(
        employeeId: employeeId,
        name: member['full_name']?.toString() ?? '-',
        totalTasks: totalTasks,
        doneTasks: doneTasks,
        monthTotalTasks: monthTasks.length,
        monthDoneTasks: monthDoneTasks,
        monthCompletionPercent: monthTasks.isEmpty ? 0 : (monthDoneTasks / monthTasks.length) * 100,
        averageProgressPercent: averageProgressPercent,
        loggedHours: loggedHours,
        estimatedHours: estimatedHours,
        productivityPercent: productivityPercent,
      );
    }).toList();
  }

  double _buildExecutionHealthPercent(List<Map<String, dynamic>> ownTasks) {
    double weightedPaceScoreSum = 0;
    int totalWeight = 0;
    final today = DateTime.now();

    for (final task in ownTasks) {
      final progressScore =
          (((task['progress'] as num?)?.toDouble() ?? 0).clamp(0, 100)) / 100;
      final weight = ((task['weight'] as num?)?.toInt() ?? 3).clamp(1, 5);
      final status = (task['status'] ?? 'todo').toString();
      final startedAt = DateTime.tryParse(task['assignee_started_at']?.toString() ?? '');
      final receivedAt = DateTime.tryParse(task['assignee_received_at']?.toString() ?? '');
      final dueDate = DateTime.tryParse(task['due_date']?.toString() ?? '');
      final completedAt = DateTime.tryParse(task['completed_at']?.toString() ?? '');
      final createdAt = DateTime.tryParse(task['created_at']?.toString() ?? '');
      final loggedHoursForTask =
          (((task['logged_hours'] as num?)?.toDouble() ?? 0).clamp(0, 9999))
              .toDouble();
      final estimateHoursForTask =
          (((task['estimate_hours'] as num?)?.toDouble() ?? 0).clamp(0, 9999))
              .toDouble();

      final untouched = status != 'done' &&
          progressScore <= 0 &&
          startedAt == null &&
          receivedAt == null &&
          loggedHoursForTask <= 0;

      if (untouched) {
        totalWeight += weight;
        continue;
      }

      final taskExecutionScore = _taskExecutionScore(
        progressScore: progressScore,
        loggedHours: loggedHoursForTask,
        estimateHours: estimateHoursForTask,
        dueDate: dueDate,
        completedAt: completedAt,
        startedAt: startedAt,
        receivedAt: receivedAt,
        createdAt: createdAt,
        today: today,
        status: status,
      );
      weightedPaceScoreSum += taskExecutionScore * weight;
      totalWeight += weight;
    }

    return totalWeight == 0 ? 0.0 : (weightedPaceScoreSum / totalWeight);
  }
}
