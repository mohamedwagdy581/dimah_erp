part of '../../dashboard_page.dart';

class _EmployeeSummarySection extends StatelessWidget {
  const _EmployeeSummarySection({required this.data});

  final _EmployeeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _ProductivityCircle(
                    value: data.productivityPercent,
                    title: t.productivity,
                  ),
                  const SizedBox(height: 8),
                  _AnimatedProgressBar(
                    value: data.monthCompletionRate,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${t.monthCompletionRate}: ${data.monthCompletionRate.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        _SmallStatCard(title: t.myTasks, value: '${data.totalTasks}'),
        _SmallStatCard(title: t.statusInProgress, value: '${data.inProgressTasks}'),
        _SmallStatCard(title: t.reviewPending, value: '${data.reviewPendingTasks}'),
        _SmallStatCard(title: t.qaPending, value: '${data.qaPendingTasks}'),
        _SmallStatCard(title: t.overdueTasks, value: '${data.overdueTasks}'),
      ],
    );
  }
}
