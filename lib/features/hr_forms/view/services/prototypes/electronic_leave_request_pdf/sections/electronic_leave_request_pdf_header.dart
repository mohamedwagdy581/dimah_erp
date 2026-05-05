import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../electronic_leave_request_pdf_theme.dart';

class ElectronicLeaveRequestPdfHeader extends pw.StatelessWidget {
  ElectronicLeaveRequestPdfHeader({
    required this.theme,
    required this.logo,
  });

  final ElectronicLeaveRequestPdfTheme theme;
  final pw.MemoryImage logo;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              theme.text(
                theme.isArabic ? 'طلب إجازة' : 'Leave Request',
                size: 20,
                bold: true,
                align: pw.TextAlign.left,
                color: ElectronicLeaveRequestPdfTheme.blue,
              ),
              pw.SizedBox(height: 4),
              theme.text(
                theme.isArabic
                    ? 'نسخة تصميمية للتجربة قبل اعتماد الشكل النهائي'
                    : 'Design prototype before final approval',
                size: 9,
                align: pw.TextAlign.left,
                color: const PdfColor.fromInt(0xFF58727B),
              ),
            ],
          ),
        ),
        pw.Image(logo, width: 98),
      ],
    );
  }
}
