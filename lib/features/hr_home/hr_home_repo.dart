import 'package:supabase_flutter/supabase_flutter.dart';

String hrHomeDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class HrHomeData {
  const HrHomeData({
    this.name = '',
    this.employees = 0,
    this.newEmployees = 0,
    this.attendanceIssues = 0,
    this.documents = const [],
    this.leaves = const [],
  });
  final String name;
  final int employees, newEmployees, attendanceIssues;
  final List<Map<String, dynamic>> documents, leaves;
}

abstract class HrHomeRepo {
  Future<HrHomeData> load(DateTime today);
}

class SupabaseHrHomeRepo implements HrHomeRepo {
  SupabaseHrHomeRepo(this.client);
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
  Future<HrHomeData> load(DateTime today) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Missing HR session');
    final actor = await client
        .from('users')
        .select('tenant_id, role, is_active, name')
        .eq('id', uid)
        .single();
    if (actor['role'] != 'hr' ||
        actor['is_active'] != true ||
        actor['tenant_id'] == null) {
      throw StateError('Active HR account required');
    }
    final tenant = actor['tenant_id'].toString();
    final date = DateTime(today.year, today.month, today.day);
    // Sunday through today. Only recorded late/absent records; no inferred violations.
    final weekStart = date.subtract(Duration(days: date.weekday % 7));
    final results = await Future.wait([
      _all(
        client
            .from('employees')
            .select('id, hire_date')
            .eq('tenant_id', tenant)
            .order('id'),
      ),
      _all(
        client
            .from('attendance_records')
            .select('id')
            .eq('tenant_id', tenant)
            .inFilter('status', ['late', 'absent'])
            .gte('date', hrHomeDate(weekStart))
            .lte('date', hrHomeDate(date))
            .order('id'),
      ),
      _all(
        client
            .from('employee_documents')
            .select('id, doc_type, expires_at, employee:employees(full_name)')
            .eq('tenant_id', tenant)
            .not('expires_at', 'is', null)
            .lte('expires_at', hrHomeDate(date.add(const Duration(days: 30))))
            .order('expires_at')
            .order('id'),
      ),
      _all(
        client
            .from('approval_requests')
            .select(
              'id, payload, current_approver_role, created_at, employee:employees(full_name)',
            )
            .eq('tenant_id', tenant)
            .eq('request_type', 'leave')
            .eq('status', 'pending')
            .order('created_at', ascending: false)
            .order('id'),
      ),
    ]);
    final monthStart = DateTime(date.year, date.month);
    final monthEnd = DateTime(date.year, date.month + 1);
    return HrHomeData(
      name: (actor['name'] ?? '').toString(),
      employees: results[0].length,
      newEmployees: results[0].where((r) {
        final hire = DateTime.tryParse('${r['hire_date'] ?? ''}');
        return hire != null &&
            !hire.isBefore(monthStart) &&
            hire.isBefore(monthEnd) &&
            !hire.isAfter(date);
      }).length,
      attendanceIssues: results[1].length,
      documents: results[2],
      leaves: results[3],
    );
  }
}
