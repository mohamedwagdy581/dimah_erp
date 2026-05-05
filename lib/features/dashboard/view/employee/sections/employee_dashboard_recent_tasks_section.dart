part of '../../dashboard_page.dart';

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
              ...data.recentTasks.map(
                (task) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(task['title']?.toString() ?? '-'),
                  subtitle: Text(
                    '${t.status}: ${task['status']} | '
                    '${t.progressLabel(((task['progress'] as num?)?.toInt() ?? 0))} | '
                    '${t.qaLabel((task['qa_status'] ?? 'pending').toString())}',
                  ),
                  trailing: (task['due_date'] ?? '').toString().isEmpty
                      ? null
                      : Text(_dateOnlyFromRaw(task['due_date']?.toString())),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
