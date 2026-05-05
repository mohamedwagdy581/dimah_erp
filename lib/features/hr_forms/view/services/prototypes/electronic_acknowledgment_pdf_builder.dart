import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../hr_form_pdf_support.dart';
import 'electronic_acknowledgment_pdf/electronic_acknowledgment_pdf_page.dart';

Future<Uint8List> buildElectronicAcknowledgmentPrototypePdf({
  required bool isArabic,
  required String employeeName,
  required String employeeId,
  required String mobile,
  required String role,
  required String department,
  required String signature,
}) async {
  final pdf = pw.Document(theme: await loadHrFormPdfTheme());
  final logo = await loadHrFormLogo();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => buildElectronicAcknowledgmentPdfPage(
        ElectronicAcknowledgmentPdfPayload(
          isArabic: isArabic,
          logo: logo,
          employeeName: employeeName,
          employeeId: employeeId,
          mobile: mobile,
          role: role,
          department: department,
          signature: signature,
        ),
      ),
    ),
  );

  return pdf.save();
}
