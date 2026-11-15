/// Numbers from PostgREST/jsonb may arrive as int, double or numeric string.
num _num(Object? v) => switch (v) {
  num n => n,
  String s => num.tryParse(s) ?? 0,
  _ => 0,
};

int _int(Object? v) => _num(v).toInt();

class LedgerRow {
  const LedgerRow({
    required this.entryId,
    required this.entryDate,
    required this.memo,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  final String entryId;
  final DateTime entryDate;
  final String memo;
  final num debit, credit, balance;

  factory LedgerRow.fromJson(Map<String, dynamic> j) => LedgerRow(
    entryId: j['entry_id'].toString(),
    entryDate: DateTime.parse(j['entry_date'].toString()),
    memo: (j['memo'] ?? '').toString(),
    debit: _num(j['debit']),
    credit: _num(j['credit']),
    balance: _num(j['balance']),
  );
}

/// Posted movements of one account; balances are in the account's normal side.
class LedgerReport {
  const LedgerReport({
    required this.accountId,
    required this.code,
    required this.name,
    required this.type,
    required this.opening,
    required this.totalDebit,
    required this.totalCredit,
    required this.closing,
    required this.truncated,
    required this.rows,
  });

  final String accountId, code, name, type;
  final num opening, totalDebit, totalCredit, closing;
  final bool truncated;
  final List<LedgerRow> rows;

  factory LedgerReport.fromJson(Map<String, dynamic> j) {
    final a = Map<String, dynamic>.from(j['account'] as Map);
    return LedgerReport(
      accountId: a['id'].toString(),
      code: (a['code'] ?? '').toString(),
      name: (a['name'] ?? '').toString(),
      type: (a['type'] ?? '').toString(),
      opening: _num(j['opening']),
      totalDebit: _num(j['total_debit']),
      totalCredit: _num(j['total_credit']),
      closing: _num(j['closing']),
      truncated: j['truncated'] == true,
      rows: [
        for (final r in (j['rows'] as List? ?? const []))
          LedgerRow.fromJson(Map<String, dynamic>.from(r as Map)),
      ],
    );
  }
}

class TrialBalanceRow {
  const TrialBalanceRow({
    required this.accountId,
    required this.code,
    required this.name,
    required this.type,
    required this.debit,
    required this.credit,
  });

  final String accountId, code, name, type;
  final num debit, credit;
  bool get isZero => debit == 0 && credit == 0;

  factory TrialBalanceRow.fromMap(Map<String, dynamic> m) => TrialBalanceRow(
    accountId: m['account_id'].toString(),
    code: (m['code'] ?? '').toString(),
    name: (m['name'] ?? '').toString(),
    type: (m['type'] ?? '').toString(),
    debit: _num(m['debit']),
    credit: _num(m['credit']),
  );
}

class AccountingKpis {
  const AccountingKpis({
    required this.cashBalance,
    required this.hasCashAccounts,
    required this.revenue,
    required this.expenses,
    required this.netProfit,
    required this.draftCount,
    required this.staleDraftCount,
  });

  final num cashBalance, revenue, expenses, netProfit;
  final bool hasCashAccounts;
  final int draftCount, staleDraftCount;

  factory AccountingKpis.fromJson(Map<String, dynamic> j) => AccountingKpis(
    cashBalance: _num(j['cash_balance']),
    hasCashAccounts: j['has_cash_accounts'] == true,
    revenue: _num(j['revenue']),
    expenses: _num(j['expenses']),
    netProfit: _num(j['net_profit']),
    draftCount: _int(j['draft_count']),
    staleDraftCount: _int(j['stale_draft_count']),
  );
}
