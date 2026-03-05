import 'package:flutter/widgets.dart';

import '../../../core/routing/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import 'nav_item.dart';

String localizedNavLabel(BuildContext context, NavItem item) {
  final t = AppLocalizations.of(context)!;
  switch (item.path) {
    case AppRoutes.dashboard:
      return t.menuDashboard;
    case AppRoutes.departments:
      return t.menuDepartments;
    case AppRoutes.jobTitles:
      return t.menuJobTitles;
    case AppRoutes.employees:
      return t.menuEmployees;
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
    case AppRoutes.approvals:
      return t.menuApprovals;
    case AppRoutes.myPortal:
      return t.menuMyPortal;
    case AppRoutes.accounts:
      return t.menuAccounts;
    case AppRoutes.journal:
      return t.menuJournal;
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
  if (path == AppRoutes.accounts || path == AppRoutes.journal) {
    return t.menuSectionAccounting;
  }
  if (path == '/profile' || path == '/change-password') {
    return t.menuSectionAccount;
  }
  return t.menuSectionHr;
}
