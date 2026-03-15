part of 'dashboard_page.dart';

extension _HrDashboardDataHelpers on _HrDashboardState {
  Future<_HrDashboardData> _load() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const _HrDashboardData();
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    final tenantId = me['tenant_id'].toString();

    final today = DateTime.now();
    final todayStr = _ymd(today);
    final end30Str = _ymd(today.add(const Duration(days: 30)));
    final monthStart = DateTime(today.year, today.month, 1);
    final monthStartStr = _ymd(monthStart);
    final core = await _loadCoreCounts(client, tenantId, todayStr);
    final attendance = await _loadAttendanceInsights(
      client,
      tenantId,
      todayStr,
      core.activeEmployees,
    );
    final pendingItems = await _loadPendingItems(client, tenantId);
    final documents = await _loadDocumentInsights(
      client,
      tenantId,
      todayStr,
      end30Str,
      today,
    );
    final leavesThisMonth = await _loadLeavesThisMonth(
      client,
      tenantId,
      monthStartStr,
    );
    final expiryAlerts = await _loadExpiryAlerts();

    return _HrDashboardData(
      activeEmployees: core.activeEmployees,
      pendingApprovals: core.pendingApprovals,
      onLeaveToday: core.onLeaveToday,
      missingCheckInToday: attendance.missingCheckInToday < 0 ? 0 : attendance.missingCheckInToday,
      leavesThisMonth: leavesThisMonth,
      checkedInToday: attendance.checkedInToday,
      lateToday: attendance.lateToday,
      overtimeToday: attendance.overtimeToday,
      todayAttentionItems: attendance.todayAttentionItems,
      pendingItems: pendingItems,
      expiringDocuments: documents.expiringDocuments,
      totalExpiryAlerts: expiryAlerts.totalExpiryAlerts,
      urgentExpiryAlerts: expiryAlerts.urgentExpiryAlerts,
      expiredDocumentsCount: documents.expiredDocumentsCount,
      totalDocumentsWithExpiry: documents.totalDocumentsWithExpiry,
      validDocumentsWithExpiry: documents.validDocumentsWithExpiry,
      expiringDocumentTypeCounts: documents.expiringDocumentTypeCounts,
    );
  }
}
