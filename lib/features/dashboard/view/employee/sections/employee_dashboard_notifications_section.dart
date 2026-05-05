part of '../../dashboard_page.dart';

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
            Text(
              t.employeeNotifications,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (data.notifications.isEmpty)
              Text(t.noEmployeeNotifications)
            else
              ...data.notifications.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(item.icon, color: item.color),
                  title: Text(_employeeNotificationTitle(t, item.type)),
                  subtitle: Text(item.subtitle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
