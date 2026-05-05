import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../hr_acknowledgment_pdf_theme.dart';

class HrAcknowledgmentPdfSignature extends pw.StatelessWidget {
  HrAcknowledgmentPdfSignature({
    required this.theme,
    required this.signature,
  });

  final HrAcknowledgmentPdfTheme theme;
  final String signature;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        theme.text('التوقيع', size: 16, bold: true, align: pw.TextAlign.right),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 28,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1.2)),
          ),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: theme.text(signature, align: pw.TextAlign.right),
          ),
        ),
      ],
    );
  }
}
