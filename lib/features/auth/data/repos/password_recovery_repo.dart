import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PasswordRecoveryRepo {
  Future<void> sendCode(String email);
  Future<void> verifyCode(String email, String code);
}

class SupabasePasswordRecoveryRepo implements PasswordRecoveryRepo {
  SupabasePasswordRecoveryRepo(this.client);
  final SupabaseClient client;
  @override
  Future<void> sendCode(String email) =>
      client.auth.resetPasswordForEmail(email.trim());
  @override
  Future<void> verifyCode(String email, String code) async {
    final response = await client.auth.verifyOTP(
      email: email.trim(),
      token: code,
      type: OtpType.recovery,
    );
    if (response.session == null) {
      throw const AuthException('Recovery session required');
    }
  }
}
