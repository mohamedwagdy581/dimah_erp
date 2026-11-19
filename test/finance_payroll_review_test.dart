import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_item.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_run.dart';
import 'package:erp_sys/features/payroll/domain/repos/payroll_repo.dart';
import 'package:erp_sys/features/payroll/view/widgets/finance_payroll_workspace.dart';

class FinanceRepo implements PayrollRepo {
  String status = 'pending_finance_manager';
  String? savedNotes;
  int approvals = 0, rejections = 0;
  bool failRead = false, failSave = false, empty = false, inconsistent = false;
  Completer<void>? pending;
  final pages = <int>[];
  final names = [
    'سارة أحمد',
    'عبدالله محمد',
    'نورة علي',
    'محمد خالد',
    'ريم عبدالله',
  ];
  PayrollRun run(String id) => PayrollRun(
    id: id,
    tenantId: 'tenant',
    periodStart: DateTime(2026, 10),
    periodEnd: DateTime(2026, 10, 31),
    status: status,
    totalEmployees: inconsistent ? 128 : 5,
    totalAmount: 59800,
    createdAt: DateTime(2026, 10, 1),
  );
  @override
  Future<({List<PayrollRun> items, int total})> fetchRuns({
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    pages.add(page);
    if (failRead) throw StateError('SocketException: offline');
    return (items: empty ? <PayrollRun>[] : [run('run')], total: empty ? 0 : 1);
  }

  @override
  Future<List<PayrollItem>> fetchRunItems({required String runId}) async =>
      List.generate(
        5,
        (i) => PayrollItem(
          id: '$i',
          runId: runId,
          employeeId: '$i',
          employeeName: names[i],
          employeeNumber: 'EMP-00${i + 1}',
          jobTitle: [
            'مدير موارد بشرية',
            'محاسب رواتب',
            'أخصائي موارد بشرية',
            'أخصائي توظيف',
            'مساعد إداري',
          ][i],
          basicSalary: [12000, 9000, 8500, 7500, 6500][i],
          housingAllowance: [3000, 2500, 2000, 2000, 1500][i],
          transportAllowance: [1000, 800, 800, 700, 600][i],
          otherAllowance: [500, 300, 200, 200, 200][i],
          total: [16500, 12600, 11500, 10400, 8800][i],
        ),
      );
  @override
  Future<String?> fetchFinanceReviewNotes({required String runId}) async =>
      savedNotes;
  @override
  Future<void> financeManagerApprove({
    required String runId,
    String? notes,
  }) async {
    approvals++;
    expect(runId, 'run');
    if (pending != null) await pending!.future;
    if (failSave) throw StateError('SocketException: offline');
    savedNotes = notes;
    status = 'pending_admin_approval';
  }

  @override
  Future<void> rejectRun({
    required String runId,
    required String reason,
    required String rejectedByRole,
  }) async {
    rejections++;
    expect(runId, 'run');
    expect(rejectedByRole, 'finance_manager');
    savedNotes = reason;
    status = 'rejected_by_finance_manager';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(
  FinanceRepo repo, {
  String lang = 'ar',
  String? initialRunId,
  ValueChanged<String>? onDisbursement,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: EmployeeTheme.from(AppTheme.light()),
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: appLocalizationDelegates,
  home: Scaffold(
    body: FinancePayrollWorkspace(
      repo: repo,
      initialRunId: initialRunId,
      today: DateTime(2026, 10, 8),
      onDisbursement: onDisbursement,
    ),
  ),
);

void main() {
  testWidgets(
    'Draft explains HR step; refreshing same payroll reveals finance actions',
    (tester) async {
      final repo = FinanceRepo()..status = 'draft';
      await tester.pumpWidget(app(repo, lang: 'en', initialRunId: 'run'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('HR must submit it for finance review'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('finance-approve')), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      repo.status = 'pending_finance_manager';
      final refresh = find.byKey(const ValueKey('finance-refresh-status'));
      await tester.ensureVisible(refresh);
      await tester.tap(refresh);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('finance-approve')), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).readOnly,
        isFalse,
      );
    },
  );
  testWidgets(
    'Awaiting admin explains next step without exposing finance decision again',
    (tester) async {
      final repo = FinanceRepo()..status = 'pending_admin_approval';
      await tester.pumpWidget(app(repo, lang: 'en', initialRunId: 'run'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Management must approve this payroll'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('finance-approve')), findsNothing);
      expect(find.byKey(const ValueKey('finance-reject')), findsNothing);
    },
  );
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
        'Review $lang at $width stays scrollable and sends real notes once',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 850));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final repo = FinanceRepo()..pending = Completer<void>();
          await tester.pumpWidget(app(repo, lang: lang));
          await tester.pumpAndSettle();
          expect(repo.pages.first, 0);
          expect(find.text('59,800.00'), findsNWidgets(2));
          expect(tester.takeException(), isNull);
          final scroll = tester.widget<SingleChildScrollView>(
            find.byKey(const ValueKey('finance-table-scroll')),
          );
          if (width < 1100) {
            expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));
          }
          final notes = find.byType(TextField);
          await tester.ensureVisible(notes);
          await tester.enterText(notes, 'Reviewed salary allowances');
          final approve = find.byKey(const ValueKey('finance-approve'));
          await tester.ensureVisible(approve);
          await tester.tap(approve);
          await tester.pump();
          await tester.tap(approve);
          await tester.pump();
          expect(repo.approvals, 1);
          repo.pending!.complete();
          await tester.pumpAndSettle();
          expect(repo.savedNotes, 'Reviewed salary allowances');
          expect(find.byKey(const ValueKey('finance-approve')), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('Rejection requires a reason and records it with finance role', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = FinanceRepo();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    final reject = find.byKey(const ValueKey('finance-reject'));
    await tester.ensureVisible(reject);
    await tester.tap(reject);
    await tester.pumpAndSettle();
    expect(repo.rejections, 0);
    expect(find.text('اكتب سبب الرفض في ملاحظات المراجعة.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'راجع بدل السكن');
    await tester.ensureVisible(reject);
    await tester.tap(reject);
    await tester.pumpAndSettle();
    expect(repo.savedNotes, 'راجع بدل السكن');
    expect(repo.rejections, 1);
  });
  testWidgets('Connection failures retry and failed decision retains notes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = FinanceRepo()..failRead = true;
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    repo.failRead = false;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Keep my notes');
    repo.failSave = true;
    final approve = find.byKey(const ValueKey('finance-approve'));
    await tester.ensureVisible(approve);
    await tester.tap(approve);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Keep my notes',
    );
    expect(repo.status, 'pending_finance_manager');
    repo.failSave = false;
    await tester.ensureVisible(approve);
    await tester.tap(approve);
    await tester.pumpAndSettle();
    expect(repo.savedNotes, 'Keep my notes');
  });
  testWidgets('No runs clears filters; incomplete totals cannot be approved', (
    tester,
  ) async {
    final repo = FinanceRepo()..empty = true;
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مسيرات رواتب لهذه الفترة'), findsOneWidget);
    repo.empty = false;
    repo.inconsistent = true;
    await tester.tap(find.text('مسح الفلاتر'));
    await tester.pumpAndSettle();
    final approve = tester.widget<FilledButton>(
      find.byKey(const ValueKey('finance-approve')),
    );
    expect(approve.onPressed, isNull);
  });
  testWidgets('Approved run remains read-only with access to disbursement', (
    tester,
  ) async {
    final repo = FinanceRepo()
      ..status = 'approved'
      ..savedNotes = 'Saved finance notes';
    String? id;
    await tester.pumpWidget(
      app(repo, initialRunId: 'run', onDisbursement: (v) => id = v),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(find.byKey(const ValueKey('finance-approve')), findsNothing);
    final payment = find.text('متابعة صرف المسير');
    await tester.ensureVisible(payment);
    await tester.tap(payment);
    expect(id, 'run');
  });
  if (const bool.fromEnvironment('EXPORT_FINANCE_PAYROLL')) {
    testWidgets('Export review preview', (tester) async {
      await tester.runAsync(() async {
        final font = FontLoader('Roboto')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                await File(
                  'assets/fonts/DINNextLTArabic-Regular-2.ttf',
                ).readAsBytes(),
              ),
            ),
          );
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                await File(
                  'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                ).readAsBytes(),
              ),
            ),
          );
        await icons.load();
      });
      await tester.binding.setSurfaceSize(const Size(1350, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: app(FinanceRepo())),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/finance_payroll_preview.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
