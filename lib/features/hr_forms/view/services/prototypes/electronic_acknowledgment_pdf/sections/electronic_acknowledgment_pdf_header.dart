import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../electronic_acknowledgment_pdf_theme.dart';

class ElectronicAcknowledgmentPdfHeader extends pw.StatelessWidget {
  ElectronicAcknowledgmentPdfHeader({
    required this.theme,
    required this.logo,
  });

  final ElectronicAcknowledgmentPdfTheme theme;
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
                theme.isArabic
                    ? 'إقرار وتعهد الموظف'
                    : 'Employee Acknowledgment',
                size: 20,
                bold: true,
                align: pw.TextAlign.left,
                color: ElectronicAcknowledgmentPdfTheme.green,
              ),
              pw.SizedBox(height: 4),
              theme.text(
                theme.isArabic
                    ? 'تصميم إلكتروني مرن لمراجعة العميل واعتماد الاتجاه البصري'
                    : 'A flexible electronic layout for client review and visual direction approval',
                size: 9,
                align: pw.TextAlign.left,
                color: const PdfColor.fromInt(0xFF58766F),
              ),
            ],
          ),
        ),
        pw.Image(logo, width: 98),
      ],
    );
  }
}
