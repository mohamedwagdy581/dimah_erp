import 'package:pdf/widgets.dart' as pw;

import 'hr_acknowledgment_pdf_sections.dart';
import 'hr_acknowledgment_pdf_theme.dart';

class HrAcknowledgmentPdfPayload {
  const HrAcknowledgmentPdfPayload({
    required this.isArabic,
    required this.logo,
    required this.employeeName,
    required this.employeeId,
    required this.mobile,
    required this.signature,
  });

  final bool isArabic;
  final pw.MemoryImage logo;
  final String employeeName;
  final String employeeId;
  final String mobile;
  final String signature;
}

pw.Widget buildHrAcknowledgmentPdfPage(HrAcknowledgmentPdfPayload payload) {
  final theme = HrAcknowledgmentPdfTheme(payload.isArabic);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      HrAcknowledgmentPdfHeader(theme: theme, logo: payload.logo),
      pw.SizedBox(height: 24),
      HrAcknowledgmentPdfLineField(
        theme: theme,
        label: 'أقر وأنا الموقع /',
        value: payload.employeeName,
      ),
      pw.SizedBox(height: 10),
      HrAcknowledgmentPdfDualLineField(
        theme: theme,
        rightLabel: 'هويتي رقم /',
        rightValue: payload.employeeId,
        leftLabel: 'جوال /',
        leftValue: payload.mobile,
      ),
      pw.SizedBox(height: 18),
      HrAcknowledgmentPdfParagraphs(theme: theme),
      pw.SizedBox(height: 24),
      HrAcknowledgmentPdfSignature(theme: theme, signature: payload.signature),
      pw.Spacer(),
      HrAcknowledgmentPdfFooter(theme: theme),
    ],
  );
}
