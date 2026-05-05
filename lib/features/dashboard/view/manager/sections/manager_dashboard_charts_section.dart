part of '../../dashboard_page.dart';

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
