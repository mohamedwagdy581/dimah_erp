part of 'dashboard_page.dart';

class _ManagerPendingQaSection extends StatelessWidget {
  const _ManagerPendingQaSection({
    required this.data,
    required this.onQaDecision,
    required this.onOpenExternalUrl,
    required this.taskTypeLabelBuilder,
  });

  final _ManagerDashboardData data;
  final void Function(Map<String, dynamic> task, {required String decision}) onQaDecision;
  final ValueChanged<String> onOpenExternalUrl;
  final String Function(AppLocalizations t, String type) taskTypeLabelBuilder;

  String _formatTimestamp(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '-';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.pendingTaskQa, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (data.pendingQaTasks.isEmpty)
              Text(t.noPendingTaskQa)
            else
              ...data.pendingQaTasks.map((task) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(task['title']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text(task['employee_name']?.toString() ?? '-', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${t.completedAtLabel}: ${_formatTimestamp(task['completed_at'])}'),
                      const SizedBox(height: 4),
                      Text('${t.progressLabel((task['progress'] as num?)?.toInt() ?? 0)} | ${taskTypeLabelBuilder(t, (task['task_type'] ?? 'general').toString())}'),
                      _AttachmentWrap(attachments: ((task['attachments'] as List?) ?? const []).cast<Map<String, dynamic>>(), onOpenExternalUrl: onOpenExternalUrl),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(onPressed: () => onQaDecision(task, decision: 'rejected'), icon: const Icon(Icons.block_outlined), label: Text(t.qaReject)),
                          OutlinedButton.icon(onPressed: () => onQaDecision(task, decision: 'rework'), icon: const Icon(Icons.restart_alt_outlined), label: Text(t.qaSendRework)),
                          ElevatedButton.icon(onPressed: () => onQaDecision(task, decision: 'accepted'), icon: const Icon(Icons.verified_outlined), label: Text(t.qaApprove)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
