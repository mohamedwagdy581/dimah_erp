import 'package:pdf/widgets.dart' as pw;

import '../electronic_leave_request_pdf_page.dart';
import '../electronic_leave_request_pdf_theme.dart';
import 'electronic_leave_request_pdf_shared.dart';

class ElectronicLeaveRequestPdfCoverageSection extends pw.StatelessWidget {
  ElectronicLeaveRequestPdfCoverageSection({
    required this.payload,
    required this.theme,
  });

  final ElectronicLeaveRequestPdfPayload payload;
  final ElectronicLeaveRequestPdfTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    return electronicLeaveSection(
      theme,
      title: theme.isArabic
          ? 'التغطية أثناء الإجازة'
          : 'Coverage During Leave',
      children: [
        electronicLeaveField(
          theme,
          theme.isArabic ? 'الموظف البديل' : 'Replacement Employee',
          payload.replacement,
        ),
        pw.SizedBox(height: 10),
        electronicLeaveField(
          theme,
          theme.isArabic ? 'ملاحظات إضافية' : 'Additional Notes',
          payload.notes,
          minHeight: 78,
        ),
      ],
    );
  }
}
