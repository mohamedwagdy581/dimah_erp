// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';

import '../../domain/nav_i18n.dart';
import '../../domain/nav_menu.dart';
import '../widgets/sidebar_item.dart';
import '../widgets/sidebar_logo.dart';
import '../widgets/sidebar_toggle_button.dart';
import '../widgets/sidebar_user_card.dart';
import '../widgets/sidebar_profile_sheet.dart';

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
    final items = NavMenu.forRole(role);
    final current = GoRouterState.of(context).matchedLocation;
    final cs = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: _expandedW,
        end: isCollapsed ? _collapsedW : _expandedW,
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, w, child) {
        return Container(
          width: w,
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              right: BorderSide(color: cs.outlineVariant.withOpacity(.6)),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                SidebarLogo(isCollapsed: w < 160),
                const SizedBox(height: 6),
                if (showToggle)
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
                      final active =
                          current == item.path ||
                          (item.path != '/' &&
                              current.startsWith('${item.path}/'));

                      return SidebarItem(
                        isCollapsed: w < 160,
                        icon: item.icon,
                        label: localizedNavLabel(context, item),
                        badgeCount: item.path == AppRoutes.approvals
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
                SidebarUserCard(
                  sidebarWidth: w,
                  email: email,
                  role: role,
                  onTap: () => _openProfileMenu(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const SidebarProfileSheet(),
    );
  }
}
