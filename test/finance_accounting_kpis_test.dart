import 'package:erp_sys/features/accounting/reports/domain/accounting_reports_models.dart';
import 'package:erp_sys/features/finance_home/finance_accounting_kpis.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/accounting_report_fakes.dart';

AccountingKpis kpis({
  num cash = 600,
  num revenue = 1000,
  num expenses = 400,
  int drafts = 1,
  int stale = 0,
  bool hasCash = true,
}) => AccountingKpis(
  cashBalance: cash,
  hasCashAccounts: hasCash,
  revenue: revenue,
  expenses: expenses,
  netProfit: revenue - expenses,
  draftCount: drafts,
  staleDraftCount: stale,
);

void main() {
  Future<({ReportsFake reports, List<String> opened})> pump(
    WidgetTester tester,
    ReportsFake reports,
  ) async {
    desktopView(tester);
    final opened = <String>[];
    await tester.pumpWidget(
      reportApp(
        SingleChildScrollView(
          child: FinanceAccountingKpis(
            repo: reports,
            initialMonth: DateTime(2026, 10),
            onOpen: opened.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (reports: reports, opened: opened);
  }

  testWidgets('shows the five KPI cards', (tester) async {
    final r = await pump(tester, ReportsFake()..kpis = kpis());
    expect(r.reports.kpiCalls.single, DateTime(2026, 10));
    for (final label in [
      'Cash balance',
      'Revenue',
      'Expenses',
      'Net profit',
      'Drafts to post',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('600.00'), findsNWidgets(2)); // cash + net profit
    expect(find.text('1,000.00'), findsOneWidget);
    expect(find.text('400.00'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('a net loss is red and in parentheses', (tester) async {
    await pump(tester, ReportsFake()..kpis = kpis(revenue: 100, expenses: 400));
    final loss = tester.widget<Text>(find.text('(300.00)'));
    expect(loss.style?.color, const Color(0xFFC62828));
  });

  testWidgets('stale drafts alert opens the journal', (tester) async {
    final r = await pump(tester, ReportsFake()..kpis = kpis(stale: 2));
    final alert = find.text(
      '2 drafts older than 7 days are waiting to be posted',
    );
    expect(alert, findsOneWidget);
    await tester.tap(alert);
    expect(r.opened.single, '/journal');
  });

  testWidgets('missing cash accounts hint opens the chart of accounts', (
    tester,
  ) async {
    final r = await pump(tester, ReportsFake()..kpis = kpis(hasCash: false));
    await tester.tap(find.text('No cash accounts marked yet'));
    expect(r.opened.single, '/accounts');
  });

  testWidgets('month selector reloads the previous month', (tester) async {
    final r = await pump(tester, ReportsFake()..kpis = kpis());
    await tester.tap(find.byKey(const ValueKey('kpi-prev-month')));
    await tester.pumpAndSettle();
    expect(r.reports.kpiCalls.last, DateTime(2026, 9));
  });

  testWidgets('a KPI error shows an inline retry', (tester) async {
    final r = await pump(
      tester,
      ReportsFake()
        ..kpis = kpis()
        ..failures = 1,
    );
    expect(find.text('Accounting figures are unavailable.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(r.reports.kpiCalls, hasLength(2));
    expect(find.text('Cash balance'), findsOneWidget);
  });

  testWidgets('quick links open the ledger and trial balance', (tester) async {
    final r = await pump(tester, ReportsFake()..kpis = kpis());
    await tester.tap(find.text('General Ledger'));
    await tester.tap(find.text('Trial Balance'));
    expect(r.opened, ['/ledger', '/trial-balance']);
  });
}
