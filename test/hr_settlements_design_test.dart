import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/employees/data/repos/hr_settlements_repo.dart';
import 'package:erp_sys/features/employees/domain/models/employee.dart';
import 'package:erp_sys/features/employees/domain/models/hr_settlement.dart';
import 'package:erp_sys/features/employees/view/pages/hr_settlements_page.dart';

final _employee = Employee(
  id: 'employee',
  tenantId: 'tenant',
  fullName: 'أحمد محمد السالم',
  employeeNumber: 'EMP-001',
  email: '',
  phone: '',
  status: 'active',
  hireDate: DateTime(2025),
  createdAt: DateTime(2025),
);
HrSettlement _row(String id) => HrSettlement(
  id: id,
  employeeId: 'employee',
  name: _employee.fullName,
  employeeNumber: 'EMP-001',
  type: 'partial',
  date: DateTime(2026, 10, 20),
  finalWorkingDate: DateTime(2026, 10, 20),
  gross: 2000,
  deductions: 100,
  notes: 'دفعة إضافية حسب الاتفاق مع الموظف',
  filePath: 'tenant/employee/file.pdf',
  fileName: 'settlement.pdf',
);

class _Repo implements HrSettlementsRepo {
  List<HrSettlement> rows = [_row('existing')];
  final drafts = <HrSettlementDraft>[];
  bool failSave = false, failLoad = false;
  Object? saveError;
  Completer<void>? gate;
  @override
  Future<HrSettlementsData> load() async {
    if (failLoad) throw StateError('Load unavailable');
    return HrSettlementsData(employees: [_employee], settlements: rows);
  }

  @override
  Future<void> save(HrSettlementDraft draft) async {
    drafts.add(draft);
    if (saveError != null) throw saveError!;
    if (gate != null) await gate!.future;
    if (failSave) throw StateError('Save unavailable');
    rows = [
      HrSettlement(
        id: draft.id,
        employeeId: draft.employeeId,
        name: _employee.fullName,
        type: draft.type,
        date: draft.date,
        finalWorkingDate: draft.finalWorkingDate,
        gross: draft.gross,
        deductions: draft.deductions,
        notes: draft.notes,
        filePath: draft.attachment == null ? null : 'tenant/employee/file.pdf',
        fileName: draft.attachment?.name,
      ),
      ...rows,
    ];
  }

  @override
  Future<String> attachmentUrl(String path) async =>
      'https://example.test/signed.pdf';
}

Widget _app(
  _Repo repo, {
  String lang = 'ar',
  Future<SettlementAttachment?> Function()? pick,
  Future<void> Function(HrSettlement)? open,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(lang),
  theme: EmployeeTheme.from(AppTheme.light()),
  localizationsDelegates: appLocalizationDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: HrSettlementsPage(
    repo: repo,
    today: DateTime(2026, 10, 26),
    pickAttachment: pick,
    openAttachment: open,
  ),
);
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, {String lang = 'ar'}) async {
  await _tap(tester, find.byType(DropdownButtonFormField<String>).first);
  await _tap(tester, find.text('أحمد محمد السالم (EMP-001)').last);
  await _tap(tester, find.byType(DropdownButtonFormField<String>).at(1));
  await _tap(
    tester,
    find.text(lang == 'ar' ? 'مخالصة جزئية' : 'Partial settlement').last,
  );
  await tester.enterText(
    find.byKey(const ValueKey('settlement-gross')),
    '1000',
  );
}

void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1350.0]) {
      testWidgets('Settlement layout $lang at $width exposes all actions', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_app(_Repo(), lang: lang));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scroll = tester.widget<SingleChildScrollView>(
          find.byKey(const ValueKey('settlements-horizontal-scroll')),
        );
        if (scroll.controller!.position.maxScrollExtent > 0) {
          scroll.controller!.jumpTo(
            scroll.controller!.position.maxScrollExtent,
          );
        }
        await _tap(
          tester,
          find.byKey(const ValueKey('settlement-actions-existing')),
        );
        await _tap(
          tester,
          find.text(lang == 'ar' ? 'عرض المخالصة' : 'View settlement'),
        );
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('دفعة إضافية حسب الاتفاق مع الموظف'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'Save validates then captures deductions notes attachment and resets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1350, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = _Repo();
      final attachment = SettlementAttachment(
        name: 'clearance.pdf',
        bytes: Uint8List.fromList([37, 80, 68, 70]),
      );
      await tester.pumpWidget(_app(repo, pick: () async => attachment));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('settlement-save')));
      expect(repo.drafts, isEmpty);
      await _fill(tester);
      await _tap(tester, find.text('الخصومات وصافي المخالصة'));
      await tester.enterText(
        find.byKey(const ValueKey('settlement-deductions')),
        '100',
      );
      await tester.enterText(
        find.byKey(const ValueKey('settlement-notes')),
        'New settlement note',
      );
      await _tap(tester, find.byKey(const ValueKey('settlement-attachment')));
      await _tap(tester, find.byKey(const ValueKey('settlement-save')));
      final saved = repo.drafts.single;
      expect(saved.type, 'partial');
      expect(saved.employeeId, 'employee');
      expect(saved.net, 900);
      expect(saved.notes, 'New settlement note');
      expect(saved.attachment, same(attachment));
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('settlement-gross')),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(repo.rows.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Save failure retains draft and retry uses same request ID', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _Repo()..failSave = true;
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    await _fill(tester);
    await _tap(tester, find.byKey(const ValueKey('settlement-save')));
    expect(repo.drafts.length, 1);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('settlement-gross')))
          .controller!
          .text,
      '1000',
    );
    repo.failSave = false;
    await _tap(tester, find.byKey(const ValueKey('settlement-save')));
    expect(repo.drafts.length, 2);
    expect(repo.drafts[0].id, repo.drafts[1].id);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Storage denial retains attachment and request for retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _Repo()
      ..saveError = const StorageException(
        'new row violates row-level security policy',
        statusCode: '403',
        error: 'Unauthorized',
      );
    final file = SettlementAttachment(
      name: 'settlement.png',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    await tester.pumpWidget(_app(repo, pick: () async => file));
    await tester.pumpAndSettle();
    await _fill(tester);
    await _tap(tester, find.byKey(const ValueKey('settlement-attachment')));
    await _tap(tester, find.byKey(const ValueKey('settlement-save')));
    expect(find.textContaining('صلاحية رفع المرفق مرفوضة'), findsOneWidget);
    expect(repo.rows.length, 1);
    expect(repo.drafts.single.attachment, same(file));
    repo.saveError = null;
    await _tap(tester, find.byKey(const ValueKey('settlement-save')));
    expect(repo.drafts.length, 2);
    expect(repo.drafts.first.id, repo.drafts.last.id);
    expect(repo.drafts.last.gross, 1000);
    expect(repo.drafts.last.attachment, same(file));
    expect(repo.rows.length, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Excess deductions and invalid attachment cannot be saved', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _Repo();
    await tester.pumpWidget(
      _app(
        repo,
        pick: () async => SettlementAttachment(
          name: 'file.exe',
          bytes: Uint8List.fromList([1]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _fill(tester);
    await _tap(tester, find.text('الخصومات وصافي المخالصة'));
    await tester.enterText(
      find.byKey(const ValueKey('settlement-deductions')),
      '2000',
    );
    await _tap(tester, find.byKey(const ValueKey('settlement-attachment')));
    expect(find.text('file.exe'), findsNothing);
    await _tap(tester, find.byKey(const ValueKey('settlement-save')));
    expect(repo.drafts, isEmpty);
    expect(find.text('الخصومات أكبر من المبلغ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Load failure shows retry and keeps form accessible', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(768, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _Repo()..failLoad = true;
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر تحميل البيانات'), findsOneWidget);
    repo.failLoad = false;
    await _tap(tester, find.byTooltip('تحديث'));
    expect(find.textContaining('تعذّر تحميل البيانات'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test('Legacy settlements keep amounts dates notes and default type', () {
    final row = HrSettlement.fromMap({
      'id': 'old',
      'employee_id': 'employee',
      'employee': {'full_name': 'Existing employee'},
      'gross_amount': '1500.50',
      'deductions_amount': 100,
      'settlement_date': '2026-10-01',
      'final_working_date': '2026-09-30',
      'notes': 'Original note',
    });
    expect(row.net, 1400.50);
    expect(row.type, 'final');
    expect(row.notes, 'Original note');
    expect(row.date, DateTime(2026, 10, 1));
    expect(row.filePath, isNull);
  });
  testWidgets('Settlement visual preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_SETTLEMENTS')) return;
    await tester.runAsync(() async {
      for (final entry in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
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
    await tester.binding.setSurfaceSize(const Size(1350, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: _app(_Repo()..rows = [_row('one'), _row('two')]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/hr_settlements_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
