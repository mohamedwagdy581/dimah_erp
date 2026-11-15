import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/hr_forms/domain/models/hr_prototype_def.dart';
import 'package:erp_sys/features/hr_forms/domain/models/hr_form_template_def.dart';
import 'package:erp_sys/features/hr_forms/view/pages/hr_forms_library_page.dart';
import 'package:erp_sys/features/hr_forms/view/pages/hr_prototype_editor.dart';
import 'package:erp_sys/features/hr_forms/view/services/hr_form_print_layout.dart';
import 'package:erp_sys/features/employees/data/repos/hr_employees_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Library searches all forms and opens the selected prototype', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HrFormsLibraryPage(onOpen: (id) => opened = id)),
      ),
    );
    expect(hrFormTemplates.length, 15);
    await tester.enterText(
      find.byKey(const ValueKey('hr-library-search')),
      'salary',
    );
    await tester.pump();
    expect(find.text('1 forms'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-salary-adjustment')));
    expect(opened, 'salary-adjustment');
    await tester.enterText(
      find.byKey(const ValueKey('hr-library-search')),
      'unknown form',
    );
    await tester.pump();
    expect(find.text('No matching forms'), findsOneWidget);
  });
  testWidgets(
    'Required fields block export; successful export contains entered values',
    (tester) async {
      var exports = 0;
      Map<String, String>? captured;
      final template = HrPrototypeDef('test', 'HR-TEST', 'اختبار', 'Test', [
        HrPrototypeField(
          'amount',
          'المبلغ',
          'Amount',
          type: HrPrototypeFieldType.number,
        ),
      ], employeeRequired: false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HrPrototypeEditor(
              template: template,
              loadEmployees: () async => const HrEmployeesData(),
              buildPdf: (data, employee) async {
                captured = data;
                return Uint8List.fromList([1]);
              },
              exportPdf: (bytes, name) async {
                exports++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('prototype-export')));
      await tester.pumpAndSettle();
      expect(exports, 0);
      await tester.enterText(
        find.byKey(const ValueKey('prototype-field-amount')),
        '-1',
      );
      await tester.tap(find.byKey(const ValueKey('prototype-export')));
      await tester.pumpAndSettle();
      expect(exports, 0);
      await tester.enterText(
        find.byKey(const ValueKey('prototype-field-amount')),
        '1250.50',
      );
      await tester.tap(find.byKey(const ValueKey('prototype-export')));
      await tester.pumpAndSettle();
      expect(exports, 1);
      expect(captured!['Amount'], '1250.50');
    },
  );
  for (final template in hrPrototypes) {
    testWidgets(
      '${template.id} fits narrow Arabic screen and requires employee',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var exports = 0;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: HrPrototypeEditor(
                template: template,
                loadEmployees: () async => const HrEmployeesData(),
                buildPdf: (data, employee) async => Uint8List(1),
                exportPdf: (bytes, name) async {
                  exports++;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey('prototype-export')),
        );
        await tester.tap(find.byKey(const ValueKey('prototype-export')));
        await tester.pumpAndSettle();
        expect(exports, 0);
        expect(tester.takeException(), isNull);
      },
    );
    for (final ar in [true, false]) {
      test('${template.id} renders printable PDF Arabic=$ar', () async {
        final bytes = await buildHrPrintDocument(
          isArabic: ar,
          isLeave: false,
          agreed: false,
          employeeName: ar ? 'موظف تجريبي' : 'Sample employee',
          employeeNumber: 'EMP-DEMO',
          department: ar ? 'الموارد البشرية' : 'Human Resources',
          jobTitle: ar ? 'موظف' : 'Employee',
          date: '2026/10/12',
          documentTitle: template.title(ar),
          templateCode: template.code,
          signatureLabels: [
            ar ? 'الموظف' : 'Employee',
            ar ? 'المدير المباشر' : 'Direct manager',
            ar ? 'الموارد البشرية' : 'Human Resources',
          ],
          fields: {
            for (final f in template.fields)
              f.label(ar): switch (f.type) {
                HrPrototypeFieldType.date => '2026/10/20',
                HrPrototypeFieldType.time => '09:00',
                HrPrototypeFieldType.number => '1000',
                HrPrototypeFieldType.check => ar ? 'تم' : 'Completed',
                _ =>
                  ar
                      ? 'بيانات تجريبية لمراجعة النموذج قبل الاستخدام.'
                      : 'Sample information for reviewing the form before use.',
              },
          },
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        if (const bool.fromEnvironment('EXPORT_HR_PROTOTYPES')) {
          Directory('tmp/pdfs/prototypes').createSync(recursive: true);
          File(
            'tmp/pdfs/prototypes/${template.id}_${ar ? 'ar' : 'en'}.pdf',
          ).writeAsBytesSync(bytes);
        }
      });
    }
  }
}
