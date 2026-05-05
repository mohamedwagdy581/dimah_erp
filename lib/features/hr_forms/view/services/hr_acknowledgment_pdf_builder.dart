import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'hr_acknowledgment_pdf/hr_acknowledgment_pdf_page.dart';
import 'hr_form_pdf_support.dart';

Future<Uint8List> buildAcknowledgmentFormPdf({
  required bool isArabic,
  required String employeeName,
  required String employeeId,
  required String department,
  required String jobTitle,
  required String subject,
  required String body,
  required String employeeSignature,
  required String date,
  required String hrSignature,
}) async {
  final pdf = pw.Document(theme: await loadHrFormPdfTheme());
  final logo = await loadHrFormLogo();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => buildHrAcknowledgmentPdfPage(
        HrAcknowledgmentPdfPayload(
          isArabic: isArabic,
          logo: logo,
          employeeName: employeeName,
          employeeId: employeeId,
          mobile: subject,
          signature: employeeSignature,
        ),
      ),
    ),
  );

  return pdf.save();
}
