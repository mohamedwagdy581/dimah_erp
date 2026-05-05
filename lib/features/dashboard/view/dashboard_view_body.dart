part of 'dashboard_page.dart';

class _DashboardViewBody extends StatelessWidget {
  const _DashboardViewBody({required this.state});

  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (state is! SessionReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = (state as SessionReady).user;
    if (user.role == 'hr') {
      return const _HrDashboard();
    }
    if ((user.role == 'manager' || user.role == 'direct_manager') &&
        user.employeeId != null) {
      return _ManagerDashboard(managerEmployeeId: user.employeeId!);
    }
    if (user.role == 'employee' && user.employeeId != null) {
      return _EmployeeDashboard(employeeId: user.employeeId!);
    }
    return _BackOfficeDashboard(title: t.menuDashboard);
  }
}
