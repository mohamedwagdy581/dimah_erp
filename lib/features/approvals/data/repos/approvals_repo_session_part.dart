part of 'approvals_repo_impl.dart';

mixin _ApprovalsRepoSessionMixin {
  SupabaseClient get _client;

  Future<String> _tenantId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final me = await _client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();

    final tenantId = me['tenant_id'];
    if (tenantId == null) throw Exception('Missing tenant_id for current user');
    return tenantId.toString();
  }

  Future<({String role, String? employeeId})> _currentActor() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final me = await _client
        .from('users')
        .select('role, employee_id')
        .eq('id', uid)
        .single();

    return (
      role: (me['role'] ?? 'employee').toString(),
      employeeId: me['employee_id']?.toString(),
    );
  }
}
