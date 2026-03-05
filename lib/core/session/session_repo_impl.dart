import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_user.dart';
import 'session_repo.dart';

class SessionRepoImpl implements SessionRepo {
  SessionRepoImpl(this._client);
  final SupabaseClient _client;

  @override
  Future<AppUser?> getCurrentAppUser() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final data = await _client
        .from('users')
        .select('id,email,role,tenant_id,employee_id')
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return null;
    return AppUser.fromJson(Map<String, dynamic>.from(data));
  }
}
