import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../hr_acknowledgment_pdf_theme.dart';

class HrAcknowledgmentPdfLineField extends pw.StatelessWidget {
  HrAcknowledgmentPdfLineField({
    required this.theme,
    required this.label,
    required this.value,
  });

  final HrAcknowledgmentPdfTheme theme;
  final String label;
  final String value;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
            ),
            child: theme.text(value, align: pw.TextAlign.right),
          ),
        ),
        pw.SizedBox(width: 8),
        theme.text(label, size: 12, bold: true, align: pw.TextAlign.right),
      ],
    );
  }
}

class HrAcknowledgmentPdfDualLineField extends pw.StatelessWidget {
  HrAcknowledgmentPdfDualLineField({
    required this.theme,
    required this.rightLabel,
    required this.rightValue,
    required this.leftLabel,
    required this.leftValue,
  });

  final HrAcknowledgmentPdfTheme theme;
  final String rightLabel;
  final String rightValue;
  final String leftLabel;
  final String leftValue;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      children: [
        _field(leftValue),
        pw.SizedBox(width: 8),
        theme.text(leftLabel, size: 12, bold: true, align: pw.TextAlign.right),
        pw.SizedBox(width: 24),
        _field(rightValue),
        pw.SizedBox(width: 8),
        theme.text(rightLabel, size: 12, bold: true, align: pw.TextAlign.right),
      ],
    );
  }

  pw.Widget _field(String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
        ),
        child: theme.text(value, align: pw.TextAlign.right),
      ),
    );
  }
}
