part of 'dashboard_page.dart';

class _TaskTemplate {
  const _TaskTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    required this.priority,
    required this.estimateHours,
  });

  final String id;
  final String title;
  final String description;
  final String taskType;
  final String priority;
  final double estimateHours;
}

class _MonthBucket {
  const _MonthBucket({required this.key, required this.label});

  final String key;
  final String label;
}

class _MonthlyMetricPoint {
  const _MonthlyMetricPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class _MonthlyDeliveryPoint {
  const _MonthlyDeliveryPoint({
    required this.label,
    required this.onTime,
    required this.delayed,
  });

  final String label;
  final double onTime;
  final double delayed;
}

class _TaskTypeDistributionPoint {
  const _TaskTypeDistributionPoint({
    required this.taskType,
    required this.count,
  });

  final String taskType;
  final int count;
}

class _EmployeeWorkloadPoint {
  const _EmployeeWorkloadPoint({
    required this.employeeName,
    required this.tasks,
  });

  final String employeeName;
  final int tasks;
}
