part of 'my_tasks_repo.dart';

mixin _MyTasksRepoHelpersMixin {
  SupabaseClient get _client;

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<Map<String, dynamic>?> _currentUserTenant() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return null;
    }
    final me = await _client.from('users').select('tenant_id').eq('id', uid).single();
    return {
      'user_id': uid,
      'tenant_id': me['tenant_id'].toString(),
    };
  }
}
