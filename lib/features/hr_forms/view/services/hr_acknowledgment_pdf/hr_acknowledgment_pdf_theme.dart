import 'package:pdf/widgets.dart' as pw;

class HrAcknowledgmentPdfTheme {
  HrAcknowledgmentPdfTheme(this.isArabic);

  final bool isArabic;

  pw.Widget text(
    String value, {
    double size = 11,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Text(
      value,
      textAlign: align,
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }
}
