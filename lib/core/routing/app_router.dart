// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounting/accounts/view/pages/accounts_page.dart';
import '../../features/accounting/journal/view/pages/journal_page.dart';
import '../../features/approvals/view/pages/approvals_page.dart';
import '../../features/attendance/view/pages/attendance_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/dashboard/view/dashboard_page.dart';
import '../../features/departments/view/departments_page.dart';
import '../../features/employee_docs/view/pages/employee_docs_page.dart';
import '../../features/employee_portal/view/pages/employee_portal_page.dart';
import '../../features/employees/view/cubit/employee_wizard_cubit.dart';
import '../../features/employees/view/pages/employee_profile_page.dart';
import '../../features/employees/view/pages/employee_wizard_page.dart';
import '../../features/employees/view/pages/employees_page.dart';
import '../../features/hr_alerts/view/pages/hr_alerts_page.dart';
import '../../features/job_titles/presentation/pages/job_titles_page.dart';
import '../../features/leaves/view/pages/leaves_page.dart';
import '../../features/notifications/view/pages/notifications_page.dart';
import '../../features/payroll/view/pages/payroll_page.dart';
import '../../features/payroll/view/pages/payroll_run_page.dart';
import '../../features/profile/view/change_password_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../../features/shell/view/shell_page.dart';
import '../../features/splash/view/splash_page.dart';
import '../auth/auth_notifier.dart';
import '../di/app_di.dart';
import 'app_routes.dart';

part 'app_router_redirect_part.dart';
part 'app_router_shell_routes_part.dart';

class AppRouter {
  static final AuthNotifier auth = AuthNotifier();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: _redirect,
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
        routes: _shellRoutes,
      ),
    ],
  );
}
