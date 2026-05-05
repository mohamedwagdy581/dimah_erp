part of '../dashboard_page.dart';

class _EmployeeDashboardBody extends StatelessWidget {
  const _EmployeeDashboardBody({required this.data});

  final _EmployeeDashboardData data;

  @override
  Widget build(BuildContext context) {
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
  }
}
