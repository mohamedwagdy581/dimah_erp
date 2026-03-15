part of 'app_router.dart';

final List<RouteBase> _shellRoutes = [
  GoRoute(
    path: AppRoutes.dashboard,
    pageBuilder: (_, __) => const MaterialPage(child: DashboardPage()),
  ),
  GoRoute(
    path: AppRoutes.departments,
    pageBuilder: (_, __) => const MaterialPage(child: DepartmentsPage()),
  ),
  GoRoute(
    path: AppRoutes.employees,
    pageBuilder: (_, __) => const MaterialPage(child: EmployeesPage()),
  ),
  GoRoute(
    path: '/profile',
    pageBuilder: (_, __) => const MaterialPage(child: ProfilePage()),
  ),
  GoRoute(
    path: '/change-password',
    pageBuilder: (_, __) => const MaterialPage(child: ChangePasswordPage()),
  ),
  GoRoute(
    path: AppRoutes.jobTitles,
    builder: (context, state) => const JobTitlesPage(),
  ),
  GoRoute(
    path: AppRoutes.attendance,
    builder: (context, state) => const AttendancePage(),
  ),
  GoRoute(
    path: AppRoutes.leaves,
    builder: (context, state) => const LeavesPage(),
  ),
  GoRoute(
    path: AppRoutes.payroll,
    builder: (context, state) => const PayrollPage(),
  ),
  GoRoute(
    path: AppRoutes.payrollRun,
    builder: (context, state) {
      final runId = state.pathParameters['runId'] ?? '';
      return PayrollRunPage(runId: runId);
    },
  ),
  GoRoute(
    path: AppRoutes.employeeDocs,
    builder: (context, state) => EmployeeDocsPage(
      initialDocType: state.uri.queryParameters['docType'],
      initialExpiryStatus: state.uri.queryParameters['expiry'],
    ),
  ),
  GoRoute(
    path: AppRoutes.hrAlerts,
    builder: (context, state) => HrAlertsPage(
      initialTypeFilter: state.uri.queryParameters['type'],
    ),
  ),
  GoRoute(
    path: AppRoutes.approvals,
    builder: (context, state) => ApprovalsPage(
      initialStatus: state.uri.queryParameters['status'],
      initialRequestType: state.uri.queryParameters['requestType'],
    ),
  ),
  GoRoute(
    path: AppRoutes.notifications,
    builder: (context, state) => const NotificationsPage(),
  ),
  GoRoute(
    path: AppRoutes.myPortal,
    builder: (context, state) => const EmployeePortalPage(),
  ),
  GoRoute(
    path: AppRoutes.accounts,
    builder: (context, state) => const AccountsPage(),
  ),
  GoRoute(
    path: AppRoutes.journal,
    builder: (context, state) => const JournalPage(),
  ),
  GoRoute(
    path: AppRoutes.employeeCreate,
    builder: (context, state) => BlocProvider(
      create: (_) => EmployeeWizardCubit(AppDI.employeesRepo),
      child: const EmployeeWizardPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.employeeProfile,
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return EmployeeProfilePage(employeeId: id);
    },
  ),
];
