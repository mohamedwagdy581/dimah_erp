part of 'dashboard_page.dart';

class _HrDashboardErrorView extends StatelessWidget {
  const _HrDashboardErrorView({
    required this.message,
    required this.onRetry,
  });

  final Object message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.failedToLoadHrDashboard, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Text(
              message.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(t.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _HrDashboardHeader extends StatelessWidget {
  const _HrDashboardHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(t.hrDashboard, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(t.refresh),
        ),
      ],
    );
  }
}

class _HrKpiSection extends StatelessWidget {
  const _HrKpiSection({
    required this.data,
    required this.kpiWidth,
  });

  final _HrDashboardData data;
  final double kpiWidth;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiCard(width: kpiWidth, title: t.activeEmployeesKpi, value: '${data.activeEmployees}', subtitle: t.currentHeadcount, icon: Icons.badge_outlined),
        _KpiCard(width: kpiWidth, title: t.pendingApprovalsKpi, value: '${data.pendingApprovals}', subtitle: t.waitingHrAction, icon: Icons.approval_outlined),
        _KpiCard(width: kpiWidth, title: t.onLeaveTodayKpi, value: '${data.onLeaveToday}', subtitle: t.approvedLeaveToday, icon: Icons.event_busy_outlined),
        _KpiCard(width: kpiWidth, title: t.noCheckInTodayKpi, value: '${data.missingCheckInToday}', subtitle: t.activeStaffNotCheckedIn, icon: Icons.login_outlined),
        _KpiCard(width: kpiWidth, title: t.leavesThisMonthKpi, value: '${data.leavesThisMonth}', subtitle: t.approvedLeaveRequests, icon: Icons.date_range_outlined),
        _KpiCard(width: kpiWidth, title: t.expiryAlertsKpi, value: '${data.totalExpiryAlerts}', subtitle: t.hrAlertsTitle, icon: Icons.notifications_active_outlined),
        _KpiCard(width: kpiWidth, title: t.expiredDocumentsKpi, value: '${data.expiredDocumentsCount}', subtitle: t.documentExpiryNeedsAction, icon: Icons.warning_amber_outlined),
        _KpiCard(width: kpiWidth, title: t.urgentAlertsKpi, value: '${data.urgentExpiryAlerts}', subtitle: t.expiringWithin30Days, icon: Icons.crisis_alert_outlined),
      ],
    );
  }
}

class _HrMetricSection extends StatelessWidget {
  const _HrMetricSection({
    required this.data,
    required this.isWide,
    required this.maxWidth,
  });

  final _HrDashboardData data;
  final bool isWide;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cardWidth = isWide ? (maxWidth - 24) / 2 : maxWidth;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricBarCard(width: cardWidth, title: t.checkInCoverage, value: data.checkInCoverage),
        _MetricBarCard(width: cardWidth, title: t.approvalLoad, value: data.approvalLoad, invertColor: true),
        _MetricBarCard(width: cardWidth, title: t.documentCompliance, value: data.documentCompliance),
      ],
    );
  }
}
