import 'package:pdf/widgets.dart' as pw;

import '../electronic_acknowledgment_pdf_theme.dart';
import 'electronic_acknowledgment_pdf_shared.dart';

class ElectronicAcknowledgmentPdfApprovalSection extends pw.StatelessWidget {
  ElectronicAcknowledgmentPdfApprovalSection({
    required this.signature,
    required this.theme,
  });

  final String signature;
  final ElectronicAcknowledgmentPdfTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    return electronicAcknowledgmentSection(
      theme,
      title: theme.isArabic ? 'الاعتماد' : 'Approval',
      hint: theme.isArabic ? 'حقل توقيع' : 'Signature Area',
      children: [
        electronicAcknowledgmentField(
          theme,
          theme.isArabic ? 'توقيع الموظف' : 'Employee Signature',
          signature,
        ),
      ],
    );
  }
}
