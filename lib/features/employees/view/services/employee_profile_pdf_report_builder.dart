import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../../core/reporting/report_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_profile_details.dart';
import '../utils/employee_profile_utils.dart';

Future<Uint8List> buildEmployeeProfilePdfReport(
  EmployeeProfileDetails profile, {
  required AppLocalizations t,
  required bool isArabic,
}) async {
  final baseFont = Platform.isWindows
      ? await _loadFont([r'C:\Windows\Fonts\arial.ttf', r'C:\Windows\Fonts\segoeui.ttf'])
      : null;
  final boldFont = Platform.isWindows
      ? await _loadFont([r'C:\Windows\Fonts\arialbd.ttf', r'C:\Windows\Fonts\segoeuib.ttf'])
      : null;
  final pdf = pw.Document(
    theme: baseFont == null ? null : pw.ThemeData.withFont(base: baseFont, bold: boldFont ?? baseFont),
  );

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(20),
      build: (_) => _pdfContent(profile, t: t, isArabic: isArabic),
    ),
  );
  return pdf.save();
}

Future<pw.Font?> _loadFont(List<String> candidates) async {
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      return pw.Font.ttf(ByteData.view(bytes.buffer));
    }
  }
  return null;
}

List<pw.Widget> _pdfContent(
  EmployeeProfileDetails p, {
  required AppLocalizations t,
  required bool isArabic,
}) {
  pw.Widget text(String value, {bool bold = false, double size = 10}) => pw.Text(
        value,
        style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: size),
        textDirection: isMostlyArabicText(value) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
      );
  pw.Widget padText(String value, {bool bold = false, double size = 10}) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: text(value, bold: bold, size: size));
  pw.Widget sectionTitle(String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6, top: 10),
        child: pw.Align(alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft, child: text(value, bold: true, size: 13)),
      );

  pw.Widget kvTable(List<(String, String?)> rows) => pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: isArabic ? const {0: pw.FlexColumnWidth(), 1: pw.FixedColumnWidth(170)} : const {0: pw.FixedColumnWidth(170), 1: pw.FlexColumnWidth()},
        children: rows.map((row) {
          final label = padText(row.$1, bold: true);
          final value = padText((row.$2 == null || row.$2!.trim().isEmpty) ? '-' : row.$2!);
          return pw.TableRow(children: isArabic ? [value, label] : [label, value]);
        }).toList(),
      );

  pw.Widget historyTable({required List<String> headers, required List<List<String>> rows, required String emptyText}) {
    if (rows.isEmpty) {
      return pw.Align(alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft, child: text(emptyText));
    }
    final orderedHeaders = ReportLayout.orderedByLocale(headers, isArabic: isArabic);
    final orderedRows = isArabic ? rows.map((row) => ReportLayout.orderedByLocale(row, isArabic: true)).toList() : rows;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: orderedHeaders.map((header) => padText(header, bold: true, size: 9)).toList()),
        ...orderedRows.map((row) => pw.TableRow(children: row.map((cell) => padText(cell, size: 9)).toList())),
      ],
    );
  }

  return [
    pw.Align(alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft, child: text(t.employeeFullReport, bold: true, size: 18)),
    pw.SizedBox(height: 4),
    pw.Align(alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft, child: text(t.reportGenerated(DateTime.now().toIso8601String()))),
    sectionTitle(t.basicInfo),
    kvTable([(t.employeeId, p.id), (t.fullName, p.fullName), (t.email, p.email), (t.phone, p.phone), (t.status, p.status), (t.department, p.departmentName), (t.menuJobTitles, p.jobTitleName), (t.hireDate, formatEmployeeDate(p.hireDate))]),
    sectionTitle(t.personal),
    kvTable([(t.nationalId, p.nationalId), (t.dateOfBirth, formatEmployeeDate(p.dateOfBirth)), (t.gender, p.gender), (t.nationality, p.nationality), (t.maritalStatus, p.maritalStatus), (t.address, p.address), (t.city, p.city), (t.country, p.country), (t.passportNo, p.passportNo), (t.passportExpiry, formatEmployeeDate(p.passportExpiry)), (t.residencyIssueDate, formatEmployeeDate(p.residencyIssueDate)), (t.residencyExpiryDate, formatEmployeeDate(p.residencyExpiryDate)), (t.insuranceStartDate, formatEmployeeDate(p.insuranceStartDate)), (t.insuranceExpiryDate, formatEmployeeDate(p.insuranceExpiryDate)), (t.insuranceProvider, p.insuranceProvider), (t.insurancePolicyNo, p.insurancePolicyNo), (t.educationLevel, p.educationLevel), (t.major, p.major), (t.university, p.university)]),
    sectionTitle(t.financial),
    kvTable([(t.paymentMethod, p.paymentMethod), (t.bankName, p.bankName), (t.iban, p.iban), (t.accountNumber, p.accountNumber)]),
    sectionTitle(t.stepCompensation),
    kvTable([(t.basicSalary, formatEmployeeMoney(p.basicSalary)), (t.housingAllowance, formatEmployeeMoney(p.housingAllowance)), (t.transportAllowance, formatEmployeeMoney(p.transportAllowance)), (t.otherAllowance, formatEmployeeMoney(p.otherAllowance)), (t.totalCompensation, formatEmployeeMoney(totalEmployeeCompensation(p)))]),
    sectionTitle(t.compensationHistory),
    historyTable(headers: [t.effectiveDate, t.basic, t.housing, t.transport, t.other, t.total], rows: p.compensationHistory.map((item) => [formatEmployeeDate(item.effectiveAt), item.basicSalary.toStringAsFixed(2), item.housingAllowance.toStringAsFixed(2), item.transportAllowance.toStringAsFixed(2), item.otherAllowance.toStringAsFixed(2), item.total.toStringAsFixed(2)]).toList(), emptyText: t.noCompensationHistory),
    sectionTitle(t.contract),
    kvTable([(t.type, p.contractType), (t.startDate, formatEmployeeDate(p.contractStart)), (t.endDate, formatEmployeeDate(p.contractEnd)), (t.probationMonths, p.probationMonths?.toString()), (t.contractFileUrl, p.contractFileUrl)]),
    sectionTitle(t.contractHistory),
    historyTable(headers: [t.type, t.start, t.end, t.probationMonths, t.file], rows: p.contractHistory.map((item) => [item.contractType, formatEmployeeDate(item.startDate), formatEmployeeDate(item.endDate), item.probationMonths?.toString() ?? '-', item.fileUrl ?? '-']).toList(), emptyText: t.noContractHistory),
    sectionTitle(t.documents),
    historyTable(headers: [t.type, t.issued, t.expires, t.urlLabel], rows: p.documents.map((item) => [item.docType, formatEmployeeDate(item.issuedAt), formatEmployeeDate(item.expiresAt), item.fileUrl]).toList(), emptyText: t.noDocumentsUploaded),
  ];
}
