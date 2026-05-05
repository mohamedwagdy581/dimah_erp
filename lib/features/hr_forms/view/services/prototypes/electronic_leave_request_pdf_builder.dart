import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../hr_form_pdf_support.dart';
import 'electronic_leave_request_pdf/electronic_leave_request_pdf_page.dart';

Future<Uint8List> buildElectronicLeaveRequestPrototypePdf({
  required bool isArabic,
  required String employeeName,
  required String employeeId,
  required String position,
  required String leaveType,
  required String fromDate,
  required String toDate,
  required String days,
  required String replacement,
  required String notes,
}) async {
  final pdf = pw.Document(theme: await loadHrFormPdfTheme());
  final logo = await loadHrFormLogo();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => buildElectronicLeaveRequestPdfPage(
        ElectronicLeaveRequestPdfPayload(
          isArabic: isArabic,
          logo: logo,
          employeeName: employeeName,
          employeeId: employeeId,
          position: position,
          leaveType: leaveType,
          fromDate: fromDate,
          toDate: toDate,
          days: days,
          replacement: replacement,
          notes: notes,
        ),
      ),
    ),
  );

  return pdf.save();
}
