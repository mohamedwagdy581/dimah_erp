import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../l10n/app_localizations.dart';

class MyTasksSection extends StatefulWidget {
  const MyTasksSection({super.key, required this.employeeId});

  final String employeeId;

  @override
  State<MyTasksSection> createState() => _MyTasksSectionState();
}

class _MyTasksSectionState extends State<MyTasksSection> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(t.failedToLoadTasks(snapshot.error.toString())),
          );
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(t.noTasksAssigned));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = items[index];
            final status = (task['status'] ?? 'todo').toString();
            final progress = (task['progress'] as num?)?.toInt() ?? 0;
            return Card(
              key: ValueKey(task['id']),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title']?.toString() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if ((task['description'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty)
                      Text(task['description'].toString()),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: InputDecoration(
                              labelText: t.status,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'todo',
                                child: Text(t.statusTodo),
                              ),
                              DropdownMenuItem(
                                value: 'in_progress',
                                child: Text(t.statusInProgress),
                              ),
                              DropdownMenuItem(
                                value: 'done',
                                child: Text(t.statusDone),
                              ),
                            ],
                            onChanged: (v) => _updateTask(
                              id: task['id'].toString(),
                              status: v ?? status,
                              progress: v == 'done'
                                  ? 100
                                  : progress.clamp(0, 99).toInt(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 160,
                          child: Text(t.progressLabel(progress)),
                        ),
                      ],
                    ),
                    Slider(
                      value: progress.toDouble().clamp(0, 100),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$progress%',
                      onChanged: (_) {},
                      onChangeEnd: (v) => _updateTask(
                        id: task['id'].toString(),
                        status: v >= 100 ? 'done' : status,
                        progress: v.round(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const [];
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    final tenantId = me['tenant_id'].toString();
    final res = await client
        .from('employee_tasks')
        .select(
          'id, title, description, status, progress, due_date, updated_at, created_at',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', widget.employeeId)
        .order('created_at', ascending: false)
        .limit(60);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> _updateTask({
    required String id,
    required String status,
    required int progress,
  }) async {
    final client = Supabase.instance.client;
    final existing = await client
        .from('employee_tasks')
        .select('status, progress')
        .eq('id', id)
        .maybeSingle();

    final oldStatus = (existing?['status'] ?? 'todo').toString();
    final oldProgress = (existing?['progress'] as num?)?.toInt() ?? 0;
    final clamped = progress.clamp(0, 100).toInt();
    final adjustedStatus = clamped >= 100 ? 'done' : status;
    final payload = <String, dynamic>{
      'status': adjustedStatus,
      'progress': clamped,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (oldStatus != 'done' && adjustedStatus == 'done') {
      payload['completed_at'] = DateTime.now().toIso8601String();
    } else if (oldStatus == 'done' && adjustedStatus != 'done') {
      payload['completed_at'] = null;
    }
    if (oldStatus == 'todo' && adjustedStatus != 'todo') {
      payload['assignee_received_at'] = DateTime.now().toIso8601String();
    }
    if (oldStatus != 'in_progress' && adjustedStatus == 'in_progress') {
      payload['assignee_started_at'] = DateTime.now().toIso8601String();
    }

    await client.from('employee_tasks').update(payload).eq('id', id);

    await _appendTaskEvent(
      taskId: id,
      oldStatus: oldStatus,
      newStatus: adjustedStatus,
      oldProgress: oldProgress,
      newProgress: clamped,
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _appendTaskEvent({
    required String taskId,
    required String oldStatus,
    required String newStatus,
    required int oldProgress,
    required int newProgress,
  }) async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;
      final me = await client
          .from('users')
          .select('tenant_id')
          .eq('id', uid)
          .single();
      String eventType = 'progress_updated';
      if (oldStatus != newStatus) {
        eventType = 'status_changed';
      } else if (oldProgress != newProgress) {
        eventType = 'progress_updated';
      }
      await client.from('employee_task_events').insert({
        'tenant_id': me['tenant_id'].toString(),
        'task_id': taskId,
        'event_type': eventType,
        'event_note': null,
        'event_payload': {
          'old_status': oldStatus,
          'new_status': newStatus,
          'old_progress': oldProgress,
          'new_progress': newProgress,
        },
        'created_by_user_id': uid,
      });
    } catch (_) {}
  }
}
