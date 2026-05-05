import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../electronic_leave_request_pdf_theme.dart';

pw.Widget electronicLeaveSection(
  ElectronicLeaveRequestPdfTheme theme, {
  required String title,
  required List<pw.Widget> children,
}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(14),
      border: pw.Border.all(
        color: ElectronicLeaveRequestPdfTheme.blueBorder,
        width: .8,
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const pw.BoxDecoration(
            color: ElectronicLeaveRequestPdfTheme.blue,
            borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(13)),
          ),
          child: theme.text(
            title,
            size: 11,
            bold: true,
            align: pw.TextAlign.left,
            color: PdfColors.white,
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

pw.Widget electronicLeaveField(
  ElectronicLeaveRequestPdfTheme theme,
  String label,
  String value, {
  double minHeight = 42,
}) {
  return pw.Container(
    constraints: pw.BoxConstraints(minHeight: minHeight),
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: pw.BoxDecoration(
      color: ElectronicLeaveRequestPdfTheme.blueSoft,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(
        color: ElectronicLeaveRequestPdfTheme.blueBorder,
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
          color: const PdfColor.fromInt(0xFF486673),
        ),
        pw.SizedBox(height: 6),
        theme.text(value, align: pw.TextAlign.right),
      ],
    ),
  );
}
