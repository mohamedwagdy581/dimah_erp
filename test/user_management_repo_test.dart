import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/user_management/user_management_repo.dart';
import 'package:erp_sys/core/session/session_repo_impl.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test('Inactive account cannot load an application session', () async {
    final client = await server((request) async {
      expect(request.uri.path, '/auth/v1/logout');
      return {};
    }, active: false);
    expect(await SessionRepoImpl(client).getCurrentAppUser(), isNull);
    expect(client.auth.currentUser, isNull);
  });
  test(
    'Active account keeps its server role in the application session',
    () async {
      final client = await server((_) async => null, role: 'manager');
      final user = await SessionRepoImpl(client).getCurrentAppUser();
      expect(user!.role, 'manager');
      expect(client.auth.currentUser, isNotNull);
    },
  );
  test('Server determines edit access and returns company accounts', () async {
    final client = await server((request) async {
      expect(request.uri.path, '/rest/v1/rpc/list_company_users');
      return {
        'actor_id': 'actor',
        'can_edit': false,
        'users': [
          {
            'id': 'target',
            'name': 'Employee',
            'email': 'employee@example.test',
            'role': 'employee',
            'is_active': false,
            'employee_id': 'employee',
          },
        ],
      };
    });
    final data = await SupabaseUserManagementRepo(client).load();
    expect(data.canEdit, false);
    expect(data.actorId, 'actor');
    expect(data.users.single.active, false);
    expect(data.users.single.employeeId, 'employee');
  });
  test('Saves only access values with expected role and status', () async {
    final client = await server((request) async {
      expect(request.uri.path, '/rest/v1/rpc/admin_update_company_user');
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      expect(body, {
        'p_user_id': 'target',
        'p_role': 'manager',
        'p_active': false,
        'p_expected_role': 'employee',
        'p_expected_active': true,
      });
      return {
        'id': 'target',
        'name': 'Employee',
        'email': 'employee@example.test',
        'role': 'manager',
        'is_active': false,
        'employee_id': 'employee',
      };
    });
    final repo = SupabaseUserManagementRepo(client);
    const user = ManagedUser(
      id: 'target',
      name: 'Employee',
      email: 'employee@example.test',
      role: 'employee',
      active: true,
      employeeId: 'employee',
    );
    final result = await repo.save(user, 'manager', false);
    expect(result.role, 'manager');
    expect(result.active, false);
    expect(result.email, user.email);
    await expectLater(
      repo.save(user, 'unsupported', true),
      throwsArgumentError,
    );
  });
}
