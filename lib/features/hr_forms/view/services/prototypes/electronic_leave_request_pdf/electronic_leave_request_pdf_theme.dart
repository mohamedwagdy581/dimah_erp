import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ElectronicLeaveRequestPdfTheme {
  ElectronicLeaveRequestPdfTheme(this.isArabic);

  final bool isArabic;

  static const blue = PdfColor.fromInt(0xFF2D7E9D);
  static const darkBlue = PdfColor.fromInt(0xFF1B4F60);
  static const blueSoft = PdfColor.fromInt(0xFFF7FBFD);
  static const blueBorder = PdfColor.fromInt(0xFFCDE0E8);

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
