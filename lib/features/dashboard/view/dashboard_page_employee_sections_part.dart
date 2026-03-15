part of 'dashboard_page.dart';

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
                  _ProductivityCircle(value: data.productivityPercent, title: t.productivity),
                  const SizedBox(height: 8),
                  _AnimatedProgressBar(value: data.monthCompletionRate, color: const Color(0xFF38BDF8)),
                  const SizedBox(height: 8),
                  Text('${t.monthCompletionRate}: ${data.monthCompletionRate.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _EmployeeActionCenterCard extends StatelessWidget {
  const _EmployeeActionCenterCard({required this.data});

  final _EmployeeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.employeeActionCenter, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(t.pendingWithValue(data.pendingTasks))),
                Chip(label: Text(t.reviewPendingWithValue(data.reviewPendingTasks))),
                Chip(label: Text(t.qaPendingWithValue(data.qaPendingTasks))),
                Chip(label: Text(t.dueSoonWithValue(data.dueSoonTasks))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeNotificationsCard extends StatelessWidget {
  const _EmployeeNotificationsCard({required this.data});

  final _EmployeeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.employeeNotifications, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (data.notifications.isEmpty)
              Text(t.noEmployeeNotifications)
            else
              ...data.notifications.map((item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(item.icon, color: item.color),
                    title: Text(_employeeNotificationTitle(t, item.type)),
                    subtitle: Text(item.subtitle),
                  )),
          ],
        ),
      ),
    );
  }
}

class _EmployeeRecentTasksCard extends StatelessWidget {
  const _EmployeeRecentTasksCard({required this.data});

  final _EmployeeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.recentTasks, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (data.recentTasks.isEmpty)
              Text(t.noTasksAssignedYet)
            else
              ...data.recentTasks.map((task) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(task['title']?.toString() ?? '-'),
                    subtitle: Text('${t.status}: ${task['status']} | ${t.progressLabel(((task['progress'] as num?)?.toInt() ?? 0))} | ${t.qaLabel((task['qa_status'] ?? 'pending').toString())}'),
                    trailing: (task['due_date'] ?? '').toString().isEmpty ? null : Text(_dateOnlyFromRaw(task['due_date']?.toString())),
                  )),
          ],
        ),
      ),
    );
  }
}
