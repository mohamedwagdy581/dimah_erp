import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeePortalSummaryRepo {
  EmployeePortalSummaryRepo(this._client);

  final SupabaseClient _client;

  Future<Map<String, int>> load(String employeeId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const {};
    final me = await _client.from('users').select('tenant_id').eq('id', uid).single();
    final tenantId = me['tenant_id'].toString();
    final rows = await _client
        .from('employee_tasks')
        .select('status, qa_status, employee_review_status')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(100);
    final tasks = (rows as List).cast<Map<String, dynamic>>();
    return {
      'all': tasks.length,
      'in_progress': tasks.where((t) => t['status'] == 'in_progress').length,
      'review_pending': tasks.where((t) => (t['employee_review_status'] ?? 'none') == 'pending').length,
      'qa_pending': tasks.where((t) => t['status'] == 'done' && (t['qa_status'] ?? 'pending') == 'pending').length,
    };
  }
}
