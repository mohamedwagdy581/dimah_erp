import 'dart:convert';

import 'package:erp_sys/features/accounting/reports/data/accounting_reports_repo_impl.dart';
import 'package:erp_sys/features/accounting/view/accounting_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'employee_attendance_repo_test.dart' show server;

Future<Map> body(dynamic request) async =>
    jsonDecode(await utf8.decoder.bind(request).join()) as Map;

void main() {
  test('fetchLedger sends account and date range and parses numbers', () async {
    final client = await server((request) async {
      expect(request.uri.path, '/rest/v1/rpc/accounting_ledger');
      expect(await body(request), {
        'p_account_id': 'a1',
        'p_from': '2026-10-01',
        'p_to': '2026-10-31',
      });
      return {
        'account': {
          'id': 'a1',
          'code': '1100',
          'name': 'Bank',
          'type': 'asset',
        },
        'opening': '1000.00',
        'total_debit': 0,
        'total_credit': 400.5,
        'closing': 599.5,
        'truncated': false,
        'rows': [
          {
            'entry_id': 'e2',
            'entry_date': '2026-10-20',
            'memo': 'Salaries',
            'debit': 0,
            'credit': 400.5,
            'balance': 599.5,
          },
        ],
      };
    }, role: 'accountant');
    final r = await AccountingReportsRepoImpl(client).fetchLedger(
      accountId: 'a1',
      from: DateTime(2026, 10, 1, 15),
      to: DateTime(2026, 10, 31),
    );
    expect(r.accountId, 'a1');
    expect(r.code, '1100');
    expect(r.type, 'asset');
    expect(r.opening, 1000);
    expect(r.totalCredit, 400.5);
    expect(r.closing, 599.5);
    expect(r.truncated, isFalse);
    expect(r.rows.single.entryDate, DateTime(2026, 10, 20));
    expect(r.rows.single.balance, 599.5);
  });

  test('fetchLedger with no rows keeps opening as closing', () async {
    final client = await server((request) async {
      return {
        'account': {
          'id': 'a1',
          'code': '1100',
          'name': 'Bank',
          'type': 'asset',
        },
        'opening': 0,
        'total_debit': 0,
        'total_credit': 0,
        'closing': 0,
        'truncated': false,
        'rows': [],
      };
    }, role: 'accountant');
    final r = await AccountingReportsRepoImpl(client).fetchLedger(
      accountId: 'a1',
      from: DateTime(2026, 10),
      to: DateTime(2026, 10, 31),
    );
    expect(r.rows, isEmpty);
    expect(r.closing, r.opening);
  });

  test('fetchTrialBalance parses rows and handles empty', () async {
    var calls = 0;
    final client = await server((request) async {
      expect(request.uri.path, '/rest/v1/rpc/accounting_trial_balance');
      expect(await body(request), {'p_as_of': '2026-10-31'});
      calls++;
      return calls == 1
          ? [
              {
                'account_id': 'a1',
                'code': '1100',
                'name': 'Bank',
                'type': 'asset',
                'debit': '600',
                'credit': 0,
              },
            ]
          : [];
    }, role: 'accountant');
    final repo = AccountingReportsRepoImpl(client);
    final rows = await repo.fetchTrialBalance(DateTime(2026, 10, 31));
    expect(rows.single.debit, 600);
    expect(rows.single.isZero, isFalse);
    expect(await repo.fetchTrialBalance(DateTime(2026, 10, 31)), isEmpty);
  });

  test('fetchKpis sends the first day of month and parses zeros', () async {
    final client = await server((request) async {
      expect(request.uri.path, '/rest/v1/rpc/accounting_kpis');
      expect(await body(request), {'p_month': '2026-10-01'});
      return {
        'cash_balance': 0,
        'has_cash_accounts': false,
        'revenue': 0,
        'expenses': 0,
        'net_profit': 0,
        'draft_count': 0,
        'stale_draft_count': 0,
      };
    }, role: 'accountant');
    final k = await AccountingReportsRepoImpl(
      client,
    ).fetchKpis(DateTime(2026, 10, 17));
    expect(k.cashBalance, 0);
    expect(k.netProfit, 0);
    expect(k.hasCashAccounts, isFalse);
    expect(k.draftCount, 0);
    expect(k.staleDraftCount, 0);
  });

  test('accountingBalance formats normal and abnormal balances', () {
    expect(accountingBalance(0), '0.00');
    expect(accountingBalance(1250), '1,250.00');
    expect(accountingBalance(-1250.5), '(1,250.50)');
  });
}
