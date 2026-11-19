import 'dart:async';

import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/accounting/journal/domain/models/journal_entry.dart';
import 'package:erp_sys/features/accounting/journal/domain/repos/journal_repo.dart';
import 'package:erp_sys/features/accounting/journal/view/cubit/journal_cubit.dart';
import 'package:erp_sys/features/accounting/journal/view/sections/journal_table_section.dart';
import 'package:erp_sys/features/accounting/view/accounting_ui.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

JournalEntry entry(String id, String status) => JournalEntry(
  id: id,
  tenantId: 'tenant',
  entryDate: DateTime(2026, 10, 5),
  memo: 'Memo $id',
  totalDebit: 1000,
  totalCredit: 1000,
  status: status,
  createdAt: DateTime(2026, 10, 5),
);

class PostFixture implements JournalRepo {
  int posts = 0, fetches = 0;
  Object? failWith;
  Completer<void>? pending;
  final items = [entry('d1', 'draft'), entry('p1', 'posted')];

  @override
  Future<({List<JournalEntry> items, int total})> fetchEntries({
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String sortBy = 'entry_date',
    bool ascending = false,
  }) async {
    fetches++;
    return (items: List.of(items), total: items.length);
  }

  @override
  Future<void> postEntry(String id) async {
    posts++;
    if (pending != null) await pending!.future;
    if (failWith != null) throw failWith!;
    final i = items.indexWhere((e) => e.id == id);
    items[i] = entry(id, 'posted');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget localized(Widget child, {String lang = 'en'}) => MaterialApp(
  theme: EmployeeTheme.from(AppTheme.light()),
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: appLocalizationDelegates,
  home: Scaffold(body: child),
);

void main() {
  group('accountingErrorText', () {
    Future<String> textFor(WidgetTester tester, Object e, String lang) async {
      late String out;
      await tester.pumpWidget(
        localized(
          Builder(
            builder: (context) {
              out = accountingErrorText(context, e);
              return const SizedBox();
            },
          ),
          lang: lang,
        ),
      );
      return out;
    }

    testWidgets('maps permission, balance and inactive errors', (tester) async {
      const denied = PostgrestException(message: 'x', code: '42501');
      expect(
        await textFor(tester, denied, 'en'),
        "You don't have permission for this action.",
      );
      expect(
        await textFor(tester, denied, 'ar'),
        'ليست لديك صلاحية لهذا الإجراء.',
      );
      const unbalanced = PostgrestException(
        message: 'Debits must equal credits',
      );
      expect(await textFor(tester, unbalanced, 'en'), 'Entry is not balanced.');
      expect(await textFor(tester, unbalanced, 'ar'), 'القيد غير متوازن.');
      const inactive = PostgrestException(
        message: 'Entry uses an inactive account',
      );
      expect(
        await textFor(tester, inactive, 'en'),
        'Entry uses an inactive account.',
      );
      expect(
        await textFor(tester, inactive, 'ar'),
        'القيد يستخدم حسابًا غير نشط.',
      );
      expect(
        await textFor(
          tester,
          const PostgrestException(message: 'Only drafts can be posted'),
          'en',
        ),
        'The server rejected this action. Refresh the page and try again.',
      );
      expect(
        await textFor(tester, StateError('SocketException'), 'en'),
        'Could not complete the action. Check your connection and retry.',
      );
    });
  });

  group('JournalCubit.postEntry', () {
    test('success reloads the list and clears postingId', () async {
      final repo = PostFixture();
      final cubit = JournalCubit(repo);
      await cubit.load();
      final error = await cubit.postEntry('d1');
      expect(error, isNull);
      expect(repo.posts, 1);
      expect(repo.fetches, 2);
      expect(cubit.state.postingId, isNull);
      expect(cubit.state.items.first.status, 'posted');
    });

    test('failure returns the error and keeps the list', () async {
      final repo = PostFixture()..failWith = StateError('offline');
      final cubit = JournalCubit(repo);
      await cubit.load();
      final error = await cubit.postEntry('d1');
      expect(error, isA<StateError>());
      expect(cubit.state.postingId, isNull);
      expect(cubit.state.items.first.status, 'draft');
    });

    test('a second post while one is running is ignored', () async {
      final repo = PostFixture()..pending = Completer<void>();
      final cubit = JournalCubit(repo);
      await cubit.load();
      final first = cubit.postEntry('d1');
      expect(cubit.state.postingId, 'd1');
      expect(await cubit.postEntry('d1'), isNull);
      repo.pending!.complete();
      await first;
      expect(repo.posts, 1);
    });
  });

  group('Post action', () {
    Future<PostFixture> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = PostFixture();
      await tester.pumpWidget(
        localized(
          BlocProvider(
            create: (_) => JournalCubit(repo)..load(),
            child: const JournalTableSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('only drafts have a Post button and it confirms first', (
      tester,
    ) async {
      final repo = await pump(tester);
      expect(find.byKey(const ValueKey('post-entry-d1')), findsOneWidget);
      expect(find.byKey(const ValueKey('post-entry-p1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('post-entry-d1')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Posting is final. The entry will count in the books and can no longer be edited.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('confirm-post')));
      await tester.pumpAndSettle();
      expect(repo.posts, 1);
      expect(find.text('Entry posted.'), findsOneWidget);
      expect(find.byKey(const ValueKey('post-entry-d1')), findsNothing);
    });

    testWidgets('cancel does not post', (tester) async {
      final repo = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('post-entry-d1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cancel-post')));
      await tester.pumpAndSettle();
      expect(repo.posts, 0);
    });

    testWidgets('Post button fits a tablet-width table', (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = PostFixture();
      await tester.pumpWidget(
        localized(
          BlocProvider(
            create: (_) => JournalCubit(repo)..load(),
            child: const JournalTableSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Post'), findsOneWidget);
    });
  });
}
