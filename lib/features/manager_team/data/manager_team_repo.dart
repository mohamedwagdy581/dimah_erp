import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/manager_team_data.dart';

abstract class ManagerTeamRepo {
  Future<ManagerTeamData> load();
}

class SupabaseManagerTeamRepo implements ManagerTeamRepo {
  SupabaseManagerTeamRepo(this.client);
  final SupabaseClient client;
  Future<List<Map<String, dynamic>>> _all(dynamic query) async {
    final result = <Map<String, dynamic>>[];
    for (var page = 0; ; page++) {
      final rows = await query.range(page * 500, page * 500 + 499) as List;
      result.addAll(rows.map((r) => Map<String, dynamic>.from(r as Map)));
      if (rows.length < 500) return result;
    }
  }

  @override
  Future<ManagerTeamData> load() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Missing session');
    final actor = await client
        .from('users')
        .select('tenant_id, employee_id, role, is_active, name')
        .eq('id', uid)
        .single();
    if (!['manager', 'direct_manager'].contains(actor['role']) ||
        actor['is_active'] != true ||
        actor['employee_id'] == null ||
        actor['tenant_id'] == null) {
      throw StateError('Active linked manager required');
    }
    final tenant = actor['tenant_id'].toString();
    final manager = actor['employee_id'].toString();
    final departments = await _all(
      client
          .from('departments')
          .select('id, name')
          .eq('tenant_id', tenant)
          .eq('manager_id', manager)
          .order('id'),
    );
    final direct = await _all(
      client
          .from('employees')
          .select('id, full_name, photo_url')
          .eq('tenant_id', tenant)
          .eq('manager_id', manager)
          .eq('status', 'active')
          .order('id'),
    );
    final departmentMembers = departments.isEmpty
        ? <Map<String, dynamic>>[]
        : await _all(
            client
                .from('employees')
                .select('id, full_name, photo_url')
                .eq('tenant_id', tenant)
                .inFilter(
                  'department_id',
                  departments.map((d) => d['id']).toList(),
                )
                .eq('status', 'active')
                .order('id'),
          );
    final byId = <String, TeamMember>{};
    for (final row in [...direct, ...departmentMembers]) {
      if (row['id'].toString() != manager) {
        byId[row['id'].toString()] = TeamMember(
          id: row['id'].toString(),
          name: (row['full_name'] ?? '—').toString(),
          photoUrl: row['photo_url']?.toString(),
        );
      }
    }
    final members = byId.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final managerName = (actor['name'] ?? '').toString();
    final departmentNames = departments
        .map((d) => (d['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();
    if (members.isEmpty) {
      return ManagerTeamData(
        managerName: managerName,
        departmentNames: departmentNames,
      );
    }
    final tasks = <TeamTask>[];
    var pending = 0;
    // Batch IDs to keep URLs bounded. Company and verified team scope on every read.
    for (var start = 0; start < members.length; start += 100) {
      final ids = members.skip(start).take(100).map((m) => m.id).toList();
      final rows = await _all(
        client
            .from('employee_tasks')
            .select(
              'id, employee_id, title, status, progress, priority, due_date, employee_review_status, qa_status',
            )
            .eq('tenant_id', tenant)
            .inFilter('employee_id', ids)
            .order('id'),
      );
      tasks.addAll(rows.map(TeamTask.new));
      final requests = await _all(
        client
            .from('approval_requests')
            .select('id')
            .eq('tenant_id', tenant)
            .inFilter('employee_id', ids)
            .eq('status', 'pending')
            .eq('current_approver_role', 'manager')
            .order('id'),
      );
      pending += requests.length;
    }
    return ManagerTeamData(
      members: members,
      tasks: tasks,
      pendingRequests: pending,
      managerName: managerName,
      departmentNames: departmentNames,
    );
  }
}
