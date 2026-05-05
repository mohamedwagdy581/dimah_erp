part of '../dashboard_page.dart';

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
        return _EmployeeDashboardBody(
          data: snapshot.data ?? const _EmployeeDashboardData(),
        );
      },
    );
  }
}
