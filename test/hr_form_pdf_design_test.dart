import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/hr_forms/view/services/hr_portal_form_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final ar in [true, false]) {
    for (final leave in [true, false]) {
      test(
        'HR printable form Arabic=$ar leave=$leave generates PDF with current fields',
        () async {
          final draft = HrPortalFormDraft(
            isArabic: ar,
            isLeave: leave,
            employeeName: ar ? 'أحمد محمد علي' : 'Ahmed Mohamed Ali',
            employeeNumber: 'EMP-DEMO-001',
            department: ar ? 'المالية والمحاسبة' : 'Finance and accounting',
            jobTitle: ar ? 'محاسب أول' : 'Senior accountant',
            date: '2026/10/12',
            agreed: false,
            fields: leave
                ? {
                    ar ? 'نوع الإجازة' : 'Leave type': ar ? 'سنوية' : 'Annual',
                    ar ? 'من تاريخ' : 'From': '2026/10/20',
                    ar ? 'إلى تاريخ' : 'To': '2026/10/24',
                    ar ? 'المدة' : 'Duration': ar ? '5 أيام' : '5 days',
                    ar ? 'الموظف البديل' : 'Replacement': ar
                        ? 'سارة أحمد'
                        : 'Sara Ahmed',
                    ar ? 'التواصل أثناء الإجازة' : 'Contact during leave':
                        '050 000 0000',
                    ar ? 'سبب الإجازة / الملاحظات' : 'Reason / notes': ar
                        ? 'طلب إجازة سنوية لأسباب شخصية. تم التنسيق لتسليم الأعمال للموظف البديل. هذه نسخة عرض ببيانات تجريبية.'
                        : 'Annual leave for personal reasons. Work handover has been arranged. Design sample with fictional data.',
                  }
                : {
                    ar ? 'نص الإقرار' : 'Acknowledgment': ar
                        ? 'أقر بأنني اطلعت على سياسات وإجراءات العمل المبلغة لي، وأتعهد بالمحافظة على سرية بيانات الشركة واستخدامها في حدود مهامي الوظيفية. هذه نسخة عرض تصميمية ببيانات تجريبية.'
                        : 'I acknowledge the workplace policies communicated to me and undertake to protect company information within my responsibilities. This is a design sample with fictional data.',
                    ar ? 'اسم الموقّع' : 'Signatory': ar
                        ? 'أحمد محمد علي'
                        : 'Ahmed Mohamed Ali',
                  },
          );
          final bytes = await buildHrPortalFormPdf(draft);
          expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
          expect(bytes.length, greaterThan(5000));
          if (const bool.fromEnvironment('EXPORT_HR_FORM_PDF_PREVIEW')) {
            final directory = ar ? 'output/pdf' : 'tmp/pdfs';
            Directory(directory).createSync(recursive: true);
          const suffix = String.fromEnvironment('HR_FORM_PREVIEW_SUFFIX');
          File(
            '$directory/hr_${leave ? 'leave_request' : 'acknowledgment'}_design$suffix.pdf',
            ).writeAsBytesSync(bytes);
          }
        },
      );
    }
  }
  test(
    'Long Arabic acknowledgment exports without dropping the document',
    () async {
      final bytes = await buildHrPortalFormPdf(
        HrPortalFormDraft(
          isArabic: true,
          isLeave: false,
          employeeName: 'موظف تجريبي',
          employeeNumber: 'EMP-DEMO-LONG',
          department: 'المالية',
          jobTitle: 'محاسب',
          date: '2026/10/12',
          agreed: false,
          fields: {
            'نص الإقرار': List.filled(
              35,
              'هذا نص تجريبي طويل لمراجعة التفاف الأسطر وانتقال النص بين صفحات المستند دون قطع البيانات.',
            ).join('\n'),
          },
        ),
      );
      expect(bytes.length, greaterThan(5000));
      if (const bool.fromEnvironment('EXPORT_HR_FORM_PDF_PREVIEW')) {
        Directory('tmp/pdfs').createSync(recursive: true);
        File('tmp/pdfs/hr_long_acknowledgment.pdf').writeAsBytesSync(bytes);
      }
    },
  );
}
