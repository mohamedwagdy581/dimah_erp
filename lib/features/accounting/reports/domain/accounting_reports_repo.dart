import 'accounting_reports_models.dart';

/// Read-only accounting reports. All figures count posted entries only.
abstract class AccountingReportsRepo {
  Future<LedgerReport> fetchLedger({
    required String accountId,
    required DateTime from,
    required DateTime to,
  });

  Future<List<TrialBalanceRow>> fetchTrialBalance(DateTime asOf);

  /// KPIs for the calendar month containing [month].
  Future<AccountingKpis> fetchKpis(DateTime month);
}
