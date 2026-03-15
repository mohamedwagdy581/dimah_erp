part of 'employee_repo_impl.dart';

mixin _EmployeesRepoAuthMixin on _EmployeesRepoSessionMixin {
  String _buildTestPasswordFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Employee@2030';

    final normalized = local.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (normalized.isEmpty) return 'Employee@2030';

    final firstUpper = normalized[0].toUpperCase();
    final restLower = normalized.length > 1
        ? normalized.substring(1).toLowerCase()
        : '';
    return '$firstUpper$restLower@2030';
  }

  Future<String?> _signUpAuthUserForTesting({
    required String email,
    required String password,
  }) async {
    final client = HttpClient();
    try {
      final req = await client.postUrl(
        Uri.parse('${Env.supabaseUrl}/auth/v1/signup'),
      );
      req.headers.set('apikey', Env.supabaseAnonKey);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.write(jsonEncode({'email': email, 'password': password}));

      final res = await req.close();
      final body = await utf8.decoder.bind(res).join();
      final map = body.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map<String, dynamic>);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final user = map['user'];
        if (user is Map && user['id'] != null) {
          return user['id'].toString();
        }
        return null;
      }

      final message =
          map['msg']?.toString() ??
          map['message']?.toString() ??
          map['error_description']?.toString() ??
          map['error']?.toString() ??
          'Auth signup failed with status ${res.statusCode}';

      if (message.toLowerCase().contains('already registered')) {
        return null;
      }
      throw Exception(message);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _upsertAppUserLink({
    required String tenantId,
    required String employeeId,
    required String fullName,
    required String email,
    String? authUserId,
  }) async {
    if (authUserId != null && authUserId.trim().isNotEmpty) {
      await _client.from('users').upsert({
        'id': authUserId,
        'tenant_id': tenantId,
        'email': email,
        'name': fullName,
        'role': 'employee',
        'employee_id': employeeId,
        'is_active': true,
      });
      return;
    }

    final existing = await _client
        .from('users')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('email', email)
        .maybeSingle();
    if (existing == null) {
      throw Exception(
        'Test login could not be auto-linked: existing auth user was not found in public.users.',
      );
    }

    await _client
        .from('users')
        .update({
          'name': fullName,
          'role': 'employee',
          'employee_id': employeeId,
          'is_active': true,
        })
        .eq('tenant_id', tenantId)
        .eq('id', existing['id'].toString());
  }

  Future<void> _createAndLinkTestLogin({
    required String tenantId,
    required String employeeId,
    required String fullName,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) return;

    final generatedPassword = _buildTestPasswordFromEmail(normalizedEmail);
    final authUserId = await _signUpAuthUserForTesting(
      email: normalizedEmail,
      password: generatedPassword,
    );

    await _upsertAppUserLink(
      tenantId: tenantId,
      employeeId: employeeId,
      fullName: fullName.trim(),
      email: normalizedEmail,
      authUserId: authUserId,
    );
  }
}
