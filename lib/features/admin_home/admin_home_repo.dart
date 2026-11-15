import 'package:supabase_flutter/supabase_flutter.dart';
import '../payroll/domain/models/payroll_run.dart';

class AdminSection<T> {
  const AdminSection.value(this.value) : error = null;
  const AdminSection.failure(this.error) : value = null;
  final T? value;
  final Object? error;
}

class AdminHomeData {
  const AdminHomeData({
    required this.name,
    required this.month,
    required this.employees,
    required this.departments,
    required this.approvals,
    required this.payroll,
    required this.journal,
    required this.users,
  });
  final String name;
  final DateTime month;
  final AdminSection<List<Map<String, dynamic>>> employees,
      departments,
      approvals,
      journal,
      users;
  final AdminSection<List<PayrollRun>> payroll;
  List<PayrollRun> get awaitingApproval =>
      payroll.value
          ?.where((r) => r.status == 'pending_admin_approval')
          .toList() ??
      [];
  List<Map<String, dynamic>> get otherApprovals =>
      approvals.value
          ?.where((r) => r['request_type'] != 'payroll_run')
          .toList() ??
      [];
  int get activeEmployees =>
      employees.value?.where((e) => e['status'] == 'active').length ?? 0;
}

abstract class AdminHomeRepo {
  Future<AdminHomeData> load(DateTime month);
}

class SupabaseAdminHomeRepo implements AdminHomeRepo {
  SupabaseAdminHomeRepo(this.client);
  final SupabaseClient client;
  Future<List<Map<String, dynamic>>> _all(dynamic query) async {
    final result = <Map<String, dynamic>>[];
    for (var page = 0; ; page++) {
      final rows = await query.range(page * 500, page * 500 + 499) as List;
      result.addAll(rows.map((r) => Map<String, dynamic>.from(r as Map)));
      if (rows.length < 500) return result;
    }
  }

  Future<AdminSection<T>> _read<T>(Future<T> Function() read) async {
    try {
      return AdminSection.value(await read());
    } catch (e) {
      return AdminSection.failure(e);
    }
  }

  @override
  Future<AdminHomeData> load(DateTime month) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Unauthorized');
    final actor = await client
        .from('users')
        .select('tenant_id, role, is_active, name')
        .eq('id', uid)
        .single();
    if (actor['is_active'] != true ||
        actor['role'] != 'admin' ||
        actor['tenant_id'] == null) {
      throw StateError('Forbidden');
    }
    final tenant = actor['tenant_id'].toString();
    String date(DateTime value) => value.toIso8601String().split('T').first;
    final start = DateTime(month.year, month.month);
    final next = DateTime(month.year, month.month + 1);
    // Keep each section independent and scope every table read to the actor's company.
    final employees = _read(
      () => _all(
        client
            .from('employees')
            .select('id, full_name, status, department_id')
            .eq('tenant_id', tenant)
            .order('id'),
      ),
    );
    final departments = _read(
      () => _all(
        client
            .from('departments')
            .select('id, name')
            .eq('tenant_id', tenant)
            .order('id'),
      ),
    );
    final approvals = _read(
      () => _all(
        client
            .from('approval_requests')
            .select('id, employee_id, request_type, created_at')
            .eq('tenant_id', tenant)
            .eq('status', 'pending')
            .eq('current_approver_role', 'admin')
            .order('created_at')
            .order('id'),
      ),
    );
    final payroll = _read(
      () async => (await _all(
        client
            .from('payroll_runs')
            .select()
            .eq('tenant_id', tenant)
            .order('created_at', ascending: false)
            .order('id'),
      )).map(PayrollRun.fromMap).toList(),
    );
    final journal = _read(
      () => _all(
        client
            .from('journal_entries')
            .select('id, status')
            .eq('tenant_id', tenant)
            .gte('entry_date', date(start))
            .lt('entry_date', date(next))
            .order('id'),
      ),
    );
    final users = _read(() async {
      final response = Map<String, dynamic>.from(
        await client.rpc('list_company_users') as Map,
      );
      if (response['actor_id'] != uid || response['can_edit'] != true) {
        throw StateError('Forbidden');
      }
      return (response['users'] as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
    });
    return AdminHomeData(
      name: (actor['name'] ?? '').toString(),
      month: start,
      employees: await employees,
      departments: await departments,
      approvals: await approvals,
      payroll: await payroll,
      journal: await journal,
      users: await users,
    );
  }
}
