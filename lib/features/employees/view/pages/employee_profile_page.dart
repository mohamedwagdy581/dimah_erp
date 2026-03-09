// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/reporting/report_layout.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_profile_details.dart';

ImageProvider? _resolvePhotoProvider(String? rawValue) {
  final value = (rawValue ?? '').trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri != null) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return NetworkImage(value);
    }
    if (scheme == 'file') {
      final filePath = uri.toFilePath();
      if (filePath.trim().isEmpty) return null;
      return FileImage(File(filePath));
    }
  }

  return FileImage(File(value));
}

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key, required this.employeeId});

  final String employeeId;

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  late Future<EmployeeProfileDetails> _future;

  @override
  void initState() {
    super.initState();
    _future = AppDI.employeesRepo.fetchEmployeeProfile(
      employeeId: widget.employeeId,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppDI.employeesRepo.fetchEmployeeProfile(
        employeeId: widget.employeeId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final session = context.read<SessionCubit>().state;
    final role = session is SessionReady ? session.user.role : '';
    final canEdit = role == 'admin' || role == 'hr';

    return Scaffold(
      appBar: AppBar(title: Text(t.employeeProfileTitle)),
      body: FutureBuilder<EmployeeProfileDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.failedToLoadEmployeeProfile,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(t.retry),
                  ),
                ],
              ),
            );
          }

          final p = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: _resolvePhotoProvider(p.photoUrl),
                    child: (p.photoUrl ?? '').trim().isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    p.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _showDownloadOptions(p),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(AppLocalizations.of(context)!.downloadReport),
                  ),
                  const SizedBox(width: 8),
                  if (canEdit)
                    OutlinedButton.icon(
                      onPressed: () => _openEditDialog(p),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(t.editProfile),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: t.personal,
                children: [
                  _kv(t.nationalId, p.nationalId),
                  _kv(t.dateOfBirth, _date(p.dateOfBirth)),
                  _kv(t.gender, p.gender),
                  _kv(t.nationality, p.nationality),
                  _kv(t.maritalStatus, p.maritalStatus),
                  _kv(t.address, p.address),
                  _kv(t.city, p.city),
                  _kv(t.country, p.country),
                  _kv(t.passportNo, p.passportNo),
                  _kv(t.passportExpiry, _date(p.passportExpiry)),
                  _kv(t.residencyIssueDate, _date(p.residencyIssueDate)),
                  _kv(t.residencyExpiryDate, _date(p.residencyExpiryDate)),
                  _kv(t.insuranceStartDate, _date(p.insuranceStartDate)),
                  _kv(t.insuranceExpiryDate, _date(p.insuranceExpiryDate)),
                  _kv(t.insuranceProvider, p.insuranceProvider),
                  _kv(t.insurancePolicyNo, p.insurancePolicyNo),
                  _kv(t.educationLevel, p.educationLevel),
                  _kv(t.major, p.major),
                  _kv(t.university, p.university),
                ],
              ),
              _SectionCard(
                title: t.basicInfo,
                children: [
                  _kv(t.fullName, p.fullName),
                  _kv(t.email, p.email),
                  _kv(t.phone, p.phone),
                  _kv(t.status, p.status),
                  _kv(t.department, p.departmentName),
                  _kv(t.menuJobTitles, p.jobTitleName),
                  _kv(t.hireDate, _date(p.hireDate)),
                ],
              ),
              _SectionCard(
                title: t.stepCompensation,
                children: [
                  if (canEdit)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _openAddCompensationVersionDialog(p),
                        icon: const Icon(Icons.request_quote_outlined),
                        label: Text(t.addCompensationVersion),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _kv(t.basicSalary, _money(p.basicSalary)),
                  _kv(t.housingAllowance, _money(p.housingAllowance)),
                  _kv(t.transportAllowance, _money(p.transportAllowance)),
                  _kv(t.otherAllowance, _money(p.otherAllowance)),
                  _kv(t.totalCompensation, _money(_totalCompensation(p))),
                  const SizedBox(height: 10),
                  Text(
                    t.compensationHistory,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (p.compensationHistory.isEmpty)
                    Text(t.noCompensationHistory)
                  else
                    ...p.compensationHistory.map(
                      (c) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${t.effectiveDate}: ${_date(c.effectiveAt)} | ${t.total}: ${c.total.toStringAsFixed(2)}',
                        ),
                        subtitle: Text(
                          '${t.basic} ${c.basicSalary.toStringAsFixed(2)} | '
                          '${t.housing} ${c.housingAllowance.toStringAsFixed(2)} | '
                          '${t.transport} ${c.transportAllowance.toStringAsFixed(2)} | '
                          '${t.other} ${c.otherAllowance.toStringAsFixed(2)}'
                          '${(c.note ?? '').trim().isEmpty ? '' : ' | ${t.notes}: ${c.note}'}',
                        ),
                      ),
                    ),
                ],
              ),
              _SectionCard(
                title: t.financial,
                children: [
                  _kv(t.paymentMethod, p.paymentMethod),
                  _kv(t.bankName, p.bankName),
                  _kv(t.iban, p.iban),
                  _kv(t.accountNumber, p.accountNumber),
                ],
              ),
              _SectionCard(
                title: t.contract,
                children: [
                  if (canEdit)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _openAddContractVersionDialog(p),
                        icon: const Icon(Icons.add_card_outlined),
                        label: Text(t.addContractVersion),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _kv(t.type, p.contractType),
                  _kv(t.startDate, _date(p.contractStart)),
                  _kv(t.endDate, _date(p.contractEnd)),
                  _kv(
                    t.probationMonthsLabel,
                    p.probationMonths == null ? '-' : '${p.probationMonths}',
                  ),
                  if ((p.contractFileUrl ?? '').trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _openUrl(p.contractFileUrl!),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(t.openContractFile),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    t.contractHistory,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (p.contractHistory.isEmpty)
                    Text(t.noContractHistory)
                  else
                    ...p.contractHistory.map(
                      (c) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${c.contractType} | ${_date(c.startDate)} -> ${_date(c.endDate)}',
                        ),
                        subtitle: Text(
                          '${t.probationMonths}: ${c.probationMonths?.toString() ?? '-'}',
                        ),
                        trailing: (c.fileUrl ?? '').trim().isEmpty
                            ? null
                            : TextButton(
                                onPressed: () => _openUrl(c.fileUrl!),
                                child: Text(t.open),
                              ),
                      ),
                    ),
                ],
              ),
              _SectionCard(
                title: t.documents,
                children: [
                  if (p.documents.isEmpty)
                    Text(t.noDocumentsUploaded)
                  else
                    ...p.documents.map(
                      (d) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(d.docType),
                        subtitle: Text(
                          '${t.issued}: ${_date(d.issuedAt)} | ${t.expires}: ${_date(d.expiresAt)}',
                        ),
                        trailing: TextButton(
                          onPressed: d.fileUrl.trim().isEmpty
                              ? null
                              : () => _openUrl(d.fileUrl),
                          child: Text(t.open),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditDialog(EmployeeProfileDetails p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _EmployeeProfileEditDialog(profile: p),
    );
    if (ok == true && mounted) {
      await _reload();
    }
  }

  Future<void> _openAddContractVersionDialog(EmployeeProfileDetails p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _AddContractVersionDialog(profile: p),
    );
    if (ok == true && mounted) {
      await _reload();
    }
  }

  Future<void> _openAddCompensationVersionDialog(
    EmployeeProfileDetails p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _AddCompensationVersionDialog(profile: p),
    );
    if (ok == true && mounted) {
      await _reload();
    }
  }

  Future<void> _openUrl(String value) async {
    final t = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(value);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidUrl)));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.unableOpenFile)));
    }
  }

  Future<void> _showDownloadOptions(EmployeeProfileDetails p) async {
    final t = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(t.downloadPdf),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.html_outlined),
              title: Text(t.downloadHtml),
              onTap: () => Navigator.pop(context, 'html'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'pdf') {
      await _downloadFullReportPdf(p);
    } else if (choice == 'html') {
      await _downloadFullReportHtml(p);
    }
  }

  Future<void> _downloadFullReportHtml(EmployeeProfileDetails p) async {
    final t = AppLocalizations.of(context)!;
    final fileName =
        'employee_report_${p.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.html';
    final saveLocation = await SafeFilePicker.saveLocation(
      context: context,
      suggestedName: fileName,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'HTML', extensions: ['html']),
      ],
    );
    if (saveLocation == null) return;

    final locale = Localizations.localeOf(context);
    final html = _buildEmployeeReportHtml(
      p,
      t: t,
      isArabic: locale.languageCode == 'ar',
    );
    final bytes = Uint8List.fromList(utf8.encode(html));
    final file = XFile.fromData(bytes, name: fileName, mimeType: 'text/html');
    await file.saveTo(saveLocation.path);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.htmlSavedTo(saveLocation.path))));
  }

  String _buildEmployeeReportHtml(
    EmployeeProfileDetails p, {
    required AppLocalizations t,
    required bool isArabic,
  }) {
    String esc(String? v) {
      final s = (v == null || v.trim().isEmpty) ? '-' : v.trim();
      return s
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;');
    }

    String tableRows(List<(String, String?)> rows) {
      return rows.map((r) {
        final value = (r.$2 ?? '').trim().isEmpty ? '-' : r.$2!.trim();
        final valueIsArabic = ReportLayout.isMostlyArabic(value);
        final valueAlign = isArabic
            ? (valueIsArabic ? 'right' : 'left')
            : 'left';
        return isArabic
            ? '<tr><td style="text-align:$valueAlign;direction:${ReportLayout.htmlDirectionFor(valueIsArabic)}">${esc(value)}</td><th style="text-align:right;direction:rtl">${esc(r.$1)}</th></tr>'
            : '<tr><th>${esc(r.$1)}</th><td>${esc(value)}</td></tr>';
      }).join();
    }

    String historyHeader(List<String> headers) {
      final ordered = ReportLayout.orderedByLocale(headers, isArabic: isArabic);
      return '<tr>${ordered.map((h) => '<th style="text-align:${isArabic ? 'right' : 'left'};direction:${isArabic ? 'rtl' : 'ltr'}">${esc(h)}</th>').join()}</tr>';
    }

    String historyRows(List<List<String>> rows) {
      return rows.map((row) {
        final ordered = ReportLayout.orderedByLocale(row, isArabic: isArabic);
        return '<tr>${ordered.map((v) {
          final isAr = ReportLayout.isMostlyArabic(v);
          final align = ReportLayout.htmlAlignFor(pageIsArabic: isArabic, value: v);
          return '<td style="text-align:$align;direction:${ReportLayout.htmlDirectionFor(isAr)}">${esc(v)}</td>';
        }).join()}</tr>';
      }).join();
    }

    final compHistoryRowsData = p.compensationHistory
        .map(
          (c) => [
            _date(c.effectiveAt),
            c.basicSalary.toStringAsFixed(2),
            c.housingAllowance.toStringAsFixed(2),
            c.transportAllowance.toStringAsFixed(2),
            c.otherAllowance.toStringAsFixed(2),
            c.total.toStringAsFixed(2),
          ],
        )
        .toList();

    final compHistoryRows = p.compensationHistory.isEmpty
        ? '<tr><td colspan="6">${esc(t.noCompensationHistory)}</td></tr>'
        : historyRows(compHistoryRowsData);

    final contractHistoryRowsData = p.contractHistory
        .map(
          (c) => [
            c.contractType,
            _date(c.startDate),
            _date(c.endDate),
            c.probationMonths?.toString() ?? '-',
            c.fileUrl ?? '-',
          ],
        )
        .toList();

    final contractHistoryRows = p.contractHistory.isEmpty
        ? '<tr><td colspan="5">${esc(t.noContractHistory)}</td></tr>'
        : historyRows(contractHistoryRowsData);

    final docsRowsData = p.documents
        .map(
          (d) => [d.docType, _date(d.issuedAt), _date(d.expiresAt), d.fileUrl],
        )
        .toList();

    final docsRows = p.documents.isEmpty
        ? '<tr><td colspan="4">${esc(t.noDocumentsUploaded)}</td></tr>'
        : historyRows(docsRowsData);

    return '''
<!doctype html>
<html><head><meta charset="utf-8"/>
<title>${esc(t.employeeProfileTitle)} - ${esc(p.fullName)}</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;background:#f6f8fb;color:#111;margin:24px;direction:${isArabic ? 'rtl' : 'ltr'};text-align:${isArabic ? 'right' : 'left'}}
h1{margin:0 0 4px 0} .meta{color:#555;margin-bottom:16px}
.card{background:#fff;border:1px solid #e5e7eb;border-radius:10px;padding:14px;margin-bottom:12px}
h2{font-size:16px;margin:0 0 10px 0}
table{width:100%;border-collapse:collapse}
th,td{border:1px solid #e5e7eb;padding:8px;font-size:13px}
th{background:#f3f4f6;width:240px}
</style></head><body>
<h1>${esc(t.employeeFullReport)}</h1><div class="meta">${esc(t.reportGenerated(DateTime.now().toIso8601String()))}</div>
<div class="card"><h2>${esc(t.basicInfo)}</h2><table>${tableRows([(t.employeeId, p.id), (t.fullName, p.fullName), (t.email, p.email), (t.phone, p.phone), (t.status, p.status), (t.department, p.departmentName), (t.menuJobTitles, p.jobTitleName), (t.hireDate, _date(p.hireDate))])}</table></div>
<div class="card"><h2>${esc(t.personal)}</h2><table>${tableRows([(t.nationalId, p.nationalId), (t.dateOfBirth, _date(p.dateOfBirth)), (t.gender, p.gender), (t.nationality, p.nationality), (t.maritalStatus, p.maritalStatus), (t.address, p.address), (t.city, p.city), (t.country, p.country), (t.passportNo, p.passportNo), (t.passportExpiry, _date(p.passportExpiry)), (t.residencyIssueDate, _date(p.residencyIssueDate)), (t.residencyExpiryDate, _date(p.residencyExpiryDate)), (t.insuranceStartDate, _date(p.insuranceStartDate)), (t.insuranceExpiryDate, _date(p.insuranceExpiryDate)), (t.insuranceProvider, p.insuranceProvider), (t.insurancePolicyNo, p.insurancePolicyNo), (t.educationLevel, p.educationLevel), (t.major, p.major), (t.university, p.university)])}</table></div>
<div class="card"><h2>${esc(t.financial)}</h2><table>${tableRows([(t.paymentMethod, p.paymentMethod), (t.bankName, p.bankName), (t.iban, p.iban), (t.accountNumber, p.accountNumber)])}</table></div>
<div class="card"><h2>${esc(t.stepCompensation)}</h2><table>${tableRows([(t.basicSalary, _money(p.basicSalary)), (t.housingAllowance, _money(p.housingAllowance)), (t.transportAllowance, _money(p.transportAllowance)), (t.otherAllowance, _money(p.otherAllowance)), (t.totalCompensation, _money(_totalCompensation(p)))])}</table></div>
<div class="card"><h2>${esc(t.compensationHistory)}</h2><table>${historyHeader([t.effectiveDate, t.basic, t.housing, t.transport, t.other, t.total])}$compHistoryRows</table></div>
<div class="card"><h2>${esc(t.contract)}</h2><table>${tableRows([(t.type, p.contractType), (t.startDate, _date(p.contractStart)), (t.endDate, _date(p.contractEnd)), (t.probationMonths, p.probationMonths?.toString()), (t.contractFileUrl, p.contractFileUrl)])}</table></div>
<div class="card"><h2>${esc(t.contractHistory)}</h2><table>${historyHeader([t.type, t.start, t.end, t.probationMonths, t.file])}$contractHistoryRows</table></div>
<div class="card"><h2>${esc(t.documents)}</h2><table>${historyHeader([t.type, t.issued, t.expires, t.urlLabel])}$docsRows</table></div>
</body></html>
''';
  }

  Future<void> _downloadFullReportPdf(EmployeeProfileDetails p) async {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final fileName =
        'employee_report_${p.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final saveLocation = await SafeFilePicker.saveLocation(
      context: context,
      suggestedName: fileName,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
    );
    if (saveLocation == null) return;

    pw.Font? baseFont;
    pw.Font? boldFont;
    if (Platform.isWindows) {
      final candidates = <String>[
        r'C:\Windows\Fonts\arial.ttf',
        r'C:\Windows\Fonts\segoeui.ttf',
      ];
      final candidatesBold = <String>[
        r'C:\Windows\Fonts\arialbd.ttf',
        r'C:\Windows\Fonts\segoeuib.ttf',
      ];
      for (final path in candidates) {
        final f = File(path);
        if (f.existsSync()) {
          final bytes = await f.readAsBytes();
          baseFont = pw.Font.ttf(ByteData.view(bytes.buffer));
          break;
        }
      }
      for (final path in candidatesBold) {
        final f = File(path);
        if (f.existsSync()) {
          final bytes = await f.readAsBytes();
          boldFont = pw.Font.ttf(ByteData.view(bytes.buffer));
          break;
        }
      }
    }

    final pdf = pw.Document(
      theme: (baseFont != null)
          ? pw.ThemeData.withFont(base: baseFont, bold: boldFont ?? baseFont)
          : null,
    );

    pw.Widget kvTable(List<(String, String?)> rows) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: isArabic
            ? const {0: pw.FlexColumnWidth(), 1: pw.FixedColumnWidth(170)}
            : const {0: pw.FixedColumnWidth(170), 1: pw.FlexColumnWidth()},
        children: rows.map((r) {
          final label = pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              r.$1,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textDirection: _isMostlyArabic(r.$1)
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
            ),
          );
          final value = pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              r.$2 == null || r.$2!.trim().isEmpty ? '-' : r.$2!,
              textDirection: _isMostlyArabic(r.$2 ?? '')
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
            ),
          );
          return pw.TableRow(
            children: isArabic ? [value, label] : [label, value],
          );
        }).toList(),
      );
    }

    pw.Widget sectionTitle(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, top: 10),
      child: pw.Align(
        alignment: isArabic
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft,
        child: pw.Text(
          t,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      ),
    );

    pw.Widget historyTable({
      required List<String> headers,
      required List<List<String>> rows,
      required String emptyText,
    }) {
      if (rows.isEmpty) {
        return pw.Align(
          alignment: isArabic
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
          child: pw.Text(
            emptyText,
            style: const pw.TextStyle(fontSize: 10),
            textDirection: isArabic
                ? pw.TextDirection.rtl
                : pw.TextDirection.ltr,
            textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
          ),
        );
      }
      final orderedHeaders = ReportLayout.orderedByLocale(
        headers,
        isArabic: isArabic,
      );
      final orderedRows = isArabic
          ? rows
                .map((r) => ReportLayout.orderedByLocale(r, isArabic: true))
                .toList()
          : rows;

      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: orderedHeaders
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                      textDirection: isArabic
                          ? pw.TextDirection.rtl
                          : pw.TextDirection.ltr,
                      textAlign: isArabic
                          ? pw.TextAlign.right
                          : pw.TextAlign.left,
                    ),
                  ),
                )
                .toList(),
          ),
          ...orderedRows.map(
            (row) => pw.TableRow(
              children: row.map((cell) {
                final ar = ReportLayout.isMostlyArabic(cell);
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    cell,
                    style: const pw.TextStyle(fontSize: 9),
                    textDirection: ar
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    textAlign: isArabic
                        ? pw.TextAlign.right
                        : pw.TextAlign.left,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(20),
        build: (_) => [
          pw.Align(
            alignment: isArabic
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft,
            child: pw.Text(
              t.employeeFullReport,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              textDirection: isArabic
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Align(
            alignment: isArabic
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft,
            child: pw.Text(
              t.reportGenerated(DateTime.now().toIso8601String()),
              textDirection: isArabic
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
            ),
          ),
          sectionTitle(t.basicInfo),
          kvTable([
            (t.employeeId, p.id),
            (t.fullName, p.fullName),
            (t.email, p.email),
            (t.phone, p.phone),
            (t.status, p.status),
            (t.department, p.departmentName),
            (t.menuJobTitles, p.jobTitleName),
            (t.hireDate, _date(p.hireDate)),
          ]),
          sectionTitle(t.personal),
          kvTable([
            (t.nationalId, p.nationalId),
            (t.dateOfBirth, _date(p.dateOfBirth)),
            (t.gender, p.gender),
            (t.nationality, p.nationality),
            (t.maritalStatus, p.maritalStatus),
            (t.address, p.address),
            (t.city, p.city),
            (t.country, p.country),
            (t.passportNo, p.passportNo),
            (t.passportExpiry, _date(p.passportExpiry)),
            (t.residencyIssueDate, _date(p.residencyIssueDate)),
            (t.residencyExpiryDate, _date(p.residencyExpiryDate)),
            (t.insuranceStartDate, _date(p.insuranceStartDate)),
            (t.insuranceExpiryDate, _date(p.insuranceExpiryDate)),
            (t.insuranceProvider, p.insuranceProvider),
            (t.insurancePolicyNo, p.insurancePolicyNo),
            (t.educationLevel, p.educationLevel),
            (t.major, p.major),
            (t.university, p.university),
          ]),
          sectionTitle(t.financial),
          kvTable([
            (t.paymentMethod, p.paymentMethod),
            (t.bankName, p.bankName),
            (t.iban, p.iban),
            (t.accountNumber, p.accountNumber),
          ]),
          sectionTitle(t.stepCompensation),
          kvTable([
            (t.basicSalary, _money(p.basicSalary)),
            (t.housingAllowance, _money(p.housingAllowance)),
            (t.transportAllowance, _money(p.transportAllowance)),
            (t.otherAllowance, _money(p.otherAllowance)),
            (t.totalCompensation, _money(_totalCompensation(p))),
          ]),
          sectionTitle(t.compensationHistory),
          historyTable(
            headers: [
              t.effectiveDate,
              t.basic,
              t.housing,
              t.transport,
              t.other,
              t.total,
            ],
            rows: p.compensationHistory
                .map(
                  (c) => [
                    _date(c.effectiveAt),
                    c.basicSalary.toStringAsFixed(2),
                    c.housingAllowance.toStringAsFixed(2),
                    c.transportAllowance.toStringAsFixed(2),
                    c.otherAllowance.toStringAsFixed(2),
                    c.total.toStringAsFixed(2),
                  ],
                )
                .toList(),
            emptyText: t.noCompensationHistory,
          ),
          sectionTitle(t.contract),
          kvTable([
            (t.type, p.contractType),
            (t.startDate, _date(p.contractStart)),
            (t.endDate, _date(p.contractEnd)),
            (t.probationMonths, p.probationMonths?.toString()),
            (t.contractFileUrl, p.contractFileUrl),
          ]),
          sectionTitle(t.contractHistory),
          historyTable(
            headers: [t.type, t.start, t.end, t.probationMonths, t.file],
            rows: p.contractHistory
                .map(
                  (c) => [
                    c.contractType,
                    _date(c.startDate),
                    _date(c.endDate),
                    c.probationMonths?.toString() ?? '-',
                    c.fileUrl ?? '-',
                  ],
                )
                .toList(),
            emptyText: t.noContractHistory,
          ),
          sectionTitle(t.documents),
          historyTable(
            headers: [t.type, t.issued, t.expires, t.urlLabel],
            rows: p.documents
                .map(
                  (d) => [
                    d.docType,
                    _date(d.issuedAt),
                    _date(d.expiresAt),
                    d.fileUrl,
                  ],
                )
                .toList(),
            emptyText: t.noDocumentsUploaded,
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final file = XFile.fromData(
      bytes,
      name: fileName,
      mimeType: 'application/pdf',
    );
    await file.saveTo(saveLocation.path);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.pdfSavedTo(saveLocation.path),
        ),
      ),
    );
  }

  String _date(DateTime? d) {
    if (d == null) return '-';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _money(double? v) {
    if (v == null) return '-';
    return v.toStringAsFixed(2);
  }

  double _totalCompensation(EmployeeProfileDetails p) {
    return (p.basicSalary ?? 0) +
        (p.housingAllowance ?? 0) +
        (p.transportAllowance ?? 0) +
        (p.otherAllowance ?? 0);
  }

  Widget _kv(String label, String? value) {
    final text = (value == null || value.trim().isEmpty) ? '-' : value.trim();
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isRtl
            ? [
                SizedBox(
                  width: 170,
                  child: Text(
                    '$label:',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ]
            : [
                SizedBox(
                  width: 170,
                  child: Text(
                    '$label:',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(text, textAlign: TextAlign.left)),
              ],
      ),
    );
  }

  bool _isMostlyArabic(String value) => ReportLayout.isMostlyArabic(value);
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _EmployeeProfileEditDialog extends StatefulWidget {
  const _EmployeeProfileEditDialog({required this.profile});

  final EmployeeProfileDetails profile;

  @override
  State<_EmployeeProfileEditDialog> createState() =>
      _EmployeeProfileEditDialogState();
}

class _EmployeeProfileEditDialogState
    extends State<_EmployeeProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _photoUrl;
  late final TextEditingController _nationality;
  late final TextEditingController _maritalStatus;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _passportNo;
  late final TextEditingController _insuranceProvider;
  late final TextEditingController _insurancePolicyNo;
  late final TextEditingController _educationLevel;
  late final TextEditingController _major;
  late final TextEditingController _university;
  late final TextEditingController _bankName;
  late final TextEditingController _iban;
  late final TextEditingController _accountNumber;
  late final TextEditingController _contractType;
  late final TextEditingController _probationMonths;
  late final TextEditingController _contractFileUrl;

  late String _status;
  late String _paymentMethod;
  DateTime? _passportExpiry;
  DateTime? _residencyIssueDate;
  DateTime? _residencyExpiryDate;
  DateTime? _insuranceStartDate;
  DateTime? _insuranceExpiryDate;
  DateTime? _contractStart;
  DateTime? _contractEnd;
  bool _pickingPhoto = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _fullName = TextEditingController(text: p.fullName);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
    _photoUrl = TextEditingController(text: p.photoUrl ?? '');
    _nationality = TextEditingController(text: p.nationality ?? '');
    _maritalStatus = TextEditingController(text: p.maritalStatus ?? '');
    _address = TextEditingController(text: p.address ?? '');
    _city = TextEditingController(text: p.city ?? '');
    _country = TextEditingController(text: p.country ?? '');
    _passportNo = TextEditingController(text: p.passportNo ?? '');
    _insuranceProvider = TextEditingController(text: p.insuranceProvider ?? '');
    _insurancePolicyNo = TextEditingController(text: p.insurancePolicyNo ?? '');
    _educationLevel = TextEditingController(text: p.educationLevel ?? '');
    _major = TextEditingController(text: p.major ?? '');
    _university = TextEditingController(text: p.university ?? '');
    _bankName = TextEditingController(text: p.bankName ?? '');
    _iban = TextEditingController(text: p.iban ?? '');
    _accountNumber = TextEditingController(text: p.accountNumber ?? '');
    _contractType = TextEditingController(text: p.contractType ?? 'full_time');
    _probationMonths = TextEditingController(
      text: p.probationMonths == null ? '' : '${p.probationMonths}',
    );
    _contractFileUrl = TextEditingController(text: p.contractFileUrl ?? '');
    _status = p.status.isEmpty ? 'active' : p.status;
    _paymentMethod = (p.paymentMethod ?? 'bank').isEmpty
        ? 'bank'
        : p.paymentMethod!;
    _passportExpiry = p.passportExpiry;
    _residencyIssueDate = p.residencyIssueDate;
    _residencyExpiryDate = p.residencyExpiryDate;
    _insuranceStartDate = p.insuranceStartDate;
    _insuranceExpiryDate = p.insuranceExpiryDate;
    _contractStart = p.contractStart;
    _contractEnd = p.contractEnd;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _photoUrl.dispose();
    _nationality.dispose();
    _maritalStatus.dispose();
    _address.dispose();
    _city.dispose();
    _country.dispose();
    _passportNo.dispose();
    _insuranceProvider.dispose();
    _insurancePolicyNo.dispose();
    _educationLevel.dispose();
    _major.dispose();
    _university.dispose();
    _bankName.dispose();
    _iban.dispose();
    _accountNumber.dispose();
    _contractType.dispose();
    _probationMonths.dispose();
    _contractFileUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.editEmployeeProfile),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_fullName, 'Full Name', required: true),
                const SizedBox(height: 10),
                _field(_email, 'Email', required: true),
                const SizedBox(height: 10),
                _field(_phone, 'Phone', required: true),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: _resolvePhotoProvider(_photoUrl.text),
                      child: _photoUrl.text.trim().isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_saving || _pickingPhoto)
                            ? null
                            : _pickPhotoOnly,
                        icon: const Icon(Icons.upload_outlined),
                        label: Text(
                          _pickingPhoto
                              ? AppLocalizations.of(context)!.pickingPhoto
                              : AppLocalizations.of(context)!.selectPhoto,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_pickingPhoto) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)!.uploadingPhoto,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.status,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(AppLocalizations.of(context)!.active),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text(AppLocalizations.of(context)!.inactive),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? 'active'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.paymentMethod,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'bank',
                            child: Text(
                              AppLocalizations.of(context)!.paymentMethodBank,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'cash',
                            child: Text(
                              AppLocalizations.of(context)!.paymentMethodCash,
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _paymentMethod = v ?? 'bank'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _field(_nationality, AppLocalizations.of(context)!.nationality),
                const SizedBox(height: 10),
                _field(
                  _maritalStatus,
                  AppLocalizations.of(context)!.maritalStatus,
                ),
                const SizedBox(height: 10),
                _field(_address, AppLocalizations.of(context)!.address),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field(_city, AppLocalizations.of(context)!.city),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        _country,
                        AppLocalizations.of(context)!.country,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _passportNo,
                        AppLocalizations.of(context)!.passportNo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickPassportExpiry,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _passportExpiry == null
                              ? AppLocalizations.of(context)!.passportExpiry
                              : _fmt(_passportExpiry),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickResidencyIssueDate,
                        icon: const Icon(Icons.badge_outlined),
                        label: Text(
                          _residencyIssueDate == null
                              ? AppLocalizations.of(context)!.residencyIssue
                              : _fmt(_residencyIssueDate),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickResidencyExpiryDate,
                        icon: const Icon(Icons.badge),
                        label: Text(
                          _residencyExpiryDate == null
                              ? AppLocalizations.of(context)!.residencyExpiry
                              : _fmt(_residencyExpiryDate),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickInsuranceStartDate,
                        icon: const Icon(Icons.health_and_safety_outlined),
                        label: Text(
                          _insuranceStartDate == null
                              ? AppLocalizations.of(context)!.insuranceStart
                              : _fmt(_insuranceStartDate),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickInsuranceExpiryDate,
                        icon: const Icon(Icons.health_and_safety),
                        label: Text(
                          _insuranceExpiryDate == null
                              ? AppLocalizations.of(context)!.insuranceExpiry
                              : _fmt(_insuranceExpiryDate),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _insuranceProvider,
                        AppLocalizations.of(context)!.insuranceProvider,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        _insurancePolicyNo,
                        AppLocalizations.of(context)!.insurancePolicyNo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _educationLevel,
                        AppLocalizations.of(context)!.educationLevel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        _major,
                        AppLocalizations.of(context)!.major,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _field(_university, AppLocalizations.of(context)!.university),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _bankName,
                        AppLocalizations.of(context)!.bankName,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(_iban, AppLocalizations.of(context)!.iban),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _field(
                  _accountNumber,
                  AppLocalizations.of(context)!.accountNumber,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _contractType,
                        AppLocalizations.of(context)!.contractType,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        _probationMonths,
                        AppLocalizations.of(context)!.probationMonths,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickContractStart,
                        icon: const Icon(Icons.event_note),
                        label: Text(
                          _contractStart == null
                              ? AppLocalizations.of(context)!.contractStart
                              : _fmt(_contractStart),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickContractEnd,
                        icon: const Icon(Icons.event_busy),
                        label: Text(
                          _contractEnd == null
                              ? AppLocalizations.of(context)!.contractEnd
                              : _fmt(_contractEnd),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _field(
                  _contractFileUrl,
                  AppLocalizations.of(context)!.contractFileUrl,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_saving || _pickingPhoto)
              ? null
              : () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: (_saving || _pickingPhoto) ? null : _save,
          child: Text(
            _saving
                ? AppLocalizations.of(context)!.saving
                : AppLocalizations.of(context)!.save,
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) {
              if ((v ?? '').trim().isEmpty) return '$label is required';
              return null;
            }
          : null,
    );
  }

  Future<void> _pickPassportExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _passportExpiry ?? now,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 20, 12, 31),
    );
    if (picked != null) setState(() => _passportExpiry = picked);
  }

  Future<void> _pickResidencyIssueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _residencyIssueDate ?? now,
      firstDate: DateTime(now.year - 15, 1, 1),
      lastDate: DateTime(now.year + 15, 12, 31),
    );
    if (picked != null) setState(() => _residencyIssueDate = picked);
  }

  Future<void> _pickResidencyExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _residencyExpiryDate ?? _residencyIssueDate ?? now,
      firstDate: DateTime(now.year - 15, 1, 1),
      lastDate: DateTime(now.year + 15, 12, 31),
    );
    if (picked != null) setState(() => _residencyExpiryDate = picked);
  }

  Future<void> _pickInsuranceStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _insuranceStartDate ?? now,
      firstDate: DateTime(now.year - 15, 1, 1),
      lastDate: DateTime(now.year + 15, 12, 31),
    );
    if (picked != null) setState(() => _insuranceStartDate = picked);
  }

  Future<void> _pickInsuranceExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _insuranceExpiryDate ?? _insuranceStartDate ?? now,
      firstDate: DateTime(now.year - 15, 1, 1),
      lastDate: DateTime(now.year + 15, 12, 31),
    );
    if (picked != null) setState(() => _insuranceExpiryDate = picked);
  }

  Future<void> _pickContractStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _contractStart ?? now,
      firstDate: DateTime(now.year - 10, 1, 1),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (picked != null) setState(() => _contractStart = picked);
  }

  Future<void> _pickContractEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _contractEnd ?? _contractStart ?? now,
      firstDate: DateTime(now.year - 10, 1, 1),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (picked != null) setState(() => _contractEnd = picked);
  }

  Future<void> _pickPhotoOnly() async {
    final t = AppLocalizations.of(context)!;
    final file = await SafeFilePicker.openSingle(
      context: context,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']),
      ],
    );
    if (file == null) return;

    setState(() => _pickingPhoto = true);
    try {
      final length = await file.length();
      if (length > 5 * 1024 * 1024) {
        throw Exception(t.photoTooLargeMax5Mb);
      }
      final bytes = await file.readAsBytes();
      final client = AppDI.supabase;
      final tenantId = await _fetchTenantId(client);
      final ext = _extension(file.name);
      final contentType = switch (ext) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'webp' => 'image/webp',
        _ => 'application/octet-stream',
      };
      final displayName = _fullName.text.trim().isEmpty
          ? widget.profile.fullName
          : _fullName.text.trim();
      final employeeSlug = _slugify(displayName);
      final employeeFolder =
          '${employeeSlug}_${widget.profile.id.substring(0, 8)}';
      final fileName = '$employeeSlug.$ext';
      final path = '$tenantId/$employeeFolder/$fileName';

      await client.storage
          .from('employee_photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          )
          .timeout(const Duration(minutes: 2));

      final publicUrl = client.storage
          .from('employee_photos')
          .getPublicUrl(path);
      _photoUrl.text = publicUrl;
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.photoUploadedSuccessfully,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('PHOTO_UPLOAD_ERROR: $e');
      debugPrint('PHOTO_UPLOAD_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.photoUploadFailed(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<String> _fetchTenantId(SupabaseClient client) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    return me['tenant_id'].toString();
  }

  String _extension(String fileName) {
    final i = fileName.lastIndexOf('.');
    if (i < 0 || i == fileName.length - 1) return 'jpg';
    return fileName.substring(i + 1).toLowerCase();
  }

  String _slugify(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'employee' : normalized;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await AppDI.employeesRepo.updateEmployeeProfile(
        employeeId: widget.profile.id,
        fullName: _fullName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        photoUrl: _photoUrl.text.trim(),
        status: _status,
        nationality: _nationality.text.trim(),
        maritalStatus: _maritalStatus.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        passportNo: _passportNo.text.trim(),
        passportExpiry: _passportExpiry,
        residencyIssueDate: _residencyIssueDate,
        residencyExpiryDate: _residencyExpiryDate,
        insuranceStartDate: _insuranceStartDate,
        insuranceExpiryDate: _insuranceExpiryDate,
        insuranceProvider: _insuranceProvider.text.trim(),
        insurancePolicyNo: _insurancePolicyNo.text.trim(),
        educationLevel: _educationLevel.text.trim(),
        major: _major.text.trim(),
        university: _university.text.trim(),
        bankName: _bankName.text.trim(),
        iban: _iban.text.trim(),
        accountNumber: _accountNumber.text.trim(),
        paymentMethod: _paymentMethod,
        contractType: _contractType.text.trim(),
        contractStart: _contractStart,
        contractEnd: _contractEnd,
        probationMonths: int.tryParse(_probationMonths.text.trim()),
        contractFileUrl: _contractFileUrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.saveFailed(e.toString())),
        ),
      );
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '-';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}

class _AddContractVersionDialog extends StatefulWidget {
  const _AddContractVersionDialog({required this.profile});

  final EmployeeProfileDetails profile;

  @override
  State<_AddContractVersionDialog> createState() =>
      _AddContractVersionDialogState();
}

class _AddContractVersionDialogState extends State<_AddContractVersionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contractType;
  late final TextEditingController _probationMonths;
  late final TextEditingController _fileUrl;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contractType = TextEditingController(text: 'full_time');
    _probationMonths = TextEditingController();
    _fileUrl = TextEditingController();
    _startDate = DateTime.now();
  }

  @override
  void dispose() {
    _contractType.dispose();
    _probationMonths.dispose();
    _fileUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.addContractVersion),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _contractType,
                decoration: InputDecoration(
                  labelText: t.contractType,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? t.contractTypeRequired : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(Icons.event_note),
                      label: Text(
                        _startDate == null ? t.startDate : _fmt(_startDate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEndDate,
                      icon: const Icon(Icons.event_busy),
                      label: Text(
                        _endDate == null ? t.endDate : _fmt(_endDate),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _probationMonths,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.probationMonths,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fileUrl,
                decoration: InputDecoration(
                  labelText: t.contractFileUrlOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? t.saving : t.save),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 20, 1, 1),
      lastDate: DateTime(now.year + 20, 12, 31),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 20, 1, 1),
      lastDate: DateTime(now.year + 20, 12, 31),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.startDateRequired),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AppDI.employeesRepo.addEmployeeContractVersion(
        employeeId: widget.profile.id,
        contractType: _contractType.text.trim(),
        startDate: _startDate!,
        endDate: _endDate,
        probationMonths: int.tryParse(_probationMonths.text.trim()),
        fileUrl: _fileUrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.saveFailed(e.toString())),
        ),
      );
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '-';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}

class _AddCompensationVersionDialog extends StatefulWidget {
  const _AddCompensationVersionDialog({required this.profile});

  final EmployeeProfileDetails profile;

  @override
  State<_AddCompensationVersionDialog> createState() =>
      _AddCompensationVersionDialogState();
}

class _AddCompensationVersionDialogState
    extends State<_AddCompensationVersionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _basic;
  late final TextEditingController _housing;
  late final TextEditingController _transport;
  late final TextEditingController _other;
  late final TextEditingController _note;
  DateTime? _effectiveAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _basic = TextEditingController(
      text: (widget.profile.basicSalary ?? 0).toStringAsFixed(2),
    );
    _housing = TextEditingController(
      text: (widget.profile.housingAllowance ?? 0).toStringAsFixed(2),
    );
    _transport = TextEditingController(
      text: (widget.profile.transportAllowance ?? 0).toStringAsFixed(2),
    );
    _other = TextEditingController(
      text: (widget.profile.otherAllowance ?? 0).toStringAsFixed(2),
    );
    _note = TextEditingController();
    _effectiveAt = DateTime.now();
  }

  @override
  void dispose() {
    _basic.dispose();
    _housing.dispose();
    _transport.dispose();
    _other.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.addCompensationVersion),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numField(_basic, t.basicSalary),
              const SizedBox(height: 10),
              _numField(_housing, t.housingAllowance),
              const SizedBox(height: 10),
              _numField(_transport, t.transportAllowance),
              const SizedBox(height: 10),
              _numField(_other, t.otherAllowance),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickEffectiveDate,
                icon: const Icon(Icons.event),
                label: Text(
                  _effectiveAt == null ? t.effectiveDate : _fmt(_effectiveAt),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(
                  labelText: t.noteOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? t.saving : t.save),
        ),
      ],
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if ((v ?? '').trim().isEmpty)
          return AppLocalizations.of(context)!.fieldRequired(label);
        if (double.tryParse(v!.trim()) == null)
          return AppLocalizations.of(context)!.invalidNumber;
        return null;
      },
    );
  }

  Future<void> _pickEffectiveDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveAt ?? now,
      firstDate: DateTime(now.year - 20, 1, 1),
      lastDate: DateTime(now.year + 20, 12, 31),
    );
    if (picked != null) setState(() => _effectiveAt = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await AppDI.employeesRepo.addEmployeeCompensationVersion(
        employeeId: widget.profile.id,
        basicSalary: double.parse(_basic.text.trim()),
        housingAllowance: double.parse(_housing.text.trim()),
        transportAllowance: double.parse(_transport.text.trim()),
        otherAllowance: double.parse(_other.text.trim()),
        effectiveAt: _effectiveAt,
        note: _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.saveFailed(e.toString())),
        ),
      );
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '-';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
