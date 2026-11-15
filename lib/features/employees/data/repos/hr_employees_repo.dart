import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/employee.dart';

class HrEmployeesData {
  const HrEmployeesData({
    this.employees = const [],
    this.departments = const {},
    this.jobTitles = const {},
  });
  final List<Employee> employees;
  final Map<String, String> departments, jobTitles;
}

abstract class HrEmployeesRepo {
  Future<HrEmployeesData> load();
}

class SupabaseHrEmployeesRepo implements HrEmployeesRepo {
  SupabaseHrEmployeesRepo(this.client);
  final SupabaseClient client;
  Future<List<Map<String, dynamic>>> _all(dynamic query) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 0; ; page++) {
      final batch = await query.range(page * 500, page * 500 + 499) as List;
      rows.addAll(batch.map((r) => Map<String, dynamic>.from(r as Map)));
      if (batch.length < 500) return rows;
    }
  }

  @override
  Future<HrEmployeesData> load() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Missing session');
    final actor = await client
        .from('users')
        .select('role, is_active, tenant_id')
        .eq('id', uid)
        .single();
    if (!['hr', 'admin'].contains(actor['role']) ||
        actor['is_active'] != true ||
        actor['tenant_id'] == null) {
      throw StateError('Active HR required');
    }
    final tenant = actor['tenant_id'].toString();
    final results = await Future.wait([
      _all(
        client
            .from('employees')
            .select(
              'id, tenant_id, employee_number, full_name, email, phone, photo_url, status, hire_date, created_at, department_id, job_title_id, department:departments!employees_department_id_fkey(name), job_title:job_titles(name)',
            )
            .eq('tenant_id', tenant)
            .order('id'),
      ),
      _all(
        client
            .from('departments')
            .select('id, name')
            .eq('tenant_id', tenant)
            .order('id'),
      ),
      _all(
        client
            .from('job_titles')
            .select('id, name')
            .eq('tenant_id', tenant)
            .order('id'),
      ),
    ]);
    return HrEmployeesData(
      employees: results[0].map(Employee.fromMap).toList(),
      departments: {
        for (final r in results[1]) '${r['id']}': '${r['name'] ?? '—'}',
      },
      jobTitles: {
        for (final r in results[2]) '${r['id']}': '${r['name'] ?? '—'}',
      },
    );
  }
}
