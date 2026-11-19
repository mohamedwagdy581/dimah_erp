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
import 'package:erp_sys/features/employees/data/repos/hr_employees_repo.dart';
import 'package:erp_sys/features/employees/domain/models/employee.dart';
import 'package:erp_sys/features/hr_forms/view/pages/hr_forms_workspace.dart';
import 'package:erp_sys/features/hr_forms/view/pages/hr_prototype_editor.dart';
import 'package:erp_sys/features/hr_forms/data/hr_form_drafts_repo.dart';
import 'package:erp_sys/features/hr_forms/view/services/hr_portal_form_pdf.dart';

final employee = Employee(
  id: 'e',
  tenantId: 't',
  fullName: 'أحمد محمد السالم',
  employeeNumber: 'EMP-001',
  email: '',
  phone: '',
  status: 'active',
  hireDate: DateTime(2025),
  createdAt: DateTime(2025),
  departmentName: 'الموارد البشرية',
  jobTitleName: 'مدير موارد بشرية',
);
Widget app({
  String lang = 'ar',
  Future<Uint8List> Function(HrPortalFormDraft)? build,
  Future<void> Function(Uint8List, String)? export,
  Widget Function(Uint8List)? preview,
  HrFormDraftsRepo? draftsRepo,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(lang),
  theme: EmployeeTheme.from(AppTheme.light()),
  localizationsDelegates: appLocalizationDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: HrFormsWorkspace(
      today: DateTime(2026, 10, 12),
      draftsRepo: draftsRepo,
      loadEmployees: () async => HrEmployeesData(employees: [employee]),
      buildPdf: build ?? (_) async => Uint8List.fromList([1, 2, 3]),
      exportPdf: export,
      previewBuilder:
          preview ?? (_) => const Center(child: Text('Rendered PDF')),
    ),
  ),
);
Future<void> selectEmployee(WidgetTester tester) async {
  final field = find.byKey(const ValueKey('hr-form-employee'));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text('أحمد محمد السالم (EMP-001)').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Additional templates open inline and can switch back to leave', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(lang: 'en'));
    await tester.pumpAndSettle();
    final hiring = find.byKey(const ValueKey('template-hiring-request'));
    await tester.ensureVisible(hiring);
    await tester.tap(hiring);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('prototype-field-headcount')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hr-template-list-scroll')),
      findsOneWidget,
    );
    expect(find.text('PDF preview'), findsOneWidget);
    final prototypeEditor = tester.widget<HrPrototypeEditor>(
      find.byType(HrPrototypeEditor),
    );
    prototypeEditor.onPreview!(Future.value(Uint8List.fromList([1, 2, 3])));
    await tester.pumpAndSettle();
    expect(find.text('Rendered PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final leave = find.byKey(const ValueKey('template-leave'));
    await tester.ensureVisible(leave);
    await tester.tap(leave);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hr-form-employee')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('prototype-field-headcount')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1350.0]) {
      testWidgets('HR forms $lang $width fill employee and switch templates', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(app(lang: lang));
        await tester.pumpAndSettle();
        await selectEmployee(tester);
        expect(find.text('EMP-001'), findsOneWidget);
        expect(find.text('Rendered PDF'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final leave = find.byKey(const ValueKey('template-leave'));
        await tester.ensureVisible(leave);
        await tester.tap(leave);
        await tester.pumpAndSettle();
        final discard = find.text(
          lang == 'ar' ? 'تجاهل التعديلات' : 'Discard changes',
        );
        if (discard.evaluate().isNotEmpty) {
          await tester.tap(discard);
          await tester.pumpAndSettle();
        }
        expect(
          find.text(lang == 'ar' ? 'نوع الإجازة' : 'Leave type'),
          findsOneWidget,
        );
        expect(find.text('EMP-001'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Export validates employee and captures current edits', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    HrPortalFormDraft? captured;
    int exports = 0;
    await tester.pumpWidget(
      app(
        build: (draft) async {
          captured = draft;
          return Uint8List.fromList([1, 2, 3]);
        },
        export: (bytes, name) async {
          exports++;
          expect(bytes, [1, 2, 3]);
          expect(name, contains('EMP-001'));
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hr-form-export')));
    await tester.pumpAndSettle();
    expect(exports, 0);
    await selectEmployee(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'Updated acknowledgment text',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hr-form-export')));
    await tester.pumpAndSettle();
    expect(exports, 1);
    expect(captured!.employeeNumber, 'EMP-001');
    expect(captured!.fields.values, contains('Updated acknowledgment text'));
    expect(captured!.agreed, isFalse);
    await tester.tap(find.byKey(const ValueKey('template-leave')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تجاهل التعديلات'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('hr-form-export')));
    await tester.tap(find.byKey(const ValueKey('hr-form-export')));
    await tester.pumpAndSettle();
    expect(exports, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Actual Arabic and English PDF bytes are generated', (
    tester,
  ) async {
    for (final ar in [true, false]) {
      final draft = HrPortalFormDraft(
        isArabic: ar,
        isLeave: false,
        employeeName: ar ? employee.fullName : 'Ahmed Salem',
        employeeNumber: 'EMP-001',
        department: ar ? 'الموارد البشرية' : 'Human resources',
        jobTitle: ar ? 'مدير موارد بشرية' : 'HR manager',
        date: '2026/10/12',
        agreed: false,
        fields: {
          ar ? 'نص الإقرار' : 'Acknowledgment': ar
              ? 'أقر بأنني اطلعت على سياسات الشركة وأتعهد بالالتزام بها.'
              : 'I agree to comply with company policies.',
        },
      );
      final bytes = await tester.runAsync(() => buildHrPortalFormPdf(draft));
      expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
      expect(bytes.length, greaterThan(1000));
      File('build/hr_form_${ar ? 'ar' : 'en'}.pdf').writeAsBytesSync(bytes);
    }
  });
  testWidgets('HR forms visual preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_HR_FORMS')) return;
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
    await tester.binding.setSurfaceSize(const Size(1350, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    final png = File('build/hr_form_pdf_preview.png');
    final image = png.existsSync() ? MemoryImage(png.readAsBytesSync()) : null;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: app(
          preview: image == null
              ? null
              : (_) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image(image: image, fit: BoxFit.contain),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await selectEmployee(tester);
    if (image != null) {
      await tester.runAsync(() => precacheImage(image, key.currentContext!));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final rendered =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/hr_forms_workspace_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      rendered.dispose();
    });
  });
}
