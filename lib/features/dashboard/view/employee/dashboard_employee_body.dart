part of '../dashboard_page.dart';

class EmployeeDashboardView extends StatelessWidget {
  const EmployeeDashboardView({
    super.key,
    required this.data,
    required this.onRefresh,
  });
  final EmployeeDashboardData data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const Icon(
              Icons.wb_sunny_rounded,
              color: Color(0xFFF59E0B),
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.employeeName.isEmpty
                        ? (ar ? 'مرحبًا بك' : 'Welcome')
                        : '${ar ? 'مرحبًا،' : 'Hello,'} ${data.employeeName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ar
                        ? 'نتمنى لك يومًا مثمرًا ومميزًا'
                        : 'Wishing you a productive day',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MaterialLocalizations.of(context).formatFullDate(now),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              tooltip: AppLocalizations.of(context)!.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _EmployeeSummarySection(data: data),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final notifications = _EmployeeNotificationsCard(data: data);
            final tasks = _EmployeeRecentTasksCard(data: data);
            if (constraints.maxWidth < 850) {
              return Column(
                children: [notifications, const SizedBox(height: 16), tasks],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: notifications),
                const SizedBox(width: 16),
                Expanded(child: tasks),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _EmployeeActionCenterCard(data: data),
      ],
    );
  }
}
