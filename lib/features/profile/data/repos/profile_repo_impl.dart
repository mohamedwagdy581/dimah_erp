import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repos/profile_repo.dart';

class ProfileRepoImpl implements ProfileRepo {
  ProfileRepoImpl(this._client);
  final SupabaseClient _client;

  @override
  Future<({String name, String phone})> getProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not logged in');

    final data = await _client
        .from('users')
        .select('name, phone')
        .eq('id', uid)
        .single();

    return (
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
    );
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not logged in');

    await _client
        .from('users')
        .update({
          'name': name,
          'phone': phone,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', uid);
  }
}
