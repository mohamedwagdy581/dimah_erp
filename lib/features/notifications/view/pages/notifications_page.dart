import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/session/session_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repos/notifications_repo.dart';
import '../../domain/models/notification_item.dart';
import '../widgets/notifications_list.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsRepo _repo;
  Future<List<NotificationItem>>? _future;

  @override
  void initState() {
    super.initState();
    _repo = NotificationsRepo(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        if (state is! SessionReady) {
          return const Center(child: CircularProgressIndicator());
        }
        _future ??= _repo.fetch(state.user, t);
        return FutureBuilder<List<NotificationItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(t.failedToLoadNotifications));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text(t.notificationsTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _future = _repo.fetch(state.user, t)),
                      icon: const Icon(Icons.refresh),
                      label: Text(t.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                NotificationsList(items: snapshot.data ?? const []),
              ],
            );
          },
        );
      },
    );
  }
}
