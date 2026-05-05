import 'package:pdf/widgets.dart' as pw;

import '../electronic_leave_request_pdf_page.dart';
import '../electronic_leave_request_pdf_theme.dart';
import 'electronic_leave_request_pdf_shared.dart';

class ElectronicLeaveRequestPdfEmployeeSection extends pw.StatelessWidget {
  ElectronicLeaveRequestPdfEmployeeSection({
    required this.payload,
    required this.theme,
  });

  final ElectronicLeaveRequestPdfPayload payload;
  final ElectronicLeaveRequestPdfTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    return electronicLeaveSection(
      theme,
      title: theme.isArabic ? 'بيانات الموظف' : 'Employee Information',
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: electronicLeaveField(
                theme,
                theme.isArabic ? 'اسم الموظف' : 'Employee Name',
                payload.employeeName,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: electronicLeaveField(
                theme,
                theme.isArabic ? 'الرقم الوظيفي' : 'Employee ID',
                payload.employeeId,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        electronicLeaveField(
          theme,
          theme.isArabic ? 'المسمى الوظيفي' : 'Job Title',
          payload.position,
        ),
      ],
    );
  }
}
