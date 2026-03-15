part of 'dashboard_page.dart';

class _ManagerDashboardHeader extends StatelessWidget {
  const _ManagerDashboardHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(t.teamProductivity, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(t.refresh),
        ),
      ],
    );
  }
}

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

class _ManagerOverviewSection extends StatelessWidget {
  const _ManagerOverviewSection({required this.data});

  final _ManagerDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.monthDepartmentOverview, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ManagerMetricGauge(title: t.monthCompletionRate, value: data.monthCompletionRate, color: const Color(0xFF22C55E)),
                _ManagerMetricGauge(title: t.monthOnTimeRate, value: data.monthOnTimeRate, color: const Color(0xFF38BDF8)),
                _ManagerMetricGauge(title: t.monthDepartmentProductivity, value: data.monthProductivityPercent, color: const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
