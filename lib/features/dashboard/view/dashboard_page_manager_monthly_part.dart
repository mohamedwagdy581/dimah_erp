part of 'dashboard_page.dart';

extension _ManagerDashboardMonthlyHelpers on _ManagerDashboardState {
  int _monthOnTimeTasks(List<Map<String, dynamic>> monthCompletedRows) {
    return monthCompletedRows.where((task) {
      final dueDate = DateTime.tryParse(task['due_date']?.toString() ?? '');
      final completedAt = DateTime.tryParse(task['completed_at']?.toString() ?? '');
      if (dueDate == null || completedAt == null) return false;
      final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final completedOnly = DateTime(completedAt.year, completedAt.month, completedAt.day);
      return !completedOnly.isAfter(dueOnly);
    }).length;
  }

  double _trendPercent({
    required List<Map<String, dynamic>> taskRows,
    required bool done,
    required DateTime now,
  }) {
    final thisWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final prevWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final prevWeekEnd = thisWeekStart.subtract(const Duration(days: 1));
    var current = 0;
    var previous = 0;
    for (final task in taskRows) {
      final isDone = (task['status'] ?? '').toString() == 'done';
      if (isDone != done) continue;
      final raw = done ? task['updated_at'] : task['created_at'];
      final timestamp = DateTime.tryParse(raw?.toString() ?? '');
      if (timestamp == null) continue;
      final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
      if (!day.isBefore(thisWeekStart)) {
        current++;
      } else if (!day.isBefore(prevWeekStart) && !day.isAfter(prevWeekEnd)) {
        previous++;
      }
    }
    if (previous <= 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  List<_MonthlyMetricPoint> _buildMonthlyCompletionSeries(List<Map<String, dynamic>> taskRows) {
    final months = _lastSixMonths();
    final monthlyDone = <String, int>{for (final month in months) month.key: 0};
    for (final task in taskRows) {
      final completedAt = DateTime.tryParse(task['completed_at']?.toString() ?? '');
      if (completedAt == null) continue;
      final key = _monthKey(completedAt);
      if (!monthlyDone.containsKey(key)) continue;
      monthlyDone[key] = (monthlyDone[key] ?? 0) + 1;
    }
    return months
        .map((month) => _MonthlyMetricPoint(label: month.label, value: (monthlyDone[month.key] ?? 0).toDouble()))
        .toList();
  }

  List<_MonthlyDeliveryPoint> _buildMonthlyDeliverySeries(List<Map<String, dynamic>> taskRows) {
    final months = _lastSixMonths();
    final counts = <String, ({int onTime, int delayed})>{for (final month in months) month.key: (onTime: 0, delayed: 0)};
    for (final task in taskRows) {
      final completedAt = DateTime.tryParse(task['completed_at']?.toString() ?? '');
      if (completedAt == null) continue;
      final key = _monthKey(completedAt);
      if (!counts.containsKey(key)) continue;
      final current = counts[key]!;
      final dueDate = DateTime.tryParse(task['due_date']?.toString() ?? '');
      if (dueDate == null) {
        counts[key] = (onTime: current.onTime + 1, delayed: current.delayed);
        continue;
      }
      final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final completedOnly = DateTime(completedAt.year, completedAt.month, completedAt.day);
      counts[key] = !completedOnly.isAfter(dueOnly)
          ? (onTime: current.onTime + 1, delayed: current.delayed)
          : (onTime: current.onTime, delayed: current.delayed + 1);
    }
    return months
        .map((month) => _MonthlyDeliveryPoint(
              label: month.label,
              onTime: counts[month.key]!.onTime.toDouble(),
              delayed: counts[month.key]!.delayed.toDouble(),
            ))
        .toList();
  }

  List<_MonthBucket> _lastSixMonths() {
    final now = DateTime.now();
    return [
      for (var offset = 5; offset >= 0; offset--)
        _MonthBucket(
          key: _monthKey(DateTime(now.year, now.month - offset, 1)),
          label: _monthLabel(DateTime(now.year, now.month - offset, 1)),
        ),
    ];
  }

  String _monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime date) {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return labels[date.month - 1];
  }
}
