import 'dart:typed_data';
import 'hr_form_print_layout.dart';

class HrPortalFormDraft {
  const HrPortalFormDraft({
    required this.isArabic,
    required this.isLeave,
    required this.employeeName,
    required this.employeeNumber,
    required this.department,
    required this.jobTitle,
    required this.date,
    required this.fields,
    required this.agreed,
  });
  final bool isArabic, isLeave, agreed;
  final String employeeName, employeeNumber, department, jobTitle, date;
  final Map<String, String> fields;
}

Future<Uint8List> buildHrPortalFormPdf(HrPortalFormDraft draft) =>
    buildHrPrintDocument(
      isArabic: draft.isArabic,
      isLeave: draft.isLeave,
      agreed: draft.agreed,
      employeeName: draft.employeeName,
      employeeNumber: draft.employeeNumber,
      department: draft.department,
      jobTitle: draft.jobTitle,
      date: draft.date,
      fields: draft.fields,
    );
