import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/accounting_reports_models.dart';
import '../domain/accounting_reports_repo.dart';

class AccountingReportsRepoImpl implements AccountingReportsRepo {
  AccountingReportsRepoImpl(this._client);
  final SupabaseClient _client;

  String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<LedgerReport> fetchLedger({
    required String accountId,
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _client.rpc(
      'accounting_ledger',
      params: {
        'p_account_id': accountId,
        'p_from': _day(from),
        'p_to': _day(to),
      },
    );
    return LedgerReport.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<List<TrialBalanceRow>> fetchTrialBalance(DateTime asOf) async {
    final res = await _client.rpc(
      'accounting_trial_balance',
      params: {'p_as_of': _day(asOf)},
    );
    return [
      for (final r in (res as List? ?? const []))
        TrialBalanceRow.fromMap(Map<String, dynamic>.from(r as Map)),
    ];
  }

  @override
  Future<AccountingKpis> fetchKpis(DateTime month) async {
    final res = await _client.rpc(
      'accounting_kpis',
      params: {'p_month': _day(DateTime(month.year, month.month))},
    );
    return AccountingKpis.fromJson(Map<String, dynamic>.from(res as Map));
  }
}
