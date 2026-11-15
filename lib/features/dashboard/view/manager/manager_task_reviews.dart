part of '../dashboard_page.dart';

class ManagerReviewsPage extends StatelessWidget {
  const ManagerReviewsPage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<SessionCubit, SessionState>(
    builder: (context, state) {
      if (state is! SessionReady) {
        return const AppLoadingState();
      }
      if (!['manager', 'direct_manager'].contains(state.user.role) ||
          state.user.employeeId == null) {
        return const SizedBox.shrink();
      }
      return _ManagerDashboard(
        managerEmployeeId: state.user.employeeId!,
        reviewsOnly: true,
      );
    },
  );
}

class ManagerTaskReviewsView extends StatefulWidget {
  const ManagerTaskReviewsView({
    super.key,
    required this.tasks,
    required this.members,
    required this.onRefresh,
    required this.onOpenFile,
    required this.onDecision,
  });
  final List<Map<String, dynamic>> tasks;
  final List<TeamMember> members;
  final VoidCallback onRefresh;
  final ValueChanged<String> onOpenFile;
  final Future<void> Function(Map<String, dynamic>, bool, String) onDecision;
  @override
  State<ManagerTaskReviewsView> createState() => _ManagerTaskReviewsViewState();
}

class _ManagerTaskReviewsViewState extends State<ManagerTaskReviewsView> {
  String? _id, _error;
  bool _busy = false;
  final _note = TextEditingController();
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> decide(Map<String, dynamic> task, bool accept) async {
    if (_busy) return;
    final qa =
        task['status'] == 'done' &&
        (task['qa_status'] ?? 'pending') == 'pending';
    if ((!accept || !qa) && _note.text.trim().isEmpty) {
      setState(
        () => _error = tr(
          'اكتب ملاحظات المراجعة أولًا',
          'Enter review notes first',
        ),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDecision(task, accept, _note.text.trim());
      if (!mounted) return;
      _note.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? tr('تم اعتماد المراجعة', 'Review approved')
                : tr('تمت إعادة المهمة للتعديل', 'Task returned for changes'),
          ),
        ),
      );
      widget.onRefresh();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = tr(
            'تعذر حفظ القرار. حدّث البيانات ثم حاول مرة أخرى.',
            'Could not save the decision. Refresh and retry.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task =
        widget.tasks.where((t) => '${t['id']}' == _id).firstOrNull ??
        widget.tasks.firstOrNull;
    if (task == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fact_check_outlined,
              size: 48,
              color: EmployeeTheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              tr('لا توجد مهام بانتظار المراجعة', 'No tasks awaiting review'),
            ),
            TextButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(tr('تحديث', 'Refresh')),
            ),
          ],
        ),
      );
    }
    return _ManagerReviewDesign(
      task: task,
      tasks: widget.tasks,
      members: widget.members,
      note: _note,
      busy: _busy,
      error: _error,
      refresh: widget.onRefresh,
      open: widget.onOpenFile,
      decide: (accept) => decide(task, accept),
      select: (value) => setState(() {
        _id = value;
        _note.clear();
        _error = null;
      }),
    );
  }
}

extension _ManagerReviewPageActions on _ManagerDashboardState {
  Future<void> _reviewTaskFromPage(
    Map<String, dynamic> task,
    bool accept,
    String note,
  ) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Session missing');
    final actor = await client
        .from('users')
        .select('tenant_id, role, employee_id')
        .eq('id', uid)
        .single();
    if (!['manager', 'direct_manager'].contains(actor['role']) ||
        actor['employee_id'] != widget.managerEmployeeId) {
      throw StateError('Manager required');
    }
    final data = await _loadData();
    if (!data.members.any((m) => m.employeeId == task['employee_id'])) {
      throw StateError('Task outside team');
    }
    final qa =
        task['status'] == 'done' &&
        (task['qa_status'] ?? 'pending') == 'pending';
    if ((!accept || !qa) && note.isEmpty) {
      throw StateError('Review notes required');
    }
    final payload = managerReviewDecisionPayload(
      task,
      accept,
      note,
      DateTime.now(),
    );
    var query = client
        .from('employee_tasks')
        .update(payload)
        .eq('id', task['id'])
        .eq('tenant_id', actor['tenant_id'])
        .eq('employee_id', task['employee_id']);
    if (qa) {
      query = query
          .eq('status', 'done')
          .or('qa_status.is.null,qa_status.eq.pending');
    } else {
      query = query.eq('employee_review_status', 'pending');
    }
    if (task['updated_at'] != null) {
      query = query.eq('updated_at', task['updated_at']);
    }
    final updated = await query.select('id').maybeSingle();
    if (updated == null) throw StateError('Review already changed');
    await _appendTaskEvent(
      taskId: '${task['id']}',
      eventType: qa
          ? (accept ? 'qa_accepted' : 'qa_rework')
          : (accept ? 'review_approved' : 'review_rejected'),
      note: note,
    );
  }
}

Map<String, dynamic> managerReviewDecisionPayload(
  Map<String, dynamic> task,
  bool accept,
  String note,
  DateTime timestamp,
) {
  final qa =
      task['status'] == 'done' && (task['qa_status'] ?? 'pending') == 'pending';
  if ((!accept || !qa) && note.trim().isEmpty) {
    throw ArgumentError('Review notes required');
  }
  final now = timestamp.toUtc().toIso8601String();
  final payload = <String, dynamic>{
    'manager_review_note': note.trim().isEmpty ? null : note.trim(),
    'manager_reviewed_at': now,
    'updated_at': now,
  };
  if (qa) {
    payload['qa_status'] = accept ? 'accepted' : 'rework';
    if (!accept) {
      payload.addAll({
        'status': 'in_progress',
        'completed_at': null,
        'progress': TeamTask.taskProgressValue(task).clamp(0, 95),
      });
    }
    if (task['employee_review_status'] == 'pending') {
      payload['employee_review_status'] = accept ? 'approved' : 'rejected';
    }
  } else {
    payload['employee_review_status'] = accept ? 'approved' : 'rejected';
  }
  return payload;
}
