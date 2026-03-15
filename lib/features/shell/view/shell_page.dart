import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../core/di/app_di.dart';
import '../../../core/session/session_cubit.dart';
import '../../../core/ui/app_breakpoints.dart';
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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is SessionUnauthed) {
            final t = AppLocalizations.of(context)!;
            return Scaffold(
              body: Center(child: Text(t.sessionMissing)),
            );
          }

          final user = (state as SessionReady).user;
          _ensurePendingPolling(user.role, user.employeeId);
          final isMobile = AppBreakpoints.isMobile(
            MediaQuery.sizeOf(context).width,
          );

          return ValueListenableBuilder<bool>(
            valueListenable: _collapsed,
            builder: (context, isCollapsed, _) {
              final title = resolveShellTitle(context, role: user.role);
              final sidebarCollapsed = isMobile ? false : isCollapsed;

              return AppScaffold(
                title: title,
                isCollapsed: isCollapsed,
                onToggle: () => _collapsed.value = !_collapsed.value,
                actions: buildShellActionButtons(
                  showNotifications: _notificationsRepo.showNotificationBadge(user.role),
                  notificationsTooltip: AppLocalizations.of(context)!.notificationsTitle,
                  notificationCount: _notificationCount,
                  onNotificationsTap: () => context.go(AppRoutes.notifications),
                  searchTooltip: AppLocalizations.of(context)!.tooltipSearch,
                  onSearchTap: () => _openSearch(context, role: user.role),
                ),
                sidebar: SidebarSection(
                  isCollapsed: sidebarCollapsed,
                  onToggle: () => _collapsed.value = !_collapsed.value,
                  role: user.role,
                  email: user.email,
                  approvalsBadgeCount: _notificationsRepo.showNotificationBadge(user.role)
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
