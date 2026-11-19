import 'package:erp_sys/features/accounting/reports/domain/accounting_reports_models.dart';
import 'package:erp_sys/features/accounting/trial_balance/view/trial_balance_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/accounting_report_fakes.dart';

TrialBalanceRow tb(
  String id,
  String code,
  String name,
  String type, {
  num debit = 0,
  num credit = 0,
}) => TrialBalanceRow(
  accountId: id,
  code: code,
  name: name,
  type: type,
  debit: debit,
  credit: credit,
);

void main() {
  final balanced = [
    tb('a5', '5100', 'Salaries', 'expense', debit: 400),
    tb('a1', '1100', 'Bank', 'asset', debit: 600),
    tb('a4', '4100', 'Sales', 'income', credit: 1000),
    tb('a2', '2100', 'Payables', 'liability'),
    tb('a0', '1000', 'Petty cash', 'asset', debit: 0),
  ];

  Future<({ReportsFake reports, List<String> opened})> pump(
    WidgetTester tester,
    List<TrialBalanceRow> rows,
  ) async {
    desktopView(tester);
    final reports = ReportsFake()..trial = rows;
    final opened = <String>[];
    await tester.pumpWidget(
      reportApp(
        TrialBalancePage(
          repo: reports,
          now: DateTime(2026, 10, 31),
          onOpen: opened.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (reports: reports, opened: opened);
  }

  testWidgets('groups accounts by type in the standard order', (tester) async {
    final r = await pump(tester, [
      ...balanced,
      tb('a3', '3100', 'Capital', 'equity', credit: 0),
    ]);
    expect(r.reports.trialCalls.single, DateTime(2026, 10, 31));
    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(y('Assets'), lessThan(y('Income')));
    expect(y('Income'), lessThan(y('Expenses')));
    expect(find.text('Liabilities'), findsNothing); // zero rows hidden
    expect(find.text('Equity'), findsNothing);
  });

  testWidgets('shows totals and a Balanced badge', (tester) async {
    await pump(tester, balanced);
    expect(find.text('1,000.00'), findsNWidgets(3)); // Sales + 2 totals
    expect(find.text('Balanced'), findsOneWidget);
  });

  testWidgets('shows the difference when out of balance', (tester) async {
    await pump(tester, [
      tb('a1', '1100', 'Bank', 'asset', debit: 600),
      tb('a4', '4100', 'Sales', 'income', credit: 500),
    ]);
    expect(find.text('Out of balance by 100.00'), findsOneWidget);
  });

  testWidgets('zero balances are hidden until the switch is turned off', (
    tester,
  ) async {
    await pump(tester, balanced);
    expect(find.text('Petty cash'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tb-hide-zero')));
    await tester.pumpAndSettle();
    expect(find.text('Petty cash'), findsOneWidget);
    expect(find.text('Liabilities'), findsOneWidget);
  });

  testWidgets('tapping a row opens that account ledger for the year', (
    tester,
  ) async {
    final r = await pump(tester, balanced);
    await tester.tap(find.byKey(const ValueKey('tb-row-a1')));
    expect(r.opened.single, '/ledger?account=a1&from=2026-01-01&to=2026-10-31');
  });

  testWidgets('empty trial balance shows a message', (tester) async {
    await pump(tester, const []);
    expect(find.text('No posted entries up to this date.'), findsOneWidget);
  });

  testWidgets('fits a landscape phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(700, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      reportApp(
        TrialBalancePage(
          repo: ReportsFake()..trial = balanced,
          now: DateTime(2026, 10, 31),
          onOpen: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Balanced'), findsOneWidget);
  });
}
