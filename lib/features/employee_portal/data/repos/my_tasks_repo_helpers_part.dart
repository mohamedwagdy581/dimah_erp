part of 'my_tasks_repo.dart';

mixin _MyTasksRepoHelpersMixin {
  SupabaseClient get _client;

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
