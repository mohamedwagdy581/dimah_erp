part of '../../dashboard_page.dart';

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
            Text(
              t.employeeActionCenter,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
