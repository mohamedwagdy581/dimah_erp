import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../electronic_acknowledgment_pdf_theme.dart';

pw.Widget electronicAcknowledgmentSection(
  ElectronicAcknowledgmentPdfTheme theme, {
  required String title,
  required List<pw.Widget> children,
  String? hint,
}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(14),
      border: pw.Border.all(
        color: ElectronicAcknowledgmentPdfTheme.greenBorder,
        width: .8,
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const pw.BoxDecoration(
            color: ElectronicAcknowledgmentPdfTheme.green,
            borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(13)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: theme.text(
                  title,
                  size: 11,
                  bold: true,
                  align: pw.TextAlign.left,
                  color: PdfColors.white,
                ),
              ),
              if (hint != null)
                theme.text(
                  hint,
                  size: 8,
                  color: const PdfColor.fromInt(0xFFE4F2EE),
                ),
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(14),
          child: pw.Column(children: children),
        ),
      ],
    ),
  );
}

pw.Widget electronicAcknowledgmentField(
  ElectronicAcknowledgmentPdfTheme theme,
  String label,
  String value,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: pw.BoxDecoration(
      color: ElectronicAcknowledgmentPdfTheme.greenSoft,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(
        color: ElectronicAcknowledgmentPdfTheme.greenBorder,
        width: .8,
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        theme.text(
          label,
          size: 8.5,
          bold: true,
          align: pw.TextAlign.left,
          color: const PdfColor.fromInt(0xFF45655D),
        ),
        pw.SizedBox(height: 6),
        theme.text(value, align: pw.TextAlign.right),
      ],
    ),
  );
}
