part of 'dashboard_page.dart';

extension _ManagerDashboardMetricsHelpers on _ManagerDashboardState {
  List<_MemberProductivity> _buildMemberMetrics(
    List<Map<String, dynamic>> members,
    List<Map<String, dynamic>> taskRows,
    DateTime monthStart,
  ) {
    return members.map((member) {
      final employeeId = member['id'].toString();
      final ownTasks = taskRows.where((task) => task['employee_id'].toString() == employeeId).toList();
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

      double weightedPaceScoreSum = 0;
      int totalWeight = 0;
      final today = DateTime.now();
      for (final task in ownTasks) {
        final progressScore = (((task['progress'] as num?)?.toDouble() ?? 0).clamp(0, 100)) / 100;
        final weight = ((task['weight'] as num?)?.toInt() ?? 3).clamp(1, 5);
        final status = (task['status'] ?? 'todo').toString();
        final startedAt = DateTime.tryParse(task['assignee_started_at']?.toString() ?? '');
        final receivedAt = DateTime.tryParse(task['assignee_received_at']?.toString() ?? '');
        final dueDate = DateTime.tryParse(task['due_date']?.toString() ?? '');
        final completedAt = DateTime.tryParse(task['completed_at']?.toString() ?? '');
        final createdAt = DateTime.tryParse(task['created_at']?.toString() ?? '');
        final loggedHoursForTask = (((task['logged_hours'] as num?)?.toDouble() ?? 0)
                .clamp(0, 9999))
            .toDouble();
        final estimateHoursForTask = (((task['estimate_hours'] as num?)?.toDouble() ?? 0)
                .clamp(0, 9999))
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

      final executionHealthPercent =
          totalWeight == 0 ? 0.0 : (weightedPaceScoreSum / totalWeight);
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

  double _taskExecutionScore({
    required double progressScore,
    required double loggedHours,
    required double estimateHours,
    required DateTime? dueDate,
    required DateTime? completedAt,
    required DateTime? startedAt,
    required DateTime? receivedAt,
    required DateTime? createdAt,
    required DateTime today,
    required String status,
  }) {
    if (estimateHours > 0 && loggedHours > 0) {
      return _hoursScore(
        progressScore: progressScore,
        loggedHours: loggedHours,
        estimateHours: estimateHours,
        status: status,
      );
    }

    if (status == 'done') {
      return _completedTimeScore(
        dueDate: dueDate,
        completedAt: completedAt,
        today: today,
      ) *
          100;
    }

    if (dueDate == null) {
      return (progressScore * 100).clamp(0.0, 100.0);
    }

    final baseline = startedAt ?? receivedAt ?? createdAt;
    if (baseline == null) {
      return (progressScore * 100).clamp(0.0, 100.0);
    }

    final expectedProgress = _expectedProgressByDate(
      baseline: baseline,
      dueDate: dueDate,
      today: today,
    );

    if (expectedProgress <= 0) {
      return progressScore > 0 ? 100.0 : 0.0;
    }

    final actualProgress = (progressScore * 100).clamp(0.0, 100.0);
    return ((actualProgress / expectedProgress) * 100).clamp(0.0, 100.0);
  }

  double _hoursScore({
    required double progressScore,
    required double loggedHours,
    required double estimateHours,
    required String status,
  }) {
    if (estimateHours <= 0) {
      return (progressScore * 100).clamp(0.0, 100.0);
    }

    final consumedPercent = ((loggedHours / estimateHours) * 100).clamp(0.0, 300.0);
    final actualProgress = (progressScore * 100).clamp(0.0, 100.0);

    if (status == 'done') {
      if (loggedHours <= estimateHours) return 100.0;
      if (loggedHours <= estimateHours * 1.1) return 90.0;
      if (loggedHours <= estimateHours * 1.25) return 75.0;
      if (loggedHours <= estimateHours * 1.5) return 55.0;
      return 35.0;
    }

    if (consumedPercent <= 0) {
      return actualProgress;
    }

    return ((actualProgress / consumedPercent) * 100).clamp(0.0, 100.0);
  }

  double _expectedProgressByDate({
    required DateTime baseline,
    required DateTime dueDate,
    required DateTime today,
  }) {
    final start = DateTime(baseline.year, baseline.month, baseline.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final current = DateTime(today.year, today.month, today.day);
    if (!dueOnly.isAfter(start)) {
      return current.isBefore(dueOnly) ? 0.0 : 100.0;
    }
    final totalDays = dueOnly.difference(start).inDays;
    final elapsedDays = current.difference(start).inDays.clamp(0, totalDays);
    return ((elapsedDays / totalDays) * 100).clamp(0.0, 100.0);
  }

  double _completedTimeScore({
    required DateTime? dueDate,
    required DateTime? completedAt,
    required DateTime today,
  }) {
    if (dueDate == null) return 0.85;
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final compare = completedAt == null
        ? DateTime(today.year, today.month, today.day)
        : DateTime(completedAt.year, completedAt.month, completedAt.day);
    final diffDays = compare.difference(dueOnly).inDays;
    if (diffDays <= 0) return 1.0;
    if (diffDays <= 2) return 0.8;
    if (diffDays <= 5) return 0.5;
    return 0.2;
  }
}
