import 'package:supabase_flutter/supabase_flutter.dart';
import '../payroll/domain/models/payroll_run.dart';

class FinanceResult<T> {
  const FinanceResult.value(this.value) : error = null;
  const FinanceResult.failure(this.error) : value = null;
  final T? value;
  final Object? error;
}

class FinanceTeamMember {
  FinanceTeamMember(Map<String, dynamic> row)
    : id = row['id'].toString(),
      name = (row['full_name'] ?? '').toString(),
      number = (row['employee_number'] ?? '').toString(),
      job = (row['job_title'] ?? '').toString(),
      photoUrl = row['photo_url']?.toString(),
      jobLevel = row['job_level']?.toString(),
      tasks = (row['tasks'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  final String id, name, number, job;
  final String? photoUrl;
  final String? jobLevel;
  final List<Map<String, dynamic>> tasks;
  int get openTasks => tasks.where((t) => t['status'] != 'done').length;
}

class FinanceHomeData {
  const FinanceHomeData({
    required this.role,
    required this.name,
    required this.month,
    required this.runs,
    required this.journal,
    required this.accounts,
    required this.approvals,
    required this.team,
  });
  final String role, name;
  final DateTime month;
  final FinanceResult<List<PayrollRun>> runs;
  final FinanceResult<List<Map<String, dynamic>>> journal, accounts;
  final FinanceResult<int> approvals;
  final FinanceResult<List<FinanceTeamMember>> team;
  bool get isManager => role == 'finance_manager';
  List<PayrollRun> get reviewRuns =>
      runs.value
          ?.where((r) => r.status == 'pending_finance_manager')
          .toList() ??
      [];
  List<PayrollRun> get assignRuns =>
      runs.value
          ?.where(
            (r) =>
                r.status == 'approved' &&
                [
                  'not_started',
                  'assigned_to_finance_manager',
                ].contains(r.disbursementStatus ?? 'not_started'),
          )
          .toList() ??
      [];
}

abstract class FinanceHomeRepo {
  Future<FinanceHomeData> load(DateTime month);
  Future<List<FinanceTeamMember>> loadTeam();
}

class SupabaseFinanceHomeRepo implements FinanceHomeRepo {
  SupabaseFinanceHomeRepo(this.client);
  final SupabaseClient client;
  Future<Map<String, dynamic>> _actor() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Unauthorized');
    final actor = await client
        .from('users')
        .select('tenant_id, employee_id, role, is_active, name')
        .eq('id', uid)
        .single();
    if (actor['is_active'] != true ||
        actor['tenant_id'] == null ||
        !['finance_manager', 'accountant'].contains(actor['role'])) {
      throw StateError('Forbidden');
    }
    return actor;
  }

  Future<List<Map<String, dynamic>>> _all(dynamic query) async {
    final result = <Map<String, dynamic>>[];
    for (var page = 0; ; page++) {
      final rows = await query.range(page * 500, page * 500 + 499) as List;
      result.addAll(rows.map((r) => Map<String, dynamic>.from(r as Map)));
      if (rows.length < 500) return result;
    }
  }

  Future<FinanceResult<T>> _read<T>(Future<T> Function() read) async {
    try {
      return FinanceResult.value(await read());
    } catch (error) {
      return FinanceResult.failure(error);
    }
  }

  @override
  Future<List<FinanceTeamMember>> loadTeam() async {
    final actor = await _actor();
    if (actor['role'] != 'finance_manager') throw StateError('Forbidden');
    final result = await client.rpc('finance_team_overview') as List;
    return result
        .map((e) => FinanceTeamMember(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<FinanceHomeData> load(DateTime month) async {
    final actor = await _actor();
    final tenant = actor['tenant_id'].toString();
    final manager = actor['role'] == 'finance_manager';
    final start = DateTime(month.year, month.month);
    final next = DateTime(month.year, month.month + 1);
    String date(DateTime d) => d.toIso8601String().split('T').first;
    // Independent sections fail independently; never display a failed read as zero.
    final runs = _read(() async {
      dynamic query = client
          .from('payroll_runs')
          .select()
          .eq('tenant_id', tenant);
      if (!manager) {
        if (actor['employee_id'] == null) return <PayrollRun>[];
        query = query.eq(
          'disbursement_assignee_employee_id',
          actor['employee_id'],
        );
      }
      final rows = await _all(
        query.order('created_at', ascending: false).order('id'),
      );
      return rows.map(PayrollRun.fromMap).toList();
    });
    final journal = _read(
      () => _all(
        client
            .from('journal_entries')
            .select('id, entry_date, memo, status, total_debit, total_credit')
            .eq('tenant_id', tenant)
            .gte('entry_date', date(start))
            .lt('entry_date', date(next))
            .order('entry_date', ascending: false)
            .order('id'),
      ),
    );
    final accounts = _read(
      () => _all(
        client
            .from('accounts')
            .select('id, code, name, type')
            .eq('tenant_id', tenant)
            .eq('is_active', true)
            .order('id'),
      ),
    );
    final approvals = _read(
      () async => (await _all(
        client
            .from('approval_requests')
            .select('id')
            .eq('tenant_id', tenant)
            .eq('status', 'pending')
            .eq('current_approver_role', actor['role'])
            .order('id'),
      )).length,
    );
    final team = manager
        ? _read(loadTeam)
        : Future.value(const FinanceResult<List<FinanceTeamMember>>.value([]));
    return FinanceHomeData(
      role: actor['role'].toString(),
      name: (actor['name'] ?? '').toString(),
      month: start,
      runs: await runs,
      journal: await journal,
      accounts: await accounts,
      approvals: await approvals,
      team: await team,
    );
  }
}
