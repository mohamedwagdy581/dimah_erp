part of 'dashboard_page.dart';

extension _ManagerDashboardWeightHelpers on _ManagerDashboardState {
  Future<int> _resolveAutoWeight({
    required String tenantId,
    required String employeeId,
    required String taskType,
  }) async {
    final client = Supabase.instance.client;
    try {
      final emp = await client
          .from('employees')
          .select('department_id')
          .eq('tenant_id', tenantId)
          .eq('id', employeeId)
          .maybeSingle();
      final departmentId = emp?['department_id']?.toString();

      if (departmentId != null && departmentId.isNotEmpty) {
        final deptRow = await client
            .from('task_type_weights')
            .select('weight')
            .eq('tenant_id', tenantId)
            .eq('department_id', departmentId)
            .eq('task_type', taskType)
            .maybeSingle();
        final w = (deptRow?['weight'] as num?)?.toInt();
        if (w != null) return w.clamp(1, 5);
      }

      final globalRow = await client
          .from('task_type_weights')
          .select('weight')
          .eq('tenant_id', tenantId)
          .filter('department_id', 'is', null)
          .eq('task_type', taskType)
          .maybeSingle();
      final globalW = (globalRow?['weight'] as num?)?.toInt();
      if (globalW != null) return globalW.clamp(1, 5);
    } catch (_) {}
    return _defaultWeightForType(taskType);
  }
}
