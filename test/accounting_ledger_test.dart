import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:erp_sys/features/accounting/ledger/view/ledger_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/accounting_report_fakes.dart';

void main() {
  final accounts = AccountListFake([
    account('a1', '1100', 'Bank', 'asset'),
    account('a9', '5900', 'Old expenses', 'expense', active: false),
  ]);

  Future<ReportsFake> pump(
    WidgetTester tester, {
    String? accountId,
    ReportsFake? fake,
    String lang = 'en',
  }) async {
    desktopView(tester);
    final reports = fake ?? (ReportsFake()..ledger = ledgerReport());
    await tester.pumpWidget(
      reportApp(
        LedgerPage(
          reportsRepo: reports,
          accountsRepo: accounts,
          initialAccountId: accountId,
          now: DateTime(2026, 10, 31),
        ),
        lang: lang,
      ),
    );
    await tester.pumpAndSettle();
    return reports;
  }

  testWidgets('no account selected shows a prompt and loads nothing', (
    tester,
  ) async {
    final reports = await pump(tester);
    expect(find.text('Choose an account to view its ledger.'), findsOneWidget);
    expect(reports.ledgerCalls, isEmpty);
  });

  testWidgets('initial account loads the current month with balances', (
    tester,
  ) async {
    final reports = await pump(tester, accountId: 'a1');
    expect(reports.ledgerCalls.single.accountId, 'a1');
    expect(reports.ledgerCalls.single.from, DateTime(2026, 10, 1));
    expect(reports.ledgerCalls.single.to, DateTime(2026, 10, 31));
    expect(find.text('Opening balance'), findsNWidgets(2)); // card + first row
    expect(find.text('1,000.00'), findsNWidgets(2));
    expect(find.text('Closing balance'), findsOneWidget);
    expect(find.text('600.00'), findsNWidgets(2)); // card + running balance
    expect(find.text('Salaries October'), findsOneWidget);
  });

  testWidgets('abnormal balance shows parentheses', (tester) async {
    await pump(
      tester,
      accountId: 'a1',
      fake: ReportsFake()..ledger = ledgerReport(closing: -50, rows: const []),
    );
    expect(find.text('(50.00)'), findsOneWidget);
  });

  testWidgets('truncated report shows a banner', (tester) async {
    await pump(
      tester,
      accountId: 'a1',
      fake: ReportsFake()..ledger = ledgerReport(truncated: true),
    );
    expect(
      find.text(
        'Showing the first 2,000 movements. Narrow the date range to see all.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no movements still shows opening and closing', (tester) async {
    await pump(
      tester,
      accountId: 'a1',
      fake: ReportsFake()
        ..ledger = ledgerReport(opening: 0, closing: 0, rows: const []),
    );
    expect(find.text('No posted movements in this period.'), findsOneWidget);
    expect(find.text('Closing balance'), findsOneWidget);
  });

  testWidgets('inactive accounts are listed in the picker', (tester) async {
    await pump(tester);
    final menu = tester.widget<DropdownMenu<String>>(
      find.byType(DropdownMenu<String>),
    );
    expect(
      menu.dropdownMenuEntries.map((e) => e.label),
      containsAll(['1100 — Bank', '5900 — Old expenses (Inactive)']),
    );
  });

  testWidgets('a failed load can be retried', (tester) async {
    final reports = await pump(
      tester,
      accountId: 'a1',
      fake: ReportsFake()
        ..ledger = ledgerReport()
        ..failures = 1,
    );
    expect(find.byType(AppFailureState), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AppFailureState),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(reports.ledgerCalls, hasLength(2));
    expect(find.text('Salaries October'), findsOneWidget);
  });

  testWidgets('Arabic layout renders without errors', (tester) async {
    await pump(tester, accountId: 'a1', lang: 'ar');
    expect(tester.takeException(), isNull);
    expect(find.text('دفتر الأستاذ العام'), findsOneWidget);
  });

  testWidgets('fits a phone screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      reportApp(
        LedgerPage(
          reportsRepo: ReportsFake()..ledger = ledgerReport(truncated: true),
          accountsRepo: accounts,
          initialAccountId: 'a1',
          now: DateTime(2026, 10, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Salaries October'), findsOneWidget);
  });
}
