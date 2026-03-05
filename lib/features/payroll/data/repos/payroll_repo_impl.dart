import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/payroll_item.dart';
import '../../domain/models/payroll_run.dart';
import '../../domain/repos/payroll_repo.dart';

class PayrollRepoImpl implements PayrollRepo {
  PayrollRepoImpl(this._client);
  final SupabaseClient _client;

  Future<String> _tenantId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final me = await _client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();

    final t = me['tenant_id'];
    if (t == null) throw Exception('Missing tenant_id for current user');
    return t.toString();
  }

  String _toDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  @override
  Future<({List<PayrollRun> items, int total})> fetchRuns({
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String sortBy = 'period_start',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final from = page * pageSize;
    final to = from + pageSize - 1;

    dynamic listQ = _client
        .from('payroll_runs')
        .select(
          'id, tenant_id, period_start, period_end, status, total_employees, total_amount, created_at',
        )
        .eq('tenant_id', tenantId);

    if (status != null && status.trim().isNotEmpty) {
      listQ = listQ.eq('status', status);
    }

    if (startDate != null) {
      listQ = listQ.gte('period_start', _toDateOnly(startDate));
    }

    if (endDate != null) {
      listQ = listQ.lte('period_end', _toDateOnly(endDate));
    }

    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => PayrollRun.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('payroll_runs')
        .select('id')
        .eq('tenant_id', tenantId);

    if (status != null && status.trim().isNotEmpty) {
      countQ = countQ.eq('status', status);
    }
    if (startDate != null) {
      countQ = countQ.gte('period_start', _toDateOnly(startDate));
    }
    if (endDate != null) {
      countQ = countQ.lte('period_end', _toDateOnly(endDate));
    }

    final countRes = await countQ;
    final total = (countRes as List).length;

    return (items: items, total: total);
  }

  @override
  Future<String> createRun({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final tenantId = await _tenantId();

    final res = await _client.rpc(
      'generate_payroll_run',
      params: {
        'p_tenant_id': tenantId,
        'p_period_start': _toDateOnly(periodStart),
        'p_period_end': _toDateOnly(periodEnd),
      },
    );

    if (res is String) return res;
    if (res is Map && res['run_id'] != null) {
      return res['run_id'].toString();
    }

    throw Exception('Invalid payroll RPC response');
  }

  @override
  Future<List<PayrollItem>> fetchRunItems({
    required String runId,
  }) async {
    final res = await _client
        .from('payroll_items')
        .select(
          'id, run_id, employee_id, basic_salary, housing_allowance, transport_allowance, other_allowance, total_amount, '
          'employee:employees(full_name)',
        )
        .eq('run_id', runId);

    return (res as List)
        .map((e) => PayrollItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> finalizeRun({required String runId}) async {
    final tenantId = await _tenantId();
    await _client
        .from('payroll_runs')
        .update({'status': 'finalized'})
        .eq('tenant_id', tenantId)
        .eq('id', runId);
  }
}
