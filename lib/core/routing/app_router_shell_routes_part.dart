part of 'app_router.dart';

final List<RouteBase> _shellRoutes = [
  GoRoute(
    path: AppRoutes.dashboard,
    pageBuilder: (_, _) => const MaterialPage(child: DashboardPage()),
  ),
  GoRoute(
    path: AppRoutes.departments,
    pageBuilder: (_, _) => const MaterialPage(child: DepartmentsPage()),
  ),
  GoRoute(
    path: AppRoutes.employees,
    pageBuilder: (_, _) => const MaterialPage(child: EmployeesPage()),
  ),
  GoRoute(
    path: '/profile',
    pageBuilder: (_, _) => const MaterialPage(child: ProfilePage()),
  ),
  GoRoute(
    path: '/change-password',
    pageBuilder: (_, _) => const MaterialPage(child: ChangePasswordPage()),
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
    builder: (context, state) {
      final issuedAtRaw = state.uri.queryParameters['issuedAt'];
      final expiresAtRaw = state.uri.queryParameters['expiresAt'];
      final oldExpiresAtRaw = state.uri.queryParameters['oldExpiresAt'];
      return EmployeeDocsPage(
        initialEmployeeId: state.uri.queryParameters['employeeId'],
        initialDocType: state.uri.queryParameters['docType'],
        initialExpiryStatus: state.uri.queryParameters['expiry'],
        autoOpenCreate: state.uri.queryParameters['openCreate'] == '1',
        initialIssuedAt:
            issuedAtRaw == null ? null : DateTime.tryParse(issuedAtRaw),
        initialExpiresAt:
            expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw),
        initialOldExpiresAt:
            oldExpiresAtRaw == null ? null : DateTime.tryParse(oldExpiresAtRaw),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.hrAlerts,
    builder: (context, state) => HrAlertsPage(
      initialTypeFilter: state.uri.queryParameters['type'],
    ),
  ),
  GoRoute(
    path: AppRoutes.hrForms,
    builder: (context, state) => const HrFormsPage(),
  ),
  GoRoute(
    path: AppRoutes.hrFormTemplate,
    builder: (context, state) {
      final templateId = state.pathParameters['templateId'] ?? '';
      return HrFormEditorPage(templateId: templateId);
    },
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
      final startRaw = state.uri.queryParameters['contractStart'];
      final endRaw = state.uri.queryParameters['contractEnd'];
      final oldEndRaw = state.uri.queryParameters['oldContractEnd'];
      return EmployeeProfilePage(
        employeeId: id,
        autoOpenAddContract: state.uri.queryParameters['openAddContract'] == '1',
        initialContractStartDate:
            startRaw == null ? null : DateTime.tryParse(startRaw),
        initialContractEndDate:
            endRaw == null ? null : DateTime.tryParse(endRaw),
        initialOldContractEndDate:
            oldEndRaw == null ? null : DateTime.tryParse(oldEndRaw),
      );
    },
  ),
];
