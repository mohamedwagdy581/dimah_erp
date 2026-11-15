import 'package:flutter/material.dart';
import '../../../../core/ui/employee_theme.dart';

List<Widget> buildShellActionButtons({
  required bool showNotifications,
  required String notificationsTooltip,
  required int notificationCount,
  required VoidCallback onNotificationsTap,
  required String searchTooltip,
  required VoidCallback onSearchTap,
  bool employeeStyle = false,
  bool compact = false,
  String profileLabel = '',
  VoidCallback? onProfileTap,
}) {
  return [
    if (showNotifications)
      IconButton(
        tooltip: notificationsTooltip,
        onPressed: onNotificationsTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none),
            if (notificationCount > 0)
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
                    notificationCount > 99 ? '99+' : '$notificationCount',
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
    if (employeeStyle && !compact)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SizedBox(
          width: 220,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              foregroundColor: const Color(0xFF667085),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onSearchTap,
            icon: const Icon(Icons.search, size: 18),
            label: Text(searchTooltip),
          ),
        ),
      )
    else
      IconButton(
        tooltip: searchTooltip,
        onPressed: onSearchTap,
        icon: const Icon(Icons.search),
      ),
    if (onProfileTap != null)
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: IconButton(
          tooltip: profileLabel,
          onPressed: onProfileTap,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: EmployeeTheme.primary,
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
  ];
}
