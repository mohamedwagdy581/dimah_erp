// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/employees/view/cubit/employee_wizard_cubit.dart';
import '../../features/employees/view/pages/employee_wizard_page.dart';
import '../../features/job_titles/presentation/pages/job_titles_page.dart';
import '../../features/profile/view/change_password_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../auth/auth_notifier.dart';
import '../di/app_di.dart';
import 'app_routes.dart';

import '../../features/splash/view/splash_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/shell/view/shell_page.dart';
import '../../features/dashboard/view/dashboard_page.dart';
import '../../features/departments/view/departments_page.dart';
import '../../features/employees/view/pages/employees_page.dart';
import '../../features/employees/view/pages/employee_profile_page.dart';
import '../../features/attendance/view/pages/attendance_page.dart';
import '../../features/leaves/view/pages/leaves_page.dart';
import '../../features/payroll/view/pages/payroll_page.dart';
import '../../features/payroll/view/pages/payroll_run_page.dart';
import '../../features/employee_docs/view/pages/employee_docs_page.dart';
import '../../features/hr_alerts/view/pages/hr_alerts_page.dart';
import '../../features/approvals/view/pages/approvals_page.dart';
import '../../features/employee_portal/view/pages/employee_portal_page.dart';
import '../../features/accounting/accounts/view/pages/accounts_page.dart';
import '../../features/accounting/journal/view/pages/journal_page.dart';

class AppRouter {
  static final AuthNotifier auth = AuthNotifier();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final loc = state.matchedLocation;

      if (loc == AppRoutes.splash) return null;
      if (!loggedIn && loc != AppRoutes.login) return AppRoutes.login;
      if (loggedIn && loc == AppRoutes.login) return AppRoutes.dashboard;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, __) => const MaterialPage(child: SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, __) => const MaterialPage(child: LoginPage()),
      ),

      ShellRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (_, __) => const MaterialPage(child: DashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.departments,
            pageBuilder: (_, __) =>
                const MaterialPage(child: DepartmentsPage()),
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
            pageBuilder: (_, __) =>
                const MaterialPage(child: ChangePasswordPage()),
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
        ],
      ),
    ],
  );
}
