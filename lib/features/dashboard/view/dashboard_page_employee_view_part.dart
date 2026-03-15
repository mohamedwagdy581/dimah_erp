part of 'dashboard_page.dart';

class _EmployeeDashboard extends StatelessWidget {
  const _EmployeeDashboard({required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EmployeeDashboardData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? const _EmployeeDashboardData();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _EmployeeSummarySection(data: data),
            const SizedBox(height: 12),
            _EmployeeActionCenterCard(data: data),
            const SizedBox(height: 12),
            _EmployeeNotificationsCard(data: data),
            const SizedBox(height: 12),
            _EmployeeRecentTasksCard(data: data),
          ],
        );
      },
    );
  }
}
