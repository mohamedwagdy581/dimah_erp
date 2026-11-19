import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/ui/employee_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/nav_item.dart';

import '../../domain/nav_i18n.dart';
import '../../domain/nav_menu.dart';
import '../widgets/sidebar_item.dart';
import '../widgets/sidebar_logo.dart';
import '../../../../core/ui/app_assets.dart';
import '../widgets/sidebar_toggle_button.dart';

class SidebarSection extends StatelessWidget {
  const SidebarSection({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.role,
    required this.email,
    this.approvalsBadgeCount = 0,
    this.showToggle = true,
    this.onNavigate,
  });

  final bool isCollapsed;
  final VoidCallback onToggle;
  final String role;
  final String email;
  final int approvalsBadgeCount;
  final bool showToggle;
  final VoidCallback? onNavigate;

  static const double _expandedW = 260;
  static const double _collapsedW = 76;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEmployee = role == 'employee';
    final portalStyle =
        role == 'admin' ||
        role == 'finance_manager' ||
        role == 'accountant' ||
        (role == 'hr' &&
            GoRouterState.of(
              context,
            ).matchedLocation.startsWith(AppRoutes.hrForms)) ||
        GoRouterState.of(context).matchedLocation == AppRoutes.userManagement ||
        isEmployee ||
        GoRouterState.of(context).matchedLocation.startsWith('/payroll') ||
        (role == 'hr' &&
            [
              AppRoutes.dashboard,
              AppRoutes.employees,
              AppRoutes.departments,
              AppRoutes.jobTitles,
              AppRoutes.attendance,
              AppRoutes.employeeDocs,
              AppRoutes.hrAlerts,
              AppRoutes.settlements,
              AppRoutes.notifications,
              AppRoutes.approvals,
              AppRoutes.approvals,
            ].contains(GoRouterState.of(context).matchedLocation)) ||
        (role == 'hr' &&
            GoRouterState.of(
              context,
            ).matchedLocation.startsWith('/employees/')) ||
        ((role == 'manager' || role == 'direct_manager') &&
            [
              AppRoutes.dashboard,
              AppRoutes.managerTeam,
              AppRoutes.managerTasks,
              AppRoutes.managerReviews,
              AppRoutes.managerRequests,
              AppRoutes.managerAttendance,
            ].contains(GoRouterState.of(context).matchedLocation));
    final items = isEmployee
        ? <NavItem>[
            NavItem(
              path: '/',
              label: t.menuDashboard,
              icon: Icons.home_outlined,
              allowedRoles: const ['employee'],
              section: 'employee',
              keywords: const [],
            ),
            NavItem(
              path: '/my?tab=tasks',
              label: t.myTasks,
              icon: Icons.task_alt,
              allowedRoles: const ['employee'],
              section: 'employee',
              keywords: const [],
            ),
            NavItem(
              path: '/my?tab=requests',
              label: t.myRequests,
              icon: Icons.assignment_outlined,
              allowedRoles: const ['employee'],
              section: 'employee',
              keywords: const [],
            ),
            NavItem(
              path: AppRoutes.notifications,
              label: t.notificationsTitle,
              icon: Icons.notifications_outlined,
              allowedRoles: const ['employee'],
              section: 'employee',
              keywords: const [],
            ),
            NavItem(
              path: '/profile',
              label: t.myProfile,
              icon: Icons.person_outline,
              allowedRoles: const ['employee'],
              section: 'employee',
              keywords: const [],
            ),
            NavItem(
              path: '/my?tab=attendance',
              label: t.myAttendance,
              icon: Icons.calendar_month_outlined,
              allowedRoles: const ['employee'],
              section: 'employee',
              keywords: const [],
            ),
          ]
        : NavMenu.forRole(role);
    final current = GoRouterState.of(context).matchedLocation;
    final currentUri = GoRouterState.of(context).uri;
    final cs = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: _expandedW,
        end: isCollapsed ? _collapsedW : (portalStyle ? 196 : _expandedW),
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, w, child) {
        return Container(
          width: w,
          decoration: BoxDecoration(
            color: portalStyle ? null : cs.surface,
            gradient: portalStyle
                ? const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [EmployeeTheme.light, EmployeeTheme.dark],
                  )
                : null,
            border: Border(
              right: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (portalStyle)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: w >= 160
                        ? Image.asset(
                            AppAssets.whiteLogo,
                            height: 96,
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            AppAssets.whiteMark,
                            height: 36,
                            width: 36,
                            fit: BoxFit.contain,
                          ),
                  )
                else
                  SidebarLogo(isCollapsed: w < 160),
                const SizedBox(height: 6),
                if (showToggle && !portalStyle)
                  SidebarToggleButton(
                    isCollapsed: w < 160,
                    onPressed: onToggle,
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final active = isEmployee && item.path.startsWith('/my?')
                          ? current == AppRoutes.myPortal &&
                                ((currentUri.queryParameters['tab'] == 'leaves'
                                            ? 'requests'
                                            : currentUri
                                                  .queryParameters['tab']) ??
                                        'tasks') ==
                                    Uri.parse(item.path).queryParameters['tab']
                          : (role == 'hr' &&
                                    current == AppRoutes.jobTitles &&
                                    item.path == AppRoutes.departments) ||
                                current == item.path ||
                                (item.path != '/' &&
                                    current.startsWith('${item.path}/'));

                      return SidebarItem(
                        showActiveIndicator: portalStyle && !isEmployee,
                        employeeStyle: portalStyle,
                        isCollapsed: w < 160,
                        icon:
                            portalStyle &&
                                !isEmployee &&
                                item.path == AppRoutes.dashboard
                            ? Icons.home_rounded
                            : item.icon,
                        label: isEmployee
                            ? item.label
                            : localizedNavLabel(context, item),
                        badgeCount:
                            item.path == AppRoutes.approvals ||
                                (isEmployee &&
                                    item.path == AppRoutes.notifications)
                            ? approvalsBadgeCount
                            : 0,
                        active: active,
                        onTap: () {
                          context.go(item.path);
                          onNavigate?.call();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
