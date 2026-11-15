import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/payroll/data/repos/payroll_disbursement_repo.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_run.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_assignee_option.dart';
import 'package:erp_sys/features/payroll/view/widgets/finance_disbursement_workspace.dart';
import 'package:erp_sys/features/payroll/view/widgets/finance_payroll_table.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_item.dart';

class FakeDisbursement implements PayrollDisbursementRepo {
  String status = 'approved', payment = 'assigned_to_finance_manager';
  bool missingTask = false, empty = false, fail = false;
  int assignments = 0;
  String? employee;
  Completer<void>? pending;
  @override
  Future<PayrollDisbursementData> load(String runId) async =>
      PayrollDisbursementData(
        run: PayrollRun(
          id: runId,
          tenantId: 'tenant',
          periodStart: DateTime(2026, 10),
          periodEnd: DateTime(2026, 10, 31),
          status: status,
          totalEmployees: 5,
          totalAmount: 59800,
          createdAt: DateTime(2026, 10, 1),
          adminApprovedAt: DateTime(2026, 10, 4),
          disbursementStatus: payment,
          disbursementTaskId: missingTask ? null : 'task-actual-id',
        ),
        accountants: empty
            ? []
            : [
                const PayrollAssigneeOption(
                  employeeId: 'accountant',
                  fullName: 'أحمد عبدالعزيز',
                  employeeNumber: 'EMP-006',
                ),
              ],
        taskTitle: 'صرف رواتب أكتوبر 2026',
        taskCreatedAt: DateTime(2026, 10, 4),
      );
  @override
  Future<void> assign(String runId, String employeeId) async {
    expect(runId, 'run');
    assignments++;
    employee = employeeId;
    if (pending != null) await pending!.future;
    if (fail) throw StateError('offline');
  }
}

Widget app(FakeDisbursement repo, {String lang = 'ar', double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: EmployeeTheme.from(AppTheme.light()),
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: FinanceDisbursementWorkspace(repo: repo, runId: 'run'),
      ),
    );
final assignButton = find.byKey(const ValueKey('disbursement-assign'));
Future<void> selectAccountant(WidgetTester tester) async {
  final dropdown = find.byKey(const ValueKey('disbursement-accountant'));
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('EMP-006').last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(assignButton);
}

void main() {
  testWidgets(
    'Large payroll scrolls both ways with fixed headings and totals',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancePayrollTable(
              items: [
                for (var i = 0; i < 30; i++)
                  PayrollItem(
                    id: '$i',
                    runId: 'run',
                    employeeId: '$i',
                    employeeName: 'Employee $i',
                    jobTitle: 'Accountant',
                    basicSalary: 1000,
                    housingAllowance: 200,
                    transportAllowance: 100,
                    otherAllowance: 0,
                    total: 1300,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final vertical = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('finance-table-vertical-scroll')),
          )
          .controller!;
      final horizontal = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('finance-table-scroll')),
          )
          .controller!;
      expect(vertical.position.maxScrollExtent, greaterThan(0));
      expect(horizontal.position.maxScrollExtent, greaterThan(0));
      final heading = tester.getRect(find.text('Employee'));
      final total = tester.getRect(find.text('Total'));
      vertical.jumpTo(vertical.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Employee')), heading);
      expect(tester.getRect(find.text('Total')), total);
      expect(
        tester.getRect(find.text('Employee 29')).bottom,
        lessThan(total.top),
      );
      horizontal.jumpTo(horizontal.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
        'Assignment $lang $width responsive and prevents repeat submission',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 850));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final repo = FakeDisbursement()..pending = Completer<void>();
          await tester.pumpWidget(app(repo, lang: lang, scale: 1.3));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.widget<FilledButton>(assignButton).onPressed, isNull);
          await selectAccountant(tester);
          await tester.tap(assignButton);
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(lang == 'ar' ? 'تأكيد الإسناد' : 'Confirm assignment'),
          );
          await tester.pump();
          expect(repo.assignments, 1);
          expect(tester.widget<FilledButton>(assignButton).onPressed, isNull);
          repo.pending!.complete();
          await tester.pumpAndSettle();
          expect(repo.employee, 'accountant');
          expect(tester.widget<FilledButton>(assignButton).onPressed, isNull);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('Cancel preserves choice; failed assignment can retry', (
    tester,
  ) async {
    final repo = FakeDisbursement()..fail = true;
    await tester.pumpWidget(app(repo, lang: 'en'));
    await tester.pumpAndSettle();
    await selectAccountant(tester);
    await tester.tap(assignButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.assignments, 0);
    await tester.tap(assignButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm assignment'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not assign.'), findsOneWidget);
    expect(find.textContaining('EMP-006'), findsOneWidget);
    repo.fail = false;
    await tester.ensureVisible(assignButton);
    await tester.tap(assignButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm assignment'));
    await tester.pumpAndSettle();
    expect(repo.assignments, 2);
    expect(find.textContaining('Disbursement assigned to'), findsOneWidget);
  });
  for (final scenario in [
    'unapproved',
    'missing',
    'assigned',
    'paid',
    'empty',
  ]) {
    testWidgets('$scenario payroll cannot assign', (tester) async {
      final repo = FakeDisbursement();
      if (scenario == 'unapproved') repo.status = 'pending_admin_approval';
      if (scenario == 'missing') repo.missingTask = true;
      if (scenario == 'assigned') repo.payment = 'assigned_to_accountant';
      if (scenario == 'paid') repo.payment = 'paid';
      if (scenario == 'empty') repo.empty = true;
      await tester.pumpWidget(app(repo, lang: 'en'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('disbursement-accountant')),
        findsNothing,
      );
      expect(tester.widget<FilledButton>(assignButton).onPressed, isNull);
      expect(repo.assignments, 0);
    });
  }
  if (const bool.fromEnvironment('EXPORT_FINANCE_PAYROLL')) {
    testWidgets('Export assignment preview', (tester) async {
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
      await tester.binding.setSurfaceSize(const Size(1350, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: app(FakeDisbursement())),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/finance_disbursement_preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
