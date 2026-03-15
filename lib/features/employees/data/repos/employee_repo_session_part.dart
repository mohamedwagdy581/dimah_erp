part of 'employee_repo_impl.dart';

mixin _EmployeesRepoSessionMixin {
  SupabaseClient get _client;

  String _toDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  Future<String> _tenantId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final me = await _client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();

    final tenantId = me['tenant_id'];
    if (tenantId == null) {
      throw Exception('Missing tenant_id for current user');
    }
    return tenantId.toString();
  }

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

  bool _isManagerRole(String role) {
    final normalized = role.trim().toLowerCase();
    return normalized == 'manager' || normalized == 'direct_manager';
  }

  String? _normalizeOptionalText(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _normalizePhotoUrl(String? photoUrl) {
    final normalized = _normalizeOptionalText(photoUrl);
    if (normalized == null || !normalized.startsWith('http')) {
      return null;
    }
    return normalized;
  }
}
