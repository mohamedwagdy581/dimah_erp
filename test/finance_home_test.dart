import 'dart:io';
import 'dart:ui' as ui;
import 'package:erp_sys/features/finance_home/finance_home_page.dart';
import 'package:erp_sys/features/finance_home/finance_home_repo.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_run.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/accounting/reports/domain/accounting_reports_models.dart';
import 'support/accounting_report_fakes.dart';

ReportsFake kpiFake() => ReportsFake()
  ..kpis = const AccountingKpis(
    cashBalance: 0,
    hasCashAccounts: true,
    revenue: 0,
    expenses: 0,
    netProfit: 0,
    draftCount: 0,
    staleDraftCount: 0,
  );

PayrollRun run(String id, String status, {String? disbursement}) => PayrollRun(
  id: id,
  tenantId: 'tenant',
  periodStart: DateTime(2026, 10),
  periodEnd: DateTime(2026, 10, 31),
  status: status,
  totalEmployees: 12,
  totalAmount: 67200,
  createdAt: DateTime(2026, 10),
  disbursementStatus: disbursement,
);

class HomeFixture implements FinanceHomeRepo {
  bool fail = false, sectionFail = false;
  String role = 'finance_manager';
  final team = [
    FinanceTeamMember({
      'id': 'member',
      'full_name': 'موظف الفريق',
      'employee_number': 'EMP-0013',
      'job_title': 'محاسب',
      'tasks': [
        {
          'id': 'task',
          'title': 'مراجعة المصروفات',
          'status': 'in_progress',
          'due_date': '2026-10-20',
        },
      ],
    }),
  ];
  @override
  Future<List<FinanceTeamMember>> loadTeam() async => team;
  @override
  Future<FinanceHomeData> load(DateTime month) async {
    if (fail) throw StateError('SocketException');
    return FinanceHomeData(
      role: role,
      name: 'Finance',
      month: month,
      runs: FinanceResult.value([
        run('review', 'pending_finance_manager'),
        run('assign', 'approved', disbursement: 'assigned_to_finance_manager'),
        run('paid', 'approved', disbursement: 'paid'),
        run('draft', 'draft'),
      ]),
      journal: const FinanceResult.value([
        {
          'id': 'entry',
          'entry_date': '2026-10-11',
          'memo': 'قيد مصروفات الكهرباء',
          'total_debit': 1000,
          'total_credit': 1000,
          'status': 'draft',
        },
      ]),
      accounts: sectionFail
          ? const FinanceResult.failure('SocketException')
          : const FinanceResult.value([]),
      approvals: const FinanceResult.value(2),
      team: FinanceResult.value(team),
    );
  }
}

Future<void> mount(
  WidgetTester tester,
  Widget child,
  double width,
  String locale,
) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  if (const bool.fromEnvironment('EXPORT_FINANCE_HOME')) {
    testWidgets('Export finance dashboard preview', (tester) async {
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
      final key = GlobalKey();
      await mount(
        tester,
        RepaintBoundary(
          key: key,
          child: FinanceHomePage(
            reportsRepo: kpiFake(),
            repo: HomeFixture(),
            now: DateTime(2026, 10),
            onOpen: (_) {},
          ),
        ),
        1440,
        'ar',
      );
      await tester.runAsync(() async {
        final picture =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/finance_home_preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    });
  }
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Finance home responsive $language $width', (tester) async {
        final fixture = HomeFixture();
        await mount(
          tester,
          FinanceHomePage(
            reportsRepo: kpiFake(),
            repo: fixture,
            now: DateTime(2026, 10),
            onOpen: (_) {},
          ),
          width,
          language,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -1800),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'Review and assignment open their exact run and exclude paid/draft',
    (tester) async {
      final opened = <String>[];
      await mount(
        tester,
        FinanceHomePage(
          reportsRepo: kpiFake(),
          repo: HomeFixture(),
          now: DateTime(2026, 10),
          onOpen: opened.add,
        ),
        1440,
        'ar',
      );
      expect(find.byKey(const ValueKey('open-run-paid')), findsNothing);
      expect(find.byKey(const ValueKey('open-run-draft')), findsNothing);
      for (final id in ['review', 'assign']) {
        final target = find.byKey(ValueKey('open-run-$id'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }
      expect(opened, ['/payroll/review', '/payroll/assign?disbursement=1']);
    },
  );
  testWidgets(
    'Failed section says unavailable instead of zero; other sections stay visible',
    (tester) async {
      final fixture = HomeFixture()..sectionFail = true;
      await mount(
        tester,
        FinanceHomePage(reportsRepo: kpiFake(), repo: fixture, onOpen: (_) {}),
        1440,
        'ar',
      );
      expect(find.text('تعذر التحميل'), findsOneWidget);
      expect(find.text('لوحة مدير المالية'), findsOneWidget);
      fixture.sectionFail = false;
      await tester.tap(find.byKey(const Key('finance-home-refresh')));
      await tester.pumpAndSettle();
      expect(find.text('تعذر التحميل'), findsNothing);
    },
  );
  testWidgets('Whole page load failure has retry', (tester) async {
    final fixture = HomeFixture()..fail = true;
    await mount(
      tester,
      FinanceHomePage(reportsRepo: kpiFake(), repo: fixture, onOpen: (_) {}),
      768,
      'en',
    );
    fixture.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Finance manager dashboard'), findsOneWidget);
  });
  testWidgets(
    'Team details only select a returned member; narrow tasks scroll',
    (tester) async {
      await mount(tester, FinanceTeamPage(repo: HomeFixture()), 320, 'ar');
      await tester.ensureVisible(
        find.byKey(const ValueKey('view-member-member')),
      );
      await tester.tap(find.byKey(const ValueKey('view-member-member')));
      await tester.pumpAndSettle();
      expect(find.text('مراجعة المصروفات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Foreign team query cannot open a profile', (tester) async {
    await mount(
      tester,
      FinanceTeamPage(repo: HomeFixture(), employeeId: 'foreign'),
      768,
      'ar',
    );
    expect(find.text('الموظف غير موجود ضمن فريقك النشط.'), findsOneWidget);
    expect(find.text('مراجعة المصروفات'), findsNothing);
  });
}
