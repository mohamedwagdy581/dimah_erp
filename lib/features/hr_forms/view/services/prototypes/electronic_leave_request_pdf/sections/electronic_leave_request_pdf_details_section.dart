import 'package:pdf/widgets.dart' as pw;

import '../electronic_leave_request_pdf_page.dart';
import '../electronic_leave_request_pdf_theme.dart';
import 'electronic_leave_request_pdf_shared.dart';

class ElectronicLeaveRequestPdfDetailsSection extends pw.StatelessWidget {
  ElectronicLeaveRequestPdfDetailsSection({
    required this.payload,
    required this.theme,
  });

  final ElectronicLeaveRequestPdfPayload payload;
  final ElectronicLeaveRequestPdfTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    return electronicLeaveSection(
      theme,
      title: theme.isArabic ? 'تفاصيل الإجازة' : 'Leave Details',
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: electronicLeaveField(
                theme,
                theme.isArabic ? 'نوع الإجازة' : 'Leave Type',
                payload.leaveType,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: electronicLeaveField(
                theme,
                theme.isArabic ? 'عدد الأيام' : 'No. of Days',
                payload.days,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: electronicLeaveField(
                theme,
                theme.isArabic ? 'من تاريخ' : 'From Date',
                payload.fromDate,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: electronicLeaveField(
                theme,
                theme.isArabic ? 'إلى تاريخ' : 'To Date',
                payload.toDate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
