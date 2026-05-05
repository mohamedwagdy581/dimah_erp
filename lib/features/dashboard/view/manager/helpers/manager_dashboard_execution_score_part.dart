part of '../../dashboard_page.dart';

extension _ManagerDashboardExecutionScoreHelpers on _ManagerDashboardState {
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

    final consumedPercent =
        ((loggedHours / estimateHours) * 100).clamp(0.0, 300.0);
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
