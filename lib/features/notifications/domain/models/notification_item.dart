import 'package:material_ui/material_ui.dart';

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
    this.category = 'updates',
    this.id,
    this.occurredAt,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;
  final String category;
  final String? id;
  final DateTime? occurredAt;
}
