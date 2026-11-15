part of '../../dashboard_page.dart';

class _EmployeeNotificationsCard extends StatelessWidget {
  const _EmployeeNotificationsCard({required this.data});
  final EmployeeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return EmployeeDashboardCard(
      title: ar ? 'الإشعارات الحديثة' : 'Recent notifications',
      actionLabel: ar ? 'عرض الكل' : 'View all',
      onAction: () => context.go(AppRoutes.notifications),
      child: data.notifications.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: AppEmptyState(
                title: t.noEmployeeNotifications,
                compact: false,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < data.notifications.take(4).length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 13,
                      backgroundColor: data.notifications[i].color.withValues(
                        alpha: .1,
                      ),
                      child: Icon(
                        data.notifications[i].icon,
                        size: 15,
                        color: data.notifications[i].color,
                      ),
                    ),
                    title: Text(
                      _employeeNotificationTitle(t, data.notifications[i].type),
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      data.notifications[i].subtitle,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: () => context.go('/my?tab=tasks'),
                  ),
                ],
              ],
            ),
    );
  }
}
