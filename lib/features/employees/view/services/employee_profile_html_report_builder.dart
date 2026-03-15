import '../../../../../core/reporting/report_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_profile_details.dart';
import '../utils/employee_profile_utils.dart';

String buildEmployeeProfileHtmlReport(
  EmployeeProfileDetails profile, {
  required AppLocalizations t,
  required bool isArabic,
}) {
  String esc(String? value) {
    final text = (value == null || value.trim().isEmpty) ? '-' : value.trim();
    return text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
  }

  String tableRows(List<(String, String?)> rows) => rows.map((row) {
    final value = (row.$2 ?? '').trim().isEmpty ? '-' : row.$2!.trim();
    final valueArabic = ReportLayout.isMostlyArabic(value);
    final valueAlign = isArabic ? (valueArabic ? 'right' : 'left') : 'left';
    return isArabic
        ? '<tr><td style="text-align:$valueAlign;direction:${ReportLayout.htmlDirectionFor(valueArabic)}">${esc(value)}</td><th style="text-align:right;direction:rtl">${esc(row.$1)}</th></tr>'
        : '<tr><th>${esc(row.$1)}</th><td>${esc(value)}</td></tr>';
  }).join();

  String historyHeader(List<String> headers) {
    final ordered = ReportLayout.orderedByLocale(headers, isArabic: isArabic);
    return '<tr>${ordered.map((header) => '<th style="text-align:${isArabic ? 'right' : 'left'};direction:${isArabic ? 'rtl' : 'ltr'}">${esc(header)}</th>').join()}</tr>';
  }

  String historyRows(List<List<String>> rows) => rows.map((row) {
    final ordered = ReportLayout.orderedByLocale(row, isArabic: isArabic);
    return '<tr>${ordered.map((value) {
      final valueArabic = ReportLayout.isMostlyArabic(value);
      final align = ReportLayout.htmlAlignFor(pageIsArabic: isArabic, value: value);
      return '<td style="text-align:$align;direction:${ReportLayout.htmlDirectionFor(valueArabic)}">${esc(value)}</td>';
    }).join()}</tr>';
  }).join();

  final p = profile;
  final compensationRows = p.compensationHistory.map((item) => [formatEmployeeDate(item.effectiveAt), item.basicSalary.toStringAsFixed(2), item.housingAllowance.toStringAsFixed(2), item.transportAllowance.toStringAsFixed(2), item.otherAllowance.toStringAsFixed(2), item.total.toStringAsFixed(2)]).toList();
  final contractRows = p.contractHistory.map((item) => [item.contractType, formatEmployeeDate(item.startDate), formatEmployeeDate(item.endDate), item.probationMonths?.toString() ?? '-', item.fileUrl ?? '-']).toList();
  final documentRows = p.documents.map((item) => [item.docType, formatEmployeeDate(item.issuedAt), formatEmployeeDate(item.expiresAt), item.fileUrl]).toList();

  return '''
<!doctype html>
<html><head><meta charset="utf-8"/>
<title>${esc(t.employeeProfileTitle)} - ${esc(p.fullName)}</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;background:#f6f8fb;color:#111;margin:24px;direction:${isArabic ? 'rtl' : 'ltr'};text-align:${isArabic ? 'right' : 'left'}}
h1{margin:0 0 4px 0}.meta{color:#555;margin-bottom:16px}
.card{background:#fff;border:1px solid #e5e7eb;border-radius:10px;padding:14px;margin-bottom:12px}
h2{font-size:16px;margin:0 0 10px 0}
table{width:100%;border-collapse:collapse}
th,td{border:1px solid #e5e7eb;padding:8px;font-size:13px}
th{background:#f3f4f6;width:240px}
</style></head><body>
<h1>${esc(t.employeeFullReport)}</h1><div class="meta">${esc(t.reportGenerated(DateTime.now().toIso8601String()))}</div>
<div class="card"><h2>${esc(t.basicInfo)}</h2><table>${tableRows([(t.employeeId, p.id), (t.fullName, p.fullName), (t.email, p.email), (t.phone, p.phone), (t.status, p.status), (t.department, p.departmentName), (t.menuJobTitles, p.jobTitleName), (t.hireDate, formatEmployeeDate(p.hireDate))])}</table></div>
<div class="card"><h2>${esc(t.personal)}</h2><table>${tableRows([(t.nationalId, p.nationalId), (t.dateOfBirth, formatEmployeeDate(p.dateOfBirth)), (t.gender, p.gender), (t.nationality, p.nationality), (t.maritalStatus, p.maritalStatus), (t.address, p.address), (t.city, p.city), (t.country, p.country), (t.passportNo, p.passportNo), (t.passportExpiry, formatEmployeeDate(p.passportExpiry)), (t.residencyIssueDate, formatEmployeeDate(p.residencyIssueDate)), (t.residencyExpiryDate, formatEmployeeDate(p.residencyExpiryDate)), (t.insuranceStartDate, formatEmployeeDate(p.insuranceStartDate)), (t.insuranceExpiryDate, formatEmployeeDate(p.insuranceExpiryDate)), (t.insuranceProvider, p.insuranceProvider), (t.insurancePolicyNo, p.insurancePolicyNo), (t.educationLevel, p.educationLevel), (t.major, p.major), (t.university, p.university)])}</table></div>
<div class="card"><h2>${esc(t.financial)}</h2><table>${tableRows([(t.paymentMethod, p.paymentMethod), (t.bankName, p.bankName), (t.iban, p.iban), (t.accountNumber, p.accountNumber)])}</table></div>
<div class="card"><h2>${esc(t.stepCompensation)}</h2><table>${tableRows([(t.basicSalary, formatEmployeeMoney(p.basicSalary)), (t.housingAllowance, formatEmployeeMoney(p.housingAllowance)), (t.transportAllowance, formatEmployeeMoney(p.transportAllowance)), (t.otherAllowance, formatEmployeeMoney(p.otherAllowance)), (t.totalCompensation, formatEmployeeMoney(totalEmployeeCompensation(p)))])}</table></div>
<div class="card"><h2>${esc(t.compensationHistory)}</h2><table>${historyHeader([t.effectiveDate, t.basic, t.housing, t.transport, t.other, t.total])}${compensationRows.isEmpty ? '<tr><td colspan="6">${esc(t.noCompensationHistory)}</td></tr>' : historyRows(compensationRows)}</table></div>
<div class="card"><h2>${esc(t.contract)}</h2><table>${tableRows([(t.type, p.contractType), (t.startDate, formatEmployeeDate(p.contractStart)), (t.endDate, formatEmployeeDate(p.contractEnd)), (t.probationMonths, p.probationMonths?.toString()), (t.contractFileUrl, p.contractFileUrl)])}</table></div>
<div class="card"><h2>${esc(t.contractHistory)}</h2><table>${historyHeader([t.type, t.start, t.end, t.probationMonths, t.file])}${contractRows.isEmpty ? '<tr><td colspan="5">${esc(t.noContractHistory)}</td></tr>' : historyRows(contractRows)}</table></div>
<div class="card"><h2>${esc(t.documents)}</h2><table>${historyHeader([t.type, t.issued, t.expires, t.urlLabel])}${documentRows.isEmpty ? '<tr><td colspan="4">${esc(t.noDocumentsUploaded)}</td></tr>' : historyRows(documentRows)}</table></div>
</body></html>
''';
}
