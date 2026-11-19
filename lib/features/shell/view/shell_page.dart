import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../core/di/app_di.dart';
import '../../../core/session/session_cubit.dart';
import '../../../core/ui/app_breakpoints.dart';
import '../../../core/ui/employee_theme.dart';
import '../../../core/ui/admin_theme.dart';
import '../../../core/routing/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/nav_item.dart';
import '../data/repos/shell_notifications_repo.dart';
import '../view/sections/sidebar_section.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../domain/nav_menu.dart';
import '../view/widgets/global_search_delegate.dart';
import '../view/widgets/shell_action_buttons.dart';
import '../view/utils/shell_title_resolver.dart';
import 'widgets/sidebar_profile_sheet.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.child});
  final Widget child;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final ValueNotifier<bool> _collapsed = ValueNotifier(false);
  Timer? _pendingTimer;
  String? _pendingKey;
  int _notificationCount = 0;
  late final ShellNotificationsRepo _notificationsRepo;

  @override
  void initState() {
    super.initState();
    _notificationsRepo = ShellNotificationsRepo(AppDI.supabase);
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SessionCubit(AppDI.sessionRepo)..load(),
      child: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          if (state is SessionLoading) {
            return const Scaffold(body: AppLoadingState());
          }
          if (state is SessionUnauthed) {
            final t = AppLocalizations.of(context)!;
            return Scaffold(body: Center(child: Text(t.sessionMissing)));
          }
          if (state is SessionFailed) {
            return Scaffold(
              body: AppFailureState(
                onRetry: () => context.read<SessionCubit>().load(),
              ),
            );
          }

          final user = (state as SessionReady).user;
          final portalStyle =
              user.role == 'admin' ||
              user.role == 'finance_manager' ||
              user.role == 'accountant' ||
              (user.role == 'hr' &&
                  GoRouterState.of(
                    context,
                  ).matchedLocation.startsWith(AppRoutes.hrForms)) ||
              GoRouterState.of(context).matchedLocation ==
                  AppRoutes.userManagement ||
              user.role == 'employee' ||
              GoRouterState.of(
                context,
              ).matchedLocation.startsWith('/payroll') ||
              (user.role == 'hr' &&
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
              (user.role == 'hr' &&
                  GoRouterState.of(
                    context,
                  ).matchedLocation.startsWith('/employees/')) ||
              ((user.role == 'manager' || user.role == 'direct_manager') &&
                  [
                    AppRoutes.dashboard,
                    AppRoutes.managerTeam,
                    AppRoutes.managerTasks,
                    AppRoutes.managerReviews,
                    AppRoutes.managerRequests,
                    AppRoutes.managerAttendance,
                  ].contains(GoRouterState.of(context).matchedLocation));
          _ensurePendingPolling(user.role, user.employeeId);
          final isMobile = AppBreakpoints.isMobile(
            MediaQuery.sizeOf(context).width,
          );

          return Theme(
            data: user.role == 'admin'
                ? AdminTheme.from(Theme.of(context))
                : portalStyle
                ? EmployeeTheme.from(Theme.of(context))
                : Theme.of(context),
            child: ValueListenableBuilder<bool>(
              valueListenable: _collapsed,
              builder: (context, isCollapsed, _) {
                final title = resolveShellTitle(context, role: user.role);
                final sidebarCollapsed = isMobile ? false : isCollapsed;

                return AppScaffold(
                  employeeStyle: portalStyle,
                  title: title,
                  isCollapsed: isCollapsed,
                  onToggle: () => _collapsed.value = !_collapsed.value,
                  actions: buildShellActionButtons(
                    employeeStyle: portalStyle,
                    compact: isMobile,
                    profileLabel: AppLocalizations.of(context)!.myProfile,
                    onProfileTap: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => const SidebarProfileSheet(),
                    ),
                    showNotifications: _notificationsRepo.showNotificationBadge(
                      user.role,
                    ),
                    notificationsTooltip: AppLocalizations.of(
                      context,
                    )!.notificationsTitle,
                    notificationCount: _notificationCount,
                    onNotificationsTap: () =>
                        context.go(AppRoutes.notifications),
                    searchTooltip: AppLocalizations.of(context)!.tooltipSearch,
                    onSearchTap: () => _openSearch(context, role: user.role),
                  ),
                  sidebar: SidebarSection(
                    isCollapsed: sidebarCollapsed,
                    onToggle: () => _collapsed.value = !_collapsed.value,
                    role: user.role,
                    email: user.email,
                    approvalsBadgeCount:
                        _notificationsRepo.showNotificationBadge(user.role)
                        ? _notificationCount
                        : 0,
                    showToggle: !isMobile,
                    onNavigate: isMobile
                        ? () => Navigator.of(context).maybePop()
                        : null,
                  ),
                  body: widget.child,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openSearch(BuildContext context, {required String role}) {
    final items = NavMenu.searchableForRole(role);
    showSearch<NavItem?>(
      context: context,
      delegate: GlobalSearchDelegate(items: items),
    );
  }

  void _ensurePendingPolling(String role, String? employeeId) {
    final key = '$role|${employeeId ?? ''}';
    if (_pendingKey == key) return;
    _pendingKey = key;
    _pendingTimer?.cancel();
    _notificationCount = 0;
    _refreshPending(role, employeeId);
    _pendingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _refreshPending(role, employeeId);
    });
  }

  Future<void> _refreshPending(String role, String? employeeId) async {
    try {
      final count = await _notificationsRepo.fetchCount(role, employeeId);
      if (!mounted) return;
      if (count != _notificationCount) {
        setState(() => _notificationCount = count);
      }
    } catch (_) {
      // Keep shell stable even if count query fails.
    }
  }
}
