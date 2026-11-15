import 'package:flutter/widgets.dart';

import '../../../core/routing/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import 'nav_item.dart';

String localizedNavLabel(BuildContext context, NavItem item) {
  final t = AppLocalizations.of(context)!;
  switch (item.path) {
    case AppRoutes.financeTeam:
      return t.localeName.startsWith('ar') ? 'فريق المالية' : 'Finance team';
    case AppRoutes.managerAttendance:
      return t.localeName.startsWith('ar') ? 'الحضور' : 'Attendance';
    case AppRoutes.managerRequests:
      return t.localeName.startsWith('ar') ? 'طلبات الفريق' : 'Team requests';
    case AppRoutes.managerTasks:
      return Localizations.localeOf(context).languageCode == 'ar'
          ? 'المهام'
          : 'Tasks';
    case AppRoutes.managerTeam:
    case AppRoutes.managerReviews:
      if (item.path == AppRoutes.managerReviews) {
        return t.localeName.startsWith('ar') ? 'المراجعات' : 'Reviews';
      }
      return Localizations.localeOf(context).languageCode == 'ar'
          ? 'فريقي'
          : 'My team';
    case AppRoutes.dashboard:
      return t.menuDashboard;
    case AppRoutes.departments:
      return item.label == 'Departments & job titles'
          ? (Localizations.localeOf(context).languageCode == 'ar'
                ? 'الأقسام والمسميات'
                : 'Departments & job titles')
          : t.menuDepartments;
    case AppRoutes.jobTitles:
      return t.menuJobTitles;
    case AppRoutes.employees:
      return t.menuEmployees;
    case AppRoutes.settlements:
      return t.localeName.startsWith('ar') ? 'المخالصات' : t.menuSettlements;
    case AppRoutes.attendance:
      return t.menuAttendance;
    case AppRoutes.leaves:
      return t.menuLeaves;
    case AppRoutes.payroll:
      return t.menuPayroll;
    case AppRoutes.employeeDocs:
      return t.menuEmployeeDocs;
    case AppRoutes.hrAlerts:
      return t.menuHrAlerts;
    case AppRoutes.hrForms:
      return Localizations.localeOf(context).languageCode == 'ar'
          ? 'النماذج'
          : 'HR Forms';
    case AppRoutes.approvals:
      return t.menuApprovals;
    case AppRoutes.notifications:
      return t.notificationsTitle;
    case AppRoutes.userManagement:
      return t.localeName.startsWith('ar')
          ? 'المستخدمون والصلاحيات'
          : 'Users and permissions';
    case AppRoutes.myPortal:
      return t.menuMyPortal;
    case AppRoutes.accounts:
      return t.menuAccounts;
    case AppRoutes.journal:
      return t.menuJournal;
    case AppRoutes.ledger:
      return t.localeName.startsWith('ar') ? 'دفتر الأستاذ' : 'General Ledger';
    case AppRoutes.trialBalance:
      return t.localeName.startsWith('ar') ? 'ميزان المراجعة' : 'Trial Balance';
    case '/profile':
      return t.myProfile;
    case '/change-password':
      return t.changePassword;
    default:
      return item.label;
  }
}

String localizedNavSection(BuildContext context, NavItem item) {
  final t = AppLocalizations.of(context)!;
  final path = item.path;
  if (path == AppRoutes.dashboard) return t.menuSectionGeneral;
  if (path == AppRoutes.myPortal) return t.menuSectionEmployee;
  if (path == AppRoutes.accounts ||
      path == AppRoutes.journal ||
      path == AppRoutes.ledger ||
      path == AppRoutes.trialBalance) {
    return t.menuSectionAccounting;
  }
  if (path == '/profile' || path == '/change-password') {
    return t.menuSectionAccount;
  }
  return t.menuSectionHr;
}
