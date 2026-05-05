import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../hr_acknowledgment_pdf_theme.dart';

class HrAcknowledgmentPdfFooter extends pw.StatelessWidget {
  HrAcknowledgmentPdfFooter({required this.theme});

  final HrAcknowledgmentPdfTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFF2D8C82), width: 1),
        ),
      ),
      child: theme.text(
        'CR 4030171445 Chamber of Commerce membership 122057',
        size: 7.5,
      ),
    );
  }
}
