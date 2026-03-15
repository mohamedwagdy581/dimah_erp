part of 'dashboard_page.dart';

class _ManagerPendingReviewSection extends StatelessWidget {
  const _ManagerPendingReviewSection({
    required this.data,
    required this.onReviewDecision,
    required this.onOpenExternalUrl,
  });

  final _ManagerDashboardData data;
  final void Function(Map<String, dynamic> task, {required bool approved}) onReviewDecision;
  final ValueChanged<String> onOpenExternalUrl;

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
            Text(t.pendingTaskReviews, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (data.pendingReviewRequests.isEmpty)
              Text(t.noPendingTaskReviews)
            else
              ...data.pendingReviewRequests.map((request) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(request['title']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text(request['employee_name']?.toString() ?? '-', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${t.reviewRequestedAt}: ${_formatTimestamp(request['employee_review_requested_at'])}'),
                      const SizedBox(height: 4),
                      Text('${t.reviewNote}: ${request['employee_review_note'] ?? '-'}'),
                      _AttachmentWrap(attachments: ((request['attachments'] as List?) ?? const []).cast<Map<String, dynamic>>(), onOpenExternalUrl: onOpenExternalUrl),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(onPressed: () => onReviewDecision(request, approved: false), icon: const Icon(Icons.close_outlined), label: Text(t.reject)),
                          ElevatedButton.icon(onPressed: () => onReviewDecision(request, approved: true), icon: const Icon(Icons.check_outlined), label: Text(t.approveAndUpdate)),
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
