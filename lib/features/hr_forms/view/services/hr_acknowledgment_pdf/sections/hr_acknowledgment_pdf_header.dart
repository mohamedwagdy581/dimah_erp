import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../hr_acknowledgment_pdf_theme.dart';

class HrAcknowledgmentPdfHeader extends pw.StatelessWidget {
  HrAcknowledgmentPdfHeader({
    required this.theme,
    required this.logo,
  });

  final HrAcknowledgmentPdfTheme theme;
  final pw.MemoryImage logo;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 72,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFD9EFEA),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: theme.text('إقرار وتعهد', size: 12, bold: true),
        ),
        pw.Spacer(),
        pw.Image(logo, width: 120),
        pw.Spacer(),
        pw.SizedBox(width: 72),
      ],
    );
  }
}
