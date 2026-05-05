import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ElectronicAcknowledgmentPdfTheme {
  ElectronicAcknowledgmentPdfTheme(this.isArabic);

  final bool isArabic;

  static const green = PdfColor.fromInt(0xFF3B8D72);
  static const greenSoft = PdfColor.fromInt(0xFFF8FCFB);
  static const greenBorder = PdfColor.fromInt(0xFFCCE3DC);

  pw.Widget text(
    String value, {
    double size = 10,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.center,
    PdfColor? color,
  }) {
    return pw.Text(
      value,
      textAlign: align,
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      style: pw.TextStyle(
        fontSize: size,
        color: color,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }
}
