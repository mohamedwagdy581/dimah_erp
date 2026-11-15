import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_user.dart';
import 'session_repo.dart';

class ApiSessionException implements Exception {
  const ApiSessionException();
}

class ApiSessionRepo implements SessionRepo {
  ApiSessionRepo({
    required String baseUrl,
    required String? Function() userId,
    required String? Function() accessToken,
    required Future<void> Function() refresh,
    required Future<void> Function() signOut,
    http.Client? client,
  }) : _userId = userId,
       _accessToken = accessToken,
       _refresh = refresh,
       _signOut = signOut,
       _client = client ?? http.Client() {
    final base = Uri.parse(baseUrl);
    if (base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw ArgumentError('DIMAH_API_URL must be an HTTPS origin');
    }
    _endpoint = base.replace(path: '/v1/me');
  }

  factory ApiSessionRepo.supabase(SupabaseClient auth, String baseUrl) =>
      ApiSessionRepo(
        baseUrl: baseUrl,
        userId: () => auth.auth.currentUser?.id,
        accessToken: () => auth.auth.currentSession?.accessToken,
        refresh: () async {
          await auth.auth.refreshSession();
        },
        signOut: () => auth.auth.signOut(scope: SignOutScope.local),
      );

  final String? Function() _userId;
  final String? Function() _accessToken;
  final Future<void> Function() _refresh;
  final Future<void> Function() _signOut;
  final http.Client _client;
  late final Uri _endpoint;

  Future<http.Response> _request(String token) async {
    final request = http.Request('GET', _endpoint)
      ..followRedirects = false
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
    return await (() async => http.Response.fromStream(
      await _client.send(request),
    ))().timeout(const Duration(seconds: 15));
  }

  @override
  Future<AppUser?> getCurrentAppUser() async {
    final uid = _userId();
    if (uid == null) return null;
    try {
      var token = _accessToken();
      if (token == null || token.isEmpty) throw const ApiSessionException();
      var response = await _request(token);
      if (_userId() != uid) return null;
      if (response.statusCode == 401) {
        await _refresh();
        if (_userId() != uid) return null;
        token = _accessToken();
        if (token == null || token.isEmpty) throw const ApiSessionException();
        response = await _request(token);
        if (_userId() != uid) return null;
      }
      final body = jsonDecode(response.body);
      if (response.statusCode == 403 &&
          body is Map &&
          body['error'] == 'active_erp_account_required') {
        await _signOut();
        return null;
      }
      if (response.statusCode != 200 || body is! Map || body['user'] is! Map) {
        throw const ApiSessionException();
      }
      final data = Map<String, dynamic>.from(body['user'] as Map);
      if (data['id'] != uid ||
          data['is_active'] != true ||
          data['role'] is! String ||
          (data['role'] as String).isEmpty ||
          data['tenant_id'] is! String ||
          (data['tenant_id'] as String).isEmpty) {
        throw const ApiSessionException();
      }
      return AppUser.fromJson(data);
    } catch (_) {
      // Keep temporary API failures separate from logged-out sessions.
      throw const ApiSessionException();
    }
  }
}
