import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/accounting/accounts/domain/models/account.dart';
import 'package:erp_sys/features/accounting/accounts/domain/repos/accounts_repo.dart';
import 'package:erp_sys/features/accounting/reports/domain/accounting_reports_models.dart';
import 'package:erp_sys/features/accounting/reports/domain/accounting_reports_repo.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

class ReportsFake implements AccountingReportsRepo {
  LedgerReport? ledger;
  List<TrialBalanceRow> trial = const [];
  AccountingKpis? kpis;
  int failures = 0;
  final ledgerCalls = <({String accountId, DateTime from, DateTime to})>[];
  final trialCalls = <DateTime>[];
  final kpiCalls = <DateTime>[];

  void _maybeFail() {
    if (failures > 0) {
      failures--;
      throw StateError('SocketException');
    }
  }

  @override
  Future<LedgerReport> fetchLedger({
    required String accountId,
    required DateTime from,
    required DateTime to,
  }) async {
    ledgerCalls.add((accountId: accountId, from: from, to: to));
    _maybeFail();
    return ledger!;
  }

  @override
  Future<List<TrialBalanceRow>> fetchTrialBalance(DateTime asOf) async {
    trialCalls.add(asOf);
    _maybeFail();
    return trial;
  }

  @override
  Future<AccountingKpis> fetchKpis(DateTime month) async {
    kpiCalls.add(month);
    _maybeFail();
    return kpis!;
  }
}

class AccountListFake implements AccountsRepo {
  AccountListFake(this.accounts);
  final List<Account> accounts;

  @override
  Future<({List<Account> items, int total})> fetchAccounts({
    required int page,
    required int pageSize,
    String? search,
    String? type,
    bool? isActive,
    String sortBy = 'code',
    bool ascending = true,
  }) async => (items: accounts, total: accounts.length);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Account account(
  String id,
  String code,
  String name,
  String type, {
  bool active = true,
}) => Account(
  id: id,
  tenantId: 'tenant',
  code: code,
  name: name,
  type: type,
  isActive: active,
  createdAt: DateTime(2026),
);

LedgerReport ledgerReport({
  num opening = 1000,
  num closing = 600,
  bool truncated = false,
  List<LedgerRow>? rows,
}) => LedgerReport(
  accountId: 'a1',
  code: '1100',
  name: 'Bank',
  type: 'asset',
  opening: opening,
  totalDebit: 0,
  totalCredit: 400,
  closing: closing,
  truncated: truncated,
  rows:
      rows ??
      [
        LedgerRow(
          entryId: 'e2',
          entryDate: DateTime(2026, 10, 20),
          memo: 'Salaries October',
          debit: 0,
          credit: 400,
          balance: 600,
        ),
      ],
);

Widget reportApp(Widget child, {String lang = 'en'}) => MaterialApp(
  theme: EmployeeTheme.from(AppTheme.light()),
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: appLocalizationDelegates,
  home: Scaffold(body: child),
);

void desktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
