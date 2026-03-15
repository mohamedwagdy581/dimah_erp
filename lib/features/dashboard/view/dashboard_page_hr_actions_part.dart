part of 'dashboard_page.dart';

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({required this.data});

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
            Text(t.quickActions, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(onPressed: () => context.go('${AppRoutes.approvals}?status=pending'), icon: const Icon(Icons.approval_outlined), label: Text('${t.pendingApprovalsKpi} (${data.pendingApprovals})')),
                OutlinedButton.icon(onPressed: () => context.go('${AppRoutes.hrAlerts}?type=document'), icon: const Icon(Icons.notifications_active_outlined), label: Text('${t.hrAlertsTitle} (${data.totalExpiryAlerts})')),
                OutlinedButton.icon(onPressed: () => context.go('${AppRoutes.employeeDocs}?expiry=expired'), icon: const Icon(Icons.description_outlined), label: Text('${t.menuEmployeeDocs} (${data.expiringDocuments.length})')),
                OutlinedButton.icon(onPressed: () => context.go(AppRoutes.employees), icon: const Icon(Icons.people_outline), label: Text(t.activeEmployeesKpi)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
