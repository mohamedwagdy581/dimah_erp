part of '../../dashboard_page.dart';

class _ManagerStatsSection extends StatelessWidget {
  const _ManagerStatsSection({required this.data});

  final _ManagerDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SmallStatCard(title: t.monthTasksCreated, value: '${data.monthCreatedTasks}'),
        _SmallStatCard(title: t.monthTasksCompleted, value: '${data.monthCompletedTasks}'),
        _SmallStatCard(title: t.monthOnTimeRate, value: '${data.monthOnTimeRate.toStringAsFixed(0)}%'),
        _SmallStatCard(title: t.monthDepartmentProductivity, value: '${data.monthProductivityPercent.toStringAsFixed(0)}%'),
        _SmallStatCard(title: t.pendingTaskReviews, value: '${data.pendingReviewRequests.length}'),
        _SmallStatCard(title: t.pendingTaskQa, value: '${data.pendingQaTasks.length}'),
        _SmallStatCard(title: t.teamMembers, value: '${data.members.length}'),
        _SmallStatCard(title: t.openTasks, value: '${data.teamPendingTasks}', trendPercent: data.pendingTrendPercent, invertTrend: true),
        _SmallStatCard(title: t.overdueTasks, value: '${data.overdueTasks}'),
        _SmallStatCard(title: t.completionRate, value: '${data.completionRate.toStringAsFixed(1)}%', trendPercent: data.completionTrendPercent),
      ],
    );
  }
}
