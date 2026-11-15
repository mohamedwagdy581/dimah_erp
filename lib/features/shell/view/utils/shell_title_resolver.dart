import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/nav_i18n.dart';
import '../../domain/nav_menu.dart';

String resolveShellTitle(BuildContext context, {required String role}) {
  final t = AppLocalizations.of(context)!;
  final loc = GoRouterState.of(context).matchedLocation;
  if (loc == AppRoutes.approvals) return t.menuApprovals;
  if (loc == AppRoutes.financeTeam) {
    return t.localeName.startsWith('ar') ? 'فريق المالية' : 'Finance team';
  }
  if (role == 'hr' && loc.startsWith(AppRoutes.hrForms)) {
    return t.localeName.startsWith('ar') ? 'نماذج الموارد البشرية' : 'HR forms';
  }
  if (role == 'hr' && loc == AppRoutes.hrAlerts) {
    return t.localeName.startsWith('ar') ? 'تنبيهات الانتهاء' : 'Expiry alerts';
  }
  if (role == 'hr' && loc == AppRoutes.employeeDocs) {
    return t.localeName.startsWith('ar')
        ? 'مستندات الموظفين'
        : 'Employee documents';
  }
  if (role == 'hr' && loc == AppRoutes.attendance) {
    return t.localeName.startsWith('ar') ? 'الحضور والانصراف' : 'Attendance';
  }
  if (role == 'hr' &&
      loc == AppRoutes.payroll &&
      GoRouterState.of(context).uri.queryParameters['history'] != '1') {
    return t.localeName.startsWith('ar')
        ? 'تجهيز مسير الرواتب'
        : 'Prepare payroll';
  }
  if (loc == AppRoutes.managerAttendance) {
    return t.localeName.startsWith('ar') ? 'حضور الفريق' : 'Team attendance';
  }
  if (loc == AppRoutes.managerRequests) {
    return t.localeName.startsWith('ar') ? 'طلبات الفريق' : 'Team requests';
  }
  if (loc == AppRoutes.managerTasks) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'المهام'
        : 'Tasks';
  }
  if (loc == AppRoutes.managerTeam) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'فريقي'
        : 'My team';
  }
  if (loc == AppRoutes.managerReviews) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'المراجعات'
        : 'Reviews';
  }

  if (loc == AppRoutes.dashboard) return t.menuDashboard;
  if (loc == AppRoutes.departments) {
    return role == 'hr'
        ? (t.localeName.startsWith('ar')
              ? 'الأقسام والمسميات'
              : 'Departments & job titles')
        : t.menuDepartments;
  }
  if (role == 'hr' && loc == AppRoutes.jobTitles) {
    return t.localeName.startsWith('ar')
        ? 'الأقسام والمسميات'
        : 'Departments & job titles';
  }
  if (loc == AppRoutes.jobTitles) return t.menuJobTitles;
  if (loc == AppRoutes.employees) return t.menuEmployees;
  if (loc == AppRoutes.notifications) return t.notificationsTitle;
  if (loc == AppRoutes.employeeCreate) return t.pageCreateEmployee;
  if (loc.startsWith('/employees/')) return t.employeeProfileTitle;
  if (loc == '/profile') return t.myProfile;
  if (loc == '/change-password') return t.changePassword;
  if (role == 'employee' && loc == '/my') {
    return switch (GoRouterState.of(context).uri.queryParameters['tab']) {
      'requests' => t.myRequests,
      'leaves' => t.myRequests,
      'attendance' => t.myAttendance,
      _ => t.myTasks,
    };
  }

  final menu = NavMenu.forRole(role);
  if (menu.isEmpty) return t.appTitle;
  final match = menu.firstWhere((m) => m.path == loc, orElse: () => menu.first);
  return localizedNavLabel(context, match);
}
