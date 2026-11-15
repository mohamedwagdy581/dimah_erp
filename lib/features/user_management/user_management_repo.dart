import 'package:supabase_flutter/supabase_flutter.dart';

const managedRoles = [
  'employee',
  'manager',
  'hr',
  'accountant',
  'finance_manager',
  'admin',
];

class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.employeeId,
  });
  final String id, name, email, role;
  final bool active;
  final String? employeeId;
  factory ManagedUser.fromMap(Map<String, dynamic> row) => ManagedUser(
    id: row['id'].toString(),
    name: (row['name'] ?? '').toString(),
    email: (row['email'] ?? '').toString(),
    role: (row['role'] ?? '').toString(),
    active: row['is_active'] == true,
    employeeId: row['employee_id']?.toString(),
  );
}

class ManagedUsersData {
  const ManagedUsersData({
    required this.actorId,
    required this.canEdit,
    required this.users,
  });
  final String actorId;
  final bool canEdit;
  final List<ManagedUser> users;
}

abstract class UserManagementRepo {
  Future<ManagedUsersData> load();
  Future<ManagedUser> save(ManagedUser user, String role, bool active);
}

class SupabaseUserManagementRepo implements UserManagementRepo {
  SupabaseUserManagementRepo(this.client);
  final SupabaseClient client;
  @override
  Future<ManagedUsersData> load() async {
    final data = Map<String, dynamic>.from(
      await client.rpc('list_company_users') as Map,
    );
    return ManagedUsersData(
      actorId: data['actor_id'].toString(),
      canEdit: data['can_edit'] == true,
      users: (data['users'] as List)
          .map((r) => ManagedUser.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList(),
    );
  }

  @override
  Future<ManagedUser> save(ManagedUser user, String role, bool active) async {
    if (!managedRoles.contains(role) && role != 'direct_manager') {
      throw ArgumentError('Unsupported role');
    }
    final data = await client.rpc(
      'admin_update_company_user',
      params: {
        'p_user_id': user.id,
        'p_role': role,
        'p_active': active,
        'p_expected_role': user.role,
        'p_expected_active': user.active,
      },
    );
    return ManagedUser.fromMap(Map<String, dynamic>.from(data as Map));
  }
}
