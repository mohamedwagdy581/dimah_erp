import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/accounting/accounts/domain/models/account.dart';
import 'package:erp_sys/features/accounting/accounts/domain/repos/accounts_repo.dart';
import 'package:erp_sys/features/accounting/accounts/view/widgets/accounts_workspace.dart';
import 'package:erp_sys/features/accounting/journal/domain/models/journal_line.dart';
import 'package:erp_sys/features/accounting/journal/domain/repos/journal_repo.dart';
import 'package:erp_sys/features/accounting/journal/view/widgets/journal_draft_workspace.dart';

class AccountsFixture implements AccountsRepo {
  int saves = 0;
  bool failSave = false, failRead = false;
  String? id;
  bool? active, filter, cash;
  Completer<void>? pending;
  final rows = [
    for (var i = 0; i < 15; i++)
      Account(
        id: 'account-$i',
        tenantId: 'tenant',
        code: '${1100 + i}',
        name: i == 0
            ? 'مصروفات الرواتب'
            : i == 1
            ? 'البنك'
            : 'حساب $i',
        type: i == 0 ? 'expense' : 'asset',
        isActive: i != 14,
        isCash: i == 1,
        createdAt: DateTime(2026, 10),
      ),
  ];
  @override
  Future<({List<Account> items, int total})> fetchAccounts({
    required int page,
    required int pageSize,
    String? search,
    String? type,
    bool? isActive,
    String sortBy = 'code',
    bool ascending = true,
  }) async {
    if (failRead) throw StateError('offline');
    filter = isActive;
    final list = rows
        .where(
          (a) =>
              (isActive == null || a.isActive == isActive) &&
              (type == null || a.type == type),
        )
        .toList();
    return (
      items: list.skip(page * pageSize).take(pageSize).toList(),
      total: list.length,
    );
  }

  @override
  Future<void> updateAccount({
    required String id,
    required String code,
    required String name,
    required String type,
    required bool isActive,
    bool isCash = false,
  }) async {
    saves++;
    this.id = id;
    active = isActive;
    cash = isCash;
    if (pending != null) await pending!.future;
    if (failSave) throw StateError('offline');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class JournalFixture implements JournalRepo {
  int saves = 0;
  bool fail = false;
  List<JournalLine>? lines;
  final ids = <String?>[];
  Completer<void>? pending;
  @override
  Future<void> createEntry({
    required DateTime entryDate,
    required String memo,
    required List<JournalLine> lines,
    String? requestId,
  }) async {
    saves++;
    this.lines = lines;
    ids.add(requestId);
    if (pending != null) await pending!.future;
    if (fail) throw StateError('offline');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(Widget child, {String lang = 'ar', double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: EmployeeTheme.from(AppTheme.light()),
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);
Widget draft(
  AccountsFixture accounts,
  JournalFixture journal, {
  VoidCallback? saved,
}) => JournalDraftWorkspace(
  accountsRepo: accounts,
  journalRepo: journal,
  onSaved: saved ?? () {},
  onCancel: () {},
);
Future<void> fillJournal(
  WidgetTester tester, {
  String debit = '1000',
  String credit = '1000',
}) async {
  final fields = find.byType(DropdownButtonFormField<String>);
  for (var i = 0; i < 2; i++) {
    await tester.ensureVisible(fields.at(i));
    await tester.tap(fields.at(i));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(i == 0 ? '1100 · مصروفات الرواتب' : '1101 · البنك').last,
    );
    await tester.pumpAndSettle();
  }
  final amounts = find
      .byType(TextField)
      .evaluate()
      .where(
        (e) =>
            (e.widget as TextField).keyboardType ==
            const TextInputType.numberWithOptions(decimal: true),
      )
      .map((e) => find.byWidget(e.widget))
      .toList();
  await tester.ensureVisible(amounts[0]);
  await tester.enterText(amounts[0], debit);
  await tester.ensureVisible(amounts[3]);
  await tester.enterText(amounts[3], credit);
}

void main() {
  testWidgets('Account read failure retries without discarding form values', (
    tester,
  ) async {
    final accounts = AccountsFixture()..failRead = true;
    await tester.pumpWidget(app(AccountsWorkspace(repo: accounts), lang: 'en'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('account-name')), 'Bank');
    accounts.failRead = false;
    final retry = find.text('Retry');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('account-name')))
          .controller!
          .text,
      'Bank',
    );
    expect(
      find.byKey(const ValueKey('edit-account-account-0')),
      findsOneWidget,
    );
  });
  testWidgets('A single line cannot contain both debit and credit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journal = JournalFixture();
    await tester.pumpWidget(app(draft(AccountsFixture(), journal), lang: 'en'));
    await tester.pumpAndSettle();
    await fillJournal(tester);
    final amounts = find
        .byType(TextField)
        .evaluate()
        .where(
          (e) =>
              (e.widget as TextField).keyboardType ==
              const TextInputType.numberWithOptions(decimal: true),
        )
        .map((e) => find.byWidget(e.widget))
        .toList();
    await tester.enterText(amounts[1], '1');
    final save = find.byKey(const ValueKey('journal-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(journal.saves, 0);
    expect(find.textContaining('positive debit OR credit'), findsOneWidget);
  });
  testWidgets(
    'Small journal scrolls to row deletion without controller errors',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(draft(AccountsFixture(), JournalFixture())));
      await tester.pumpAndSettle();
      final remove = find.byIcon(Icons.delete_outline).first;
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Journal loads active accounts beyond the old 200-account limit',
    (tester) async {
      final accounts = AccountsFixture();
      accounts.rows.clear();
      accounts.rows.addAll([
        for (var i = 0; i < 250; i++)
          Account(
            id: '$i',
            tenantId: 'tenant',
            code: '$i',
            name: 'Account $i',
            type: 'asset',
            isActive: true,
            createdAt: DateTime(2026),
          ),
      ]);
      await tester.pumpWidget(app(draft(accounts, JournalFixture())));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.byType(DropdownButton<String>).first,
            )
            .items!
            .length,
        250,
      );
    },
  );
  test(
    'Money parser supports Arabic digits and exact cents; rejects invalid money',
    () {
      expect(journalCents('١٢٣٫٤٥'), 12345);
      expect(journalCents('0.1'), 10);
      expect(journalCents('0.2'), 20);
      for (final input in ['NaN', 'Infinity', '-1', '1.234', 'wrong']) {
        expect(journalCents(input), isNull);
      }
    },
  );
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Accounting $lang $width responsive and editable', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 850));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final accounts = AccountsFixture();
        await tester.pumpWidget(
          app(AccountsWorkspace(repo: accounts), lang: lang, scale: 1.3),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final edit = find.byKey(const ValueKey('edit-account-account-0'));
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(find.byKey(const ValueKey('account-code')))
              .controller!
              .text,
          '1100',
        );
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        final save = find.byKey(const ValueKey('account-save'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(accounts.id, 'account-0');
        expect(accounts.active, false);
        expect(accounts.saves, 1);
        await tester.pumpWidget(
          app(draft(accounts, JournalFixture()), lang: lang, scale: 1.3),
        );
        await tester.pumpAndSettle();
        expect(accounts.filter, true);
        expect(tester.takeException(), isNull);
        final add = find.byKey(const ValueKey('journal-add-line'));
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'Unbalanced draft cannot save; balanced draft saves once while busy',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journal = JournalFixture()..pending = Completer<void>();
      await tester.pumpWidget(
        app(draft(AccountsFixture(), journal), lang: 'en'),
      );
      await tester.pumpAndSettle();
      await fillJournal(tester, credit: '900');
      final save = find.byKey(const ValueKey('journal-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(journal.saves, 0);
      expect(
        find.textContaining('total debits must equal total credits'),
        findsOneWidget,
      );
      await fillJournal(tester);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(journal.saves, 1);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      journal.pending!.complete();
      await tester.pumpAndSettle();
      expect(journal.lines!.first.debit, 1000);
      expect(journal.lines!.last.credit, 1000);
    },
  );
  testWidgets('Failed draft retry retains values and the same request id', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journal = JournalFixture()..fail = true;
    await tester.pumpWidget(app(draft(AccountsFixture(), journal), lang: 'en'));
    await tester.pumpAndSettle();
    await fillJournal(tester, debit: '٠٫٣٠', credit: '0.30');
    final save = find.byKey(const ValueKey('journal-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save.'), findsOneWidget);
    journal.fail = false;
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(journal.ids.length, 2);
    expect(journal.ids[0], journal.ids[1]);
    expect(journal.lines!.first.debit, .3);
  });
  testWidgets('Account save failure retains fields and identity for retry', (
    tester,
  ) async {
    final accounts = AccountsFixture()..failSave = true;
    await tester.pumpWidget(app(AccountsWorkspace(repo: accounts), lang: 'en'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('account-code')), '5100');
    await tester.enterText(
      find.byKey(const ValueKey('account-name')),
      'Salary expenses',
    );
    final save = find.byKey(const ValueKey('account-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final id = accounts.id;
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('account-name')))
          .controller!
          .text,
      'Salary expenses',
    );
    accounts.failSave = false;
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(accounts.id, id);
  });
  testWidgets('Cash checkbox only for assets and clears on type change', (
    tester,
  ) async {
    final accounts = AccountsFixture();
    await tester.pumpWidget(app(AccountsWorkspace(repo: accounts), lang: 'en'));
    await tester.pumpAndSettle();
    final cash = find.byKey(const ValueKey('account-is-cash'));
    expect(cash, findsNothing);
    Future<void> pickType(String label) async {
      final field = find.descendant(
        of: find.byKey(const ValueKey('account-type')),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await pickType('Asset');
    expect(cash, findsOneWidget);
    await tester.ensureVisible(cash);
    await tester.tap(cash);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(cash).value, isTrue);
    await pickType('Expense');
    expect(cash, findsNothing);
    await tester.enterText(find.byKey(const ValueKey('account-code')), '5100');
    await tester.enterText(find.byKey(const ValueKey('account-name')), 'Rent');
    final save = find.byKey(const ValueKey('account-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(accounts.saves, 1);
    expect(accounts.cash, isFalse);
  });
  testWidgets('Cash accounts show a chip, keep the flag, and open the ledger', (
    tester,
  ) async {
    final accounts = AccountsFixture();
    String? opened;
    await tester.pumpWidget(
      app(
        AccountsWorkspace(repo: accounts, onOpenLedger: (id) => opened = id),
        lang: 'en',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cash'), findsOneWidget);
    final edit = find.byKey(const ValueKey('edit-account-account-1'));
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    final cash = find.byKey(const ValueKey('account-is-cash'));
    expect(tester.widget<CheckboxListTile>(cash).value, isTrue);
    final save = find.byKey(const ValueKey('account-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(accounts.cash, isTrue);
    final ledger = find.byKey(const ValueKey('ledger-account-account-1'));
    await tester.ensureVisible(ledger);
    await tester.tap(ledger);
    await tester.pumpAndSettle();
    expect(opened, 'account-1');
  });
  if (const bool.fromEnvironment('EXPORT_ACCOUNTING')) {
    for (final accountsScreen in [true, false]) {
      testWidgets('Export ${accountsScreen ? 'accounts' : 'journal'} preview', (
        tester,
      ) async {
        await tester.runAsync(() async {
          for (final entry in {
            'Roboto': 'assets/fonts/DINNextLTArabic-Regular-2.ttf',
            'MaterialIcons':
                'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          }.entries) {
            await (FontLoader(entry.key)..addFont(
                  Future.value(
                    ByteData.sublistView(await File(entry.value).readAsBytes()),
                  ),
                ))
                .load();
          }
        });
        await tester.binding.setSurfaceSize(const Size(1440, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: app(
              accountsScreen
                  ? AccountsWorkspace(repo: AccountsFixture())
                  : draft(AccountsFixture(), JournalFixture()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (!accountsScreen) {
          await fillJournal(tester);
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, 900),
          );
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/accounting_${accountsScreen ? 'accounts' : 'journal'}_preview.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
