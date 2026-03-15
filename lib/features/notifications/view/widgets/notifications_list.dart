import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/notification_item.dart';

class NotificationsList extends StatelessWidget {
  const NotificationsList({super.key, required this.items});

  final List<NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Text(t.noNotificationsAvailable)),
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(item.icon, color: item.color),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: item.route == null
                    ? null
                    : TextButton(
                        onPressed: () => context.go(item.route!),
                        child: Text(t.open),
                      ),
              ),
            ),
          )
          .toList(),
    );
  }
}
