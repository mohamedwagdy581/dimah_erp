part of 'dashboard_page.dart';

class _HrWorkflowPanel extends StatelessWidget {
  const _HrWorkflowPanel({required this.data});

  final _HrDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.hrWorkflowBoard, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _WorkflowStepCard(index: 1, title: t.reviewPendingApprovals, subtitle: t.pendingWithValue(data.pendingApprovals), color: Colors.orange, onTap: () => context.go('${AppRoutes.approvals}?status=pending')),
                _WorkflowStepCard(index: 2, title: t.resolveExpiryAlerts, subtitle: t.pendingWithValue(data.totalExpiryAlerts), color: Colors.redAccent, onTap: () => context.go(AppRoutes.hrAlerts)),
                _WorkflowStepCard(index: 3, title: t.completeEmployeeDocuments, subtitle: t.pendingWithValue(data.expiredDocumentsCount), color: Colors.indigo, onTap: () => context.go('${AppRoutes.employeeDocs}?expiry=expired')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowStepCard extends StatelessWidget {
  const _WorkflowStepCard({required this.index, required this.title, required this.subtitle, required this.color, required this.onTap});

  final int index;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: color.withValues(alpha: 0.18), foregroundColor: color, child: Text('$index')),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12))])),
          ],
        ),
      ),
    );
  }
}
