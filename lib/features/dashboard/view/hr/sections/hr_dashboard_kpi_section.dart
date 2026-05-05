part of '../../dashboard_page.dart';

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
        _KpiCard(
          width: kpiWidth,
          title: t.activeEmployeesKpi,
          value: '${data.activeEmployees}',
          subtitle: t.currentHeadcount,
          icon: Icons.badge_outlined,
        ),
        _KpiCard(
          width: kpiWidth,
          title: t.pendingApprovalsKpi,
          value: '${data.pendingApprovals}',
          subtitle: t.waitingHrAction,
          icon: Icons.approval_outlined,
        ),
        _KpiCard(
          width: kpiWidth,
          title: t.onLeaveTodayKpi,
          value: '${data.onLeaveToday}',
          subtitle: t.approvedLeaveToday,
          icon: Icons.event_busy_outlined,
        ),
        _KpiCard(
          width: kpiWidth,
          title: t.noCheckInTodayKpi,
          value: '${data.missingCheckInToday}',
          subtitle: t.activeStaffNotCheckedIn,
          icon: Icons.login_outlined,
        ),
        _KpiCard(
          width: kpiWidth,
          title: t.leavesThisMonthKpi,
          value: '${data.leavesThisMonth}',
          subtitle: t.approvedLeaveRequests,
          icon: Icons.date_range_outlined,
        ),
        _KpiCard(
          width: kpiWidth,
          title: t.expiryAlertsKpi,
          value: '${data.totalExpiryAlerts}',
          subtitle: t.hrAlertsTitle,
          icon: Icons.notifications_active_outlined,
        ),
        _KpiCard(
          width: kpiWidth,
          title: t.expiredDocumentsKpi,
          value: '${data.expiredDocumentsCount}',
          subtitle: t.documentExpiryNeedsAction,
          icon: Icons.warning_amber_outlined,
        ),
        _KpiCard(
          width: kpiWidth,
          title: t.urgentAlertsKpi,
          value: '${data.urgentExpiryAlerts}',
          subtitle: t.expiringWithin30Days,
          icon: Icons.crisis_alert_outlined,
        ),
      ],
    );
  }
}
