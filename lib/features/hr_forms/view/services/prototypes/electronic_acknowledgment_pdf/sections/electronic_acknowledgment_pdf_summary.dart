import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../electronic_acknowledgment_pdf_theme.dart';

class ElectronicAcknowledgmentPdfSummary extends pw.StatelessWidget {
  ElectronicAcknowledgmentPdfSummary({required this.theme});

  final ElectronicAcknowledgmentPdfTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          theme.isArabic ? 'سري / داخلي' : 'Confidential / Internal',
          const PdfColor.fromInt(0xFFEBF7F2),
          const PdfColor.fromInt(0xFF2F7F66),
        ),
        _chip(
          theme.isArabic ? 'اعتماد موظف' : 'Employee Acknowledgment',
          const PdfColor.fromInt(0xFFF0F8FB),
          const PdfColor.fromInt(0xFF2E6E86),
        ),
        _chip(
          theme.isArabic ? 'نسخة للعميل' : 'Client Review Copy',
          const PdfColor.fromInt(0xFFF8F4EA),
          const PdfColor.fromInt(0xFF8B6A2D),
        ),
      ],
    );
  }

  pw.Widget _chip(String text, PdfColor bg, PdfColor fg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(999),
        border: pw.Border.all(color: fg, width: .5),
      ),
      child: theme.text(text, size: 8, bold: true, color: fg),
    );
  }
}
