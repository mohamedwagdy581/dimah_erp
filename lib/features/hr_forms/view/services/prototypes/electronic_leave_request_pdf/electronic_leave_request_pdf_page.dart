import 'package:pdf/widgets.dart' as pw;

import 'electronic_leave_request_pdf_sections.dart';
import 'electronic_leave_request_pdf_theme.dart';

class ElectronicLeaveRequestPdfPayload {
  const ElectronicLeaveRequestPdfPayload({
    required this.isArabic,
    required this.logo,
    required this.employeeName,
    required this.employeeId,
    required this.position,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.replacement,
    required this.notes,
  });

  final bool isArabic;
  final pw.MemoryImage logo;
  final String employeeName;
  final String employeeId;
  final String position;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final String days;
  final String replacement;
  final String notes;
}

pw.Widget buildElectronicLeaveRequestPdfPage(
  ElectronicLeaveRequestPdfPayload payload,
) {
  final theme = ElectronicLeaveRequestPdfTheme(payload.isArabic);

  return pw.Stack(
    children: [
      _buildPageDecoration(theme),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          ElectronicLeaveRequestPdfHeader(theme: theme, logo: payload.logo),
          pw.SizedBox(height: 16),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: ElectronicLeaveRequestPdfTheme.darkBlue,
              borderRadius: pw.BorderRadius.circular(24),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                ElectronicLeaveRequestPdfEmployeeSection(
                  payload: payload,
                  theme: theme,
                ),
                ElectronicLeaveRequestPdfDetailsSection(
                  payload: payload,
                  theme: theme,
                ),
                ElectronicLeaveRequestPdfCoverageSection(
                  payload: payload,
                  theme: theme,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildFooterDecoration(theme),
        ],
      ),
    ],
  );
}

pw.Widget _buildPageDecoration(ElectronicLeaveRequestPdfTheme theme) {
  return pw.Positioned.fill(
    child: pw.Stack(
      children: [
        pw.Positioned(
          left: -84,
          top: -28,
          child: pw.Transform.rotate(
            angle: -0.45,
            child: pw.Container(
              width: 260,
              height: 150,
              decoration: pw.BoxDecoration(
                color: ElectronicLeaveRequestPdfTheme.blue,
                borderRadius: pw.BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        pw.Positioned(
          left: 0,
          top: 156,
          right: 0,
          child: pw.Container(
            height: 260,
            decoration: pw.BoxDecoration(
              color: ElectronicLeaveRequestPdfTheme.darkBlue,
            ),
          ),
        ),
        pw.Positioned(
          right: -72,
          bottom: -28,
          child: pw.Transform.rotate(
            angle: 0.42,
            child: pw.Container(
              width: 320,
              height: 190,
              decoration: pw.BoxDecoration(
                color: ElectronicLeaveRequestPdfTheme.darkBlue,
                borderRadius: pw.BorderRadius.circular(32),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildFooterDecoration(ElectronicLeaveRequestPdfTheme theme) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    height: 96,
    child: pw.Stack(
      children: [
        pw.Positioned(
          left: 0,
          top: 20,
          child: pw.Container(
            width: 160,
            height: 72,
            decoration: pw.BoxDecoration(
              color: ElectronicLeaveRequestPdfTheme.blue,
              borderRadius: pw.BorderRadius.circular(18),
            ),
          ),
        ),
        pw.Positioned(
          right: 0,
          bottom: 0,
          child: pw.Container(
            width: 220,
            height: 80,
            decoration: pw.BoxDecoration(
              color: ElectronicLeaveRequestPdfTheme.darkBlue,
              borderRadius: pw.BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    ),
  );
}
