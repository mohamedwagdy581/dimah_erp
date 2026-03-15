part of 'dashboard_page.dart';

class _EmployeeDashboardData {
  const _EmployeeDashboardData({
    this.totalTasks = 0,
    this.pendingTasks = 0,
    this.doneTasks = 0,
    this.inProgressTasks = 0,
    this.reviewPendingTasks = 0,
    this.qaPendingTasks = 0,
    this.overdueTasks = 0,
    this.dueSoonTasks = 0,
    this.monthCompletionRate = 0,
    this.productivityPercent = 0,
    this.recentTasks = const [],
    this.notifications = const [],
  });

  final int totalTasks;
  final int pendingTasks;
  final int doneTasks;
  final int inProgressTasks;
  final int reviewPendingTasks;
  final int qaPendingTasks;
  final int overdueTasks;
  final int dueSoonTasks;
  final double monthCompletionRate;
  final double productivityPercent;
  final List<Map<String, dynamic>> recentTasks;
  final List<_EmployeeNotificationItem> notifications;
}

class _EmployeeNotificationItem {
  const _EmployeeNotificationItem({
    required this.type,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String type;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _ManagerDashboardData {
  const _ManagerDashboardData({
    this.members = const [],
    this.managedDepartmentNames = const [],
    this.teamTotalTasks = 0,
    this.teamDoneTasks = 0,
    this.teamPendingTasks = 0,
    this.monthCreatedTasks = 0,
    this.monthCompletedTasks = 0,
    this.monthOnTimeTasks = 0,
    this.monthProductivityPercent = 0,
    this.overdueTasks = 0,
    this.dueSoonTasks = const [],
    this.pendingReviewRequests = const [],
    this.pendingQaTasks = const [],
    this.monthlyCompletionSeries = const [],
    this.monthlyDeliverySeries = const [],
    this.taskTypeDistribution = const [],
    this.employeeWorkloadSeries = const [],
    this.completionTrendPercent = 0,
    this.pendingTrendPercent = 0,
    this.topPerformers = const [],
    this.needsAttention = const [],
  });
  final List<_MemberProductivity> members;
  final List<String> managedDepartmentNames;
  final int teamTotalTasks;
  final int teamDoneTasks;
  final int teamPendingTasks;
  final int monthCreatedTasks;
  final int monthCompletedTasks;
  final int monthOnTimeTasks;
  final double monthProductivityPercent;
  final int overdueTasks;
  final List<Map<String, dynamic>> dueSoonTasks;
  final List<Map<String, dynamic>> pendingReviewRequests;
  final List<Map<String, dynamic>> pendingQaTasks;
  final List<_MonthlyMetricPoint> monthlyCompletionSeries;
  final List<_MonthlyDeliveryPoint> monthlyDeliverySeries;
  final List<_TaskTypeDistributionPoint> taskTypeDistribution;
  final List<_EmployeeWorkloadPoint> employeeWorkloadSeries;
  final double completionTrendPercent;
  final double pendingTrendPercent;
  final List<_MemberProductivity> topPerformers;
  final List<_MemberProductivity> needsAttention;

  double get completionRate {
    if (teamTotalTasks == 0) return 0;
    return (teamDoneTasks / teamTotalTasks) * 100;
  }

  double get monthCompletionRate {
    if (monthCreatedTasks == 0) return 0;
    return (monthCompletedTasks / monthCreatedTasks) * 100;
  }

  double get monthOnTimeRate {
    if (monthCompletedTasks == 0) return 0;
    return (monthOnTimeTasks / monthCompletedTasks) * 100;
  }

  String? get primaryManagedDepartmentName {
    if (managedDepartmentNames.isEmpty) return null;
    return managedDepartmentNames.first;
  }
}

class _MemberProductivity {
  const _MemberProductivity({
    required this.employeeId,
    required this.name,
    required this.totalTasks,
    required this.doneTasks,
    required this.monthTotalTasks,
    required this.monthDoneTasks,
    required this.monthCompletionPercent,
    required this.averageProgressPercent,
    required this.loggedHours,
    required this.estimatedHours,
    required this.productivityPercent,
  });

  final String employeeId;
  final String name;
  final int totalTasks;
  final int doneTasks;
  final int monthTotalTasks;
  final int monthDoneTasks;
  final double monthCompletionPercent;
  final double averageProgressPercent;
  final double loggedHours;
  final double estimatedHours;
  final double productivityPercent;
}
