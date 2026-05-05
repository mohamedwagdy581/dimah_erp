import 'package:pdf/widgets.dart' as pw;

import '../electronic_acknowledgment_pdf_page.dart';
import '../electronic_acknowledgment_pdf_theme.dart';
import 'electronic_acknowledgment_pdf_shared.dart';

class ElectronicAcknowledgmentPdfEmployeeSection extends pw.StatelessWidget {
  ElectronicAcknowledgmentPdfEmployeeSection({
    required this.payload,
    required this.theme,
  });

  final ElectronicAcknowledgmentPdfPayload payload;
  final ElectronicAcknowledgmentPdfTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    return electronicAcknowledgmentSection(
      theme,
      title: theme.isArabic ? 'بيانات الموظف' : 'Employee Information',
      hint: theme.isArabic ? 'تجريبي' : 'Prototype',
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: electronicAcknowledgmentField(
                theme,
                theme.isArabic ? 'اسم الموظف' : 'Employee Name',
                payload.employeeName,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: electronicAcknowledgmentField(
                theme,
                theme.isArabic
                    ? 'رقم الهوية / الإقامة'
                    : 'ID / Iqama Number',
                payload.employeeId,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: electronicAcknowledgmentField(
                theme,
                theme.isArabic ? 'القسم' : 'Department',
                payload.department,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: electronicAcknowledgmentField(
                theme,
                theme.isArabic ? 'المسمى الوظيفي' : 'Job Title',
                payload.role,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        electronicAcknowledgmentField(
          theme,
          theme.isArabic ? 'رقم الجوال' : 'Mobile Number',
          payload.mobile,
        ),
      ],
    );
  }
}
