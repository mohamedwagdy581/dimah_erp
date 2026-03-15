part of 'dashboard_page.dart';

extension _HrDashboardLoadHelpers on _HrDashboardState {
  String _ymd(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  Future<({int activeEmployees, int pendingApprovals, int onLeaveToday})> _loadCoreCounts(
    SupabaseClient client,
    String tenantId,
    String todayStr,
  ) async {
    final activeEmployeesRes = await client.from('employees').select('id').eq('tenant_id', tenantId).eq('status', 'active');
    final pendingApprovalsRes = await client.from('approval_requests').select('id').eq('tenant_id', tenantId).eq('status', 'pending').eq('current_approver_role', 'hr');
    final onLeaveTodayRes = await client.from('leave_requests').select('id').eq('tenant_id', tenantId).eq('status', 'approved').lte('start_date', todayStr).gte('end_date', todayStr);
    return (
      activeEmployees: (activeEmployeesRes as List).length,
      pendingApprovals: (pendingApprovalsRes as List).length,
      onLeaveToday: (onLeaveTodayRes as List).length,
    );
  }
}
