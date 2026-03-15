import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/safe_file_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_profile_details.dart';
import 'employee_profile_html_report_builder.dart';
import 'employee_profile_pdf_report_builder.dart';

class EmployeeProfileReportService {
  static Future<void> showDownloadOptions(
    BuildContext context,
    EmployeeProfileDetails profile,
  ) async {
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
    if (choice == 'pdf') await _downloadPdf(context, profile);
    if (choice == 'html') await _downloadHtml(context, profile);
  }

  static Future<void> _downloadHtml(
    BuildContext context,
    EmployeeProfileDetails profile,
  ) async {
    final t = AppLocalizations.of(context)!;
    final fileName =
        'employee_report_${profile.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.html';
    final saveLocation = await SafeFilePicker.saveLocation(
      context: context,
      suggestedName: fileName,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'HTML', extensions: ['html']),
      ],
    );
    if (saveLocation == null) return;

    final html = buildEmployeeProfileHtmlReport(
      profile,
      t: t,
      isArabic: Localizations.localeOf(context).languageCode == 'ar',
    );
    await XFile.fromData(
      Uint8List.fromList(utf8.encode(html)),
      name: fileName,
      mimeType: 'text/html',
    ).saveTo(saveLocation.path);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.htmlSavedTo(saveLocation.path))));
  }

  static Future<void> _downloadPdf(
    BuildContext context,
    EmployeeProfileDetails profile,
  ) async {
    final t = AppLocalizations.of(context)!;
    final fileName =
        'employee_report_${profile.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final saveLocation = await SafeFilePicker.saveLocation(
      context: context,
      suggestedName: fileName,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
    );
    if (saveLocation == null) return;

    final bytes = await buildEmployeeProfilePdfReport(
      profile,
      t: t,
      isArabic: Localizations.localeOf(context).languageCode == 'ar',
    );
    await XFile.fromData(
      bytes,
      name: fileName,
      mimeType: 'application/pdf',
    ).saveTo(saveLocation.path);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.pdfSavedTo(saveLocation.path))));
  }
}
