import 'package:flutter/material.dart';

List<Widget> buildShellActionButtons({
  required bool showNotifications,
  required String notificationsTooltip,
  required int notificationCount,
  required VoidCallback onNotificationsTap,
  required String searchTooltip,
  required VoidCallback onSearchTap,
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    IconButton(
      tooltip: searchTooltip,
      onPressed: onSearchTap,
      icon: const Icon(Icons.search),
    ),
  ];
}
