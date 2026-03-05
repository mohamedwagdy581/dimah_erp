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
import '../view/sections/sidebar_section.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../domain/nav_i18n.dart';
import '../domain/nav_menu.dart';
import '../view/widgets/global_search_delegate.dart';

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
  int _pendingApprovals = 0;

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
              final title = _titleForLocation(context, role: user.role);
              final sidebarCollapsed = isMobile ? false : isCollapsed;

              return AppScaffold(
                title: title,
                isCollapsed: isCollapsed,
                onToggle: () => _collapsed.value = !_collapsed.value,
                actions: [
                  if (_showApprovalsBadge(user.role))
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.tooltipApprovals,
                      onPressed: () => context.go(AppRoutes.approvals),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none),
                          if (_pendingApprovals > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _pendingApprovals > 99
                                      ? '99+'
                                      : '$_pendingApprovals',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  IconButton(
                    tooltip: AppLocalizations.of(context)!.tooltipSearch,
                    onPressed: () => _openSearch(context, role: user.role),
                    icon: const Icon(Icons.search),
                  ),
                ],
                sidebar: SidebarSection(
                  isCollapsed: sidebarCollapsed,
                  onToggle: () => _collapsed.value = !_collapsed.value,
                  role: user.role,
                  email: user.email,
                  approvalsBadgeCount: _showApprovalsBadge(user.role)
                      ? _pendingApprovals
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

  String _titleForLocation(BuildContext context, {required String role}) {
    final t = AppLocalizations.of(context)!;
    final loc = GoRouterState.of(context).matchedLocation;

    if (loc == AppRoutes.dashboard) return t.menuDashboard;
    if (loc == AppRoutes.departments) return t.menuDepartments;
    if (loc == AppRoutes.jobTitles) return t.menuJobTitles;
    if (loc == AppRoutes.employees) return t.menuEmployees;
    if (loc == AppRoutes.employeeCreate) return t.pageCreateEmployee;
    if (loc == '/profile') return t.myProfile;
    if (loc == '/change-password') return t.changePassword;

    final menu = NavMenu.forRole(role);
    if (menu.isEmpty) return t.appTitle;
    final match = menu.firstWhere(
      (m) => m.path == loc,
      orElse: () => menu.first,
    );
    return localizedNavLabel(context, match);
  }

  void _openSearch(BuildContext context, {required String role}) {
    final items = NavMenu.searchableForRole(role);
    showSearch<NavItem?>(
      context: context,
      delegate: GlobalSearchDelegate(items: items),
    );
  }

  bool _showApprovalsBadge(String role) {
    return role == 'admin' || role == 'hr' || role == 'manager' || role == 'employee';
  }

  Future<int> _pendingApprovalsCount(String role, String? employeeId) {
    final repo = AppDI.approvalsRepo;
    if (role == 'admin' || role == 'hr' || role == 'manager') {
      return repo.fetchPendingCount();
    }
    if (role == 'employee' && employeeId != null) {
      return repo.fetchProcessedCount(employeeId: employeeId);
    }
    return Future.value(0);
  }

  void _ensurePendingPolling(String role, String? employeeId) {
    final key = '$role|${employeeId ?? ''}';
    if (_pendingKey == key) return;
    _pendingKey = key;
    _pendingTimer?.cancel();
    _pendingApprovals = 0;
    _refreshPending(role, employeeId);
    _pendingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _refreshPending(role, employeeId);
    });
  }

  Future<void> _refreshPending(String role, String? employeeId) async {
    try {
      final count = await _pendingApprovalsCount(role, employeeId);
      if (!mounted) return;
      if (count != _pendingApprovals) {
        setState(() => _pendingApprovals = count);
      }
    } catch (_) {
      // Keep shell stable even if count query fails.
    }
  }
}
