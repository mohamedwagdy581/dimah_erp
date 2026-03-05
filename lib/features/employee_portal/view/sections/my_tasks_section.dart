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
          return Center(child: Text(t.failedToLoadTasks(snapshot.error.toString())));
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(t.noTasksAssigned));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = items[index];
            final status = (task['status'] ?? 'todo').toString();
            final progress = (task['progress'] as num?)?.toInt() ?? 0;
            return Card(
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
                    if ((task['description'] ?? '').toString().trim().isNotEmpty)
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
                      onChanged: (v) => _updateTask(
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
        .select('id, title, description, status, progress, due_date, updated_at')
        .eq('tenant_id', tenantId)
        .eq('employee_id', widget.employeeId)
        .order('updated_at', ascending: false)
        .limit(60);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> _updateTask({
    required String id,
    required String status,
    required int progress,
  }) async {
    final clamped = progress.clamp(0, 100).toInt();
    final adjustedStatus = clamped >= 100 ? 'done' : status;
    await Supabase.instance.client
        .from('employee_tasks')
        .update({
          'status': adjustedStatus,
          'progress': clamped,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    if (!mounted) return;
    await _reload();
  }
}
