part of 'dashboard_page.dart';

class _DashboardViewBody extends StatelessWidget {
  const _DashboardViewBody({required this.state});

  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (state is! SessionReady) {
      return const AppLoadingState();
    }

    final user = (state as SessionReady).user;
    if (user.role == 'admin') {
      return const AdminHomePage();
    }
    if (user.role == 'finance_manager' || user.role == 'accountant') {
      return const FinanceHomePage();
    }
    if (user.role == 'hr') {
      return const HrHomePage();
    }
    if ((user.role == 'manager' || user.role == 'direct_manager') &&
        user.employeeId != null) {
      return const ManagerHomePage();
    }
    if (user.role == 'employee' && user.employeeId != null) {
      return _EmployeeDashboard(employeeId: user.employeeId!);
    }
    return _BackOfficeDashboard(title: t.menuDashboard);
  }
}
