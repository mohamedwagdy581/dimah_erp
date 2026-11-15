import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/session/session_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repos/notifications_repo.dart';
import '../../domain/models/notification_item.dart';
import '../widgets/notifications_list.dart';
import '../widgets/employee_notifications_view.dart';
import '../widgets/hr_notifications_view.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsRepo _repo;
  Future<List<NotificationItem>>? _future;
  String? _loadedFor;

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
          return const AppLoadingState();
        }
        final identity =
            '${state.user.id}:${state.user.tenantId}:${state.user.employeeId}:${t.localeName}';
        if (_loadedFor != identity) {
          _loadedFor = identity;
          _future = _repo.fetch(state.user, t);
        }
        return FutureBuilder<List<NotificationItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (state.user.role == 'hr') {
              return HrNotificationsView(
                key: ValueKey('${state.user.id}:${state.user.tenantId}'),
                scope: '${state.user.tenantId}:${state.user.id}',
                items: snapshot.data ?? const [],
                loading: snapshot.connectionState == ConnectionState.waiting,
                failed: snapshot.hasError,
                error: snapshot.error,
                onRefresh: () =>
                    setState(() => _future = _repo.fetch(state.user, t)),
              );
            }
            if (state.user.role == 'employee') {
              return EmployeeNotificationsView(
                key: ValueKey(identity),
                items: snapshot.data ?? const [],
                loading: snapshot.connectionState == ConnectionState.waiting,
                failed: snapshot.hasError,
                error: snapshot.error,
                onRefresh: () {
                  final next = _repo.fetch(state.user, t);
                  setState(() {
                    _future = next;
                  });
                },
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingState();
            }
            if (snapshot.hasError) {
              return AppFailureState(
                error: snapshot.error,
                onRetry: () =>
                    setState(() => _future = _repo.fetch(state.user, t)),
                title: t.failedToLoadNotifications,
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text(
                      t.notificationsTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        final nextNotifications = _repo.fetch(state.user, t);
                        setState(() {
                          _future = nextNotifications;
                        });
                      },
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
