import 'dart:convert';
import 'package:erp_sys/features/auth/data/repos/password_recovery_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'employee_attendance_repo_test.dart' show server;

class RecoveryTestStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

void main() {
  test(
    'Recovery requests existing-account email, never signs up or uses localhost',
    () async {
      final client = await server((request) async {
        expect(request.uri.path, '/auth/v1/recover');
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        expect(body['email'], 'fixture@example.test');
        expect(body.containsKey('create_user'), isFalse);
        expect(request.uri.toString().contains('localhost'), isFalse);
        return {};
      }, asyncStorage: RecoveryTestStorage());
      await SupabasePasswordRecoveryRepo(
        client,
      ).sendCode(' fixture@example.test ');
    },
  );
  test(
    'Verify explicitly uses recovery type and emits password recovery event',
    () async {
      final client = await server((request) async {
        expect(request.uri.path, '/auth/v1/verify');
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        expect(body['type'], 'recovery');
        expect(body['email'], 'fixture@example.test');
        expect(body['token'], '123456');
        final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
        final token =
            '${base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256'})))}.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'auth-fixture', 'exp': exp})))}.test-signature';
        return {
          'access_token': token,
          'refresh_token': 'test-refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': 'auth-fixture',
            'aud': 'authenticated',
            'email': 'fixture@example.test',
            'created_at': '2026-10-11T00:00:00Z',
          },
        };
      });
      final event = client.auth.onAuthStateChange.firstWhere(
        (state) => state.event == AuthChangeEvent.passwordRecovery,
      );
      await SupabasePasswordRecoveryRepo(
        client,
      ).verifyCode('fixture@example.test', '123456');
      expect((await event).session, isNotNull);
    },
  );
  test('Expired server code cannot produce recovery session', () async {
    final client = await server((request) async {
      expect(request.uri.path, '/auth/v1/verify');
      request.response.statusCode = 403;
      return {'message': 'Token has expired', 'error_code': 'otp_expired'};
    });
    await expectLater(
      SupabasePasswordRecoveryRepo(
        client,
      ).verifyCode('fixture@example.test', '123456'),
      throwsA(isA<AuthException>()),
    );
  });
}
