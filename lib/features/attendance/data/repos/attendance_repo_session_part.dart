part of 'attendance_repo_impl.dart';

mixin _AttendanceRepoSessionMixin {
  SupabaseClient get _client;

  bool _isManagerRole(String role) {
    final normalized = role.trim().toLowerCase();
    return normalized == 'manager' || normalized == 'direct_manager';
  }

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

  String _toDateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day)
          .toIso8601String()
          .split('T')
          .first;

  Future<({String role, String? employeeId})> _currentUserIdentity() async {
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
