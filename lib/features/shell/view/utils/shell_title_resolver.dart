import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/nav_i18n.dart';
import '../../domain/nav_menu.dart';

String resolveShellTitle(BuildContext context, {required String role}) {
  final t = AppLocalizations.of(context)!;
  final loc = GoRouterState.of(context).matchedLocation;

  if (loc == AppRoutes.dashboard) return t.menuDashboard;
  if (loc == AppRoutes.departments) return t.menuDepartments;
  if (loc == AppRoutes.jobTitles) return t.menuJobTitles;
  if (loc == AppRoutes.employees) return t.menuEmployees;
  if (loc == AppRoutes.notifications) return t.notificationsTitle;
  if (loc == AppRoutes.employeeCreate) return t.pageCreateEmployee;
  if (loc == '/profile') return t.myProfile;
  if (loc == '/change-password') return t.changePassword;

  final menu = NavMenu.forRole(role);
  if (menu.isEmpty) return t.appTitle;
  final match = menu.firstWhere((m) => m.path == loc, orElse: () => menu.first);
  return localizedNavLabel(context, match);
}
