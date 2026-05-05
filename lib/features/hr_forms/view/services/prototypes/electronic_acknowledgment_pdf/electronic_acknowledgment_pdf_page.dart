import 'package:pdf/widgets.dart' as pw;

import 'electronic_acknowledgment_pdf_sections.dart';
import 'electronic_acknowledgment_pdf_theme.dart';

class ElectronicAcknowledgmentPdfPayload {
  const ElectronicAcknowledgmentPdfPayload({
    required this.isArabic,
    required this.logo,
    required this.employeeName,
    required this.employeeId,
    required this.mobile,
    required this.role,
    required this.department,
    required this.signature,
  });

  final bool isArabic;
  final pw.MemoryImage logo;
  final String employeeName;
  final String employeeId;
  final String mobile;
  final String role;
  final String department;
  final String signature;
}

pw.Widget buildElectronicAcknowledgmentPdfPage(
  ElectronicAcknowledgmentPdfPayload payload,
) {
  final theme = ElectronicAcknowledgmentPdfTheme(payload.isArabic);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      ElectronicAcknowledgmentPdfHeader(theme: theme, logo: payload.logo),
      pw.SizedBox(height: 16),
      ElectronicAcknowledgmentPdfSummary(theme: theme),
      pw.SizedBox(height: 14),
      ElectronicAcknowledgmentPdfEmployeeSection(payload: payload, theme: theme),
      ElectronicAcknowledgmentPdfClausesSection(theme: theme),
      ElectronicAcknowledgmentPdfApprovalSection(
        signature: payload.signature,
        theme: theme,
      ),
    ],
  );
}
