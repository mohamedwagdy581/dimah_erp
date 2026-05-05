import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../electronic_acknowledgment_pdf_theme.dart';
import 'electronic_acknowledgment_pdf_shared.dart';

class ElectronicAcknowledgmentPdfClausesSection extends pw.StatelessWidget {
  ElectronicAcknowledgmentPdfClausesSection({required this.theme});

  final ElectronicAcknowledgmentPdfTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    return electronicAcknowledgmentSection(
      theme,
      title: theme.isArabic ? 'بنود الإقرار' : 'Acknowledgment Clauses',
      hint: theme.isArabic ? 'صياغة تجريبية' : 'Prototype Copy',
      children: [
        _clause(
          '01',
          theme.isArabic ? 'سرية المعلومات' : 'Information Confidentiality',
          theme.isArabic
              ? 'أقر بأن جميع البيانات والملفات والسجلات التي أطلع عليها خلال عملي تعتبر معلومات داخلية تخص المؤسسة، وأتعهد بالمحافظة عليها وعدم نسخها أو مشاركتها إلا في حدود صلاحياتي العملية.'
              : 'I acknowledge that all records, files, and internal materials accessed during my work are confidential and may only be used within my authorized scope.',
        ),
        _clause(
          '02',
          theme.isArabic
              ? 'عدم الاحتفاظ أو الإفشاء'
              : 'No Retention or Disclosure',
          theme.isArabic
              ? 'أتعهد بعدم الاحتفاظ بأي نسخة من المعلومات أو المستندات الخاصة بالمؤسسة بعد انتهاء الحاجة العملية إليها، سواء خلال العمل أو بعد انتهاء العلاقة التعاقدية.'
              : 'I undertake not to retain or disclose company documents or data beyond operational need, whether during employment or after it ends.',
        ),
          
      ],
    );
  }

  pw.Widget _clause(String index, String title, String body) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: ElectronicAcknowledgmentPdfTheme.greenSoft,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: ElectronicAcknowledgmentPdfTheme.greenBorder,
          width: .8,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 28,
            height: 28,
            decoration: pw.BoxDecoration(
              color: ElectronicAcknowledgmentPdfTheme.green,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            alignment: pw.Alignment.center,
            child: theme.text(
              index,
              size: 8.5,
              bold: true,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                theme.text(
                  title,
                  size: 10,
                  bold: true,
                  align: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 6),
                theme.text(body, size: 9.2, align: pw.TextAlign.right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
