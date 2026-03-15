part of 'dashboard_page.dart';

class _ManagerChartsSection extends StatelessWidget {
  const _ManagerChartsSection({
    required this.data,
    required this.taskTypeLabelBuilder,
  });

  final _ManagerDashboardData data;
  final String Function(AppLocalizations t, String type) taskTypeLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MonthlyTrendChartCard(title: t.monthlyCompletionTrend, subtitle: t.lastSixMonths, series: data.monthlyCompletionSeries, color: const Color(0xFF22C55E)),
        _MonthlyStackedChartCard(title: t.onTimeVsDelayed, subtitle: t.lastSixMonths, series: data.monthlyDeliverySeries, onTimeLabel: t.onTime, delayedLabel: t.delayed),
        _TaskTypeDistributionCard(title: t.taskTypeDistribution, subtitle: t.currentMonthBreakdown, items: data.taskTypeDistribution, labelBuilder: (type) => taskTypeLabelBuilder(t, type)),
        _EmployeeWorkloadCard(title: t.employeeWorkload, subtitle: t.currentMonthBreakdown, items: data.employeeWorkloadSeries),
      ],
    );
  }
}

class _ManagerPerformanceSection extends StatelessWidget {
  const _ManagerPerformanceSection({required this.data});

  final _ManagerDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _PerformanceListCard(title: t.topPerformers, emptyText: t.noTeamDataYet, members: data.topPerformers, color: Colors.green),
        _PerformanceListCard(title: t.needsAttention, emptyText: t.noTeamDataYet, members: data.needsAttention, color: Colors.orange),
      ],
    );
  }
}

class _ManagerMembersSection extends StatelessWidget {
  const _ManagerMembersSection({
    required this.data,
    required this.onShowTimeline,
  });

  final _ManagerDashboardData data;
  final void Function(String employeeId, String employeeName) onShowTimeline;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: data.members.map((member) {
        return SizedBox(
          width: 220,
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onShowTimeline(member.employeeId, member.name),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _ProductivityCircle(value: member.productivityPercent, title: member.name),
                    const SizedBox(height: 8),
                    _InlineMetric(label: t.monthCompletionRate, value: '${member.monthCompletionPercent.toStringAsFixed(0)}%'),
                    const SizedBox(height: 6),
                    _AnimatedProgressBar(value: member.monthCompletionPercent, color: const Color(0xFF38BDF8)),
                    const SizedBox(height: 8),
                    Text(t.tasksWithValue(member.totalTasks)),
                    Text(t.doneWithValue(member.doneTasks)),
                    Text(t.monthTasksWithValue(member.monthTotalTasks)),
                    Text(t.completedThisMonthWithValue(member.monthDoneTasks)),
                    Text(
                      isArabic
                          ? 'الساعات المسجلة: ${member.loggedHours.toStringAsFixed(1)} / ${member.estimatedHours.toStringAsFixed(1)}h'
                          : 'Logged Hours: ${member.loggedHours.toStringAsFixed(1)} / ${member.estimatedHours.toStringAsFixed(1)}h',
                    ),
                    Text(t.avgTaskProgressWithValue(member.averageProgressPercent.toStringAsFixed(0))),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
